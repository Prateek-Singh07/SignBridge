//
//  LetterPracticeView.swift
//  SignBridge_1
//
//  Created by KIET2 on 23/10/26.
//

import AVFoundation
import SwiftUI
import UIKit

/// Practice screen for an individual letter featuring Live Hand Tracking,
/// Live ASL Recognition, and an intelligent Practice Coach.
struct LetterPracticeView: View {
    let letter: ASLLetter

    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    @ObservedObject private var cameraManager = CameraSessionManager.shared
    @StateObject private var poseProcessor = HandPoseProcessor()

    @State private var currentLetter: ASLLetter
    @State private var isCameraActive = true

    // State machine for "Held pose triggers ONCE" & "Require hand to leave or letter change"
    @State private var hasRecordedPracticeMatch = false
    @State private var hasHandLeftAfterMatch = true

    // Live ASL Recognition state
    @State private var displayedRecognizedLetter: ASLLetter? = nil
    @State private var candidateLetter: ASLLetter? = nil
    @State private var candidateStreak: Int = 0

    // Landmark motion tracking for "Hold steady" hint
    @State private var lastWristPoint: CGPoint? = nil
    @State private var isHandMoving: Bool = false

    // Contextual similar-letter comparison modal
    @State private var activeComparison: SimilarLetterComparison? = nil

    // Alphabet Explorer modal
    @State private var showAlphabetExplorer = false

    init(letter: ASLLetter) {
        self.letter = letter
        _currentLetter = State(initialValue: letter)
    }

