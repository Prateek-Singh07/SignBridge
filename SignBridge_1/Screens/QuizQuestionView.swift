//
//  QuizQuestionView.swift
//  SignBridge_1
//
//  Created by KIET2 on 24/10/26.
//

import AVFoundation
import SwiftUI

/// Main question screen for Quiz Mode.
/// Displays target letter without visual clues, captures the user's handshape on button press,
/// evaluates against the recognition engine, and manages running score.
struct QuizQuestionView: View {
    let questionCount: Int
    let onExitToDashboard: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    @ObservedObject private var cameraManager = CameraSessionManager.shared
    @StateObject private var poseProcessor = HandPoseProcessor()

    @State private var questions: [QuizQuestion] = []
    @State private var currentIndex: Int = 0
    @State private var isCameraActive: Bool = false

    // Evaluation feedback state for the active question
    @State private var evaluationState: EvaluationStatus = .waitingForCapture
    @State private var showResultsScreen: Bool = false

    enum EvaluationStatus: Equatable {
        case waitingForCapture
        case noHandDetected
        case motionIncomplete(hint: String)
        case inconclusive(hint: String?)
        case evaluated(isCorrect: Bool, recognizedLetter: ASLLetter?, message: String)
    }

    var body: some View {
        VStack(spacing: 0) {
            if showResultsScreen {
                QuizResultsView(
                    result: QuizResult(totalQuestions: questions.count, questions: questions),
                    onRetakeQuiz: {
                        restartQuiz()
                    },
                    onReturnToDashboard: {
                        cameraManager.stop()
                        dismiss()
                        onExitToDashboard()
                    }
                )
            } else if !questions.isEmpty && currentIndex < questions.count {
                questionContent
            } else {
                ProgressView("Preparing Quiz...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .warmBackground()
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if !showResultsScreen {
                    Button("Exit Quiz") {
                        cameraManager.stop()
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                }
            }
        }
        .onAppear {
            #if DEBUG
            print("[Camera Timing] QuizQuestionView appeared at \(CFAbsoluteTimeGetCurrent())")
            #endif
            if questions.isEmpty {
                questions = QuizGenerator.generateQuestions(count: questionCount)
            }
            startActiveQuestion()
        }
        .onDisappear {
            cameraManager.stop()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if isCameraActive && !showResultsScreen {
                if newPhase == .active {
                    cameraManager.start()
                } else {
                    cameraManager.stop()
                }
            }
        }
    }

    // MARK: - Question Content Layout

    @ViewBuilder
    private var questionContent: some View {
        let currentQuestion = questions[currentIndex]

        ScrollView {
            VStack(spacing: 16) {
                // Top Progress & Score Bar
                headerSection

                // Prominent Target Letter Display (NO visual hints/illustrations!)
                targetPromptSection(letter: currentQuestion.targetLetter)

                // Live Camera Section with Hand Skeleton Overlay
                cameraSection

                // Evaluation Feedback Banner
                evaluationBanner

                // Bottom Action Controls
                actionButtonsSection
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
            .frame(maxWidth: 540)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    // MARK: - Header (Progress and Score)

    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Question \(currentIndex + 1) of \(questions.count)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundStyle(Theme.amber)
                    Text("Score: \(runningScore)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.primaryText)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Theme.cardSurface)
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(Theme.border, lineWidth: 1))
            }

            ProgressView(value: Double(currentIndex + 1), total: Double(questions.count))
                .tint(Theme.terracotta)
        }
        .padding(.top, 8)
    }

    // MARK: - Target Prompt Section

    private func targetPromptSection(letter: ASLLetter) -> some View {
        VStack(spacing: 6) {
            Text("Form the handshape for:")
                .font(.subheadline)
                .foregroundStyle(Theme.secondaryText)

            HStack(spacing: 12) {
                Text("Letter")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundStyle(Theme.secondaryText)

                Text(letter.name)
                    .font(.system(size: AppSettings.shared.scaled(52), weight: .black, design: .rounded))
                    .foregroundStyle(Theme.terracotta)
            }

            if letter == .j || letter == .z {
                Label("Dynamic sign: trace movement in air", systemImage: "waveform.path")
                    .font(.caption)
                    .foregroundStyle(Theme.amber)
            }
        }
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(Theme.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                .strokeBorder(Theme.border, lineWidth: 1)
        )
        .shadow(color: Theme.shadowColor, radius: Theme.shadowRadius, x: 0, y: Theme.shadowY)
    }

    // MARK: - Live Camera View

    @ViewBuilder
    private var cameraSection: some View {
        switch cameraManager.permissionState {
        case .running:
            ZStack {
                CameraPreviewView(session: cameraManager.session)
                    .accessibilityHidden(true)

                HandSkeletonView(
                    landmarks: poseProcessor.landmarks,
                    videoDimensions: poseProcessor.videoDimensions
                )
            }
            .aspectRatio(3.0 / 4.0, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(cameraBorderColor, lineWidth: 3)
            )

        case .denied, .restricted:
            VStack(spacing: 14) {
                Image(systemName: "camera.badge.ellipsis")
                    .font(.system(size: 36))
                    .foregroundStyle(Theme.terracotta)
                Text("Camera Access Required")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.primaryText)
                Text("Camera access is needed to evaluate your signs during the quiz. Please enable access in Settings.")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)

                HStack(spacing: 12) {
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Text("Open Settings")
                            .frame(minHeight: 44)
                    }
                    .buttonStyle(WarmPrimaryButtonStyle(backgroundColor: Theme.terracotta))
                    .accessibilityLabel("Open system settings to enable camera")

                    Button {
                        cameraManager.retry(
                            sampleBufferDelegate: poseProcessor,
                            queue: poseProcessor.processingQueue
                        )
                    } label: {
                        Text("Retry")
                            .frame(minHeight: 44)
                    }
                    .buttonStyle(WarmSecondaryButtonStyle(tintColor: Theme.primaryText))
                    .accessibilityLabel("Retry camera access")
                }
            }
            .padding(20)
            .frame(height: 260)
            .frame(maxWidth: .infinity)
            .background(Theme.cardSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.border, lineWidth: 1))

