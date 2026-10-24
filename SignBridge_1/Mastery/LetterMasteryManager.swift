//
//  LetterMasteryManager.swift
//  SignBridge_1
//
//  Created by KIET2 on 24/10/26.
//

import Combine
import Foundation
import SwiftUI

/// The three distinct mastery progression states for an alphabet letter.
enum LetterMasteryStatus: String, Codable, CaseIterable, Identifiable {
    case new = "New"
    case learning = "Learning"
    case mastered = "Mastered"

    var id: String { rawValue }

    var badgeColor: Color {
        switch self {
        case .new:
            return Theme.masteryNew
        case .learning:
            return Theme.masteryLearning
        case .mastered:
            return Theme.masteryMastered
        }
    }

    var iconName: String {
        switch self {
        case .new:
            return "circle.dashed"
        case .learning:
            return "arrow.triangle.2.circlepath"
        case .mastered:
            return "checkmark.seal.fill"
        }
    }

    var shortDescription: String {
        switch self {
        case .new:
            return "Not started yet"
        case .learning:
            return "Practicing in progress"
        case .mastered:
            return "Sign verified & mastered"
        }
    }
}

/// Persistent record tracking practice and quiz performance for an individual letter.
struct LetterMasteryRecord: Codable, Identifiable, Equatable {
    var id: String { letter }
    let letter: String
    var practiceSuccessCount: Int
    var quizCorrectCount: Int
    var quizAttemptCount: Int
    var lastUpdated: Date?

    init(
        letter: String,
        practiceSuccessCount: Int = 0,
        quizCorrectCount: Int = 0,
        quizAttemptCount: Int = 0,
        lastUpdated: Date? = nil
    ) {
        self.letter = letter
        self.practiceSuccessCount = practiceSuccessCount
        self.quizCorrectCount = quizCorrectCount
        self.quizAttemptCount = quizAttemptCount
        self.lastUpdated = lastUpdated
    }

    var totalSuccessCount: Int {
        practiceSuccessCount + quizCorrectCount
    }

    /// Computed mastery state based on consistent, verified threshold.
    /// A letter requires at least 3 successful recognitions across practice and quizzes to become Mastered.
    var status: LetterMasteryStatus {
        if practiceSuccessCount == 0 && quizAttemptCount == 0 {
            return .new
        }
        if totalSuccessCount >= 3 {
            return .mastered
        }
        return .learning
    }
}

/// Central manager for tracking and persisting local letter mastery.
/// Reuses existing quiz history upon initialization to avoid duplicate tracking.
final class LetterMasteryManager: ObservableObject {
    static let shared = LetterMasteryManager()

    private let storageKey = "signbridge_letter_mastery_records"

    @Published private(set) var records: [String: LetterMasteryRecord] = [:]

    init() {
        loadRecords()
        syncWithExistingQuizHistoryIfNeeded()
    }

    // MARK: - Persistence & Sync

    private func loadRecords() {
        var loaded: [String: LetterMasteryRecord] = [:]

        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([String: LetterMasteryRecord].self, from: data) {
            loaded = decoded
        }

        // Ensure all 26 letters (A–Z) have an initialized record
        for letter in ASLLetter.allCases {
            let key = letter.name
            if loaded[key] == nil {
                loaded[key] = LetterMasteryRecord(letter: key)
            }
        }

        self.records = loaded
    }

    private func persist() {
        if let encoded = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    /// Reuses past quiz attempts stored in QuizHistoryManager if this is a fresh launch or missing records.
    private func syncWithExistingQuizHistoryIfNeeded() {
        let history = QuizHistoryManager.shared.attempts
        guard !history.isEmpty else { return }

        var changed = false
        for attempt in history {
            for q in attempt.questionResults {
                let letterKey = q.targetLetter
                guard var rec = records[letterKey] else { continue }

                // If quiz counts are unrecorded for this letter, tally them from history
                if rec.quizAttemptCount == 0 {
                    rec.quizAttemptCount += 1
                    if q.isCorrect {
                        rec.quizCorrectCount += 1
                    }
                    rec.lastUpdated = attempt.date
                    records[letterKey] = rec
                    changed = true
                }
            }
        }

        if changed {
            persist()
        }
    }

    // MARK: - Mutation Methods

    /// Records a successful recognition in Letter Practice mode.
    func recordPracticeSuccess(for letter: ASLLetter) {
        let key = letter.name
        var rec = records[key] ?? LetterMasteryRecord(letter: key)
        rec.practiceSuccessCount += 1
        rec.lastUpdated = Date()
        records[key] = rec
        persist()
    }

    /// Records an evaluated question from Quiz mode.
    func recordQuizAttempt(for letter: ASLLetter, isCorrect: Bool) {
        let key = letter.name
        var rec = records[key] ?? LetterMasteryRecord(letter: key)
        rec.quizAttemptCount += 1
        if isCorrect {
            rec.quizCorrectCount += 1
        }
        rec.lastUpdated = Date()
        records[key] = rec
        persist()
    }

    /// Resets all letter mastery tracking back to initial state.
    func resetMastery() {
        var clean: [String: LetterMasteryRecord] = [:]
        for letter in ASLLetter.allCases {
            clean[letter.name] = LetterMasteryRecord(letter: letter.name)
        }
        records = clean
        persist()
    }

    // MARK: - Aggregate Queries

    func record(for letter: ASLLetter) -> LetterMasteryRecord {
        records[letter.name] ?? LetterMasteryRecord(letter: letter.name)
    }

    func status(for letter: ASLLetter) -> LetterMasteryStatus {
        record(for: letter).status
    }

    var masteredCount: Int {
        records.values.filter { $0.status == .mastered }.count
    }

    var learningCount: Int {
        records.values.filter { $0.status == .learning }.count
    }

    var newCount: Int {
        records.values.filter { $0.status == .new }.count
    }

    var totalLetters: Int {
        ASLLetter.allCases.count
    }

    var progressPercentage: Int {
        guard totalLetters > 0 else { return 0 }
        return Int(round(Double(masteredCount) / Double(totalLetters) * 100.0))
    }

    /// Returns letters that still need practice (Letters in 'Learning' state first, followed by 'New').
    var lettersNeedingPractice: [ASLLetter] {
        let learningLetters = ASLLetter.allCases.filter { status(for: $0) == .learning }
        let newLetters = ASLLetter.allCases.filter { status(for: $0) == .new }
        return learningLetters + newLetters
    }
}
