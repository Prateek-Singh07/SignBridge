//
//  DailyChallengeManager.swift
//  SignBridge_1
//
//  Created by KIET2 on 24/10/26.
//

import Combine
import Foundation
import SwiftUI

/// Persistent record tracking daily 5-letter challenge progress for a specific calendar day.
struct DailyChallengeRecord: Codable, Equatable {
    let dateString: String
    let targetLetters: [String]
    var completedLetters: [String]
    var isCompleted: Bool
    var completedAt: Date?

    var progressCount: Int {
        completedLetters.count
    }

    var totalCount: Int {
        targetLetters.count
    }

    var progressFraction: Double {
        guard totalCount > 0 else { return 0 }
        return Double(progressCount) / Double(totalCount)
    }

    var progressPercentage: Int {
        Int(round(progressFraction * 100.0))
    }
}

/// Central manager for the Daily Sign Challenge.
/// Deterministically selects 5 letters per calendar day and persists progress across app restarts.
final class DailyChallengeManager: ObservableObject {
    static let shared = DailyChallengeManager()

    private let storagePrefix = "signbridge_daily_challenge_"

    @Published private(set) var currentChallenge: DailyChallengeRecord

    private var calendar: Calendar {
        Calendar.current
    }

    private var dateFormatter: DateFormatter {
        let df = DateFormatter()
        df.calendar = calendar
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd"
        return df
    }

    var todayString: String {
        dateFormatter.string(from: Date())
    }

    init() {
        let today = DateFormatter()
        today.calendar = Calendar.current
        today.locale = Locale(identifier: "en_US_POSIX")
        today.dateFormat = "yyyy-MM-dd"
        let dStr = today.string(from: Date())

        self.currentChallenge = DailyChallengeManager.loadChallenge(for: dStr)
    }

    /// Refreshes challenge state for the current day if the date rolled over.
    func checkDailyRollover() {
        let today = todayString
        if currentChallenge.dateString != today {
            currentChallenge = DailyChallengeManager.loadChallenge(for: today)
        }
    }

    // MARK: - Deterministic Letter Selection

    /// Deterministically generates 5 distinct ASL letters for any given date string.
    static func letters(for dateString: String) -> [ASLLetter] {
        var hash: UInt64 = 5381
        for byte in dateString.utf8 {
            hash = ((hash << 5) &+ hash) &+ UInt64(byte)
        }

        var available = ASLLetter.allCases
        var selected: [ASLLetter] = []

        for _ in 0..<5 {
            hash = hash &* 6364136223846793005 &+ 1442695040888963407
            let index = Int(hash % UInt64(available.count))
            selected.append(available.remove(at: index))
        }

        return selected
    }

    // MARK: - Persistence

    private static func loadChallenge(for dateString: String) -> DailyChallengeRecord {
        let key = "signbridge_daily_challenge_" + dateString
        if let data = UserDefaults.standard.data(forKey: key),
           let record = try? JSONDecoder().decode(DailyChallengeRecord.self, from: data) {
            return record
        }

        // Generate a new deterministic challenge for this date
        let targetLetters = letters(for: dateString).map { $0.name }
        let newRecord = DailyChallengeRecord(
            dateString: dateString,
            targetLetters: targetLetters,
            completedLetters: [],
            isCompleted: false,
            completedAt: nil
        )

        // Save immediately
        if let encoded = try? JSONEncoder().encode(newRecord) {
            UserDefaults.standard.set(encoded, forKey: key)
        }

        return newRecord
    }

    private func persistCurrent() {
        let key = storagePrefix + currentChallenge.dateString
        if let encoded = try? JSONEncoder().encode(currentChallenge) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }

    // MARK: - Progress Tracking

    /// Records genuine practice match completion for a letter.
    /// Only marks progress if the letter is part of today's challenge and not already completed.
    func recordPracticeSuccess(for letter: ASLLetter) {
        checkDailyRollover()

        let letterName = letter.name
        guard currentChallenge.targetLetters.contains(letterName) else {
            return
        }

        if !currentChallenge.completedLetters.contains(letterName) {
            currentChallenge.completedLetters.append(letterName)

            // Check if all 5 letters are now completed
            if currentChallenge.completedLetters.count >= currentChallenge.targetLetters.count {
                if !currentChallenge.isCompleted {
                    currentChallenge.isCompleted = true
                    currentChallenge.completedAt = Date()
                    // Record streak activity (only once per calendar day)
                    DailyStreakManager.shared.recordMeaningfulActivity()
                }
            }

            persistCurrent()
        }
    }

    /// Returns the challenge target letters as ASLLetter cases.
    var targetASLLetters: [ASLLetter] {
        currentChallenge.targetLetters.compactMap { name in
            ASLLetter.allCases.first(where: { $0.name == name })
        }
    }

    /// Returns whether a given letter in the challenge is already completed today.
    func isLetterCompleted(_ letter: ASLLetter) -> Bool {
        currentChallenge.completedLetters.contains(letter.name)
    }

    /// Returns the first pending (uncompleted) letter in today's challenge, or the first letter if all done.
    var firstPendingLetter: ASLLetter? {
        for letter in targetASLLetters {
            if !isLetterCompleted(letter) {
                return letter
            }
        }
        return targetASLLetters.first
    }
}
