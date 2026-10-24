//
//  QuizModels.swift
//  SignBridge_1
//
//  Created by KIET2 on 24/10/26.
//

import Foundation

/// Represents an individual question in a Quiz session.
struct QuizQuestion: Identifiable, Equatable {
    let id: UUID
    let targetLetter: ASLLetter
    var recognizedLetter: ASLLetter?
    var isCorrect: Bool
    var isEvaluated: Bool
    var evaluationMessage: String

    init(targetLetter: ASLLetter) {
        self.id = UUID()
        self.targetLetter = targetLetter
        self.recognizedLetter = nil
        self.isCorrect = false
        self.isEvaluated = false
        self.evaluationMessage = ""
    }
}

/// Aggregates results of an entire completed quiz session.
struct QuizResult: Equatable {
    let totalQuestions: Int
    let questions: [QuizQuestion]

    var correctCount: Int {
        questions.filter { $0.isCorrect }.count
    }

    var incorrectCount: Int {
        totalQuestions - correctCount
    }

    var percentage: Int {
        guard totalQuestions > 0 else { return 0 }
        return Int(round(Double(correctCount) / Double(totalQuestions) * 100.0))
    }

    var feedbackTitle: String {
        switch percentage {
        case 100:
            return "Flawless Score!"
        case 80...99:
            return "Outstanding Mastery!"
        case 60...79:
            return "Good Progress!"
        case 40...59:
            return "Keep Practicing!"
        default:
            return "Room for Improvement"
        }
    }

    var feedbackDescription: String {
        switch percentage {
        case 100:
            return "Exceptional work! You recognized and accurately signed every letter without visual guides. Your muscle memory is top-tier."
        case 80...99:
            return "Great job! You have strong command of alphabet fingerspelling. Review the few letters missed to achieve complete mastery."
        case 60...79:
            return "Solid performance! You demonstrated good knowledge of many letters. Head to Practice Mode to reinforce the handshapes you missed."
        case 40...59:
            return "You are getting there! Some letters can be tricky to distinguish. Use Practice Mode with real-time skeleton feedback to hone your skills."
        default:
            return "Learning sign language takes time and patience! Spend some more time in Practice Mode with the reference diagrams, then try this quiz again."
        }
    }

    var missedLetters: [ASLLetter] {
        questions.filter { !$0.isCorrect }.map { $0.targetLetter }
    }
}

/// Helper for generating randomized quiz questions adhering to:
/// "Randomly select target letters from A–Z without repeating a letter within a quiz until all 26 letters have been used."
enum QuizGenerator {
    static func generateQuestions(count: Int) -> [QuizQuestion] {
        var pool: [ASLLetter] = []
        var selected: [ASLLetter] = []

        while selected.count < count {
            if pool.isEmpty {
                pool = ASLLetter.allCases.shuffled()
            }
            selected.append(pool.removeFirst())
        }

        return selected.map { QuizQuestion(targetLetter: $0) }
    }
}