    var body: some View {
        ZStack {
            GeometryReader { geometry in
                let isWide = geometry.size.width >= 720

                ScrollView {
                    VStack(spacing: 20) {
                        // Header Bar
                        headerBar

                        if isWide {
                            // Two-column side-by-side layout: Target & Coach on left, Camera & Live Recognition on right
                            HStack(alignment: .top, spacing: 20) {
                                VStack(spacing: 16) {
                                    referenceCard
                                    coachCard
                                }
                                .frame(maxWidth: .infinity)

                                VStack(spacing: 16) {
                                    cameraSection
                                    liveRecognitionCard
                                }
                                .frame(maxWidth: .infinity)
                            }
                        } else {
                            // Single-column adaptive layout
                            VStack(spacing: 18) {
                                referenceCard
                                cameraSection
                                liveRecognitionCard
                                coachCard
                            }
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 28)
                    .frame(maxWidth: isWide ? 1040 : 580)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .warmBackground()
            .navigationBarTitleDisplayMode(.inline)

            // Dimmed Modal Overlay: Similar-Letter Comparison Popup
            if let comparison = activeComparison {
                ZStack {
                    Theme.backdrop
                        .ignoresSafeArea()
                        .contentShape(Rectangle())
                        .onTapGesture {
                            FeedbackService.shared.playTap()
                            withAnimation(.easeInOut(duration: 0.2)) {
                                activeComparison = nil
                            }
                        }

                    SimilarLetterComparisonPopupView(
                        comparison: comparison,
                        onDismiss: {
                            FeedbackService.shared.playTap()
                            withAnimation(.easeInOut(duration: 0.2)) {
                                activeComparison = nil
                            }
                        }
                    )
                    .transition(.scale(scale: 0.95).combined(with: .opacity))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .zIndex(100)
            }

            // Dimmed Modal Overlay: Alphabet Explorer Popup
            if showAlphabetExplorer {
                ZStack {
                    Theme.backdrop
                        .ignoresSafeArea()
                        .contentShape(Rectangle())
                        .onTapGesture {
                            FeedbackService.shared.playTap()
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showAlphabetExplorer = false
                            }
                        }

                    AlphabetExplorerPopupView(
                        isPresented: $showAlphabetExplorer,
                        currentLetter: currentLetter,
                        onSelectLetter: { letter in
                            navigateToLetter(letter)
                        }
                    )
                    .transition(.scale(scale: 0.95).combined(with: .opacity))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .zIndex(105)
            }
        }
        .onAppear {
            startPractice(for: currentLetter)
        }
        .onDisappear {
            cameraManager.stop()
        }
        .onChange(of: poseProcessor.landmarks) { _, newLandmarks in
            updateLiveTrackingAndRecognition(landmarks: newLandmarks)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if isCameraActive {
                if newPhase == .active {
                    cameraManager.start()
                } else {
                    cameraManager.stop()
                }
            }
        }
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Practice Mode")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(Theme.secondaryText)

                HStack(spacing: 8) {
                    Text("Letter \(currentLetter.name)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.primaryText)
                        .accessibilityAddTraits(.isHeader)

                    // Compact header stepper for quick switching
                    HStack(spacing: 4) {
                        Button {
                            FeedbackService.shared.playTap()
                            goToPreviousLetter()
                        } label: {
                            Image(systemName: "chevron.left.circle.fill")
                                .font(.title3)
                                .foregroundStyle(previousLetter == nil ? Theme.secondaryText.opacity(0.25) : Theme.secondaryText)
                        }
                        .buttonStyle(.plain)
                        .disabled(previousLetter == nil)
                        .accessibilityLabel("Go to previous letter")

                        Button {
                            FeedbackService.shared.playTap()
                            advanceToNextLetter()
                        } label: {
                            Image(systemName: "chevron.right.circle.fill")
                                .font(.title3)
                                .foregroundStyle(nextLetter == nil ? Theme.secondaryText.opacity(0.25) : Theme.terracotta)
                        }
                        .buttonStyle(.plain)
                        .disabled(nextLetter == nil)
                        .accessibilityLabel("Go to next letter")

                        // Quick grid icon to open Alphabet Explorer
                        Button {
                            FeedbackService.shared.playTap()
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showAlphabetExplorer = true
                            }
                        } label: {
                            Image(systemName: "square.grid.3x3.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Theme.terracotta)
                                .frame(width: 26, height: 26)
                                .background(Theme.fieldSurface)
                                .clipShape(Circle())
                                .overlay(Circle().strokeBorder(Theme.border, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Open Alphabet Explorer Grid")
                    }
                }
            }
            Spacer()

            // Dismiss Button
            Button {
                cameraManager.stop()
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Theme.secondaryText)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close practice mode")
        }
        .padding(.top, 4)
    }

    // MARK: - 1. Live Hand Tracking Camera Section

    @ViewBuilder
    private var cameraSection: some View {
        VStack(spacing: 10) {
            switch cameraManager.permissionState {
            case .running:
                VStack(spacing: 10) {
                    // Top row: Tracking status chip
                    HStack {
                        // Feature 1: Status chip: "Hand Detected" / "No Hand Detected" (icon + text)
                        HStack(spacing: 6) {
                            Image(systemName: poseProcessor.landmarks.isEmpty ? "hand.wave" : "hand.raised.fill")
                                .font(.caption)
                                .foregroundStyle(poseProcessor.landmarks.isEmpty ? Theme.secondaryText : Theme.sage)

                            Text(poseProcessor.landmarks.isEmpty ? "No Hand Detected" : "Hand Detected")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(poseProcessor.landmarks.isEmpty ? Theme.secondaryText : Theme.primaryText)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Theme.cardSurface)
                        .clipShape(Capsule())
                        .overlay(Capsule().strokeBorder(Theme.border, lineWidth: 1))
                        .shadow(color: Theme.shadowColor, radius: 8, x: 0, y: 3)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(poseProcessor.landmarks.isEmpty ? "Status: No Hand Detected" : "Status: Hand Detected")

                        Spacer()
                    }

                    // Existing Camera Preview with HandSkeletonView (coordinate mapping untouched)
                    ZStack {
                        CameraPreviewView(session: cameraManager.session)
                            .accessibilityHidden(true)

                        HandSkeletonView(
                            landmarks: poseProcessor.landmarks,
                            videoDimensions: poseProcessor.videoDimensions
                        )
                    }
                    .aspectRatio(3.0 / 4.0, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(cameraBorderColor, lineWidth: 2.5)
                    )
                    .shadow(color: Theme.shadowColor, radius: Theme.shadowRadius, x: 0, y: Theme.shadowY)
                }

            case .notDetermined:
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Starting camera...")
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondaryText)
                }
                .frame(height: 260)
                .frame(maxWidth: .infinity)
                .background(Theme.cardSurface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))

            case .denied, .restricted:
                VStack(spacing: 14) {
                    Text("Camera Access Required")
                        .font(.headline)
                        .foregroundStyle(Theme.primaryText)

                    Text("SignBridge uses the camera to track hand gestures in real time. Please enable camera access in Settings.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondaryText)
                        .multilineTextAlignment(.center)

                    Button("Open Settings") {
                        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsURL)
                        }
                    }
                    .buttonStyle(WarmPrimaryButtonStyle(backgroundColor: Theme.terracotta))
                }
                .padding(24)
                .frame(maxWidth: .infinity)
                .background(Theme.cardSurface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous).strokeBorder(Theme.border, lineWidth: 1))

            case .unavailable(let reason):
                VStack(spacing: 12) {
                    Text("Camera Unavailable")
                        .font(.headline)
                        .foregroundStyle(Theme.primaryText)
                    Text(reason)
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(24)
                .frame(maxWidth: .infinity)
                .background(Theme.cardSurface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
            }
        }
    }

    // MARK: - 2. Live ASL Recognition Card

    private var liveRecognitionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Live Recognition")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.primaryText)

                Spacer()

                // State chip: "Recognizing…", "Hold Steady", "Letter Recognized", or "No Hand Detected"
                HStack(spacing: 5) {
                    Image(systemName: liveRecognitionStateIcon)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(liveRecognitionStateColor)

                    Text(liveRecognitionStateText)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(liveRecognitionStateColor)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(liveRecognitionStateColor.opacity(0.12))
                .clipShape(Capsule())
                .accessibilityLabel("Recognition State: \(liveRecognitionStateText)")
            }

            HStack(spacing: 16) {
                // Large recognized letter (debounced output, zero flicker)
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(recognizedLetterBoxColor)
                        .frame(width: 72, height: 72)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(Theme.border, lineWidth: 1)
                        )

                    if let rec = displayedRecognizedLetter {
                        Text(rec.name)
                            .font(.system(size: AppSettings.shared.scaled(44), weight: .black, design: .rounded))
                            .foregroundStyle(rec == currentLetter ? Theme.sage : Theme.amber)
                    } else {
                        Text("—")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.secondaryText.opacity(0.4))
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    if let rec = displayedRecognizedLetter {
                        Text("Letter \(rec.name)")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.primaryText)

                        Text(rec == currentLetter ? "Matches target sign" : "Different sign detected")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(rec == currentLetter ? Theme.sage : Theme.amber)
                    } else {
                        Text(poseProcessor.landmarks.isEmpty ? "No hand in view" : "Analyzing handshape…")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(Theme.secondaryText)

                        Text(poseProcessor.landmarks.isEmpty ? "Raise hand into camera" : "Hold fingers steady to match")
                            .font(.caption2)
                            .foregroundStyle(Theme.secondaryText.opacity(0.8))
                    }
                }

                Spacer()
            }
        }
        .padding(16)
        .background(Theme.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                .strokeBorder(Theme.border, lineWidth: 1)
        )
        .shadow(color: Theme.shadowColor, radius: Theme.shadowRadius, x: 0, y: Theme.shadowY)
    }

    // MARK: - 3. Practice Coach Card

    private var coachCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Practice Coach", systemImage: "sparkles")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.terracotta)
                Spacer()
            }

            // Dynamic feedback status banner
            coachStatusView

            // Permanent Alphabet Navigation (Always Visible)
            alphabetNavigationView

            // Bottom Navigation Control
            Button {
                cameraManager.stop()
                dismiss()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                    Text("Back to Letters")
                }
            }
            .buttonStyle(WarmSecondaryButtonStyle(tintColor: Theme.primaryText))
            .accessibilityLabel("Return to letter selection")
        }
        .padding(18)
        .background(Theme.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                .strokeBorder(Theme.border, lineWidth: 1)
        )
        .shadow(color: Theme.shadowColor, radius: Theme.shadowRadius, x: 0, y: Theme.shadowY)
    }

    @ViewBuilder
    private var coachStatusView: some View {
        if poseProcessor.landmarks.isEmpty {
            // Hint when no hand: "Move your hand into view"
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Theme.secondaryText.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: "hand.wave")
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondaryText)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Move your hand into view")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.primaryText)
                    Text("Position your hand clearly within the camera frame.")
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryText)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.fieldSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Theme.border, lineWidth: 1))

        } else if displayedRecognizedLetter == currentLetter {
            // Target reliably recognized: "Correct!" with clear success state and retry option
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Theme.sage.opacity(0.18))
                        .frame(width: 40, height: 40)
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title3)
                        .foregroundStyle(Theme.sage)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Correct!")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.sage)
                    Text("Letter \(currentLetter.name) formed correctly.")
                        .font(.caption)
                        .foregroundStyle(Theme.primaryText)
                }

                Spacer()

                Button {
                    FeedbackService.shared.playTap()
                    retryPractice()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Retry")
                    }
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.sage)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Theme.sage.opacity(0.15))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Practice letter \(currentLetter.name) again")
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(Theme.sage.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Theme.sage.opacity(0.3), lineWidth: 1)
            )

        } else if let other = displayedRecognizedLetter {
            // Different letter confidently recognized: show detected letter + Retry button
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Theme.amber.opacity(0.18))
                            .frame(width: 40, height: 40)
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(Theme.amber)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Recognized as Letter \(other.name)")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.primaryText)
                        Text("Adjust your fingers to form Letter \(currentLetter.name) instead.")
                            .font(.caption)
                            .foregroundStyle(Theme.secondaryText)
                    }
                    Spacer()
                }

                Button {
                    FeedbackService.shared.playTap()
                    retryPractice()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Retry Letter \(currentLetter.name)")
                    }
                }
                .buttonStyle(WarmSecondaryButtonStyle(tintColor: Theme.terracotta))
                .accessibilityLabel("Retry practicing letter \(currentLetter.name)")
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.amber.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Theme.amber.opacity(0.3), lineWidth: 1)
            )

        } else {
            // Inconclusive: Neutral guidance, never mark wrong
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill((isHandMoving ? Theme.amber : Theme.terracotta).opacity(0.14))
                        .frame(width: 36, height: 36)
                    Image(systemName: isHandMoving ? "hand.raised.fill" : "info.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(isHandMoving ? Theme.amber : Theme.terracotta)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(isHandMoving ? "Hold Steady" : "Adjusting Handshape")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.primaryText)

                    Text(inconclusiveHint)
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryText)
                }
                Spacer()
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.fieldSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Theme.border, lineWidth: 1))
        }
    }

    // MARK: - Alphabet Navigation (Always Visible)

    private var alphabetNavigationView: some View {
        HStack(spacing: 10) {
            // Previous Alphabet Button
            Button {
                FeedbackService.shared.playTap()
                goToPreviousLetter()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.left")
                    Text(previousLetter != nil ? "Previous: \(previousLetter!.name)" : "Previous")
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(previousLetter == nil ? Theme.fieldSurface.opacity(0.4) : Theme.fieldSurface)
                .foregroundStyle(previousLetter == nil ? Theme.secondaryText.opacity(0.35) : Theme.primaryText)
                .clipShape(RoundedRectangle(cornerRadius: Theme.buttonRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.buttonRadius, style: .continuous)
                        .strokeBorder(previousLetter == nil ? Theme.border.opacity(0.4) : Theme.border, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(previousLetter == nil)
            .accessibilityLabel(previousLetter != nil ? "Go to previous letter \(previousLetter!.name)" : "Previous letter disabled")

            // Alphabet Explorer Grid Button
            Button {
                FeedbackService.shared.playTap()
                withAnimation(.easeInOut(duration: 0.2)) {
                    showAlphabetExplorer = true
                }
            } label: {
                Image(systemName: "square.grid.3x3.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Theme.terracotta)
                    .frame(width: 48, height: 48)
                    .background(Theme.fieldSurface)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.buttonRadius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.buttonRadius, style: .continuous)
                            .strokeBorder(Theme.border, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open Alphabet Explorer Grid")

            // Next Alphabet Button
            Button {
                FeedbackService.shared.playTap()
                advanceToNextLetter()
            } label: {
                HStack(spacing: 6) {
                    Text(nextLetter != nil ? "Next: \(nextLetter!.name)" : "Next")
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    Image(systemName: "arrow.right")
                }
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    nextLetter == nil
                        ? Theme.fieldSurface.opacity(0.4)
                        : (displayedRecognizedLetter == currentLetter ? Theme.sage : Theme.terracotta)
                )
                .foregroundStyle(nextLetter == nil ? Theme.secondaryText.opacity(0.35) : Color.white)
                .clipShape(RoundedRectangle(cornerRadius: Theme.buttonRadius, style: .continuous))
                .shadow(
                    color: nextLetter == nil ? Color.clear : (displayedRecognizedLetter == currentLetter ? Theme.sage : Theme.terracotta).opacity(0.25),
                    radius: 8, x: 0, y: 3
                )
            }
            .buttonStyle(.plain)
            .disabled(nextLetter == nil)
            .accessibilityLabel(nextLetter != nil ? "Go to next letter \(nextLetter!.name)" : "Next letter disabled")
        }
    }

    // MARK: - Reference Card (Target Letter & Reference Image)

    private var referenceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Target Sign")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(Theme.secondaryText)

                    Text("Letter \(currentLetter.name)")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(Theme.primaryText)
                }

                Spacer()

                // Target Letter Badge
                Text(currentLetter.name)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Theme.terracotta)
                    .clipShape(Circle())
                    .shadow(color: Theme.terracotta.opacity(0.3), radius: 8, x: 0, y: 3)
            }

            // Reference Image
            referenceImageView

            // Practice Instructions
            Text(currentLetter.instruction)
                .font(.subheadline)
                .foregroundStyle(Theme.secondaryText)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            // Contextual Similar-Letter Comparison Note
            if let comparison = SimilarLetterComparison.comparison(for: currentLetter) {
                Button {
                    FeedbackService.shared.playTap()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        activeComparison = comparison
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.left.and.right.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Theme.terracotta)

                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 5) {
                                Text("Similar Sign:")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundStyle(Theme.primaryText)

                                Text("Letter " + comparison.comparedLetter.name)
                                    .font(.system(size: 11, weight: .black, design: .rounded))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 1.5)
                                    .background(Theme.terracotta.opacity(0.14))
                                    .foregroundStyle(Theme.terracotta)
                                    .clipShape(Capsule())
                            }

                            Text("These letters can be easy to confuse. Tap to compare.")
                                .font(.caption2)
                                .foregroundStyle(Theme.secondaryText)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(Theme.terracotta.opacity(0.8))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Theme.fieldSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Theme.border, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("These letters can be easy to confuse. Tap to compare letter " + currentLetter.name + " with letter " + comparison.comparedLetter.name)
            }
        }
        .padding(18)
        .background(Theme.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                .strokeBorder(Theme.border, lineWidth: 1)
        )
        .shadow(color: Theme.shadowColor, radius: Theme.shadowRadius, x: 0, y: Theme.shadowY)
    }

    // MARK: - Reference Image

    @ViewBuilder
    private var referenceImageView: some View {
        let imageName = "asl_letter_" + currentLetter.lowercased()
        if UIImage(named: imageName) != nil {
            HStack {
                Spacer()
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 140)
                    .accessibilityLabel("Reference image for letter \(currentLetter.name)")
                Spacer()
            }
            .padding(.vertical, 8)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Theme.border, lineWidth: 1)
            )
        } else {
            HStack {
                Spacer()
                Text("Reference image not available")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)
                Spacer()
            }
            .padding(.vertical, 14)
            .background(Theme.fieldSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    // MARK: - State Logic & Pipeline Processing

    private func startPractice(for target: ASLLetter) {
        poseProcessor.targetLetter = target
        isCameraActive = true
        cameraManager.setupAndStart(
            sampleBufferDelegate: poseProcessor,
            queue: poseProcessor.processingQueue
        )
    }

    private func updateLiveTrackingAndRecognition(landmarks: [String: HandLandmark]) {
        // 1. Hand presence check
        guard !landmarks.isEmpty else {
            // Hand is not in view
            displayedRecognizedLetter = nil
            candidateLetter = nil
            candidateStreak = 0
            isHandMoving = false
            lastWristPoint = nil
            hasHandLeftAfterMatch = true // Hand has left! Allows next match to trigger once re-entered
            return
        }

        // 2. Measure landmark stability
        if let wrist = landmarks["wrist"] {
            if let last = lastWristPoint {
                let delta = hypot(wrist.point.x - last.x, wrist.point.y - last.y)
                isHandMoving = delta > 0.025
            } else {
                isHandMoving = false
            }
            lastWristPoint = wrist.point
        }

        // 3. Evaluate Recognition
        // Check if target letter is matched (debounced by existing MatchDebouncer)
        if poseProcessor.matchResult.isMatched {
            displayedRecognizedLetter = currentLetter
            candidateLetter = nil
            candidateStreak = 0

            // Trigger success, sound, haptic, mastery/streak updates ONCE per held pose
            if !hasRecordedPracticeMatch && hasHandLeftAfterMatch {
                hasRecordedPracticeMatch = true
                hasHandLeftAfterMatch = false // Lock until hand leaves or letter changes
                LetterMasteryManager.shared.recordPracticeSuccess(for: currentLetter)
                DailyChallengeManager.shared.recordPracticeSuccess(for: currentLetter)
                DailyStreakManager.shared.recordMeaningfulActivity()
                FeedbackService.shared.playSuccess()
            }
            return
        }

        // If target is not matched, check if a different valid letter is formed
        var detectedOther: ASLLetter? = nil
        for candidate in ASLLetter.allCases where candidate != currentLetter {
            let eval = HandPoseMatcher.evaluate(landmarks: landmarks, for: candidate, motionTracker: nil)
            if eval.isMatched {
                detectedOther = candidate
                break
            }
        }

        if let other = detectedOther {
            if candidateLetter == other {
                candidateStreak += 1
                if candidateStreak >= 4 { // Stably held for consecutive frames
                    displayedRecognizedLetter = other
                }
            } else {
                candidateLetter = other
                candidateStreak = 1
            }
        } else {
            candidateLetter = nil
            candidateStreak = 0
            displayedRecognizedLetter = nil
        }
    }

    private func navigateToLetter(_ target: ASLLetter) {
        currentLetter = target
        poseProcessor.targetLetter = target
        poseProcessor.resetMatch()
        hasRecordedPracticeMatch = false
        hasHandLeftAfterMatch = true
        displayedRecognizedLetter = nil
        candidateLetter = nil
        candidateStreak = 0
        lastWristPoint = nil
        isHandMoving = false
        activeComparison = nil
    }

    private func advanceToNextLetter() {
        guard let next = nextLetter else { return }
        navigateToLetter(next)
    }

    private func goToPreviousLetter() {
        guard let prev = previousLetter else { return }
        navigateToLetter(prev)
    }

    private func retryPractice() {
        poseProcessor.resetMatch()
        hasRecordedPracticeMatch = false
        displayedRecognizedLetter = nil
        candidateLetter = nil
        candidateStreak = 0
    }

    private var previousLetter: ASLLetter? {
        let all = ASLLetter.allCases
        guard let idx = all.firstIndex(of: currentLetter), idx > 0 else {
            return nil
        }
        return all[idx - 1]
    }

    private var nextLetter: ASLLetter? {
        let all = ASLLetter.allCases
        guard let idx = all.firstIndex(of: currentLetter), idx + 1 < all.count else {
            return nil
        }
        return all[idx + 1]
    }

    private var inconclusiveHint: String {
        if isHandMoving {
            return "Hold your hand steady in camera view."
        }
        if let hint = poseProcessor.matchResult.hint {
            return hint
        }
        return "Position fingers to match the reference instruction."
    }

    private var liveRecognitionStateText: String {
        if poseProcessor.landmarks.isEmpty {
            return "No Hand Detected"
        }
        if displayedRecognizedLetter != nil {
            return "Letter Recognized"
        }
        if isHandMoving || poseProcessor.matchResult.state == .adjustYourFingers {
            return "Hold Steady"
        }
        return "Recognizing…"
    }

    private var liveRecognitionStateIcon: String {
        if poseProcessor.landmarks.isEmpty {
            return "hand.wave"
        }
        if displayedRecognizedLetter != nil {
            return "checkmark.circle.fill"
        }
        if isHandMoving || poseProcessor.matchResult.state == .adjustYourFingers {
            return "hand.raised.fill"
        }
        return "sparkles"
    }

    private var liveRecognitionStateColor: Color {
        if poseProcessor.landmarks.isEmpty {
            return Theme.secondaryText
        }
        if displayedRecognizedLetter != nil {
            return displayedRecognizedLetter == currentLetter ? Theme.sage : Theme.amber
        }
        if isHandMoving || poseProcessor.matchResult.state == .adjustYourFingers {
            return Theme.amber
        }
        return Theme.terracotta
    }

    private var recognizedLetterBoxColor: Color {
        if let rec = displayedRecognizedLetter {
            return (rec == currentLetter ? Theme.sage : Theme.amber).opacity(0.14)
        }
        return Theme.fieldSurface
    }

    private var cameraBorderColor: Color {
        if poseProcessor.landmarks.isEmpty {
            return Theme.border
        }
        if displayedRecognizedLetter == currentLetter {
            return Theme.sage
        }
        if displayedRecognizedLetter != nil {
            return Theme.amber
        }
        if isHandMoving || poseProcessor.matchResult.state == .adjustYourFingers {
            return Theme.amber
        }
        return Theme.peach
    }
}

