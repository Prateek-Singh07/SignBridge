//
//  HandPoseMatcher.swift
//  SignBridge_1
//
//  Created by KIET2 on 23/10/26.
//

import CoreGraphics
import Foundation

/// Pure, UI-free, camera-free hand pose evaluator for fingerspelling.
/// Normalizes landmarks by hand size and calculates handedness-invariant geometry.
struct HandPoseMatcher {
    // MARK: - Named Constants & Thresholds

    static let minConfidenceThreshold: Float = 0.35
    static let minHandScaleThreshold: CGFloat = 0.04
    static let fingerExtendedRatio: CGFloat = 0.72
    static let fingerCurledRatio: CGFloat = 0.70
    static let thumbExtendedRatio: CGFloat = 0.60
    static let thumbFoldedRatio: CGFloat = 0.70

    // MARK: - Evaluation

    /// Evaluates hand landmarks against a target letter.
    /// - Parameters:
    ///   - landmarks: Dictionary of landmark names to HandLandmark structures.
    ///   - letter: The target letter to evaluate.
    ///   - motionTracker: Optional temporal tracker for dynamic letters (J, Z).
    /// - Returns: A PoseMatchResult indicating status, hint, and match flag.
    static func evaluate(
        landmarks: [String: HandLandmark],
        for letter: ASLLetter,
        motionTracker: HandMotionTracker? = nil
    ) -> PoseMatchResult {
        guard !landmarks.isEmpty else {
            return .noHand
        }

        // If letter is not supported for recognition, keep skeleton active but never match
        guard letter.isRecognitionSupported else {
            return PoseMatchResult(
                state: .handDetected,
                hint: nil,
                isMatched: false
            )
        }

        // Required base joints for all letters
        guard let wrist = validPoint(for: "wrist", in: landmarks),
              let middleMCP = validPoint(for: "middle_mcp", in: landmarks),
              let indexMCP = validPoint(for: "index_mcp", in: landmarks),
              let ringMCP = validPoint(for: "ring_mcp", in: landmarks),
              let littleMCP = validPoint(for: "little_mcp", in: landmarks),
              let thumbTip = validPoint(for: "thumb_tip", in: landmarks),
              let indexTip = validPoint(for: "index_tip", in: landmarks),
              let middleTip = validPoint(for: "middle_tip", in: landmarks),
              let ringTip = validPoint(for: "ring_tip", in: landmarks),
              let littleTip = validPoint(for: "little_tip", in: landmarks)
        else {
            return .adjust(hint: nil)
        }

        // Hand scale normalization based on wrist-to-middleMCP span
        let handScale = distance(wrist, middleMCP)
        guard handScale >= minHandScaleThreshold else {
            return .adjust(hint: nil)
        }

        // Optional PIP and DIP joints for detailed curl/hook evaluation
        let indexPIP = validPoint(for: "index_pip", in: landmarks)
        let middlePIP = validPoint(for: "middle_pip", in: landmarks)
        let ringPIP = validPoint(for: "ring_pip", in: landmarks)
        let littlePIP = validPoint(for: "little_pip", in: landmarks)

        // Optional thumb joints

        // Hand coordinate frame (handedness-invariant relative to palm)
        // Palm vector points from wrist to middleMCP
        let palmVec = CGPoint(x: (middleMCP.x - wrist.x) / handScale, y: (middleMCP.y - wrist.y) / handScale)
        // Transverse vector points across knuckles from littleMCP toward indexMCP (radial direction)
        let transDist = max(distance(indexMCP, littleMCP), 0.01)
        let transVec = CGPoint(x: (indexMCP.x - littleMCP.x) / transDist, y: (indexMCP.y - littleMCP.y) / transDist)

        func toHandCoords(_ pt: CGPoint) -> CGPoint {
            let rx = pt.x - wrist.x
            let ry = pt.y - wrist.y
            let y = (rx * palmVec.x + ry * palmVec.y) / handScale
            let x = (rx * transVec.x + ry * transVec.y) / handScale
            return CGPoint(x: x, y: y)
        }

        // Evaluate extension state for each non-thumb finger
        let indexExtended = isFingerExtended(tip: indexTip, mcp: indexMCP, pip: indexPIP, wrist: wrist, scale: handScale)
        let middleExtended = isFingerExtended(tip: middleTip, mcp: middleMCP, pip: middlePIP, wrist: wrist, scale: handScale)
        let ringExtended = isFingerExtended(tip: ringTip, mcp: ringMCP, pip: ringPIP, wrist: wrist, scale: handScale)
        let littleExtended = isFingerExtended(tip: littleTip, mcp: littleMCP, pip: littlePIP, wrist: wrist, scale: handScale)

        // Evaluate curled state for non-thumb fingers
        let indexCurled = isFingerCurled(tip: indexTip, mcp: indexMCP, pip: indexPIP, wrist: wrist, scale: handScale)
        let middleCurled = isFingerCurled(tip: middleTip, mcp: middleMCP, pip: middlePIP, wrist: wrist, scale: handScale)
        let ringCurled = isFingerCurled(tip: ringTip, mcp: ringMCP, pip: ringPIP, wrist: wrist, scale: handScale)
        let littleCurled = isFingerCurled(tip: littleTip, mcp: littleMCP, pip: littlePIP, wrist: wrist, scale: handScale)

        // Thumb geometry
        let thumbSpan = distance(thumbTip, indexMCP) / handScale
        let thumbExtended = thumbSpan >= thumbExtendedRatio
        let thumbFolded = thumbSpan < thumbFoldedRatio

        let thumbCoords = toHandCoords(thumbTip)
        let indexMCPCoords = toHandCoords(indexMCP)
        let middleMCPCoords = toHandCoords(middleMCP)
        let ringMCPCoords = toHandCoords(ringMCP)

        switch letter {
        // MARK: - A
        case .a:
            // Fist with thumb resting upright alongside index finger (radial side)
            let allCurled = indexCurled && middleCurled && ringCurled && littleCurled
            let thumbAlongside = thumbCoords.x >= indexMCPCoords.x - 0.04 && thumbCoords.y > 0.48

            if allCurled && thumbAlongside {
                return .match
            } else if !allCurled {
                return .adjust(hint: "Curl your four fingers into a fist")
            } else {
                return .adjust(hint: "Rest your thumb upright against the side of your index finger")
            }

        // MARK: - B (Preserved existing rule)
        case .b:
            let allFingersExtended = indexExtended && middleExtended && ringExtended && littleExtended
            if allFingersExtended && thumbFolded {
                return .match
            } else if allFingersExtended && !thumbFolded {
                return .adjust(hint: "Fold your thumb across your palm")
            } else {
                return .adjust(hint: "Extend your fingers straight up")
            }

        // MARK: - C
        case .c:
            // Curved hand in open 'C' arch
            let indexTipDist = distance(indexTip, indexMCP) / handScale
            let middleTipDist = distance(middleTip, middleMCP) / handScale
            let isCurved = (indexTipDist >= 0.30 && indexTipDist < 0.85) &&
                           (middleTipDist >= 0.30 && middleTipDist < 0.85)
            let gap = distance(thumbTip, indexTip) / handScale
            let hasOpenCGap = gap >= 0.22 && gap <= 1.05

            if isCurved && hasOpenCGap && !indexExtended && !middleExtended {
                return .match
            } else if gap < 0.22 {
                return .adjust(hint: "Open your hand slightly to form a 'C'")
            } else {
                return .adjust(hint: "Curve your fingers and thumb to form an open 'C' shape")
            }

        // MARK: - D
        case .d:
            // Index upright, middle/ring/pinky touching or held by thumb in a ring
            let isUpward = indexTip.y > indexMCP.y - 0.05
            let othersCurled = !middleExtended && !ringExtended && !littleExtended
            let thumbTouchesMiddle = distance(thumbTip, middleTip) / handScale < 0.58 ||
                                    distance(thumbTip, ringTip) / handScale < 0.58

            if isUpward && indexExtended && othersCurled && thumbTouchesMiddle {
                return .match
            } else if !isUpward || !indexExtended {
                return .adjust(hint: "Point your index finger straight up")
            } else if !thumbTouchesMiddle {
                return .adjust(hint: "Touch your thumb to your middle and ring fingertips")
            } else {
                return .adjust(hint: "Curl your other three fingers")
            }

        // MARK: - E
        case .e:
            // All fingers curled down with tips resting against thumb folded beneath them
            let allCurled = indexCurled && middleCurled && ringCurled && littleCurled
            let thumbFoldedBelow = thumbCoords.y < 0.90
            let tipsNearThumb = distance(indexTip, thumbTip) / handScale < 0.62 ||
                                distance(middleTip, thumbTip) / handScale < 0.62

            if allCurled && thumbFoldedBelow && tipsNearThumb {
                return .match
            } else if !allCurled {
                return .adjust(hint: "Curl all four fingers down into your palm")
            } else {
                return .adjust(hint: "Rest your curled fingertips against your folded thumb")
            }

        // MARK: - F
        case .f:
            // Index and thumb tip touch forming a circle, other three fingers extended straight up
            let circleFormed = distance(indexTip, thumbTip) / handScale < 0.48
            let threeExtended = middleExtended && ringExtended && littleExtended

            if circleFormed && threeExtended {
                return .match
            } else if !circleFormed {
                return .adjust(hint: "Touch the tips of your index finger and thumb together")
            } else {
                return .adjust(hint: "Extend your middle, ring, and little fingers straight up")
            }

        // MARK: - G
        case .g:
            // Index finger and thumb pointing sideways horizontally, others curled
            let indexVec = CGPoint(x: indexTip.x - indexMCP.x, y: indexTip.y - indexMCP.y)
            let isHorizontal = abs(indexVec.x) > abs(indexVec.y) * 0.48
            let indexExtendedHoriz = hypot(indexVec.x, indexVec.y) / handScale >= 0.60
            let othersCurled = !middleExtended && !ringExtended && !littleExtended
            let thumbOut = distance(thumbTip, indexMCP) / handScale >= 0.30

            if indexExtendedHoriz && isHorizontal && othersCurled && thumbOut {
                return .match
            } else if !isHorizontal {
                return .adjust(hint: "Point your index finger horizontally sideways")
            } else if !othersCurled {
                return .adjust(hint: "Curl your other three fingers into your palm")
            } else {
                return .adjust(hint: "Extend your thumb parallel along your index finger")
            }

        // MARK: - H
        case .h:
            // Index and middle fingers extended together horizontally sideways
            let indexVec = CGPoint(x: indexTip.x - indexMCP.x, y: indexTip.y - indexMCP.y)
            let middleVec = CGPoint(x: middleTip.x - middleMCP.x, y: middleTip.y - middleMCP.y)
            let isHoriz = abs(indexVec.x) > abs(indexVec.y) * 0.48 && abs(middleVec.x) > abs(middleVec.y) * 0.48
            let bothExtended = (hypot(indexVec.x, indexVec.y) / handScale >= 0.60) &&
                               (hypot(middleVec.x, middleVec.y) / handScale >= 0.60)
            let together = distance(indexTip, middleTip) / handScale < 0.38
            let othersCurled = !ringExtended && !littleExtended

            if bothExtended && isHoriz && together && othersCurled {
                return .match
            } else if !isHoriz {
                return .adjust(hint: "Point your index and middle fingers sideways")
            } else if !together {
                return .adjust(hint: "Keep your index and middle fingers held together")
            } else {
                return .adjust(hint: "Curl your ring and little fingers into your palm")
            }

        // MARK: - I (Preserved existing rule)
        case .i:
            let othersCurled = !indexExtended && !middleExtended && !ringExtended
            if littleExtended && !thumbExtended && othersCurled {
                return .match
            } else if !littleExtended {
                return .adjust(hint: "Extend your little finger")
            } else if thumbExtended {
                return .adjust(hint: "Fold your thumb across your fingers")
            } else {
                return .adjust(hint: "Curl your other three fingers")
            }

        // MARK: - J (Temporal tracking)
        case .j:
            let othersCurled = !indexExtended && !middleExtended && !ringExtended

            guard othersCurled else {
                return .adjust(hint: "Hold your little finger up with other fingers curled")
            }

            if let tracker = motionTracker {
                let motionResult = tracker.checkJMotion(scale: handScale)
                if motionResult.isComplete {
                    return .match
                } else if let hint = motionResult.hint {
                    return .adjust(hint: hint)
                }
            }
            return .adjust(hint: "Draw a 'J' hook in the air with your little finger")

        // MARK: - K
        case .k:
            // Index upright, middle tilted forward, thumb between them near middle PIP
            let isUpward = indexTip.y > indexMCP.y - 0.05
            let twoExtended = indexExtended && middleExtended && !ringExtended && !littleExtended
            let thumbBetween = thumbCoords.x > middleMCPCoords.x - 0.20 &&
                               thumbCoords.x < indexMCPCoords.x + 0.20 &&
                               thumbCoords.y > 0.55

            if isUpward && twoExtended && thumbBetween {
                return .match
            } else if !isUpward {
                return .adjust(hint: "Point your fingers upright")
            } else if !twoExtended {
                return .adjust(hint: "Extend your index and middle fingers, curling the others")
            } else {
                return .adjust(hint: "Place your thumb between your index and middle fingers")
            }

        // MARK: - L (Validated existing rule)
        case .l:
            let othersCurled = !middleExtended && !ringExtended && !littleExtended
            if indexExtended && thumbExtended && othersCurled {
                return .match
            } else if !indexExtended {
                return .adjust(hint: "Extend your index finger")
            } else if !thumbExtended {
                return .adjust(hint: "Extend your thumb out to the side")
            } else {
                return .adjust(hint: "Curl your other fingers")
            }

        // MARK: - M
        case .m:
            // Fist with thumb tucked under 3 fingers (emerging under ring finger)
            let allCurled = indexCurled && middleCurled && ringCurled && littleCurled
            let thumbUnderThree = thumbCoords.x <= ringMCPCoords.x + 0.02 && thumbCoords.y > 0.48

            if allCurled && thumbUnderThree {
                return .match
            } else if !allCurled {
                return .adjust(hint: "Curl your fingers into a fist")
            } else {
                return .adjust(hint: "Tuck your thumb under your first three fingers (index, middle, ring)")
            }

        // MARK: - N
        case .n:
            // Fist with thumb tucked under 2 fingers (emerging between middle and ring)
            let allCurled = indexCurled && middleCurled && ringCurled && littleCurled
            let thumbBetweenMidRing = thumbCoords.x > ringMCPCoords.x - 0.02 &&
                                     thumbCoords.x <= middleMCPCoords.x + 0.02 &&
                                     thumbCoords.y > 0.48

            if allCurled && thumbBetweenMidRing {
                return .match
            } else if !allCurled {
                return .adjust(hint: "Curl your fingers into a fist")
            } else {
                return .adjust(hint: "Tuck your thumb under your index and middle fingers")
            }

        // MARK: - O
        case .o:
            // All fingertips touch thumb forming an 'O'
            let indexTouch = distance(indexTip, thumbTip) / handScale < 0.45
            let middleTouch = distance(middleTip, thumbTip) / handScale < 0.50
            let notFlat = !indexExtended && !middleExtended

            if indexTouch && middleTouch && notFlat {
                return .match
            } else {
                return .adjust(hint: "Touch all your fingertips to your thumb to form an 'O'")
            }

        // MARK: - P
        case .p:
            // Downward-oriented K: wrist above index/middle in Vision coordinates
            let isDownward = indexTip.y < indexMCP.y + 0.05
            let twoExtended = (distance(indexTip, indexMCP) / handScale >= 0.58) &&
                              (distance(middleTip, middleMCP) / handScale >= 0.55) &&
                              !ringExtended && !littleExtended

            if isDownward && twoExtended {
                return .match
            } else if !isDownward {
                return .adjust(hint: "Point your 'K' handshape downward towards the ground")
            } else {
                return .adjust(hint: "Extend index and middle fingers in a 'K' handshape")
            }

        // MARK: - Q
        case .q:
            // Downward-oriented G: index and thumb pointing downward
            let isDownward = indexTip.y < indexMCP.y + 0.05
            let indexExtendedDown = distance(indexTip, indexMCP) / handScale >= 0.55
            let othersCurled = !middleExtended && !ringExtended && !littleExtended

            if isDownward && indexExtendedDown && othersCurled {
                return .match
            } else if !isDownward {
                return .adjust(hint: "Point your index finger and thumb downward")
            } else {
                return .adjust(hint: "Curl your other three fingers into your palm")
            }

        // MARK: - R
        case .r:
            // Index and middle fingers extended upright and crossed
            let twoExtended = indexExtended && middleExtended && !ringExtended && !littleExtended
            let separation = distance(indexTip, middleTip) / handScale
            let crossed = separation < 0.35

            if twoExtended && crossed {
                return .match
            } else if !twoExtended {
                return .adjust(hint: "Extend your index and middle fingers")
            } else {
                return .adjust(hint: "Cross your middle finger over your index finger")
            }

        // MARK: - S
        case .s:
            // Fist with thumb wrapped across front of fingers
            let allCurled = indexCurled && middleCurled && ringCurled && littleCurled
            let thumbAcrossFront = thumbCoords.x <= indexMCPCoords.x + 0.08 && thumbCoords.y > 0.52

            if allCurled && thumbAcrossFront {
                return .match
            } else if !allCurled {
                return .adjust(hint: "Curl your fingers into a tight fist")
            } else {
                return .adjust(hint: "Wrap your thumb firmly across the front of your curled fingers")
            }

        // MARK: - T
        case .t:
            // Fist with thumb tucked between index and middle
            let allCurled = indexCurled && middleCurled && ringCurled && littleCurled
            let thumbTucked = thumbCoords.x > middleMCPCoords.x - 0.02 &&
                              thumbCoords.x < indexMCPCoords.x - 0.02 &&
                              thumbCoords.y > 0.50

            if allCurled && thumbTucked {
                return .match
            } else if !allCurled {
                return .adjust(hint: "Curl your fingers into a fist")
            } else {
                return .adjust(hint: "Tuck your thumb between your index and middle fingers")
            }

        // MARK: - U
        case .u:
            // Index & middle extended straight up, held tightly together
            let twoExtended = indexExtended && middleExtended && !ringExtended && !littleExtended
            let separation = distance(indexTip, middleTip) / handScale
            let together = separation < 0.30

            if twoExtended && together {
                return .match
            } else if !twoExtended {
                return .adjust(hint: "Extend your index and middle fingers straight up")
            } else {
                return .adjust(hint: "Hold your index and middle fingers tightly together")
            }

        // MARK: - V (Preserved existing rule + distinct U/V spread check)
        case .v:
            let indexAndMiddle = indexExtended && middleExtended
            let othersCurled = !ringExtended && !littleExtended
            let separation = distance(indexTip, middleTip) / handScale
            let spreadApart = separation >= 0.30

            if indexAndMiddle && othersCurled && spreadApart {
                return .match
            } else if !indexAndMiddle {
                return .adjust(hint: "Extend your index and middle fingers")
            } else if !spreadApart {
                return .adjust(hint: "Spread your index and middle fingers apart in a 'V'")
            } else {
                return .adjust(hint: "Curl your ring and little fingers")
            }

        // MARK: - W (Preserved existing rule)
        case .w:
            let threeExtended = indexExtended && middleExtended && ringExtended
            let littleCurled = !littleExtended
            if threeExtended && littleCurled {
                return .match
            } else if !threeExtended {
                return .adjust(hint: "Extend your index, middle, and ring fingers")
            } else {
                return .adjust(hint: "Hold your little finger down")
            }

        // MARK: - X
        case .x:
            // Fist with index finger bent into a curved hook
            let othersCurled = !middleExtended && !ringExtended && !littleExtended
            let indexTipDist = distance(indexTip, indexMCP) / handScale
            let indexHooked = indexTipDist >= 0.25 && indexTipDist <= 0.80 && !indexExtended

            if indexHooked && othersCurled {
                return .match
            } else if !othersCurled {
                return .adjust(hint: "Curl your middle, ring, and little fingers")
            } else if indexExtended {
                return .adjust(hint: "Bend your index finger into a hook shape")
            } else {
                return .adjust(hint: "Raise your index finger bent like a hook")
            }

        // MARK: - Y (Validated existing rule)
        case .y:
            let othersCurled = !indexExtended && !middleExtended && !ringExtended
            if thumbExtended && littleExtended && othersCurled {
                return .match
            } else if !littleExtended {
                return .adjust(hint: "Extend your little finger")
            } else if !thumbExtended {
                return .adjust(hint: "Extend your thumb out")
            } else {
                return .adjust(hint: "Curl your other three fingers")
            }

        // MARK: - Z (Temporal tracking)
        case .z:
            let othersCurled = !middleExtended && !ringExtended && !littleExtended

            guard othersCurled else {
                return .adjust(hint: "Point your index finger up with other fingers curled")
            }

            if let tracker = motionTracker {
                let motionResult = tracker.checkZMotion(scale: handScale)
                if motionResult.isComplete {
                    return .match
                } else if let hint = motionResult.hint {
                    return .adjust(hint: hint)
                }
            }
            return .adjust(hint: "Trace a 'Z' in the air with your index finger")
        }
    }

