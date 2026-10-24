//
//  SettingsView.swift
//  SignBridge_1
//
//  Created by KIET2 on 24/10/26.
//

import SwiftUI

/// Settings view providing visual appearance, typography scale,
/// sound, and haptic feedback accessibility controls.
struct SettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var masteryManager = LetterMasteryManager.shared
    @ObservedObject private var historyManager = QuizHistoryManager.shared

    @State private var showResetMasteryConfirmation = false
    @State private var showResetSettingsConfirmation = false
    @State private var testFeedbackBanner: String? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Preferences")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)

                        Text("Settings")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .accessibilityAddTraits(.isHeader)
                    }
                    Spacer()
                }

                // Temporary Banner for Feedback Tests
                if let banner = testFeedbackBanner {
                    HStack(spacing: 10) {
                        Image(systemName: "bell.badge.fill")
                            .foregroundStyle(Theme.terracotta)
                        Text(banner)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                    }
                    .padding(12)
                    .background(Theme.terracotta.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .transition(.opacity)
                }

                // Section 1: Visual Appearance
                VStack(alignment: .leading, spacing: 14) {
                    Label("Appearance", systemImage: "circle.lefthalf.filled")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Picker("Theme", selection: $settings.appearanceMode) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Label(mode.rawValue, systemImage: mode.iconName)
                                .tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityLabel("Appearance Theme Mode")

                    Text("Chooses between automatic system styling or an explicit Light or Dark theme throughout the application.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.cardSurface)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // Section 2: Text Size & Legibility
                VStack(alignment: .leading, spacing: 14) {
                    Label("Text Size", systemImage: "textformat.size")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Picker("Scale", selection: $settings.textSize) {
                        ForEach(AppTextSize.allCases) { size in
                            Text(size.rawValue)
                                .tag(size)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityLabel("Typography Scale")

                    // Live sample preview box
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Preview:")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)

                        Text("SignBridge • Letter A to Z")
                            .font(.system(size: settings.scaled(17), weight: .medium))
                            .foregroundStyle(.primary)
                            .animation(.easeInOut(duration: 0.2), value: settings.textSize)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.fieldSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                    Text("Applies immediate typography scaling to instructions, buttons, card descriptions, and feedback prompts.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.cardSurface)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // Section 3: Sensory Feedback (Sound & Haptics)
                VStack(alignment: .leading, spacing: 16) {
                    Label("Feedback & Cues", systemImage: "speaker.wave.2.fill")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Toggle(isOn: $settings.isSoundEnabled) {
                        HStack(spacing: 12) {
                            Image(systemName: settings.isSoundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                                .foregroundStyle(settings.isSoundEnabled ? Theme.terracotta : .secondary)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Sound Feedback")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text("Auditory chime on correct sign matches and quiz answers")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .accessibilityLabel("Toggle Sound Feedback")

                    Divider()

                    Toggle(isOn: $settings.isHapticsEnabled) {
                        HStack(spacing: 12) {
                            Image(systemName: "iphone.radiowaves.left.and.right")
                                .foregroundStyle(settings.isHapticsEnabled ? Theme.amber : .secondary)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Haptic Feedback")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text("Vibration and tactile pulses for gestures and button presses")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .accessibilityLabel("Toggle Haptic Feedback")

                    Divider()

                    // Test Feedback Buttons
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Verify Feedback:")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 12) {
                            Button {
                                if settings.isSoundEnabled {
                                    FeedbackService.shared.triggerSoundTest()
                                    showBanner("Played sound cue successfully.")
                                } else {
                                    showBanner("Sound is currently turned off.")
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "play.fill")
                                    Text("Test Sound")
                                }
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.regular)

                            Button {
                                if settings.isHapticsEnabled {
                                    FeedbackService.shared.triggerHapticTest()
                                    showBanner("Triggered haptic pulse successfully.")
                                } else {
                                    showBanner("Haptics are currently turned off.")
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "waveform")
                                    Text("Test Haptics")
                                }
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.regular)
                        }
                    }
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.cardSurface)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // Section 4: Data & Reset Controls
                VStack(alignment: .leading, spacing: 14) {
                    Label("Data & Progress", systemImage: "arrow.counterclockwise.circle.fill")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Current Letter Mastery")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("\(masteryManager.masteredCount) Mastered • \(masteryManager.learningCount) Learning • \(masteryManager.newCount) New")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }

                    HStack(spacing: 12) {
                        Button(role: .destructive) {
                            showResetMasteryConfirmation = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "trash")
                                Text("Reset Mastery")
                            }
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.regular)

                        Button {
                            showResetSettingsConfirmation = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                Text("Reset Settings")
                            }
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.regular)
                    }
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.cardSurface)
                .clipShape(RoundedRectangle(cornerRadius: 16))
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

                // Section 5: About App
                VStack(spacing: 8) {
                    Text("SignBridge Education")
                        .font(.subheadline)
                        .fontWeight(.bold)
                    Text("College Project Demonstration Build")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Vision-based real-time 26-letter recognition.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: 580)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .warmBackground()
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
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
    NavigationStack {
        SettingsView()
    }
}
