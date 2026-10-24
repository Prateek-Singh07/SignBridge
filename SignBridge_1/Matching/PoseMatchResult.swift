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
