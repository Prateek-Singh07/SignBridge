//
//  DashboardView.swift
//  SignBridge_1
//
//  Created by KIET2 on 24/10/26.
//

import SwiftUI

/// Warm, minimal home dashboard separating Practice Mode and Quiz Mode,
/// featuring a soft cream dropdown menu for Settings, Daily Streak, and Alphabet Mastery popups.
struct DashboardView: View {
    enum CenteredPopupType: Identifiable {
        case settings
        case streak
        case challenge
        case mastery
        case history

        var id: Self { self }
    }

    @ObservedObject private var historyManager = QuizHistoryManager.shared
    @ObservedObject private var masteryManager = LetterMasteryManager.shared
    @ObservedObject private var streakManager = DailyStreakManager.shared
    @ObservedObject private var challengeManager = DailyChallengeManager.shared
    @ObservedObject private var settings = AppSettings.shared

    @State private var isQuizActive = false
    @State private var showDropdownMenu = false
    @State private var activeCenteredPopup: CenteredPopupType? = nil
    @State private var activePracticeLetter: ASLLetter? = nil
    @State private var isLaunchingFromChallenge = false

    var body: some View {
        ZStack {
            // Main Dashboard Content
            ScrollView {
                VStack(spacing: 20) {
                    // Brand Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Theme.terracotta, Theme.peach],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 68, height: 68)
                                .shadow(color: Theme.terracotta.opacity(0.25), radius: 14, x: 0, y: 6)

                            Image(systemName: "hand.raised.fill")
                                .font(.system(size: settings.scaled(32), weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        .padding(.top, 12)

                        VStack(spacing: 4) {
                            Text("SignBridge")
                                .font(.system(size: settings.scaled(28), weight: .bold, design: .rounded))
                                .foregroundStyle(Theme.primaryText)
                                .accessibilityAddTraits(.isHeader)

                            Text("Sign Language Recognition")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(Theme.secondaryText)
                        }
                    }
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 4)

                    // Mode Selection Cards (Warm palette: Terracotta, Amber, Sage)
                    VStack(spacing: 16) {
                        // Card 1: Practice Mode (Terracotta / Peach tint)
                        NavigationLink {
                            LessonSelectionView()
                        } label: {
                            DashboardCard(
                                title: "Practice Mode",
                                badgeText: "Learn A–Z",
                                subtitle: "Interactive Alphabet Learning",
                                description: "Explore all 26 handshapes at your own pace with visual reference guides and real-time vision tracking.",
                                actionText: "Start Practicing",
                                iconName: "book.fill",
                                iconColor: Theme.terracotta,
                                tileGradient: [Theme.peach.opacity(0.35), Theme.peach.opacity(0.18)]
                            )
                        }
                        .buttonStyle(CardButtonStyle())
                        .accessibilityLabel("Practice Mode: Learn A to Z")

                        // Card 2: Quiz Mode (Amber tint)
                        Button {
                            FeedbackService.shared.playTap()
                            isQuizActive = true
                        } label: {
                            DashboardCard(
                                title: "Quiz Mode",
                                badgeText: "Test Recall",
                                subtitle: "Knowledge & Memory Test",
                                description: "Test your fingerspelling from memory under test conditions with instant landmark accuracy feedback.",
                                actionText: "Start Quiz Mode",
                                iconName: "brain.head.profile",
                                iconColor: Theme.amber,
                                tileGradient: [Theme.amber.opacity(0.28), Theme.amber.opacity(0.14)]
                            )
                        }
                        .buttonStyle(CardButtonStyle())
                        .accessibilityLabel("Quiz Mode: Test Yourself")
                        .navigationDestination(isPresented: $isQuizActive) {
                            QuizSetupView(isQuizActive: $isQuizActive)
                        }


                    }
                }
                .padding(.bottom, 24)
                .padding(.horizontal, 22)
                .frame(maxWidth: 680)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .warmBackground()
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Top-right Menu Button (Soft peach circle with terracotta icon)
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        FeedbackService.shared.playTap()
                        withAnimation(.easeInOut(duration: 0.18)) {
                            showDropdownMenu.toggle()
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: settings.scaled(15), weight: .bold))
                            .foregroundStyle(Theme.terracotta)
                            .frame(width: 40, height: 40)
                            .background(Theme.peach.opacity(0.45))
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .strokeBorder(Theme.border, lineWidth: 1)
                            )
                    }
                    .accessibilityLabel("Menu: Settings, Daily Streak, Daily Sign Challenge, Alphabet Mastery, Quiz History")
                }
            }
            .navigationDestination(item: $activePracticeLetter) { letter in
                LetterPracticeView(letter: letter)
            }
            .onChange(of: activePracticeLetter) { oldVal, newVal in
                if oldVal != nil && newVal == nil && isLaunchingFromChallenge {
                    isLaunchingFromChallenge = false
                    withAnimation(.easeInOut(duration: 0.2)) {
                        activeCenteredPopup = .challenge
                    }
                }
            }

            // Dropdown Menu (Warm cream card anchored below navigation bar)
            if showDropdownMenu {
                ZStack(alignment: .topTrailing) {
                    // Tap-away backdrop with gentle warm brown dimming
                    Theme.backdrop
                        .ignoresSafeArea()
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.18)) {
                                showDropdownMenu = false
                            }
                        }

                    VStack {
                        opaqueDropdownMenu
                            .padding(.top, 8)
                            .padding(.trailing, 16)
                        Spacer()
                    }
                    .transition(.scale(scale: 0.95, anchor: .topTrailing).combined(with: .opacity))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .zIndex(99)
            }

            // Dimmed Modal Overlay: Centered Popups (Warm brown backdrop, not black)
            if let popup = activeCenteredPopup {
                ZStack {
                    Theme.backdrop
                        .ignoresSafeArea()
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                activeCenteredPopup = nil
                            }
                        }

                    switch popup {
                    case .settings:
                        SettingsPopupView(isPresented: Binding(
                            get: { activeCenteredPopup == .settings },
                            set: { if !$0 { activeCenteredPopup = nil } }
                        ))
                        .transition(.scale(scale: 0.95).combined(with: .opacity))

                    case .streak:
                        DailyStreakView(isPresented: Binding(
                            get: { activeCenteredPopup == .streak },
                            set: { if !$0 { activeCenteredPopup = nil } }
                        ))
                        .transition(.scale(scale: 0.95).combined(with: .opacity))

                    case .challenge:
                        DailyChallengePopupView(
                            isPresented: Binding(
                                get: { activeCenteredPopup == .challenge },
                                set: { if !$0 { activeCenteredPopup = nil } }
                            ),
                            onPracticeLetter: { letter in
                                activeCenteredPopup = nil
                                isLaunchingFromChallenge = true
                                activePracticeLetter = letter
                            }
                        )
                        .transition(.scale(scale: 0.95).combined(with: .opacity))

                    case .mastery:
                        AlphabetMasteryPopupView(
                            isPresented: Binding(
                                get: { activeCenteredPopup == .mastery },
                                set: { if !$0 { activeCenteredPopup = nil } }
                            ),
                            onSelectLetter: { letter in
                                activeCenteredPopup = nil
                                activePracticeLetter = letter
                            }
                        )
                        .transition(.scale(scale: 0.95).combined(with: .opacity))

                    case .history:
                        QuizHistoryPopupView(isPresented: Binding(
                            get: { activeCenteredPopup == .history },
                            set: { if !$0 { activeCenteredPopup = nil } }
                        ))
                        .transition(.scale(scale: 0.95).combined(with: .opacity))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .ignoresSafeArea()
                .transition(.opacity)
                .zIndex(100)
            }
        }

    }

    // MARK: - Warm Dropdown Menu

    private var opaqueDropdownMenu: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Option 1: Settings
            DropdownMenuItem(
                iconName: "gearshape.fill",
                iconColor: Theme.terracotta,
                title: "Settings",
                subtitle: "Theme, text size & sound"
            ) {
                openCenteredPopup(.settings)
            }

            Divider()
                .background(Theme.border)
                .padding(.horizontal, 10)

            // Option 2: Daily Streak
            DropdownMenuItem(
                iconName: "flame.fill",
                iconColor: Theme.amber,
                title: "Daily Streak",
                subtitle: streakManager.currentStreak > 0 ? "\(streakManager.currentStreak) day streak active" : "Track daily consistency"
            ) {
                openCenteredPopup(.streak)
            }

            Divider()
                .background(Theme.border)
                .padding(.horizontal, 10)

            // Option 3: Daily Sign Challenge
            DropdownMenuItem(
                iconName: "target",
                iconColor: Theme.terracotta,
                title: "Daily Sign Challenge",
                subtitle: challengeManager.currentChallenge.isCompleted
                    ? "Today's 5 signs completed! 🎉"
                    : "\(challengeManager.currentChallenge.progressCount)/5 signs completed"
            ) {
                openCenteredPopup(.challenge)
            }

            Divider()
                .background(Theme.border)
                .padding(.horizontal, 10)

            // Option 4: Alphabet Mastery
            DropdownMenuItem(
                iconName: "trophy.fill",
                iconColor: Theme.amber,
                title: "Alphabet Mastery",
                subtitle: "\(masteryManager.masteredCount)/26 Mastered (\(masteryManager.progressPercentage)%)"
            ) {
                openCenteredPopup(.mastery)
            }

            Divider()
                .background(Theme.border)
                .padding(.horizontal, 10)

            // Option 5: Quiz History
            DropdownMenuItem(
                iconName: "chart.line.uptrend.xyaxis",
                iconColor: Theme.sage,
                title: "Quiz History",
                subtitle: historyManager.totalQuizzes == 0 ? "Track performance & scores" : "\(historyManager.totalQuizzes) \(historyManager.totalQuizzes == 1 ? "Quiz" : "Quizzes") (\(historyManager.averageAccuracy)% avg)"
            ) {
                openCenteredPopup(.history)
            }

            Divider()
                .background(Theme.border)
                .padding(.horizontal, 10)

            // Option 6: Log Out
            DropdownMenuItem(
                iconName: "rectangle.portrait.and.arrow.right",
                iconColor: Theme.rose,
                title: "Log Out",
                subtitle: "Sign out of account"
            ) {
                FeedbackService.shared.playTap()
                withAnimation(.easeInOut(duration: 0.15)) {
                    showDropdownMenu = false
                }
                CameraSessionManager.shared.stop()
                AuthManager.shared.logout()
            }
        }
        .padding(.vertical, 6)
        .frame(width: 250)
        .background(Theme.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Theme.border, lineWidth: 1)
        )
        .shadow(color: Theme.terracotta.opacity(0.12), radius: 18, x: 0, y: 8)
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .onTapGesture { /* Consume taps inside menu */ }
    }

    private func openCenteredPopup(_ popup: CenteredPopupType) {
        FeedbackService.shared.playTap()
        withAnimation(.easeInOut(duration: 0.15)) {
            showDropdownMenu = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.easeInOut(duration: 0.2)) {
                activeCenteredPopup = popup
            }
        }
    }
}

