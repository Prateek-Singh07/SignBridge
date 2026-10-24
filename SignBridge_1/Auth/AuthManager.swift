//
//  AuthManager.swift
//  SignBridge_1
//
//  Created by KIET2 on 24/10/26.
//

import Combine
import SwiftUI

/// Authentication manager handling demo credentials verification,
/// session persistence with "Remember Me", and sign-out lifecycle.
final class AuthManager: ObservableObject {
    static let shared = AuthManager()

    // Required demo credentials
    static let validUserID = "Prateek Singh"
    static let validPassword = "1234"

    private let userDefaultsKeyIsLoggedIn = "SignBridge_isLoggedIn"
    private let userDefaultsKeyRememberMe = "SignBridge_rememberMe"
    private let userDefaultsKeySavedUserID = "SignBridge_savedUserID"

    @Published var isAuthenticated: Bool

    private init() {
        let rememberMe = UserDefaults.standard.bool(forKey: userDefaultsKeyRememberMe)
        let isLoggedIn = UserDefaults.standard.bool(forKey: userDefaultsKeyIsLoggedIn)
        self.isAuthenticated = rememberMe && isLoggedIn
    }

    /// Validates User ID and Password against required credentials.
    func validate(userID: String, password: String) -> Bool {
        let trimmedUser = userID.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPass = password.trimmingCharacters(in: .whitespacesAndNewlines)

        let isUserMatch = trimmedUser.caseInsensitiveCompare(Self.validUserID) == .orderedSame
        let isPassMatch = trimmedPass == Self.validPassword

        return isUserMatch && isPassMatch
    }

    /// Logs the user in and records session state based on Remember Me preference.
    func login(rememberMe: Bool, userID: String) {
        UserDefaults.standard.set(rememberMe, forKey: userDefaultsKeyRememberMe)
        UserDefaults.standard.set(true, forKey: userDefaultsKeyIsLoggedIn)

        if rememberMe {
            UserDefaults.standard.set(userID.trimmingCharacters(in: .whitespacesAndNewlines), forKey: userDefaultsKeySavedUserID)
        } else {
            UserDefaults.standard.removeObject(forKey: userDefaultsKeySavedUserID)
        }

        withAnimation(.easeInOut(duration: 0.3)) {
            self.isAuthenticated = true
        }
    }

    /// Logs the user out and clears the active session.
    func logout() {
        UserDefaults.standard.set(false, forKey: userDefaultsKeyIsLoggedIn)
        withAnimation(.easeInOut(duration: 0.3)) {
            self.isAuthenticated = false
        }
    }

    var savedUserID: String {
        UserDefaults.standard.string(forKey: userDefaultsKeySavedUserID) ?? ""
    }

    var isRememberMeEnabled: Bool {
        UserDefaults.standard.bool(forKey: userDefaultsKeyRememberMe)
    }
}