    // MARK: - Helpers

    static func validPoint(for key: String, in landmarks: [String: HandLandmark]) -> CGPoint? {
        guard let landmark = landmarks[key], landmark.confidence >= minConfidenceThreshold else {
            return nil
        }
        return landmark.point
    }

    static func distance(_ p1: CGPoint, _ p2: CGPoint) -> CGFloat {
        hypot(p1.x - p2.x, p1.y - p2.y)
    }

    static func isFingerExtended(
        tip: CGPoint,
        mcp: CGPoint,
        pip: CGPoint?,
        wrist: CGPoint,
        scale: CGFloat
    ) -> Bool {
        let tipToMCP = distance(tip, mcp) / scale
        let tipToWrist = distance(tip, wrist)

        if let pip = pip {
            let pipToWrist = distance(pip, wrist)
            return tipToMCP >= fingerExtendedRatio && tipToWrist > pipToWrist
        }

        return tipToMCP >= fingerExtendedRatio
    }

    static func isFingerCurled(
        tip: CGPoint,
        mcp: CGPoint,
        pip: CGPoint?,
        wrist: CGPoint,
        scale: CGFloat
    ) -> Bool {
        let tipToMCP = distance(tip, mcp) / scale
        let tipToWrist = distance(tip, wrist)

        if let pip = pip {
            let pipToWrist = distance(pip, wrist)
            return tipToMCP <= fingerCurledRatio || tipToWrist <= pipToWrist
        }

        return tipToMCP <= fingerCurledRatio
    }
}
