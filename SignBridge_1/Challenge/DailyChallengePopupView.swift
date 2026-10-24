//
//  DailyChallengePopupView.swift
//  SignBridge_1
//
//  Created by KIET2 on 24/10/26.
//

import SwiftUI
import UIKit

/// Centered modal popup for the Daily Sign Challenge.
/// Presents 5 deterministically selected letters for today, tracks verified practice completions,
/// previews the ASL reference image for each sign, and allows jumping straight into Practice Mode.
struct DailyChallengePopupView: View {
    @Binding var isPresented: Bool
    var onPracticeLetter: (ASLLetter) -> Void

    @ObservedObject private var challengeManager = DailyChallengeManager.shared
    @State private var selectedLetter: ASLLetter? = nil

    private var challenge: DailyChallengeRecord {
        challengeManager.currentChallenge
    }

    private var targetLetters: [ASLLetter] {
        challengeManager.targetASLLetters
    }

    private var activeLetter: ASLLetter {
        if let sel = selectedLetter {
            return sel
        }
        return challengeManager.firstPendingLetter ?? (targetLetters.first ?? .a)
    }

    private var formattedDateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            headerBar

            Divider()
                .background(Theme.border)

            // Content ScrollView
            ScrollView {
                VStack(spacing: 16) {
                    // Progress Overview Card
                    progressOverviewCard

                    // 5-Letter Stepper Row
                    fiveLettersStepperRow

                    // If all 5 completed: Celebration Banner
                    if challenge.isCompleted {
                        completionCelebrationCard
                    } else {
                        // Active Letter Reference Card
                        activeLetterCard
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }

            Divider()
                .background(Theme.border)

            // Bottom Action
            bottomActionButton
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
        }
        .frame(maxWidth: 500)
        .frame(maxHeight: 640)
        .background(Theme.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                .strokeBorder(Theme.border, lineWidth: 1)
        )
        .shadow(color: Theme.terracotta.opacity(0.12), radius: 20, x: 0, y: 8)
        .contentShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
        .onTapGesture { /* Consume taps inside popup */ }
        .padding(.horizontal, 20)
        .onAppear {
            challengeManager.checkDailyRollover()
            if selectedLetter == nil {
                selectedLetter = challengeManager.firstPendingLetter
            }
        }
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack(alignment: .center) {
            HStack(spacing: 8) {
                Image(systemName: "target")
                    .font(.headline)
                    .foregroundStyle(Theme.terracotta)

                Text("Daily Sign Challenge")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(Theme.primaryText)

                if challenge.isCompleted {
                    Text("Completed")
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
            .accessibilityLabel("Close Daily Challenge")
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 12)
    }

    // MARK: - Progress Overview Card

    private var progressOverviewCard: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(formattedDateString)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(Theme.secondaryText)

                    Text("\(challenge.progressCount) of 5 Signs Completed")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.primaryText)
                }

                Spacer()

