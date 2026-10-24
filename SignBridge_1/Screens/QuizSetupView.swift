//
//  QuizSetupView.swift
//  SignBridge_1
//
//  Created by KIET2 on 24/10/26.
//

import SwiftUI

/// Warm, minimal setup screen for configuring Quiz Mode parameters.
/// Allows learners to pick question count (5, 10, or 15) and review testing guidelines.
struct QuizSetupView: View {
    @Binding var isQuizActive: Bool

    @Environment(\.dismiss) private var dismiss
    @State private var selectedCount: Int = 10
    @State private var isQuestionActive: Bool = false

    private let presetCounts = [5, 10, 15]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header description (Cleaned to prevent duplicate / ghost title)
                VStack(spacing: 4) {
                    Text("Test your alphabet recall without visual reference hints.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 8)

                // Question Count Selection Card
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Label("Number of Questions", systemImage: "number.circle.fill")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.terracotta)

                        Spacer()

                        Text("\(selectedCount) Questions")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Theme.terracotta.opacity(0.12))
                            .foregroundStyle(Theme.terracotta)
                            .clipShape(Capsule())
                    }

                    Text("Select a quiz length:")
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryText)

                    // Presets Grid (Terracotta when selected, cream with soft border when unselected)
                    HStack(spacing: 12) {
                        ForEach(presetCounts, id: \.self) { count in
                            let isSelected = (selectedCount == count)
                            Button {
                                FeedbackService.shared.playTap()
                                selectedCount = count
                            } label: {
                                VStack(spacing: 4) {
                                    Text("\(count)")
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                    Text("signs")
                                        .font(.caption2)
                                        .foregroundStyle(isSelected ? Color.white.opacity(0.85) : Theme.secondaryText)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(isSelected ? Theme.terracotta : Theme.fieldSurface)
                                .foregroundStyle(isSelected ? Color.white : Theme.primaryText)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.buttonRadius, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.buttonRadius, style: .continuous)
                                        .strokeBorder(isSelected ? Theme.terracotta : Theme.border, lineWidth: 1)
                                )
                                .shadow(color: isSelected ? Theme.terracotta.opacity(0.2) : Color.clear, radius: 8, x: 0, y: 3)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(count) signs")
                        }
                    }

                    // Stepper for counts restricted strictly to 5, 10, 15
                    Stepper(
                        value: $selectedCount,
                        in: 5...15,
                        step: 5
                    ) {
                        Text("Length: \(selectedCount) questions")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(Theme.primaryText)
                    }
                    .tint(Theme.terracotta)
                    .padding(.top, 4)
                }
                .padding(20)
                .background(Theme.cardSurface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                        .strokeBorder(Theme.border, lineWidth: 1)
                )
                .shadow(color: Theme.shadowColor, radius: Theme.shadowRadius, x: 0, y: Theme.shadowY)

                // How it works card
                VStack(alignment: .leading, spacing: 14) {
                    Label("How Quiz Mode Works", systemImage: "info.circle.fill")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.terracotta)

                    VStack(alignment: .leading, spacing: 12) {
                        guideRow(
                            icon: "eye.slash.fill",
                            color: Theme.terracotta,
                            title: "No Visual Clues",
                            detail: "Reference images are hidden so you can test true recognition from memory."
                        )

                        guideRow(
                            icon: "camera.viewfinder",
                            color: Theme.amber,
                            title: "Capture on Demand",
                            detail: "Form the letter in front of the camera and tap 'Capture Answer' when ready."
                        )

                        guideRow(
                            icon: "checkmark.seal.fill",
                            color: Theme.sage,
                            title: "Accurate Evaluation",
                            detail: "Awards 1 mark per correct sign with detailed review and score breakdown."
                        )

                        guideRow(
                            icon: "waveform.path",
                            color: Theme.peach,
                            title: "Motion Tracking for J & Z",
                            detail: "Traces dynamic trajectories without penalizing in-progress movements."
                        )
                    }
                }
                .padding(20)
                .background(Theme.cardSurface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                        .strokeBorder(Theme.border, lineWidth: 1)
                )
                .shadow(color: Theme.shadowColor, radius: Theme.shadowRadius, x: 0, y: Theme.shadowY)

                // Start Quiz Button (Terracotta)
                Button {
                    FeedbackService.shared.playTap()
                    isQuestionActive = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                        Text("Start Quiz (\(selectedCount) Questions)")
                    }
                }
                .buttonStyle(WarmPrimaryButtonStyle(backgroundColor: Theme.terracotta))
                .padding(.top, 4)
                .navigationDestination(isPresented: $isQuestionActive) {
                    QuizQuestionView(
                        questionCount: selectedCount,
                        onExitToDashboard: {
                            isQuestionActive = false
                            isQuizActive = false
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
            .frame(maxWidth: 580)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .warmBackground()
        .navigationTitle("Quiz Setup")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func guideRow(icon: String, color: Color, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color.opacity(0.14))
                    .frame(width: 28, height: 28)

                Image(systemName: icon)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(color)
            }
            .padding(.top, 1)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.primaryText)

                Text(detail)
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)
            }
        }
    }
}
