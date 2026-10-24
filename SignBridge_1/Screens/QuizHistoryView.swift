//
//  QuizHistoryView.swift
//  SignBridge_1
//
//  Created by KIET2 on 24/10/26.
//

import SwiftUI

/// Compact, centred popup displaying locally stored quiz attempts, score trends, and question breakdowns.
/// Matching the visual style of SettingsPopupView and AlphabetMasteryPopupView.
struct QuizHistoryPopupView: View {
    @Binding var isPresented: Bool
    @ObservedObject private var historyManager = QuizHistoryManager.shared
    @State private var showClearConfirmation = false

    var body: some View {
        VStack(spacing: 16) {
            // Header with badge & Close Button
            HStack(alignment: .center) {
                HStack(spacing: 8) {
                    Text("📊 Quiz History")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(Theme.primaryText)

                    if historyManager.totalQuizzes > 0 {
                        Text("\(historyManager.totalQuizzes) \(historyManager.totalQuizzes == 1 ? "Quiz" : "Quizzes")")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Theme.sage.opacity(0.18))
                            .foregroundStyle(Theme.sage)
                            .clipShape(Capsule())
                    }
                }

                Spacer()

                Button {
                    FeedbackService.shared.playTap()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isPresented = false
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Theme.secondaryText.opacity(0.8))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close Quiz History Popup")
            }

            // Scrollable Content
            if historyManager.attempts.isEmpty {
                emptyStateView
            } else {
                ScrollView(showsIndicators: true) {
                    VStack(spacing: 16) {
                        // 1. Summary Stats
                        summarySection

                        // 2. Score Trend Section
                        scoreTrendSection

                        // 3. Previous Attempts List
                        attemptsListSection

                        // 4. Clear History Action
                        HStack {
                            Spacer()
                            Button(role: .destructive) {
                                showClearConfirmation = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "trash")
                                    Text("Clear All Quiz History")
                                }
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(Theme.rose)
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 4)
                            Spacer()
                        }
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 2)
                }
                .frame(maxHeight: 460)
            }

            Divider()
                .background(Theme.border)

            // Done Button
            Button {
                FeedbackService.shared.playTap()
                withAnimation(.easeInOut(duration: 0.2)) {
                    isPresented = false
                }
            } label: {
                Text("Done")
            }
            .buttonStyle(WarmPrimaryButtonStyle(backgroundColor: Theme.terracotta))
        }
        .padding(20)
        .frame(maxWidth: 480)
        .background(Theme.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                .strokeBorder(Theme.border, lineWidth: 1)
        )
        .shadow(color: Theme.terracotta.opacity(0.12), radius: 20, x: 0, y: 8)
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .onTapGesture { /* Consume taps inside card */ }
        .padding(.horizontal, 24)
        .confirmationDialog(
            "Clear Quiz History?",
            isPresented: $showClearConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete All History", role: .destructive) {
                historyManager.clearHistory()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently remove all stored quiz attempts and score trends.")
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Theme.sage.opacity(0.12))
                    .frame(width: 54, height: 54)
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Theme.sage)
            }
            .padding(.top, 12)

            Text("No Quiz History Yet")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(Theme.primaryText)

            Text("Complete a quiz from the Quiz Mode card to see your performance, score trends, and question breakdowns here.")
                .font(.caption)
                .foregroundStyle(Theme.secondaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Theme.fieldSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Summary Stats

    private var summarySection: some View {
        HStack(spacing: 10) {
            statCard(
                title: "Completed",
                value: "\(historyManager.totalQuizzes)",
                icon: "checkmark.seal.fill",
                color: Theme.terracotta
            )

            statCard(
                title: "Avg Accuracy",
                value: "\(historyManager.averageAccuracy)%",
                icon: "chart.bar.fill",
                color: Theme.amber
            )

            statCard(
                title: "Best Score",
                value: "\(historyManager.bestAccuracy)%",
                icon: "trophy.fill",
                color: Theme.sage
            )
        }
    }

    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(color.opacity(0.14))
                        .frame(width: 26, height: 26)
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(color)
                }
                Spacer()
            }

            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.primaryText)

            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Theme.secondaryText)
                .lineLimit(1)
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(Theme.fieldSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Score Trend Section

    private var scoreTrendSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Score Trend", systemImage: "chart.line.uptrend.xyaxis")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.terracotta)

            let trend = historyManager.recentTrend

            HStack(alignment: .bottom, spacing: 10) {
                ForEach(trend) { attempt in
                    VStack(spacing: 4) {
                        Text("\(attempt.accuracy)%")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Theme.secondaryText)

                        // Bar
                        RoundedRectangle(cornerRadius: 5)
                            .fill(barColor(for: attempt.accuracy))
                            .frame(height: max(14, CGFloat(attempt.accuracy) * 0.75))

                        Text(attempt.shortDate)
                            .font(.system(size: 9))
                            .foregroundStyle(Theme.secondaryText)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 95, alignment: .bottom)
            .padding(.top, 4)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.fieldSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Attempts List Section

    private var attemptsListSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Previous Attempts")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.primaryText)

            ForEach(historyManager.attempts) { attempt in
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(attempt.formattedDate)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(Theme.primaryText)

                            Text("\(attempt.questionCount) Questions")
                                .font(.caption2)
                                .foregroundStyle(Theme.secondaryText)
                        }

                        Spacer()

                        HStack(spacing: 4) {
                            Text("\(attempt.score)/\(attempt.questionCount)")
                                .font(.system(size: 13, weight: .bold, design: .rounded))

                            Text("(\(attempt.accuracy)%)")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(barColor(for: attempt.accuracy))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(barColor(for: attempt.accuracy).opacity(0.12))
                        .clipShape(Capsule())
                    }

                    // Question letter pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 5) {
                            ForEach(attempt.questionResults) { q in
                                HStack(spacing: 2) {
                                    Text(q.targetLetter)
                                        .font(.system(size: 10, weight: .bold))
                                    Image(systemName: q.isCorrect ? "checkmark" : "xmark")
                                        .font(.system(size: 7, weight: .bold))
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(q.isCorrect ? Theme.sage.opacity(0.15) : Theme.rose.opacity(0.15))
                                .foregroundStyle(q.isCorrect ? Theme.sage : Theme.rose)
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                            }
                        }
                    }
                }
                .padding(12)
                .background(Theme.cardSurface)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Theme.border, lineWidth: 1)
                )
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.fieldSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func barColor(for accuracy: Int) -> Color {
        if accuracy >= 80 {
            return Theme.sage
        } else if accuracy >= 60 {
            return Theme.amber
        } else {
            return Theme.rose
        }
    }
}

/// Backward compatible standalone view wrapper.
struct QuizHistoryView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Theme.backdrop.ignoresSafeArea()
            QuizHistoryPopupView(isPresented: Binding(
                get: { true },
                set: { if !$0 { dismiss() } }
            ))
        }
        .warmBackground()
        .navigationTitle("Quiz History")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.4)
            .ignoresSafeArea()
        QuizHistoryPopupView(isPresented: .constant(true))
    }
}
