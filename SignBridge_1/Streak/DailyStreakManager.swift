//
//  DailyStreakManager.swift
//  SignBridge_1
//
//  Created by KIET2 on 24/10/26.
//

import Combine
import Foundation

/// Status of a specific calendar day in the weekly streak overview.
struct DayPracticeStatus: Identifiable, Equatable {
    var id: String { dateString }
    let date: Date
    let dateString: String
    let weekdaySymbol: String
    let dayNumber: String
    let isToday: Bool
    let isPracticed: Bool
}

/// Tracks, calculates, and persists daily fingerspelling streaks using the local device calendar.
/// Only meaningful activity (verified practice matches or completed quizzes) counts toward the streak.
final class DailyStreakManager: ObservableObject {
    static let shared = DailyStreakManager()

    private let storageKey = "signbridge_daily_streak_dates"
    private let longestStreakKey = "signbridge_daily_longest_streak"

    @Published private(set) var practicedDateStrings: Set<String> = []
    @Published private(set) var longestStreak: Int = 0

    init() {
        loadData()
    }

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

    func dateString(from date: Date) -> String {
        dateFormatter.string(from: date)
    }

    var todayString: String {
        dateString(from: Date())
    }

    var hasPracticedToday: Bool {
        practicedDateStrings.contains(todayString)
    }

    // MARK: - Activity Recording

    /// Records a meaningful practice or quiz event.
    /// Each calendar day is counted at most once regardless of session volume.
    func recordMeaningfulActivity(on date: Date = Date()) {
        let dStr = dateString(from: date)
        if !practicedDateStrings.contains(dStr) {
            practicedDateStrings.insert(dStr)
            persist()
            updateLongestStreak()
        }
    }

    // MARK: - Streak Calculation

    var currentStreak: Int {
        let today = Date()

        var checkDate = today
        if !hasPracticedToday {
            // If user has not practiced today yet, verify if streak was active through yesterday
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
                  practicedDateStrings.contains(dateString(from: yesterday)) else {
                return 0
            }
            checkDate = yesterday
        }

        var streak = 0
        while practicedDateStrings.contains(dateString(from: checkDate)) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else {
                break
            }
            checkDate = previousDay
        }

        return streak
    }

    private func updateLongestStreak() {
        let curr = currentStreak
        if curr > longestStreak {
            longestStreak = curr
            UserDefaults.standard.set(longestStreak, forKey: longestStreakKey)
        }
    }

    // MARK: - Weekly Calendar Overview

    var currentWeekDays: [DayPracticeStatus] {
        let today = Date()
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: today) else {
            return []
        }

        var days: [DayPracticeStatus] = []
        let weekdayFormatter = DateFormatter()
        weekdayFormatter.calendar = calendar
        weekdayFormatter.locale = Locale.current
        weekdayFormatter.dateFormat = "EEEEE" // Single letter: S, M, T, W, T, F, S

        let dayNumFormatter = DateFormatter()
        dayNumFormatter.calendar = calendar
        dayNumFormatter.dateFormat = "d"

        for offset in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: offset, to: weekInterval.start) {
                let dStr = dateString(from: date)
                let isToday = calendar.isDateInToday(date)
                let isPracticed = practicedDateStrings.contains(dStr)
                let symbol = weekdayFormatter.string(from: date)
                let num = dayNumFormatter.string(from: date)

                days.append(DayPracticeStatus(
                    date: date,
                    dateString: dStr,
                    weekdaySymbol: symbol,
                    dayNumber: num,
                    isToday: isToday,
                    isPracticed: isPracticed
                ))
            }
        }
        return days
    }

    // MARK: - Encouraging Message

    var encouragingMessage: String {
        if currentStreak == 0 && !hasPracticedToday {
            return "Start your daily streak! Complete a practice sign or quiz today to ignite your flame."
        } else if hasPracticedToday {
            if currentStreak >= 7 {
                return "🔥 Incredible dedication! You've maintained a \(currentStreak)-day practice streak!"
            } else if currentStreak >= 3 {
                return "You're on fire! \(currentStreak) consecutive days of practice. Keep the momentum going!"
            } else {
                return "Practice completed for today! Your daily streak is active and growing."
            }
        } else {
            return "Keep your \(currentStreak)-day streak alive! Complete any letter practice or quiz today to keep your flame burning."
        }
    }

    // MARK: - Persistence

    private func loadData() {
        if let storedDates = UserDefaults.standard.stringArray(forKey: storageKey) {
            self.practicedDateStrings = Set(storedDates)
        } else {
            self.practicedDateStrings = []
        }

        self.longestStreak = UserDefaults.standard.integer(forKey: longestStreakKey)
        updateLongestStreak()
    }

    private func persist() {
        UserDefaults.standard.set(Array(practicedDateStrings), forKey: storageKey)
    }

    func resetStreak() {
        practicedDateStrings.removeAll()
        longestStreak = 0
        UserDefaults.standard.removeObject(forKey: storageKey)
        UserDefaults.standard.removeObject(forKey: longestStreakKey)
    }
}