#Preview {
    NavigationStack {
        LetterPracticeView(letter: .b)
    }
}


// MARK: - Similar-Letter Comparison Model

struct SimilarLetterComparison: Identifiable {
    let id = UUID()
    let targetLetter: ASLLetter
    let comparedLetter: ASLLetter
    let differenceExplanation: String
    let targetKeyPoint: String
    let comparedKeyPoint: String

    static func comparison(for letter: ASLLetter) -> SimilarLetterComparison? {
        switch letter {
        case .m:
            return SimilarLetterComparison(
                targetLetter: .m,
                comparedLetter: .n,
                differenceExplanation: "Both letters tuck the thumb into a fist under folded fingers. For 'M', three fingers fold over the thumb. For 'N', only two fingers fold over the thumb.",
                targetKeyPoint: "Thumb tucked under 3 fingers (index, middle, ring).",
                comparedKeyPoint: "Thumb tucked under only 2 fingers (index, middle)."
            )
        case .n:
            return SimilarLetterComparison(
                targetLetter: .n,
                comparedLetter: .m,
                differenceExplanation: "Both letters tuck the thumb into a fist under folded fingers. For 'N', two fingers fold over the thumb. For 'M', three fingers fold over the thumb.",
                targetKeyPoint: "Thumb tucked under 2 fingers (index, middle).",
                comparedKeyPoint: "Thumb tucked under 3 fingers (index, middle, ring)."
            )
        case .u:
            return SimilarLetterComparison(
                targetLetter: .u,
                comparedLetter: .v,
                differenceExplanation: "Both letters extend the index and middle fingers straight up. For 'U', hold both fingers pressed together. For 'V', spread them apart in a 'V' shape.",
                targetKeyPoint: "Index and middle fingers pressed tightly together.",
                comparedKeyPoint: "Index and middle fingers spread apart into a 'V'."
            )
        case .v:
            return SimilarLetterComparison(
                targetLetter: .v,
                comparedLetter: .u,
                differenceExplanation: "Both letters extend the index and middle fingers straight up. For 'V', spread both fingers apart in a 'V' shape. For 'U', hold both fingers pressed tightly together.",
                targetKeyPoint: "Index and middle fingers spread apart into a 'V'.",
                comparedKeyPoint: "Index and middle fingers pressed tightly together."
            )
        case .a:
            return SimilarLetterComparison(
                targetLetter: .a,
                comparedLetter: .s,
                differenceExplanation: "Both letters form a fist. For 'A', your thumb rests upright along the outer side of your index finger. For 'S', your thumb wraps across the front of your curled fingers.",
                targetKeyPoint: "Thumb rests upright along the outer side of index finger.",
                comparedKeyPoint: "Thumb wraps firmly across the front of curled fingers."
            )
        case .s:
            return SimilarLetterComparison(
                targetLetter: .s,
                comparedLetter: .a,
                differenceExplanation: "Both letters form a fist. For 'S', your thumb wraps across the front of your curled fingers. For 'A', your thumb rests upright along the outer side of your index finger.",
                targetKeyPoint: "Thumb wraps firmly across the front of curled fingers.",
                comparedKeyPoint: "Thumb rests upright along the outer side of index finger."
            )
        case .g:
            return SimilarLetterComparison(
                targetLetter: .g,
                comparedLetter: .h,
                differenceExplanation: "Both letters point horizontally. For 'G', only the index finger and thumb extend parallel. For 'H', both index and middle fingers extend forward together.",
                targetKeyPoint: "Only index finger and thumb extend horizontally.",
                comparedKeyPoint: "Both index and middle fingers extend forward together."
            )
        case .h:
            return SimilarLetterComparison(
                targetLetter: .h,
                comparedLetter: .g,
                differenceExplanation: "Both letters point horizontally. For 'H', both index and middle fingers extend forward together. For 'G', only the index finger extends forward parallel to the thumb.",
                targetKeyPoint: "Both index and middle fingers extend forward together.",
                comparedKeyPoint: "Only index finger and thumb extend horizontally."
            )
        case .d:
            return SimilarLetterComparison(
                targetLetter: .d,
                comparedLetter: .f,
                differenceExplanation: "For 'D', your index finger points straight up while the other three fingers touch the thumb. For 'F', the index finger and thumb touch in an 'OK' circle while the other three fingers stand upright.",
                targetKeyPoint: "Index finger points straight up; other 3 fingers touch thumb.",
                comparedKeyPoint: "Index and thumb touch in a circle; 3 fingers stand straight up."
            )
        case .f:
            return SimilarLetterComparison(
                targetLetter: .f,
                comparedLetter: .d,
                differenceExplanation: "For 'F', your index finger and thumb touch in an 'OK' circle while the other three fingers stand upright. For 'D', your index finger points straight up while the other three fingers touch the thumb.",
                targetKeyPoint: "Index and thumb touch in a circle; 3 fingers stand straight up.",
                comparedKeyPoint: "Index finger points straight up; other 3 fingers touch thumb."
            )
        case .k:
            return SimilarLetterComparison(
                targetLetter: .k,
                comparedLetter: .p,
                differenceExplanation: "'K' and 'P' share the exact same finger shape (index upright, middle angled forward, thumb at the base). For 'K', the hand points upright. For 'P', the hand tilts downward.",
                targetKeyPoint: "Handshape points upright towards the ceiling.",
                comparedKeyPoint: "Handshape tilted forward and pointing downward."
            )
        case .p:
            return SimilarLetterComparison(
                targetLetter: .p,
                comparedLetter: .k,
                differenceExplanation: "'P' and 'K' share the exact same finger shape. For 'P', the hand tilts downward towards the floor. For 'K', the hand points upright towards the ceiling.",
                targetKeyPoint: "Handshape tilted forward and pointing downward.",
                comparedKeyPoint: "Handshape points upright towards the ceiling."
            )
        case .c:
            return SimilarLetterComparison(
                targetLetter: .c,
                comparedLetter: .o,
                differenceExplanation: "Both letters curve the hand into a rounded shape. For 'C', the hand stays open without fingertips touching the thumb. For 'O', all fingertips touch the thumb to close the circle.",
                targetKeyPoint: "Open curved hand shape; fingertips and thumb stay apart.",
                comparedKeyPoint: "Closed circle; all fingertips touch the thumb."
            )
        case .o:
            return SimilarLetterComparison(
                targetLetter: .o,
                comparedLetter: .c,
                differenceExplanation: "Both letters curve the hand into a rounded shape. For 'O', all fingertips touch the thumb to form a closed circle. For 'C', the hand stays open without fingertips touching the thumb.",
                targetKeyPoint: "Closed circle; all fingertips touch the thumb.",
                comparedKeyPoint: "Open curved hand shape; fingertips and thumb stay apart."
            )
        case .i:
            return SimilarLetterComparison(
                targetLetter: .i,
                comparedLetter: .j,
                differenceExplanation: "Both letters feature the extended little finger. For 'I', the hand is held stationary upright in place. For 'J', the little finger traces a curved 'J' motion downward in the air.",
                targetKeyPoint: "Little finger held stationary upright in place.",
                comparedKeyPoint: "Little finger traces the 'J' curve in the air."
            )
        case .j:
            return SimilarLetterComparison(
                targetLetter: .j,
                comparedLetter: .i,
                differenceExplanation: "Both letters feature the extended little finger. For 'J', the little finger traces a curved 'J' motion through the air. For 'I', the hand is held stationary upright in place.",
                targetKeyPoint: "Little finger traces the 'J' curve in the air.",
                comparedKeyPoint: "Little finger held stationary upright in place."
            )
        default:
            return nil
        }
    }
}

