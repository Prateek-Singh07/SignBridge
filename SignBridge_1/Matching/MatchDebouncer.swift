//
//  MatchDebouncer.swift
//  SignBridge_1
//
//  Created by KIET2 on 23/10/26.
//

import Foundation
import UIKit

/// Manages temporal hysteresis for match confirmation and throttled VoiceOver announcements.
final class MatchDebouncer {
    // MARK: - Constants

    let requiredConsecutiveMatchFrames: Int
    let requiredConsecutiveDropFrames: Int
    let minimumAnnouncementInterval: TimeInterval

    // MARK: - State

    private var consecutiveMatchCount: Int = 0
    private var consecutiveDropCount: Int = 0
    private(set) var isStableMatch: Bool = false

    private var lastAnnouncedState: FeedbackState?
    private var lastAnnouncementDate: Date = .distantPast

    init(
        requiredConsecutiveMatchFrames: Int = 8,
        requiredConsecutiveDropFrames: Int = 8,
        minimumAnnouncementInterval: TimeInterval = 2.5
    ) {
        self.requiredConsecutiveMatchFrames = requiredConsecutiveMatchFrames
        self.requiredConsecutiveDropFrames = requiredConsecutiveDropFrames
        self.minimumAnnouncementInterval = minimumAnnouncementInterval
    }

    /// Feeds an instantaneous match evaluation result and returns the debounced feedback state.
    func process(rawResult: PoseMatchResult) -> PoseMatchResult {
        if rawResult.isMatched {
            consecutiveMatchCount += 1
            consecutiveDropCount = 0

            if consecutiveMatchCount >= requiredConsecutiveMatchFrames {
                isStableMatch = true
            }
        } else {
            consecutiveDropCount += 1
            consecutiveMatchCount = 0

            if isStableMatch {
                if consecutiveDropCount >= requiredConsecutiveDropFrames {
                    isStableMatch = false
                }
            }
        }

        let effectiveState: FeedbackState
        let effectiveHint: String?

        if isStableMatch {
            effectiveState = .goodMatch
            effectiveHint = nil
        } else {
            effectiveState = rawResult.state
            effectiveHint = rawResult.hint
        }

        announceIfNeeded(state: effectiveState, hint: effectiveHint)

        return PoseMatchResult(
            state: effectiveState,
            hint: effectiveHint,
            isMatched: isStableMatch
        )
    }

    /// Resets the debouncer state (e.g., when switching letters or retrying).
    func reset() {
        consecutiveMatchCount = 0
        consecutiveDropCount = 0
        isStableMatch = false
        lastAnnouncedState = nil
        lastAnnouncementDate = .distantPast
    }

    // MARK: - VoiceOver Throttling

    private func announceIfNeeded(state: FeedbackState, hint: String?) {
        let now = Date()
        guard state != lastAnnouncedState || now.timeIntervalSince(lastAnnouncementDate) >= minimumAnnouncementInterval else {
            return
        }

        var announcement = state.rawValue
        if let hint = hint, state == .adjustYourFingers {
            announcement += ". \(hint)"
        }

        lastAnnouncedState = state
        lastAnnouncementDate = now

        UIAccessibility.post(notification: .announcement, argument: announcement)
    }
}
