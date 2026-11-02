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
    @Published private(set) var detectedHands: [DetectedHand] = []
    @Published private(set) var multiHandPose: MultiHandPose = .empty
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
        request.maximumHandCount = 2
        return request
    }()

    // Internal state for stable hand identification across frames (accessed on processingQueue)
    private struct TrackedState {
        var id: Int
        var chirality: HandChirality
        var wristLocation: CGPoint?
    }
    private var trackedHands: [TrackedState] = []

    private struct RawHandData {
        let landmarks: [String: HandLandmark]
        let wrist: CGPoint?
        let chirality: HandChirality
        let confidence: Float
    }

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

            let observations = handPoseRequest.results ?? []
            if observations.isEmpty {
                trackedHands.removeAll()
                publishNoHandDetected(frameSize: frameSize)
            } else {
                processObservations(observations, frameSize: frameSize)
            }
        } catch {
            trackedHands.removeAll()
            publishNoHandDetected(frameSize: frameSize)
        }

        isProcessingFrame = false
    }

    // MARK: - Observation Handling

    private func processObservations(_ observations: [VNHumanHandPoseObservation], frameSize: CGSize) {
        // Cap to at most 2 observations
        let validObservations = Array(observations.prefix(2))

        var rawHands: [RawHandData] = []
        for obs in validObservations {
            let extracted = extractLandmarks(from: obs)
            let wrist = extracted["wrist"]?.point ?? centroid(from: extracted)
            let chirality: HandChirality
            switch obs.chirality {
            case .left:
                chirality = .left
            case .right:
                chirality = .right
            default:
                chirality = .unknown
            }
            let avgConfidence: Float
            if !extracted.isEmpty {
                let sum = extracted.values.reduce(0.0) { $0 + $1.confidence }
                avgConfidence = sum / Float(extracted.count)
            } else {
                avgConfidence = 0
            }

            rawHands.append(RawHandData(
                landmarks: extracted,
                wrist: wrist,
                chirality: chirality,
                confidence: avgConfidence
            ))
        }

        let activeRawHands = rawHands.filter { !$0.landmarks.isEmpty }
        guard !activeRawHands.isEmpty else {
            trackedHands.removeAll()
            publishNoHandDetected(frameSize: frameSize)
            return
        }

        let detected = assignStableHands(from: activeRawHands)
        let multiPose = MultiHandPose(hands: detected)

        motionTracker.update(multiHandPose: multiPose)

        let rawResult = HandPoseMatcher.evaluate(
            multiHandPose: multiPose,
            for: targetLetter,
            motionTracker: motionTracker
        )

        let debouncedResult = debouncer.process(rawResult: rawResult)

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.detectedHands = detected
            self.multiHandPose = multiPose
            self.landmarks = multiPose.primaryHand?.landmarks ?? [:]
            self.matchResult = debouncedResult
            self.videoDimensions = frameSize
        }
    }

    // MARK: - Stable Hand Assignment

    private func assignStableHands(from rawHands: [RawHandData]) -> [DetectedHand] {
        if rawHands.count == 1 {
            let raw = rawHands[0]
            let stableId: Int
            if let existing = trackedHands.first {
                stableId = existing.id
            } else {
                stableId = (raw.chirality == .left) ? 2 : 1
            }
            let finalChirality = (raw.chirality != .unknown) ? raw.chirality : (trackedHands.first(where: { $0.id == stableId })?.chirality ?? .unknown)
            trackedHands = [TrackedState(id: stableId, chirality: finalChirality, wristLocation: raw.wrist)]

            return [
                DetectedHand(
                    id: stableId,
                    chirality: finalChirality,
                    landmarks: raw.landmarks,
                    wristLocation: raw.wrist,
                    confidence: raw.confidence
                )
            ]
        }

        let rawA = rawHands[0]
        let rawB = rawHands[1]

        let idA: Int
        let idB: Int
        let chirA: HandChirality
        let chirB: HandChirality

        if trackedHands.count == 2 {
            let t0 = trackedHands[0]
            let t1 = trackedHands[1]

            func cost(_ raw: RawHandData, _ tracked: TrackedState) -> CGFloat {
                var d: CGFloat = 0.5
                if let w1 = raw.wrist, let w2 = tracked.wristLocation {
                    d = hypot(w1.x - w2.x, w1.y - w2.y)
                }
                if raw.chirality != .unknown && tracked.chirality != .unknown && raw.chirality != tracked.chirality {
                    d += 1.0
                }
                return d
            }

            let pairing1Cost = cost(rawA, t0) + cost(rawB, t1)
            let pairing2Cost = cost(rawA, t1) + cost(rawB, t0)

            if pairing1Cost <= pairing2Cost {
                idA = t0.id
                idB = t1.id
                chirA = (rawA.chirality != .unknown) ? rawA.chirality : t0.chirality
                chirB = (rawB.chirality != .unknown) ? rawB.chirality : t1.chirality
            } else {
                idA = t1.id
                idB = t0.id
                chirA = (rawA.chirality != .unknown) ? rawA.chirality : t1.chirality
                chirB = (rawB.chirality != .unknown) ? rawB.chirality : t0.chirality
            }
        } else if trackedHands.count == 1 {
            let t0 = trackedHands[0]
            let distA = (rawA.wrist != nil && t0.wristLocation != nil) ? hypot(rawA.wrist!.x - t0.wristLocation!.x, rawA.wrist!.y - t0.wristLocation!.y) : 0.5
            let distB = (rawB.wrist != nil && t0.wristLocation != nil) ? hypot(rawB.wrist!.x - t0.wristLocation!.x, rawB.wrist!.y - t0.wristLocation!.y) : 0.5

            if distA <= distB {
                idA = t0.id
                idB = (t0.id == 1) ? 2 : 1
                chirA = (rawA.chirality != .unknown) ? rawA.chirality : t0.chirality
                chirB = rawB.chirality
            } else {
                idB = t0.id
                idA = (t0.id == 1) ? 2 : 1
                chirB = (rawB.chirality != .unknown) ? rawB.chirality : t0.chirality
                chirA = rawA.chirality
            }
        } else {
            // First detection of 2 hands
            if rawA.chirality == .right || rawB.chirality == .left {
                idA = (rawA.chirality == .left) ? 2 : 1
                idB = (idA == 1) ? 2 : 1
            } else if rawA.chirality == .left || rawB.chirality == .right {
                idA = 2
                idB = 1
            } else {
                let xA = rawA.wrist?.x ?? 0.0
                let xB = rawB.wrist?.x ?? 1.0
                if xA <= xB {
                    idA = 1
                    idB = 2
                } else {
                    idA = 2
                    idB = 1
                }
            }
            chirA = rawA.chirality
            chirB = rawB.chirality
        }

        let handA = DetectedHand(id: idA, chirality: chirA, landmarks: rawA.landmarks, wristLocation: rawA.wrist, confidence: rawA.confidence)
        let handB = DetectedHand(id: idB, chirality: chirB, landmarks: rawB.landmarks, wristLocation: rawB.wrist, confidence: rawB.confidence)

        trackedHands = [
            TrackedState(id: idA, chirality: chirA, wristLocation: rawA.wrist),
            TrackedState(id: idB, chirality: chirB, wristLocation: rawB.wrist)
        ].sorted(by: { $0.id < $1.id })

        return [handA, handB].sorted(by: { $0.id < $1.id })
    }

    private func centroid(from landmarks: [String: HandLandmark]) -> CGPoint? {
        guard !landmarks.isEmpty else { return nil }
        var sumX: CGFloat = 0
        var sumY: CGFloat = 0
        for lm in landmarks.values {
            sumX += lm.point.x
            sumY += lm.point.y
        }
        return CGPoint(x: sumX / CGFloat(landmarks.count), y: sumY / CGFloat(landmarks.count))
    }

    private func publishNoHandDetected(frameSize: CGSize) {
        let debouncedResult = debouncer.process(rawResult: .noHand)

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.landmarks = [:]
            self.detectedHands = []
            self.multiHandPose = .empty
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
        processingQueue.async { [weak self] in
            self?.trackedHands.removeAll()
        }
        DispatchQueue.main.async {
            self.matchResult = .noHand
        }
    }
}

