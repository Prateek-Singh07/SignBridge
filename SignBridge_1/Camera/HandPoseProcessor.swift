//
//  HandPoseProcessor.swift
//  SignBridge_1
//
//  Created by KIET2 on 23/10/26.
//

import AVFoundation
import Combine
import CoreGraphics
import Foundation
import Vision

/// Processes camera video frames with Vision framework to detect hand landmarks
/// and evaluate pose matches.
final class HandPoseProcessor: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    // MARK: - Published UI State (MainActor)

    @Published private(set) var landmarks: [String: HandLandmark] = [:]
    @Published private(set) var matchResult: PoseMatchResult = .noHand
    @Published private(set) var videoDimensions: CGSize = CGSize(width: 720, height: 1280)

    // MARK: - Properties

    let processingQueue = DispatchQueue(label: "com.signbridge.videoDataQueue", qos: .userInitiated)
    private var isProcessingFrame = false
    private let debouncer = MatchDebouncer()
    let motionTracker = HandMotionTracker()
    private var hasLoggedFirstFrame = false
    private var hasLoggedFirstRecognition = false

    var targetLetter: ASLLetter = .b {
        didSet {
            debouncer.reset()
            motionTracker.reset()
        }
    }

    private let handPoseRequest: VNDetectHumanHandPoseRequest = {
        let request = VNDetectHumanHandPoseRequest()
        request.maximumHandCount = 1
        return request
    }()

    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        // Drop frames while previous frame is still being processed
        guard !isProcessingFrame else { return }
        isProcessingFrame = true

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            isProcessingFrame = false
            return
        }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let frameSize = CGSize(width: CGFloat(width), height: CGFloat(height))

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        do {
            try handler.perform([handPoseRequest])

            guard let observation = handPoseRequest.results?.first else {
                publishNoHandDetected(frameSize: frameSize)
                isProcessingFrame = false
                return
            }

            processObservation(observation, frameSize: frameSize)
        } catch {
            publishNoHandDetected(frameSize: frameSize)
        }

        isProcessingFrame = false
    }

    // MARK: - Observation Handling

    private func processObservation(_ observation: VNHumanHandPoseObservation, frameSize: CGSize) {
        let extractedLandmarks = extractLandmarks(from: observation)

        motionTracker.update(landmarks: extractedLandmarks)

        let rawResult = HandPoseMatcher.evaluate(
            landmarks: extractedLandmarks,
            for: targetLetter,
            motionTracker: motionTracker
        )

        let debouncedResult = debouncer.process(rawResult: rawResult)

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.landmarks = extractedLandmarks
            self.matchResult = debouncedResult
            self.videoDimensions = frameSize
        }
    }

    private func publishNoHandDetected(frameSize: CGSize) {
        let debouncedResult = debouncer.process(rawResult: .noHand)

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.landmarks = [:]
            self.matchResult = debouncedResult
            self.videoDimensions = frameSize
        }
    }

    private func extractLandmarks(from observation: VNHumanHandPoseObservation) -> [String: HandLandmark] {
        var result: [String: HandLandmark] = [:]

        let jointMappings: [(VNHumanHandPoseObservation.JointName, String)] = [
            (.wrist, "wrist"),
            (.thumbCMC, "thumb_cmc"),
            (.thumbMP, "thumb_mp"),
            (.thumbIP, "thumb_ip"),
            (.thumbTip, "thumb_tip"),
            (.indexMCP, "index_mcp"),
            (.indexPIP, "index_pip"),
            (.indexDIP, "index_dip"),
            (.indexTip, "index_tip"),
            (.middleMCP, "middle_mcp"),
            (.middlePIP, "middle_pip"),
            (.middleDIP, "middle_dip"),
            (.middleTip, "middle_tip"),
            (.ringMCP, "ring_mcp"),
            (.ringPIP, "ring_pip"),
            (.ringDIP, "ring_dip"),
            (.ringTip, "ring_tip"),
            (.littleMCP, "little_mcp"),
            (.littlePIP, "little_pip"),
            (.littleDIP, "little_dip"),
            (.littleTip, "little_tip")
        ]

        for (jointName, key) in jointMappings {
            if let point = try? observation.recognizedPoint(jointName), point.confidence >= HandPoseMatcher.minConfidenceThreshold {
                result[key] = HandLandmark(
                    name: key,
                    point: point.location,
                    confidence: point.confidence
                )
            }
        }

        return result
    }

    /// Resets match state (e.g. for Retry button)
    func resetMatch() {
        debouncer.reset()
        motionTracker.reset()
        DispatchQueue.main.async {
            self.matchResult = .noHand
        }
    }
}
