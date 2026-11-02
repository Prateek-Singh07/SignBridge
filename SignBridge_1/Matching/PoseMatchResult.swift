//
//  PoseMatchResult.swift
//  SignBridge_1
//
//  Created by KIET2 on 23/10/26.
//

import CoreGraphics
import Foundation

/// Discrete feedback states required by the core practice experience.
enum FeedbackState: String, Equatable {
    case showYourHand = "Show your hand"
    case handDetected = "Hand detected"
    case adjustYourFingers = "Adjust your fingers"
    case goodMatch = "Good match"
}

/// A normalized hand landmark point with associated confidence.
struct HandLandmark: Equatable {
    let name: String
    let point: CGPoint
    let confidence: Float
}

/// The result of evaluating a hand pose against a target letter.
struct PoseMatchResult: Equatable {
    let state: FeedbackState
    let hint: String?
    let isMatched: Bool

    static let noHand = PoseMatchResult(
        state: .showYourHand,
        hint: nil,
        isMatched: false
    )

    static let handDetected = PoseMatchResult(
        state: .handDetected,
        hint: nil,
        isMatched: false
    )

    static func adjust(hint: String?) -> PoseMatchResult {
        PoseMatchResult(
            state: .adjustYourFingers,
            hint: hint,
            isMatched: false
        )
    }

    static let match = PoseMatchResult(
        state: .goodMatch,
        hint: nil,
        isMatched: true
    )
}

/// Chirality (handedness) of a detected hand.
enum HandChirality: String, Equatable, Codable {
    case left
    case right
    case unknown
}

/// A detected hand containing recognized landmarks and metadata.
struct DetectedHand: Identifiable, Equatable {
    let id: Int
    let chirality: HandChirality
    let landmarks: [String: HandLandmark]
    let wristLocation: CGPoint?
    let confidence: Float

    var isEmpty: Bool {
        landmarks.isEmpty
    }
}

/// Spatial and gestural relationships between two detected hands.
struct TwoHandRelationship: Equatable {
    let wristDistance: CGFloat
    let indexTipDistance: CGFloat?
    let thumbTipDistance: CGFloat?
    let relativeElevation: CGFloat // wrist1.y - wrist2.y
    let isTouching: Bool

    static func compute(hand1: DetectedHand, hand2: DetectedHand) -> TwoHandRelationship? {
        guard let wrist1 = hand1.wristLocation, let wrist2 = hand2.wristLocation else {
            return nil
        }

        let wristDist = hypot(wrist1.x - wrist2.x, wrist1.y - wrist2.y)
        let relElevation = wrist1.y - wrist2.y

        var indexDist: CGFloat? = nil
        if let idx1 = hand1.landmarks["index_tip"], let idx2 = hand2.landmarks["index_tip"] {
            indexDist = hypot(idx1.point.x - idx2.point.x, idx1.point.y - idx2.point.y)
        }

        var thumbDist: CGFloat? = nil
        if let th1 = hand1.landmarks["thumb_tip"], let th2 = hand2.landmarks["thumb_tip"] {
            thumbDist = hypot(th1.point.x - th2.point.x, th1.point.y - th2.point.y)
        }

        let isTouching = wristDist < 0.15 || (indexDist != nil && indexDist! < 0.08) || (thumbDist != nil && thumbDist! < 0.08)

        return TwoHandRelationship(
            wristDistance: wristDist,
            indexTipDistance: indexDist,
            thumbTipDistance: thumbDist,
            relativeElevation: relElevation,
            isTouching: isTouching
        )
    }
}

/// Container for all hands detected in a camera frame.
struct MultiHandPose: Equatable {
    let hands: [DetectedHand]

    var primaryHand: DetectedHand? {
        hands.first(where: { $0.chirality == .right }) ?? hands.first
    }

    var secondaryHand: DetectedHand? {
        if let primary = primaryHand {
            return hands.first(where: { $0.id != primary.id })
        }
        return nil
    }

    var leftHand: DetectedHand? {
        hands.first(where: { $0.chirality == .left })
    }

    var rightHand: DetectedHand? {
        hands.first(where: { $0.chirality == .right })
    }

    var relationship: TwoHandRelationship? {
        guard hands.count >= 2 else { return nil }
        return TwoHandRelationship.compute(hand1: hands[0], hand2: hands[1])
    }

    var isEmpty: Bool { hands.isEmpty }
    var handCount: Int { hands.count }

    static let empty = MultiHandPose(hands: [])
}

