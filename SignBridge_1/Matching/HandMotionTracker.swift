//
//  HandMotionTracker.swift
//  SignBridge_1
//
//  Created by KIET2 on 24/10/26.
//

import CoreGraphics
import Foundation

/// Tracks temporal hand landmark movement trajectories for dynamic letters (J and Z).
final class HandMotionTracker {
    struct TimedPoint {
        let point: CGPoint
        let timestamp: TimeInterval
    }

    private var littleTipHistory: [TimedPoint] = []
    private var indexTipHistory: [TimedPoint] = []

    /// Maximum duration of history window in seconds
    private let maxHistoryDuration: TimeInterval = 2.0

    /// Holds match state temporarily after motion completes to allow debouncing confirmation
    private var completedJUntil: TimeInterval = 0
    private var completedZUntil: TimeInterval = 0

    // MARK: - Update & Reset

    func update(landmarks: [String: HandLandmark]) {
        let now = ProcessInfo.processInfo.systemUptime

        if let little = landmarks["little_tip"] {
            littleTipHistory.append(TimedPoint(point: little.point, timestamp: now))
        }
        if let index = landmarks["index_tip"] {
            indexTipHistory.append(TimedPoint(point: index.point, timestamp: now))
        }

        // Trim expired points
        littleTipHistory.removeAll { now - $0.timestamp > maxHistoryDuration }
        indexTipHistory.removeAll { now - $0.timestamp > maxHistoryDuration }
    }

    func reset() {
        littleTipHistory.removeAll()
        indexTipHistory.removeAll()
        completedJUntil = 0
        completedZUntil = 0
    }

    // MARK: - Motion Evaluation

    /// Evaluates if the little finger has recently drawn a 'J' hook motion (downward then curved upward).
    func checkJMotion(scale: CGFloat) -> (isComplete: Bool, hint: String?) {
        let now = ProcessInfo.processInfo.systemUptime
        if now < completedJUntil {
            return (true, nil)
        }

        guard littleTipHistory.count >= 6 else {
            return (false, "Draw a 'J' hook in the air with your pinky")
        }

        // Analyze trajectory: downwards stroke, followed by curve upwards
        let points = littleTipHistory.map { $0.point }
        let startY = points.first!.y
        var minY = startY
        var minIndex = 0

        for (i, p) in points.enumerated() {
            if p.y < minY {
                minY = p.y
                minIndex = i
            }
        }

        // Downward travel threshold (in Vision coords, downward is decreasing y)
        let downwardTravel = startY - minY
        let minDownwardRequired = max(0.03, scale * 0.15)

        guard downwardTravel >= minDownwardRequired else {
            return (false, "Draw a 'J' hook in the air with your pinky")
        }

        // After the lowest point, check for upward hook and lateral sweep
        let hookPoints = points[minIndex...]
        guard hookPoints.count >= 2 else {
            return (false, "Now curve your pinky upward into a hook")
        }

        let lowestPt = points[minIndex]
        let endPt = hookPoints.last!
        let upwardHook = endPt.y - lowestPt.y
        let lateralSweep = abs(endPt.x - lowestPt.x)

        let minUpwardRequired = max(0.015, scale * 0.08)
        let minLateralRequired = max(0.015, scale * 0.08)

        if upwardHook >= minUpwardRequired && lateralSweep >= minLateralRequired {
            // Motion confirmed! Hold for 0.8s to allow debouncer confirmation
            completedJUntil = now + 0.8
            return (true, nil)
        } else if downwardTravel >= minDownwardRequired {
            return (false, "Now curve upward to finish the 'J'")
        }

        return (false, "Draw a 'J' hook in the air with your pinky")
    }

    /// Evaluates if the index finger has recently traced a 'Z' pattern (stroke right, diagonal down-left, stroke right).
    func checkZMotion(scale: CGFloat) -> (isComplete: Bool, hint: String?) {
        let now = ProcessInfo.processInfo.systemUptime
        if now < completedZUntil {
            return (true, nil)
        }

        guard indexTipHistory.count >= 6 else {
            return (false, "Trace a 'Z' in the air with your index finger")
        }

        let points = indexTipHistory.map { $0.point }
        let minStrokeLen = max(0.025, scale * 0.14)

        let start = points.first!
        var corner1Index: Int? = nil
        var currentDirX: CGFloat = 0

        // Find Corner 1: first point where horizontal displacement exceeds minStrokeLen
        for (i, p) in points.enumerated() {
            let dx = p.x - start.x
            if abs(dx) >= minStrokeLen {
                currentDirX = dx > 0 ? 1 : -1
                corner1Index = i
                break
            }
        }

        guard let c1 = corner1Index else {
            return (false, "Trace a 'Z' in the air with your index finger")
        }

        // Expand Corner 1 to the actual turning point (furthest in currentDirX)
        var c1Pt = points[c1]
        var corner2SearchStart = c1
        for i in c1..<points.count {
            let p = points[i]
            if (p.x - c1Pt.x) * currentDirX > 0 {
                c1Pt = p
                corner2SearchStart = i
            } else if (c1Pt.x - p.x) * currentDirX >= minStrokeLen * 0.4 {
                break
            }
        }

        // Find Corner 2: diagonal stroke moving opposite to currentDirX and downward
        var corner2Index: Int? = nil
        var c2Pt = c1Pt
        for i in corner2SearchStart..<points.count {
            let p = points[i]
            let dx = p.x - c1Pt.x
            let dy = p.y - c1Pt.y
            if (dx * currentDirX <= -minStrokeLen * 0.5) && (dy <= -minStrokeLen * 0.3) {
                if corner2Index == nil || (p.x - c2Pt.x) * currentDirX < 0 || p.y < c2Pt.y {
                    c2Pt = p
                    corner2Index = i
                }
            }
        }

        guard let c2 = corner2Index else {
            return (false, "Trace diagonally down across")
        }

        // Check Stroke 3: horizontal motion from Corner 2 back in currentDirX
        var stroke3Complete = false
        for i in c2..<points.count {
            let p = points[i]
            let dx = p.x - c2Pt.x
            if dx * currentDirX >= minStrokeLen * 0.5 {
                stroke3Complete = true
                break
            }
        }

        if stroke3Complete {
            completedZUntil = now + 0.8
            return (true, nil)
        } else {
            return (false, "Complete the final horizontal stroke of the 'Z'")
        }
    }
}