// MARK: - Dropdown Menu Item Row

private struct DropdownMenuItem: View {
    let iconName: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(iconColor.opacity(0.14))
                        .frame(width: 32, height: 32)

                    Image(systemName: iconName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(iconColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.primaryText)

                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(Theme.secondaryText)
                        .lineLimit(1)
                }

                Spacer(minLength: 4)

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(Theme.secondaryText.opacity(0.6))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isHovered ? iconColor.opacity(0.08) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Rich & Beautiful Dashboard Card Component

private struct DashboardCard: View {
    let title: String
    let badgeText: String
    let subtitle: String
    let description: String
    let actionText: String
    let iconName: String
    let iconColor: Color
    var tileGradient: [Color] = [Theme.terracotta.opacity(0.18), Theme.peach.opacity(0.08)]
    @ObservedObject private var settings = AppSettings.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Card Header: Icon + Title + Badge + Subtitle
            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: tileGradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)

                    Image(systemName: iconName)
                        .font(.system(size: settings.scaled(22), weight: .bold))
                        .foregroundStyle(iconColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.system(size: settings.scaled(18), weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.primaryText)
                            .lineLimit(1)

                        if !badgeText.isEmpty {
                            Text(badgeText)
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(iconColor.opacity(0.14))
                                .foregroundStyle(iconColor)
                                .clipShape(Capsule())
                                .lineLimit(1)
                        }
                    }

                    Text(subtitle)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Theme.secondaryText)
                        .lineLimit(1)
                }

                Spacer()
            }

            // Card Description
            Text(description)
                .font(.subheadline)
                .foregroundStyle(Theme.secondaryText)
                .lineSpacing(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Divider()
                .background(Theme.border)

            // Card Action Prompt
            HStack {
                Text(actionText)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(iconColor)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(iconColor)
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
    }
}

// MARK: - Card Button Style with subtle press animation

private struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.985 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

#Preview {
    NavigationStack {
        DashboardView()
    }
}
