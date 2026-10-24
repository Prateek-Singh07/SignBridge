//
//  QuizResultsView.swift
//  SignBridge_1
//
//  Created by KIET2 on 24/10/26.
//

import SwiftUI

/// Screen displaying final quiz score, percentage, question-by-question review,
/// and tailored constructive feedback.
struct QuizResultsView: View {
    let result: QuizResult
    let onRetakeQuiz: () -> Void
    let onReturnToDashboard: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header badge
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(badgeColor.opacity(0.15))
                            .frame(width: 80, height: 80)

                        Image(systemName: badgeIcon)
                            .font(.system(size: 38, weight: .bold))
                            .foregroundStyle(badgeColor)
                    }

                    Text("Quiz Completed!")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(result.feedbackTitle)
                        .font(.headline)
                        .foregroundStyle(badgeColor)
                }
                .padding(.top, 12)

                // High-level score card
                VStack(spacing: 16) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("\(result.correctCount)")
                            .font(.system(size: AppSettings.shared.scaled(48), weight: .bold))
                            .foregroundStyle(Theme.terracotta)

                        Text("/ \(result.totalQuestions) marks")
                            .font(.title3)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text("\(result.percentage)%")
                            .font(.system(size: AppSettings.shared.scaled(36), weight: .bold))
                            .foregroundStyle(badgeColor)
                    }

                    Divider()

                    HStack(spacing: 16) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Theme.sage)
                            Text("\(result.correctCount) Correct")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }

                        Spacer()

                        HStack(spacing: 6) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Theme.rose)
                            Text("\(result.incorrectCount) Incorrect")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
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

                // Constructive feedback card
                VStack(alignment: .leading, spacing: 12) {
                    Label("Performance Analysis", systemImage: "lightbulb.fill")
                        .font(.headline)
                        .foregroundStyle(Theme.terracotta)

                    Text(result.feedbackDescription)
                        .font(.body)
                        .foregroundStyle(.primary)

                    if !result.missedLetters.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Recommended for practice:")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(result.missedLetters) { letter in
                                        Text("Letter \(letter.name)")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(Theme.rose.opacity(0.12))
                                            .foregroundStyle(Theme.rose)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                        .padding(.top, 4)
                    } else {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.title3)
                                .foregroundStyle(Theme.sage)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("No Missed Letters!")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(Theme.sage)
                                Text("Outstanding! You answered every question correctly in this quiz.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.sage.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.top, 4)
                    }
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.cardSurface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                        .strokeBorder(Theme.border, lineWidth: 1)
                )
                .shadow(color: Theme.shadowColor, radius: Theme.shadowRadius, x: 0, y: Theme.shadowY)

                // Question-by-Question Review
                VStack(alignment: .leading, spacing: 14) {
                    Text("Question-by-Question Review")
                        .font(.headline)
                        .fontWeight(.bold)

                    ForEach(Array(result.questions.enumerated()), id: \.element.id) { index, q in
                        HStack(spacing: 14) {
                            // Question number
                            Text("#\(index + 1)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.secondary)
                                .frame(width: 28, alignment: .leading)

                            // Target letter
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Target: Letter \(q.targetLetter.name)")
                                    .font(.subheadline)
                                    .fontWeight(.bold)

                                if let recognized = q.recognizedLetter {
                                    Text(q.isCorrect ? "Matched correctly" : "Recognized as: Letter \(recognized.name)")
                                        .font(.caption)
                                        .foregroundStyle(q.isCorrect ? .green : .secondary)
                                } else {
                                    Text("Handshape not recognized")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            // Result pill
                            if q.isCorrect {
                                Label("Correct (+1)", systemImage: "checkmark")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(Theme.sage)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Theme.sage.opacity(0.15))
                                    .clipShape(Capsule())
                            } else {
                                Label("Incorrect (+0)", systemImage: "xmark")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(Theme.rose)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Theme.rose.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(14)
                        .background(Theme.fieldSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(Theme.border, lineWidth: 1)
                        )
                    }
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.cardSurface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                        .strokeBorder(Theme.border, lineWidth: 1)
                )
                .shadow(color: Theme.shadowColor, radius: Theme.shadowRadius, x: 0, y: Theme.shadowY)

                // Action Buttons: Practice Missed Letters, Retake Quiz, or Return to Dashboard
                VStack(spacing: 12) {
                    if !result.missedLetters.isEmpty {
                        NavigationLink {
                            LessonSelectionView(
                                letters: result.missedLetters,
                                customTitle: "Practice Missed Letters",
                                customSubtitle: "Focused practice on the \(result.missedLetters.count) letter\(result.missedLetters.count > 1 ? "s" : "") answered incorrectly."
                            )
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "hand.raised.fill")
                                Text("Practice Missed Letters (\(result.missedLetters.count))")
                            }
                        }
                        .buttonStyle(WarmPrimaryButtonStyle(backgroundColor: Theme.amber))
                    }

                    Button {
                        onRetakeQuiz()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Take Another Quiz")
                        }
                    }
                    .buttonStyle(WarmPrimaryButtonStyle(backgroundColor: Theme.terracotta))

                    Button {
                        onReturnToDashboard()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "house.fill")
                            Text("Return to Dashboard")
                        }
                    }
                    .buttonStyle(WarmSecondaryButtonStyle(tintColor: Theme.primaryText))
                }
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: 580)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .warmBackground()
        .navigationBarBackButtonHidden(true)
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var badgeColor: Color {
        if result.percentage >= 80 {
            return Theme.sage
        } else if result.percentage >= 60 {
            return Theme.amber
        } else {
            return Theme.rose
        }
    }

    private var badgeIcon: String {
        if result.percentage == 100 {
            return "trophy.fill"
        } else if result.percentage >= 80 {
            return "star.fill"
        } else if result.percentage >= 60 {
            return "hand.thumbsup.fill"
        } else {
            return "book.closed.fill"
        }
    }
}
