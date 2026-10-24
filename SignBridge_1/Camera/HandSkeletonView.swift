//
//  HandSkeletonView.swift
//  SignBridge_1
//
//  Created by KIET2 on 23/10/26.
//

import SwiftUI

/// Draws hand joints and bones from normalized Vision landmarks, aligned with preview layer coordinates.
struct HandSkeletonView: View {
    let landmarks: [String: HandLandmark]
    let videoDimensions: CGSize

    // Primary skeleton blue color
    private let skeletonColor = Color(red: 0.15, green: 0.55, blue: 0.95)

    // Pairs of joint keys forming bones
    private let bones: [(String, String)] = [
        // Thumb
        ("wrist", "thumb_cmc"),
        ("thumb_cmc", "thumb_mp"),
        ("thumb_mp", "thumb_ip"),
        ("thumb_ip", "thumb_tip"),
        // Index
        ("wrist", "index_mcp"),
        ("index_mcp", "index_pip"),
        ("index_pip", "index_dip"),
        ("index_dip", "index_tip"),
        // Middle
        ("wrist", "middle_mcp"),
        ("middle_mcp", "middle_pip"),
        ("middle_pip", "middle_dip"),
        ("middle_dip", "middle_tip"),
        // Ring
        ("wrist", "ring_mcp"),
        ("ring_mcp", "ring_pip"),
        ("ring_pip", "ring_dip"),
        ("ring_dip", "ring_tip"),
        // Little
        ("wrist", "little_mcp"),
        ("little_mcp", "little_pip"),
        ("little_pip", "little_dip"),
        ("little_dip", "little_tip"),
        // Palm
        ("index_mcp", "middle_mcp"),
        ("middle_mcp", "ring_mcp"),
        ("ring_mcp", "little_mcp")
    ]

    var body: some View {
        GeometryReader { geometry in
            let viewSize = geometry.size

            Canvas { context, _ in
                // 1. Draw bones first (blue connecting lines between joints)
                for (jointAKey, jointBKey) in bones {
                    guard let landmarkA = landmarks[jointAKey],
                          let landmarkB = landmarks[jointBKey] else {
                        continue
                    }

                    let pointA = convertPoint(landmarkA.point, viewSize: viewSize)
                    let pointB = convertPoint(landmarkB.point, viewSize: viewSize)

                    var path = Path()
                    path.move(to: pointA)
                    path.addLine(to: pointB)

                    context.stroke(
                        path,
                        with: .color(skeletonColor.opacity(0.85)),
                        style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round)
                    )
                }

                // 2. Draw joints (white fill with blue outline)
                for (_, landmark) in landmarks {
                    let point = convertPoint(landmark.point, viewSize: viewSize)
                    let rect = CGRect(
                        x: point.x - 4.5,
                        y: point.y - 4.5,
                        width: 9.0,
                        height: 9.0
                    )
                    context.fill(Path(ellipseIn: rect), with: .color(Color.white))
                    context.stroke(Path(ellipseIn: rect), with: .color(skeletonColor), lineWidth: 1.5)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    // MARK: - Aspect-Fill Coordinate Conversion

    private func convertPoint(_ normPoint: CGPoint, viewSize: CGSize) -> CGPoint {
        let vw = videoDimensions.width > 0 ? videoDimensions.width : 720
        let vh = videoDimensions.height > 0 ? videoDimensions.height : 1280

        let videoAspect = vw / vh
        let viewAspect = viewSize.width / max(viewSize.height, 1)

        let scale: CGFloat
        let offsetX: CGFloat
        let offsetY: CGFloat

        if viewAspect > videoAspect {
            scale = viewSize.width / vw
            offsetX = 0
            offsetY = (viewSize.height - vh * scale) / 2.0
        } else {
            scale = viewSize.height / vh
            offsetX = (viewSize.width - vw * scale) / 2.0
            offsetY = 0
        }

        let screenX = offsetX + normPoint.x * vw * scale
        let screenY = offsetY + (1.0 - normPoint.y) * vh * scale

        return CGPoint(x: screenX, y: screenY)
    }
}