        case .unavailable(let reason):
            VStack(spacing: 14) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Theme.amber)
                Text("Camera Unavailable")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.primaryText)
                Text(reason)
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)

                Button {
                    cameraManager.retry(
                        sampleBufferDelegate: poseProcessor,
                        queue: poseProcessor.processingQueue
                    )
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Retry Camera")
                    }
                    .frame(minHeight: 44)
                }
                .buttonStyle(WarmSecondaryButtonStyle(tintColor: Theme.terracotta))
                .accessibilityLabel("Retry camera initialization")
            }
            .padding(20)
            .frame(height: 260)
            .frame(maxWidth: .infinity)
            .background(Theme.cardSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.border, lineWidth: 1))

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
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.border, lineWidth: 1))
        }
    }

    // MARK: - Evaluation Banner

    @ViewBuilder
    private var evaluationBanner: some View {
        switch evaluationState {
        case .waitingForCapture:
            HStack(spacing: 8) {
                Image(systemName: "hand.raised.fill")
                    .foregroundStyle(Theme.terracotta)
                Text("Position your hand in camera view, then tap Capture Answer.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 6)

        case .noHandDetected:
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Theme.amber)
                Text("No hand detected. Hold your hand clearly in the frame and retry.")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Theme.amber)
            }
            .padding(10)
            .frame(maxWidth: .infinity)
            .background(Theme.amber.opacity(0.14))
            .clipShape(RoundedRectangle(cornerRadius: 10))

        case .motionIncomplete(let hint):
            HStack(spacing: 8) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundStyle(Theme.terracotta)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Movement Incomplete")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(Theme.terracotta)
                    Text(hint)
                        .font(.caption2)
                        .foregroundStyle(.primary)
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.peach.opacity(0.25))
            .clipShape(RoundedRectangle(cornerRadius: 10))

        case .inconclusive(let hint):
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Theme.amber)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Recognition Inconclusive")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(Theme.amber)
                        Text(hint ?? "Camera could not clearly recognize the handshape.")
                            .font(.caption)
                            .foregroundStyle(.primary)
                    }
                }
                Text("Adjust your hand in frame and retry without penalty.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.amber.opacity(0.14))
            .clipShape(RoundedRectangle(cornerRadius: 12))

        case .evaluated(let isCorrect, let recognizedLetter, let message):
            if isCorrect {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Theme.sage)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Correct! (+1 mark)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(Theme.sage)

                        Text(message)
                            .font(.caption)
                            .foregroundStyle(.primary)
                    }
                    Spacer()
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(Theme.sage.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                let targetLetter = questions[currentIndex].targetLetter
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Theme.rose)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Incorrect (+0 marks)")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundStyle(Theme.rose)

                            Text(message)
                                .font(.caption)
                                .foregroundStyle(.primary)

                            if let rec = recognizedLetter {
                                Text("Recognized shape: Letter \(rec.name)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                    }

                    Divider()

                    // Reveal correct reference image and guidance
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(Theme.amber)
                            Text("Correct Handshape for Letter \(targetLetter.name):")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                        }

                        let imageName = "asl_letter_" + targetLetter.lowercased()
                        if UIImage(named: imageName) != nil {
                            HStack {
                                Spacer()
                                Image(imageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 140)
                                    .accessibilityLabel("Correct handshape for letter \(targetLetter.name)")
                                Spacer()
                            }
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white)
                            )
                        }

                        Text(targetLetter.instruction)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineSpacing(2)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.rose.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Theme.rose.opacity(0.25), lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Action Buttons

    @ViewBuilder
    private var actionButtonsSection: some View {
        switch evaluationState {
        case .waitingForCapture, .noHandDetected, .motionIncomplete:
            Button {
                captureAndEvaluate()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "camera.viewfinder")
                    Text("Capture Answer")
                }
            }
            .buttonStyle(WarmPrimaryButtonStyle(backgroundColor: Theme.terracotta))

        case .inconclusive:
            VStack(spacing: 10) {
                Button {
                    captureAndEvaluate()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Retry Capture (No Penalty)")
                    }
                }
                .buttonStyle(WarmPrimaryButtonStyle(backgroundColor: Theme.amber))

                Button {
                    markInconclusiveAsIncorrect()
                } label: {
                    HStack(spacing: 6) {
                        Text("Skip / Mark Incorrect")
                        Image(systemName: "chevron.right")
                    }
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)
                }
            }

        case .evaluated(let isCorrect, _, _):
            HStack(spacing: 12) {
                if !isCorrect {
                    Button {
                        retryCurrentQuestion()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Try Again")
                        }
                    }
                    .buttonStyle(WarmSecondaryButtonStyle(tintColor: Theme.terracotta))
                }

                Button {
                    goToNextQuestion()
                } label: {
                    HStack(spacing: 6) {
                        Text(isLastQuestion ? "View Results" : "Next Question")
                        Image(systemName: isLastQuestion ? "chart.bar.doc.horizontal.fill" : "arrow.right")
                    }
                }
                .buttonStyle(WarmPrimaryButtonStyle(backgroundColor: isCorrect ? Theme.sage : Theme.terracotta))
            }
        }
    }

    // MARK: - Helper Computations & Actions

    private var isLastQuestion: Bool {
        currentIndex + 1 >= questions.count
    }

    private var runningScore: Int {
        questions.filter { $0.isCorrect }.count
    }

    private var cameraBorderColor: Color {
        switch evaluationState {
        case .waitingForCapture:
            return Theme.border
        case .noHandDetected, .inconclusive, .motionIncomplete:
            return Theme.amber
        case .evaluated(let isCorrect, _, _):
            return isCorrect ? Theme.sage : Theme.rose
        }
    }

    private func startActiveQuestion() {
        guard currentIndex < questions.count else { return }
        let letter = questions[currentIndex].targetLetter
        poseProcessor.targetLetter = letter
        poseProcessor.resetMatch()
        evaluationState = .waitingForCapture

        if !isCameraActive {
            isCameraActive = true
            cameraManager.setupAndStart(
                sampleBufferDelegate: poseProcessor,
                queue: poseProcessor.processingQueue
            )
        }
    }

    private func captureAndEvaluate() {
        // Prevent duplicate evaluations if already scored
        if case .evaluated = evaluationState { return }

        let landmarks = poseProcessor.landmarks
        guard !landmarks.isEmpty else {
            evaluationState = .noHandDetected
            return
        }

        let target = questions[currentIndex].targetLetter

        // Special graceful handling for dynamic letters (J and Z)
        if target == .j || target == .z {
            let eval = HandPoseMatcher.evaluate(
                landmarks: landmarks,
                for: target,
                motionTracker: poseProcessor.motionTracker
            )

            // If the motion was incomplete or in progress, do not penalize as wrong immediately
            if !eval.isMatched, let hint = eval.hint, isMotionHint(hint) {
                evaluationState = .motionIncomplete(hint: hint)
                return
            }
        }

        // Standard evaluation against target letter
        let targetMatch = HandPoseMatcher.evaluate(
            landmarks: landmarks,
            for: target,
            motionTracker: poseProcessor.motionTracker
        )

        if targetMatch.isMatched {
            // Confirmed Correct Answer
            questions[currentIndex].isCorrect = true
            questions[currentIndex].isEvaluated = true
            questions[currentIndex].recognizedLetter = target
            questions[currentIndex].evaluationMessage = "Target Letter \(target.name) successfully matched."
            LetterMasteryManager.shared.recordQuizAttempt(for: target, isCorrect: true)
            FeedbackService.shared.playSuccess()
            evaluationState = .evaluated(
                isCorrect: true,
                recognizedLetter: target,
                message: "Target Letter \(target.name) matched!"
            )
        } else {
            // Check if another known letter was formed instead
            var recognizedOther: ASLLetter? = nil
            for candidate in ASLLetter.allCases where candidate != target {
                let candidateResult = HandPoseMatcher.evaluate(
                    landmarks: landmarks,
                    for: candidate,
                    motionTracker: nil
                )
                if candidateResult.isMatched {
                    recognizedOther = candidate
                    break
                }
            }

            if let confirmedIncorrect = recognizedOther {
                // Confirmed Incorrect: Another valid letter was clearly signed
                questions[currentIndex].isCorrect = false
                questions[currentIndex].isEvaluated = true
                questions[currentIndex].recognizedLetter = confirmedIncorrect
                let msg = "Sign recognized as Letter \(confirmedIncorrect.name) instead of Letter \(target.name)."
                questions[currentIndex].evaluationMessage = msg
                LetterMasteryManager.shared.recordQuizAttempt(for: target, isCorrect: false)
                FeedbackService.shared.playIncorrect()

                evaluationState = .evaluated(
                    isCorrect: false,
                    recognizedLetter: confirmedIncorrect,
                    message: msg
                )
            } else {
                // Inconclusive Recognition: Neither target nor any other letter matched
                // Allow user to retry without penalizing them
                evaluationState = .inconclusive(hint: targetMatch.hint)
            }
        }
    }

    private func isMotionHint(_ hint: String) -> Bool {
        let keywords = ["hook", "trace", "curve", "stroke", "draw", "across", "air"]
        let lower = hint.lowercased()
        return keywords.contains { lower.contains($0) }
    }

    private func markInconclusiveAsIncorrect() {
        let target = questions[currentIndex].targetLetter
        questions[currentIndex].isCorrect = false
        questions[currentIndex].isEvaluated = true
        questions[currentIndex].recognizedLetter = nil
        let msg = "Handshape was inconclusive for Letter \(target.name)."
        questions[currentIndex].evaluationMessage = msg
        LetterMasteryManager.shared.recordQuizAttempt(for: target, isCorrect: false)
        FeedbackService.shared.playIncorrect()
        evaluationState = .evaluated(
            isCorrect: false,
            recognizedLetter: nil,
            message: msg
        )
    }

    private func retryCurrentQuestion() {
        questions[currentIndex].isCorrect = false
        questions[currentIndex].isEvaluated = false
        questions[currentIndex].recognizedLetter = nil
        poseProcessor.resetMatch()
        evaluationState = .waitingForCapture
    }

    private func goToNextQuestion() {
        if currentIndex + 1 < questions.count {
            currentIndex += 1
            startActiveQuestion()
        } else {
            // Save completed quiz attempt to local history
            let completedResult = QuizResult(totalQuestions: questions.count, questions: questions)
            QuizHistoryManager.shared.recordCompletedQuiz(result: completedResult)
            showResultsScreen = true
        }
    }

    private func restartQuiz() {
        questions = QuizGenerator.generateQuestions(count: questionCount)
        currentIndex = 0
        showResultsScreen = false
        startActiveQuestion()
    }
}