                Text("\(challenge.progressPercentage)%")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(challenge.isCompleted ? Theme.sage : Theme.terracotta)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background((challenge.isCompleted ? Theme.sage : Theme.terracotta).opacity(0.14))
                    .clipShape(Capsule())
            }

            // Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Theme.border.opacity(0.6))
                        .frame(height: 8)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Theme.amber, Theme.sage],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(8, geo.size.width * CGFloat(challenge.progressFraction)), height: 8)
                        .animation(.easeInOut(duration: 0.3), value: challenge.progressFraction)
                }
            }
            .frame(height: 8)
        }
        .padding(14)
        .background(Theme.fieldSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Theme.border, lineWidth: 1)
        )
    }

    // MARK: - 5 Letters Stepper Row

    private var fiveLettersStepperRow: some View {
        HStack(spacing: 8) {
            ForEach(targetLetters) { letter in
                let isDone = challengeManager.isLetterCompleted(letter)
                let isSelected = activeLetter == letter

                Button {
                    FeedbackService.shared.playTap()
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedLetter = letter
                    }
                } label: {
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .fill(isDone ? Theme.sage : (isSelected ? Theme.terracotta : Theme.cardSurface))
                                .frame(width: 38, height: 38)
                                .shadow(
                                    color: (isDone ? Theme.sage : Theme.terracotta).opacity(isSelected ? 0.25 : 0),
                                    radius: 6, x: 0, y: 2
                                )

                            if isDone {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(.white)
                            } else {
                                Text(letter.name)
                                    .font(.system(size: 16, weight: .black, design: .rounded))
                                    .foregroundStyle(isSelected ? Color.white : Theme.primaryText)
                            }
                        }

                        Text("Letter " + letter.name)
                            .font(.system(size: 10, weight: isSelected ? .bold : .medium, design: .rounded))
                            .foregroundStyle(isSelected ? Theme.primaryText : Theme.secondaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(isSelected ? Theme.terracotta.opacity(0.08) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(isSelected ? Theme.terracotta.opacity(0.4) : Color.clear, lineWidth: 1.5)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Sign \(letter.name), Status: \(isDone ? "Completed" : "Pending")")
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Active Letter Card

    private var activeLetterCard: some View {
        let isDone = challengeManager.isLetterCompleted(activeLetter)
        let imageName = "asl_letter_" + activeLetter.lowercased()

        return VStack(spacing: 12) {
            // Card Header
            HStack {
                HStack(spacing: 8) {
                    Text(activeLetter.name)
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(isDone ? Theme.sage : Theme.terracotta)
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 1) {
                        Text("Target Sign: Letter \(activeLetter.name)")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.primaryText)

                        Text(isDone ? "Completed today" : "Practice required")
                            .font(.caption2)
                            .foregroundStyle(isDone ? Theme.sage : Theme.amber)
                    }
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: isDone ? "checkmark.circle.fill" : "circle.dashed")
                    Text(isDone ? "Verified" : "Pending")
                }
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(isDone ? Theme.sage : Theme.secondaryText)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background((isDone ? Theme.sage : Theme.border).opacity(0.18))
                .clipShape(Capsule())
            }

            // Reference Image with Error / Empty Fallback
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Theme.border, lineWidth: 1)
                    )

                if UIImage(named: imageName) != nil {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 140)
                        .padding(8)
                        .accessibilityLabel("Reference sign for Letter \(activeLetter.name)")
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "photo.badge.exclamationmark")
                            .font(.system(size: 32))
                            .foregroundStyle(Theme.secondaryText.opacity(0.6))
                        Text("Reference sign image unavailable")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.primaryText)
                        Text("You can still practice this letter using the instructional guide below.")
                            .font(.caption2)
                            .foregroundStyle(Theme.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }
                    .frame(height: 140)
                }
            }
            .frame(height: 140)

            // Instruction Text
            Text(activeLetter.instruction)
                .font(.caption)
                .foregroundStyle(Theme.secondaryText)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(Theme.fieldSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(isDone ? Theme.sage.opacity(0.3) : Theme.border, lineWidth: 1)
        )
    }

    // MARK: - Completion Celebration Card

    private var completionCelebrationCard: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Theme.amber.opacity(0.18))
                    .frame(width: 58, height: 58)

                Image(systemName: "trophy.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Theme.amber)
            }
            .padding(.top, 4)

            VStack(spacing: 4) {
                Text("Challenge Completed! 🎉")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.primaryText)

                Text("You've mastered all 5 challenge signs for \(formattedDateString).")
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)
                    .multilineTextAlignment(.center)
            }

            // Completed signs summary badges
            HStack(spacing: 8) {
                ForEach(targetLetters) { letter in
                    HStack(spacing: 3) {
                        Text(letter.name)
                            .font(.system(size: 13, weight: .black, design: .rounded))
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(Theme.sage)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Theme.sage.opacity(0.14))
                    .clipShape(Capsule())
                }
            }
            .padding(.top, 2)

            Text("🔥 Daily practice streak recorded! Return tomorrow for 5 new signs.")
                .font(.caption)
                .foregroundStyle(Theme.terracotta)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10)
                .padding(.top, 4)
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(Theme.amber.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Theme.amber.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Bottom Action Button

    @ViewBuilder
    private var bottomActionButton: some View {
        if challenge.isCompleted {
            Button {
                FeedbackService.shared.playTap()
                withAnimation(.easeInOut(duration: 0.2)) {
                    isPresented = false
                }
            } label: {
                Text("Done")
            }
            .buttonStyle(WarmPrimaryButtonStyle(backgroundColor: Theme.sage))
        } else {
            let isCurrentDone = challengeManager.isLetterCompleted(activeLetter)
            if isCurrentDone {
                // If selected letter is done, provide option to practice the next pending one
                if let nextPending = challengeManager.firstPendingLetter {
                    Button {
                        FeedbackService.shared.playTap()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isPresented = false
                        }
                        onPracticeLetter(nextPending)
                    } label: {
                        HStack(spacing: 6) {
                            Text("Practise Next: Letter \(nextPending.name)")
                            Image(systemName: "arrow.right")
                        }
                    }
                    .buttonStyle(WarmPrimaryButtonStyle(backgroundColor: Theme.terracotta))
                } else {
                    Button {
                        FeedbackService.shared.playTap()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isPresented = false
                        }
                    } label: {
                        Text("Done")
                    }
                    .buttonStyle(WarmPrimaryButtonStyle(backgroundColor: Theme.sage))
                }
            } else {
                Button {
                    FeedbackService.shared.playTap()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isPresented = false
                    }
                    onPracticeLetter(activeLetter)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "hand.raised.fill")
                        Text("Practise Letter \(activeLetter.name)")
                    }
                }
                .buttonStyle(WarmPrimaryButtonStyle(backgroundColor: Theme.terracotta))
            }
        }
    }
}
