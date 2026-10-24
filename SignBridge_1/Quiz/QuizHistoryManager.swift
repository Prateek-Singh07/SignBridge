//
//  QuizHistoryManager.swift
//  SignBridge_1
//
//  Created by KIET2 on 24/10/26.
//

import Combine
import Foundation

/// Stored record of a single question within a completed quiz attempt.
struct QuizQuestionRecord: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    let targetLetter: String
    let recognizedLetter: String?
    let isCorrect: Bool

    enum CodingKeys: String, CodingKey {
        case id, targetLetter, recognizedLetter, isCorrect
    }
}

/// Stored record of a completed quiz attempt.
struct QuizAttemptRecord: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    let date: Date
    let questionCount: Int
    let score: Int
    let accuracy: Int
    let questionResults: [QuizQuestionRecord]

    enum CodingKeys: String, CodingKey {
        case id, date, questionCount, score, accuracy, questionResults
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    var shortDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
}

/// Manages local persistent storage of completed quiz attempts without network, account, or API key.
final class QuizHistoryManager: ObservableObject {
    static let shared = QuizHistoryManager()

    private let storageKey = "signbridge_local_quiz_history"

    @Published private(set) var attempts: [QuizAttemptRecord] = []

    init() {
        loadAttempts()
    }

    func loadAttempts() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            self.attempts = []
            return
        }

        if let decoded = try? JSONDecoder().decode([QuizAttemptRecord].self, from: data) {
            // Keep newest attempts first
            self.attempts = decoded.sorted(by: { $0.date > $1.date })
        }
    }

    /// Records a completed quiz attempt. Only fully completed quizzes are saved.
    func recordCompletedQuiz(result: QuizResult) {
        guard result.totalQuestions > 0 else { return }
        DailyStreakManager.shared.recordMeaningfulActivity()

        let questionRecords = result.questions.map { q in
            QuizQuestionRecord(
                targetLetter: q.targetLetter.name,
                recognizedLetter: q.recognizedLetter?.name,
                isCorrect: q.isCorrect
            )
        }

        let record = QuizAttemptRecord(
            date: Date(),
            questionCount: result.totalQuestions,
            score: result.correctCount,
            accuracy: result.percentage,
            questionResults: questionRecords
        )

        attempts.insert(record, at: 0)
        persist()
    }

    func clearHistory() {
        attempts.removeAll()
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    private func persist() {
        if let encoded = try? JSONEncoder().encode(attempts) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    // MARK: - Aggregate Statistics & Trend Data

    var totalQuizzes: Int {
        attempts.count
    }

    var averageAccuracy: Int {
        guard !attempts.isEmpty else { return 0 }
        let total = attempts.reduce(0) { $0 + $1.accuracy }
        return total / attempts.count
    }

    var bestAccuracy: Int {
        attempts.map { $0.accuracy }.max() ?? 0
    }

    /// Returns the last up to 7 attempts chronologically for the score trend graph.
    var recentTrend: [QuizAttemptRecord] {
        Array(attempts.prefix(7).reversed())
    }
}
