//
//  LoginView.swift
//  SignBridge_1
//
//  Created by KIET2 on 24/10/26.
//

import SwiftUI

/// Polished login view in warm, light, minimal aesthetic,
/// featuring logo animation, credential validation, show/hide password toggle,
/// and Remember Me persistence.
struct LoginView: View {
    @ObservedObject private var auth = AuthManager.shared
    @ObservedObject private var settings = AppSettings.shared

    @State private var userID: String = ""
    @State private var password: String = ""
    @State private var rememberMe: Bool = true
    @State private var isPasswordVisible: Bool = false
    @State private var errorMessage: String? = nil
    @State private var isLoading: Bool = false

    // 0.3-second subtle launch logo animation
    @State private var logoScale: CGFloat = 0.85
    @State private var logoOpacity: Double = 0.0

    var body: some View {
        ZStack {
            // Warm Cream Background Gradient
            LinearGradient(
                colors: [Theme.background, Theme.backgroundEnd],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Spacer(minLength: 28)

                    // Logo & Brand Header with 0.3-second animation
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Theme.terracotta, Theme.peach],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                                .shadow(color: Theme.terracotta.opacity(0.25), radius: 16, x: 0, y: 6)

                            Image(systemName: "hand.raised.fill")
                                .font(.system(size: settings.scaled(40), weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)

                        VStack(spacing: 4) {
                            Text("SignBridge")
                                .font(.system(size: settings.scaled(32), weight: .bold, design: .rounded))
                                .foregroundStyle(Theme.primaryText)

                            Text("Sign Language Recognition")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(Theme.secondaryText)
                        }
                    }
                    .multilineTextAlignment(.center)

                    // Login Card
                    VStack(spacing: 20) {
                        // Card Header
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Welcome Back")
                                .font(.system(size: settings.scaled(20), weight: .bold, design: .rounded))
                                .foregroundStyle(Theme.primaryText)

                            Text("Sign in to your learning account")
                                .font(.subheadline)
                                .foregroundStyle(Theme.secondaryText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        // Error Banner
                        if let error = errorMessage {
                            HStack(spacing: 10) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(Theme.rose)

                                Text(error)
                                    .font(.footnote)
                                    .fontWeight(.medium)
                                    .foregroundStyle(Theme.rose)

                                Spacer()
                            }
                            .padding(12)
                            .background(Theme.rose.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(Theme.rose.opacity(0.25), lineWidth: 1)
                            )
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        // Input Fields
                        VStack(spacing: 16) {
                            // User ID Field
                            VStack(alignment: .leading, spacing: 6) {
                                Text("User ID")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Theme.primaryText)

                                HStack(spacing: 10) {
                                    Image(systemName: "person.fill")
                                        .font(.subheadline)
                                        .foregroundStyle(Theme.terracotta)
                                        .frame(width: 20)

                                    TextField("Enter User ID", text: $userID)
                                        .autocapitalization(.words)
                                        .disableAutocorrection(true)
                                        .foregroundStyle(Theme.primaryText)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(Theme.fieldSurface)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .strokeBorder(Theme.border, lineWidth: 1)
                                )
                            }

                            // Password Field with Show/Hide Toggle
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Password")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Theme.primaryText)

                                HStack(spacing: 10) {
                                    Image(systemName: "lock.fill")
                                        .font(.subheadline)
                                        .foregroundStyle(Theme.terracotta)
                                        .frame(width: 20)

                                    if isPasswordVisible {
                                        TextField("Enter Password", text: $password)
                                            .autocapitalization(.none)
                                            .disableAutocorrection(true)
                                            .foregroundStyle(Theme.primaryText)
                                    } else {
                                        SecureField("Enter Password", text: $password)
                                            .autocapitalization(.none)
                                            .disableAutocorrection(true)
                                            .foregroundStyle(Theme.primaryText)
                                    }

                                    Button {
                                        isPasswordVisible.toggle()
                                    } label: {
                                        Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                            .font(.subheadline)
                                            .foregroundStyle(Theme.secondaryText)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel(isPasswordVisible ? "Hide password" : "Show password")
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(Theme.fieldSurface)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .strokeBorder(Theme.border, lineWidth: 1)
                                )
                            }
                        }

                        // Remember Me Checkbox
                        HStack {
                            Button {
                                FeedbackService.shared.playTap()
                                rememberMe.toggle()
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: rememberMe ? "checkmark.square.fill" : "square")
                                        .font(.system(size: 17))
                                        .foregroundStyle(rememberMe ? Theme.terracotta : Theme.secondaryText)

                                    Text("Remember Me")
                                        .font(.subheadline)
                                        .foregroundStyle(Theme.primaryText)
                                }
                            }
                            .buttonStyle(.plain)

                            Spacer()
                        }
                        .padding(.top, 2)

                        // Login Action Button
                        Button {
                            performLogin()
                        } label: {
                            HStack(spacing: 8) {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Sign In")
                                        .font(.system(size: 16, weight: .bold, design: .rounded))

                                    Image(systemName: "arrow.right")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                }
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Theme.terracotta)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.buttonRadius, style: .continuous))
                            .shadow(color: Theme.terracotta.opacity(0.3), radius: 10, x: 0, y: 4)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .disabled(isLoading)
                    }
                    .padding(24)
                    .background(Theme.cardSurface)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                            .strokeBorder(Theme.border, lineWidth: 1)
                    )
                    .shadow(color: Theme.shadowColor, radius: Theme.shadowRadius, x: 0, y: Theme.shadowY)
                    .frame(maxWidth: 440)

                    Spacer(minLength: 28)
                }
                .padding(.horizontal, 24)
            }
        }
        .onAppear {
            // Trigger 0.3s logo animation
            withAnimation(.easeOut(duration: 0.3)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }

            // Restore saved User ID if Remember Me was previously enabled
            if auth.isRememberMeEnabled && !auth.savedUserID.isEmpty {
                userID = auth.savedUserID
                rememberMe = true
            }
        }
    }

    private func performLogin() {
        FeedbackService.shared.playTap()
        errorMessage = nil

        let trimmedUser = userID.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPass = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedUser.isEmpty && !trimmedPass.isEmpty else {
            withAnimation(.easeInOut(duration: 0.2)) {
                errorMessage = "Please enter both User ID and Password."
            }
            return
        }

        isLoading = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            isLoading = false
            if auth.validate(userID: trimmedUser, password: trimmedPass) {
                auth.login(rememberMe: rememberMe, userID: trimmedUser)
            } else {
                withAnimation(.easeInOut(duration: 0.2)) {
                    errorMessage = "Invalid User ID or Password. Please try again."
                }
            }
        }
    }
}

// MARK: - Scale Button Style

private struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.25), value: configuration.isPressed)
    }
}

#Preview {
    LoginView()
}
