//
//  Theme.swift
//  SignBridge_1
//
//  Created by KIET2 on 24/10/26.
//

import SwiftUI
import UIKit

/// Central design system tokens for the warm, light, minimal, soft visual theme.
enum Theme {
    // MARK: - Palette (Light Default & Warm Dark Brown fallback)

    /// Background: #FFF8F0 (warm cream), dark fallback: #2A211C (warm dark brown)
    static let background = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0x2A/255.0, green: 0x21/255.0, blue: 0x1C/255.0, alpha: 1.0)
            : UIColor(red: 0xFF/255.0, green: 0xF8/255.0, blue: 0xF0/255.0, alpha: 1.0)
    })

    /// Background gradient end: #FDEFE2, dark: #221A15
    static let backgroundEnd = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0x22/255.0, green: 0x1A/255.0, blue: 0x15/255.0, alpha: 1.0)
            : UIColor(red: 0xFD/255.0, green: 0xEF/255.0, blue: 0xE2/255.0, alpha: 1.0)
    })

    /// Card Surface: #FFFFFF at ~90% over cream (#FFF3E6), dark: #382C26
    static let cardSurface = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0x38/255.0, green: 0x2C/255.0, blue: 0x26/255.0, alpha: 1.0)
            : UIColor(red: 1.0, green: 0.985, blue: 0.965, alpha: 0.95)
    })

    /// Field & Secondary Card Surface: #FAF1E6, dark: #2F241E
    static let fieldSurface = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0x2F/255.0, green: 0x24/255.0, blue: 0x1E/255.0, alpha: 1.0)
            : UIColor(red: 0xFA/255.0, green: 0xF1/255.0, blue: 0xE6/255.0, alpha: 1.0)
    })

    /// Primary text: #3B2F2A, dark: #FFF8F0
    static let primaryText = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0xFF/255.0, green: 0xF8/255.0, blue: 0xF0/255.0, alpha: 1.0)
            : UIColor(red: 0x3B/255.0, green: 0x2F/255.0, blue: 0x2A/255.0, alpha: 1.0)
    })

    /// Secondary text: #7A6A60, dark: #C7B7AB
    static let secondaryText = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0xC7/255.0, green: 0xB7/255.0, blue: 0xAB/255.0, alpha: 1.0)
            : UIColor(red: 0x7A/255.0, green: 0x6A/255.0, blue: 0x60/255.0, alpha: 1.0)
    })

    /// Primary accent: #BF5B35 (terracotta)
    static let terracotta = Color(red: 0xBF/255.0, green: 0x5B/255.0, blue: 0x35/255.0)

    /// Secondary accent: #E8A15D (amber)
    static let amber = Color(red: 0xE8/255.0, green: 0xA1/255.0, blue: 0x5D/255.0)

    /// Peach tint: #F2C6A0
    static let peach = Color(red: 0xF2/255.0, green: 0xC6/255.0, blue: 0xA0/255.0)

    /// Success: #6F9A7E (sage)
    static let sage = Color(red: 0x6F/255.0, green: 0x9A/255.0, blue: 0x7E/255.0)

    /// Error: #C4504F (muted rose-red)
    static let rose = Color(red: 0xC4/255.0, green: 0x50/255.0, blue: 0x4F/255.0)

    /// Borders / dividers: #EADBCB at 1pt, dark: #4D3E35
    static let border = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0x4D/255.0, green: 0x3E/255.0, blue: 0x35/255.0, alpha: 1.0)
            : UIColor(red: 0xEA/255.0, green: 0xDB/255.0, blue: 0xCB/255.0, alpha: 1.0)
    })

    /// Dimmed backdrop for popups & menus: warm brown (not black)
    static let backdrop = Color(red: 0x2A/255.0, green: 0x21/255.0, blue: 0x1C/255.0).opacity(0.35)

    // MARK: - Mastery State Colors
    static let masteryNew = Color(red: 0xD9/255.0, green: 0xC9/255.0, blue: 0xB8/255.0)
    static let masteryLearning = amber
    static let masteryMastered = sage

    // MARK: - Geometry & Radii
    static let cardRadius: CGFloat = 22
    static let buttonRadius: CGFloat = 16
    static let chipRadius: CGFloat = 12

    // MARK: - Shadow Tokens
    static let shadowColor = terracotta.opacity(0.08)
    static let shadowRadius: CGFloat = 16
    static let shadowY: CGFloat = 6
}

// MARK: - View Modifiers

struct WarmBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            LinearGradient(
                colors: [Theme.background, Theme.backgroundEnd],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            content
        }
    }
}

struct WarmCardModifier: ViewModifier {
    var radius: CGFloat = Theme.cardRadius

    func body(content: Content) -> some View {
        content
            .background(Theme.cardSurface)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Theme.border, lineWidth: 1)
            )
            .shadow(color: Theme.shadowColor, radius: Theme.shadowRadius, x: 0, y: Theme.shadowY)
    }
}

extension View {
    func warmBackground() -> some View {
        modifier(WarmBackgroundModifier())
    }

    func warmCard(radius: CGFloat = Theme.cardRadius) -> some View {
        modifier(WarmCardModifier(radius: radius))
    }
}

// MARK: - Button Styles

struct WarmPrimaryButtonStyle: ButtonStyle {
    var backgroundColor: Color = Theme.terracotta
    var foregroundColor: Color = .white

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .foregroundStyle(foregroundColor)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: Theme.buttonRadius, style: .continuous))
            .shadow(color: backgroundColor.opacity(0.25), radius: 10, x: 0, y: 4)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.25), value: configuration.isPressed)
    }
}

struct WarmSecondaryButtonStyle: ButtonStyle {
    var tintColor: Color = Theme.terracotta

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundStyle(tintColor)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Theme.fieldSurface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.buttonRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.buttonRadius, style: .continuous)
                    .strokeBorder(Theme.border, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.25), value: configuration.isPressed)
    }
}
