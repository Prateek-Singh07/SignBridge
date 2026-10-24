//
//  CameraSessionManager.swift
//  SignBridge_1
//
//  Created by KIET2 on 23/10/26.
//

import AVFoundation
import Combine
import Foundation

/// Possible camera authorization and availability states.
enum CameraPermissionState: Equatable {
    case notDetermined
    case running
    case denied
    case restricted
    case unavailable(reason: String)
}

/// Manages the AVCaptureSession lifecycle strictly off the main thread on a dedicated serial queue.
final class CameraSessionManager: ObservableObject {
    static let shared = CameraSessionManager()

    // MARK: - Published Properties

    @Published private(set) var permissionState: CameraPermissionState = .notDetermined

    // MARK: - Core AVFoundation Properties

    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.signbridge.cameraSessionQueue")
    private let videoOutput = AVCaptureVideoDataOutput()
    private var isConfigured = false

    // MARK: - Public API

    /// Checks or requests permission and configures the session.
    func setupAndStart(sampleBufferDelegate: AVCaptureVideoDataOutputSampleBufferDelegate, queue: DispatchQueue) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            configureAndStart(delegate: sampleBufferDelegate, queue: queue)

        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard let self = self else { return }
                if granted {
                    self.configureAndStart(delegate: sampleBufferDelegate, queue: queue)
                } else {
                    DispatchQueue.main.async {
                        self.permissionState = .denied
                    }
                }
            }

        case .denied:
            DispatchQueue.main.async {
                self.permissionState = .denied
            }

        case .restricted:
            DispatchQueue.main.async {
                self.permissionState = .restricted
            }

        @unknown default:
            DispatchQueue.main.async {
                self.permissionState = .denied
            }
        }
    }

    /// Retries session initialization if previously failed.
    func retry(sampleBufferDelegate: AVCaptureVideoDataOutputSampleBufferDelegate, queue: DispatchQueue) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.isConfigured = false
        }
        setupAndStart(sampleBufferDelegate: sampleBufferDelegate, queue: queue)
    }

    /// Starts running the capture session on the dedicated queue.
    func prewarm() {}

    func start() {
        sessionQueue.async { [weak self] in
            guard let self = self, self.isConfigured, !self.session.isRunning else { return }
            self.session.startRunning()
            DispatchQueue.main.async {
                self.permissionState = .running
            }
        }
    }

    /// Stops running the capture session on the dedicated queue.
    func stop() {
        sessionQueue.async { [weak self] in
            guard let self = self, self.session.isRunning else { return }
            self.videoOutput.setSampleBufferDelegate(nil, queue: nil)
            self.session.stopRunning()
            DispatchQueue.main.async {
                self.permissionState = .notDetermined
            }
        }
    }

    // MARK: - Private Configuration

    private func configureAndStart(delegate: AVCaptureVideoDataOutputSampleBufferDelegate, queue: DispatchQueue) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            guard !self.isConfigured else {
                self.videoOutput.setSampleBufferDelegate(delegate, queue: queue)
                if !self.session.isRunning {
                    self.session.startRunning()
                }
                DispatchQueue.main.async {
                    self.permissionState = .running
                }
                return
            }

            self.session.beginConfiguration()
            self.session.sessionPreset = .high

            // Select front camera with graceful fallback to back camera
            let device: AVCaptureDevice?
            if let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
                device = frontCamera
            } else if let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                device = backCamera
            } else {
                device = AVCaptureDevice.default(for: .video)
            }

            guard let captureDevice = device else {
                self.session.commitConfiguration()
                DispatchQueue.main.async {
                    self.permissionState = .unavailable(reason: "No compatible camera device found.")
                }
                return
            }

            do {
                let input = try AVCaptureDeviceInput(device: captureDevice)
                if self.session.canAddInput(input) {
                    self.session.addInput(input)
                } else {
                    self.session.commitConfiguration()
                    DispatchQueue.main.async {
                        self.permissionState = .unavailable(reason: "Cannot attach camera input.")
                    }
                    return
                }
            } catch {
                self.session.commitConfiguration()
                DispatchQueue.main.async {
                    self.permissionState = .unavailable(reason: "Failed to initialize camera input: \(error.localizedDescription)")
                }
                return
            }

            // Configure video output
            self.videoOutput.alwaysDiscardsLateVideoFrames = true
            self.videoOutput.setSampleBufferDelegate(delegate, queue: queue)

            if self.session.canAddOutput(self.videoOutput) {
                self.session.addOutput(self.videoOutput)
            } else {
                self.session.commitConfiguration()
                DispatchQueue.main.async {
                    self.permissionState = .unavailable(reason: "Cannot attach camera output.")
                }
                return
            }

            // Configure connection orientation & mirroring
            if let connection = self.videoOutput.connection(with: .video) {
                if #available(iOS 17.0, *), connection.isVideoRotationAngleSupported(90) {
                    connection.videoRotationAngle = 90
                } else if connection.isVideoOrientationSupported {
                    connection.videoOrientation = .portrait
                }

                if connection.isVideoMirroringSupported {
                    let isMac: Bool = {
                        #if targetEnvironment(macCatalyst)
                        return true
                        #else
                        return ProcessInfo.processInfo.isiOSAppOnMac
                        #endif
                    }()
                    connection.automaticallyAdjustsVideoMirroring = false
                    connection.isVideoMirrored = (captureDevice.position == .front || isMac)
                }
            }

            self.session.commitConfiguration()
            self.isConfigured = true

            self.session.startRunning()
            DispatchQueue.main.async {
                self.permissionState = .running
            }
        }
    }
}