// MARK: - Similar-Letter Comparison Popup View

struct SimilarLetterComparisonPopupView: View {
    let comparison: SimilarLetterComparison
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .center) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.left.and.right.circle.fill")
                        .font(.headline)
                        .foregroundStyle(Theme.terracotta)

                    Text("Compare: " + comparison.targetLetter.name + " vs " + comparison.comparedLetter.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(Theme.primaryText)
                }

                Spacer()

                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Theme.secondaryText)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close Comparison")
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 12)

            Divider().background(Theme.border)

            // Content
            ScrollView {
                VStack(spacing: 16) {
                    // Side-by-side ASL reference cards
                    HStack(alignment: .top, spacing: 12) {
                        comparisonLetterCard(
                            letter: comparison.targetLetter,
                            badgeTitle: "Current Target",
                            badgeColor: Theme.terracotta,
                            keyPoint: comparison.targetKeyPoint
                        )

                        comparisonLetterCard(
                            letter: comparison.comparedLetter,
                            badgeTitle: "Similar Sign",
                            badgeColor: Theme.amber,
                            keyPoint: comparison.comparedKeyPoint
                        )
                    }

                    // Key Difference Card
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Theme.amber)

                            Text("Key Difference")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(Theme.primaryText)
                        }

                        Text(comparison.differenceExplanation)
                            .font(.subheadline)
                            .foregroundStyle(Theme.secondaryText)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.amber.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Theme.amber.opacity(0.25), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }

            Divider().background(Theme.border)

            // Bottom Action
            Button {
                onDismiss()
            } label: {
                Text("Back to Practice")
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
        .contentShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
        .onTapGesture { /* Prevent dismissal when tapping inside the card */ }
        .padding(.horizontal, 20)
    }

    private func comparisonLetterCard(
        letter: ASLLetter,
        badgeTitle: String,
        badgeColor: Color,
        keyPoint: String
    ) -> some View {
        VStack(spacing: 8) {
            // Letter Badge & Label
            HStack(spacing: 6) {
                Text(letter.name)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(badgeColor)
                    .clipShape(Circle())

                Text(badgeTitle)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(badgeColor)

                Spacer()
            }

            // Image Container
            let imageName = "asl_letter_" + letter.lowercased()
            if UIImage(named: imageName) != nil {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 115)
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Theme.border, lineWidth: 1)
                    )
                    .accessibilityLabel("Reference image for letter " + letter.name)
            } else {
                Text("No Image")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)
                    .frame(height: 115)
                    .frame(maxWidth: .infinity)
                    .background(Theme.fieldSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            // Finger gesture key point
            Text(keyPoint)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.secondaryText)
                .lineSpacing(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Theme.fieldSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(badgeColor.opacity(0.3), lineWidth: 1)
        )
    }
}
