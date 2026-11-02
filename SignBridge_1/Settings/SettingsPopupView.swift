//
//  SettingsPopupView.swift
//  SignBridge_1
//
//  Created by KIET2 on 24/10/26.
//

import SwiftUI

/// Compact centered modal popup providing theme preferences, typography scale,
/// sound and haptic cues, and data reset options.
struct SettingsPopupView: View {
    @Binding var isPresented: Bool

    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var masteryManager = LetterMasteryManager.shared
    @ObservedObject private var historyManager = QuizHistoryManager.shared

    @State private var showResetMasteryConfirmation = false
    @State private var showResetSettingsConfirmation = false
    @State private var testFeedbackBanner: String? = nil

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .center) {
                HStack(spacing: 8) {
                    Text("⚙️ Settings")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
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
                .accessibilityLabel("Close Settings Popup")
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 12)

            Divider().background(Theme.border)

            // Scrollable Settings Sections
            ScrollView {
                VStack(spacing: 16) {
                    // Temporary Feedback Test Banner
                    if let banner = testFeedbackBanner {
                        HStack(spacing: 10) {
                            Image(systemName: "bell.badge.fill")
                                .foregroundStyle(Theme.terracotta)
                            Text(banner)
                                .font(.caption)
                                .fontWeight(.medium)
                            Spacer()
                        }
                        .padding(10)
                        .background(Theme.terracotta.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .transition(.opacity)
                    }

                    // Section 1: Appearance Mode
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Appearance", systemImage: "circle.lefthalf.filled")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)

                        Picker("Theme", selection: $settings.appearanceMode) {
                            ForEach(AppearanceMode.allCases) { mode in
                                Label(mode.rawValue, systemImage: mode.iconName)
                                    .tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .accessibilityLabel("Appearance Theme Mode")

                        Text("Choose between automatic system styling or an explicit Light or Dark theme.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.fieldSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    // Section 2: Text Size & Legibility
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Text Size", systemImage: "textformat.size")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)

                        Picker("Scale", selection: $settings.textSize) {
                            ForEach(AppTextSize.allCases) { size in
                                Text(size.rawValue)
                                    .tag(size)
                            }
                        }
                        .pickerStyle(.segmented)
                        .accessibilityLabel("Typography Scale")

                        // Live preview
                        HStack {
                            Text("Preview: ")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)

                            Text("SignBridge • Letter A–Z")
                                .font(.system(size: settings.scaled(15), weight: .medium))
                                .foregroundStyle(.primary)
                                .animation(.easeInOut(duration: 0.2), value: settings.textSize)
                        }
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.cardSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.fieldSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    // Section 3: Sound & Haptic Cues
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Sound & Feedback", systemImage: "speaker.wave.2.fill")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)

                        Toggle(isOn: $settings.isSoundEnabled) {
                            HStack(spacing: 10) {
                                Image(systemName: settings.isSoundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                                    .foregroundStyle(settings.isSoundEnabled ? Theme.terracotta : .secondary)
                                    .frame(width: 20)

                                VStack(alignment: .leading, spacing: 1) {
                                    Text("Sound Feedback")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                    Text("Auditory chime on correct sign matches")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }

                        Divider().background(Theme.border)

                        Toggle(isOn: $settings.isHapticsEnabled) {
                            HStack(spacing: 10) {
                                Image(systemName: "iphone.radiowaves.left.and.right")
                                    .foregroundStyle(settings.isHapticsEnabled ? Theme.amber : .secondary)
                                    .frame(width: 20)

                                VStack(alignment: .leading, spacing: 1) {
                                    Text("Haptic Feedback")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                    Text("Tactile pulses for gestures & buttons")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }

                        Divider().background(Theme.border)

                        // Test Feedback Buttons
                        HStack(spacing: 10) {
                            Button {
                                if settings.isSoundEnabled {
                                    FeedbackService.shared.triggerSoundTest()
                                    showBanner("Played sound cue successfully.")
                                } else {
                                    showBanner("Sound is currently disabled.")
                                }
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: "play.fill")
                                    Text("Test Sound")
                                }
                                .font(.caption)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)

                            Button {
                                if settings.isHapticsEnabled {
                                    FeedbackService.shared.triggerHapticTest()
                                    showBanner("Triggered haptic pulse successfully.")
                                } else {
                                    showBanner("Haptics are currently disabled.")
                                }
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: "waveform")
                                    Text("Test Haptics")
                                }
                                .font(.caption)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.fieldSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    // Section 4: Data & Reset Controls
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Data & Progress", systemImage: "arrow.counterclockwise.circle.fill")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)

                        Text("\(masteryManager.masteredCount) Mastered • \(masteryManager.learningCount) Learning • \(masteryManager.newCount) New")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 10) {
                            Button(role: .destructive) {
                                showResetMasteryConfirmation = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "trash")
                                    Text("Reset Mastery")
                                }
                                .font(.caption)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)

                            Button {
                                showResetSettingsConfirmation = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                    Text("Reset Settings")
                                }
                                .font(.caption)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.fieldSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    // Section 5: Account & Session
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Account Session", systemImage: "person.circle.fill")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)

                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(AuthManager.shared.savedUserID.isEmpty ? "Prateek Singh" : AuthManager.shared.savedUserID)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text("Active User")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button(role: .destructive) {
                                FeedbackService.shared.playTap()
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isPresented = false
                                }
                                AuthManager.shared.logout()
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                    Text("Log Out")
                                }
                                .font(.caption)
                                .fontWeight(.semibold)
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                            .controlSize(.small)
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.fieldSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    // Section 6: About App
                    VStack(spacing: 4) {
                        Text("SignBridge Education")
                            .font(.caption)
                            .fontWeight(.bold)
                        Text("Vision-based real-time 26-letter recognition.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("Official ISL alphabet references courtesy of ISLRTC, Govt. of India.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 4)
                }
                .padding(18)
            }
            .frame(maxHeight: 460)

            Divider().background(Theme.border)

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
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .frame(maxWidth: 480)
        .background(Theme.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                .strokeBorder(Theme.border, lineWidth: 1)
        )
        .shadow(color: Theme.terracotta.opacity(0.12), radius: 20, x: 0, y: 8)
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .onTapGesture { /* Consume taps */ }
        .padding(.horizontal, 24)
        .confirmationDialog(
            "Reset Letter Mastery Progress?",
            isPresented: $showResetMasteryConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset All Mastery Progress", role: .destructive) {
                masteryManager.resetMastery()
                showBanner("Letter mastery reset to initial state.")
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This resets the New/Learning/Mastered progress for all 26 letters.")
        }
        .confirmationDialog(
            "Reset Settings to Defaults?",
            isPresented: $showResetSettingsConfirmation,
            titleVisibility: .visible
        ) {
            Button("Restore Default Settings", role: .destructive) {
                settings.resetToDefaults()
                showBanner("Settings restored to defaults.")
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This restores system theme, standard text size, and enables audio/haptics.")
        }
    }

    private func showBanner(_ message: String) {
        withAnimation {
            testFeedbackBanner = message
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation {
                if testFeedbackBanner == message {
                    testFeedbackBanner = nil
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.4)
            .ignoresSafeArea()
        SettingsPopupView(isPresented: .constant(true))
    }
}
