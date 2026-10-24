//
//  LessonSelectionView.swift
//  SignBridge_1
//
//  Created by KIET2 on 23/10/26.
//

import SwiftUI

/// Warm, minimal screen allowing the learner to choose an individual letter to practice.
/// Displays real-time letter mastery badges (New, Learning, Mastered) on each letter card.
struct LessonSelectionView: View {
    let letters: [ASLLetter]
    let customTitle: String?
    let customSubtitle: String?

    @ObservedObject private var masteryManager = LetterMasteryManager.shared
    @State private var selectedLetter: ASLLetter? = nil

    init(
        letters: [ASLLetter] = ASLLetter.allCases,
        customTitle: String? = nil,
        customSubtitle: String? = nil
    ) {
        self.letters = letters
        self.customTitle = customTitle
        self.customSubtitle = customSubtitle
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header section
                VStack(alignment: .leading, spacing: 4) {
                    Text(customTitle ?? "Choose a Letter")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.primaryText)
                        .accessibilityAddTraits(.isHeader)

                    Text(customSubtitle ?? "Practice one handshape at a time with real-time feedback.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondaryText)
                }
                .padding(.top, 8)

                // Adaptive letter grid
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 88, maximum: 115), spacing: 12)],
                    spacing: 12
                ) {
                    ForEach(letters) { letter in
                        let isSelected = (selectedLetter == letter)
                        let status = masteryManager.status(for: letter)

                        Button {
                            FeedbackService.shared.playTap()
                            selectedLetter = letter
                        } label: {
                            VStack(spacing: 8) {
                                // Top row: Mastery badge + selection indicator
                                HStack {
                                    HStack(spacing: 3) {
                                        Circle()
                                            .fill(status.badgeColor)
                                            .frame(width: 6, height: 6)
                                        Text(status.rawValue)
                                            .font(.system(size: 9, weight: .bold, design: .rounded))
                                            .foregroundStyle(status == .new ? Theme.secondaryText : status.badgeColor)
                                    }
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(status.badgeColor.opacity(0.14))
                                    .clipShape(Capsule())

                                    Spacer()

                                    if isSelected {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.caption)
                                            .foregroundStyle(Theme.terracotta)
                                            .accessibilityHidden(true)
                                    } else {
                                        Image(systemName: "circle")
                                            .font(.caption)
                                            .foregroundStyle(Theme.secondaryText.opacity(0.4))
                                            .accessibilityHidden(true)
                                    }
                                }

                                Text(letter.name)
                                    .font(.system(size: AppSettings.shared.scaled(34), weight: .bold, design: .rounded))
                                    .foregroundStyle(isSelected ? Theme.terracotta : Theme.primaryText)

                                Text(isSelected ? "Selected" : "Tap to select")
                                    .font(.caption2)
                                    .foregroundStyle(Theme.secondaryText)
                            }
                            .padding(.vertical, 14)
                            .padding(.horizontal, 10)
                            .frame(maxWidth: .infinity)
                            .background(isSelected ? Theme.terracotta.opacity(0.06) : Theme.cardSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(
                                        isSelected ? Theme.terracotta : Theme.border,
                                        lineWidth: isSelected ? 2.0 : 1.0
                                    )
                            )
                            .shadow(color: isSelected ? Theme.terracotta.opacity(0.12) : Theme.shadowColor, radius: 10, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Letter \(letter.name), Status: \(status.rawValue)")
                        .accessibilityValue(isSelected ? "Selected" : "Not selected")
                        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
                    }
                }

                Spacer(minLength: 20)

                // Start Practice button (disabled until a letter is selected)
                if let letter = selectedLetter {
                    NavigationLink {
                        LetterPracticeView(letter: letter)
                    } label: {
                        Text("Start Practice")
                    }
                    .buttonStyle(WarmPrimaryButtonStyle(backgroundColor: Theme.terracotta))
                    .accessibilityLabel("Start Practice for letter \(letter.name)")
                } else {
                    Button { } label: {
                        Text("Select a Letter to Practice")
                    }
                    .buttonStyle(WarmPrimaryButtonStyle(backgroundColor: Theme.border, foregroundColor: Theme.secondaryText))
                    .disabled(true)
                    .accessibilityLabel("Start Practice. Disabled until a letter is selected.")
                }
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 24)
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .warmBackground()
        .navigationTitle("Practice Alphabet")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        LessonSelectionView()
    }
}
