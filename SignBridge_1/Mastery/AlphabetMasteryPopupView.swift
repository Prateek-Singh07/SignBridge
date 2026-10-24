//
//  AlphabetMasteryPopupView.swift
//  SignBridge_1
//
//  Created by KIET2 on 24/10/26.
//

import SwiftUI

/// Compact modal popup displaying the learner's overall alphabet mastery,
/// status counts (Mastered, Learning, New), unmastered letters, and the interactive A–Z grid.
/// Appears centered horizontally and vertically over the dimmed Dashboard.
struct AlphabetMasteryPopupView: View {
    @Binding var isPresented: Bool
    var onSelectLetter: (ASLLetter) -> Void

    @ObservedObject private var masteryManager = LetterMasteryManager.shared
    @ObservedObject private var settings = AppSettings.shared

    var body: some View {
        VStack(spacing: 16) {
            // Header with percentage badge & Close Button
            HStack(alignment: .center) {
                HStack(spacing: 8) {
                    Text("🏆 Alphabet Mastery")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)

                    Text("\(masteryManager.progressPercentage)%")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.orange.opacity(0.15))
                        .foregroundStyle(.orange)
                        .clipShape(Capsule())
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
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close Mastery Popup")
            }

            // Overall Progress Bar
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("\(masteryManager.masteredCount) of 26 Letters Mastered")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    Spacer()
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.secondary.opacity(0.2))
                            .frame(height: 7)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Theme.amber, Theme.sage],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(
                                width: max(7, geo.size.width * CGFloat(masteryManager.progressPercentage) / 100.0),
                                height: 7
                            )
                    }
                }
                .frame(height: 7)
            }

            // Three Status Breakdown Pills
            HStack(spacing: 6) {
                MasteryPill(
                    title: "Mastered",
                    count: masteryManager.masteredCount,
                    color: Theme.sage,
                    iconName: "checkmark.seal.fill"
                )
                MasteryPill(
                    title: "Learning",
                    count: masteryManager.learningCount,
                    color: Theme.amber,
                    iconName: "arrow.triangle.2.circlepath"
                )
                MasteryPill(
                    title: "New",
                    count: masteryManager.newCount,
                    color: Theme.masteryNew,
                    iconName: "circle.dashed"
                )
            }

            // Letters Needing Practice Chips (if any)
            if !masteryManager.lettersNeedingPractice.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Letters to Practice (Tap to practice):")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(masteryManager.lettersNeedingPractice.prefix(10)) { letter in
                                Button {
                                    FeedbackService.shared.playTap()
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        isPresented = false
                                    }
                                    onSelectLetter(letter)
                                } label: {
                                    HStack(spacing: 4) {
                                        Text(letter.name)
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundStyle(.primary)

                                        let st = masteryManager.status(for: letter)
                                        Circle()
                                            .fill(st.badgeColor)
                                            .frame(width: 6, height: 6)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Theme.fieldSurface)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }

            // Full 26-Letter Grid (A–Z)
            VStack(alignment: .leading, spacing: 8) {
                Text("Full Alphabet Grid (A–Z):")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 13), spacing: 4) {
                    ForEach(ASLLetter.allCases) { letter in
                        let st = masteryManager.status(for: letter)

                        Button {
                            FeedbackService.shared.playTap()
                            withAnimation(.easeInOut(duration: 0.15)) {
                                isPresented = false
                            }
                            onSelectLetter(letter)
                        } label: {
                            Text(letter.name)
                                .font(.system(size: settings.scaled(11), weight: .bold, design: .rounded))
                                .foregroundStyle(st == .new ? Theme.primaryText : Color.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 26)
                                .background(st == .new ? Theme.masteryNew.opacity(0.35) : (st == .learning ? Theme.amber : Theme.sage))
                                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Letter \(letter.name), Status: \(st.rawValue). Tap to practice.")
                    }
                }
            }
            .padding(10)
            .background(Theme.fieldSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Action Button
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
    }
}

private struct MasteryPill: View {
    let title: String
    let count: Int
    let color: Color
    let iconName: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.system(size: 9))
                .foregroundStyle(color)

            Text("\(count) \(title)")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.4)
            .ignoresSafeArea()
        AlphabetMasteryPopupView(isPresented: .constant(true), onSelectLetter: { _ in })
    }
}
