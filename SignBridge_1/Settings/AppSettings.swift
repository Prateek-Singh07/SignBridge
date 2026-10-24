//
//  AppSettings.swift
//  SignBridge_1
//
//  Created by KIET2 on 24/10/26.
//

import Combine
import Foundation
import SwiftUI

/// Available visual appearance theme modes.
enum AppearanceMode: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    var iconName: String {
        switch self {
        case .system:
            return "circle.righthalf.filled"
        case .light:
            return "sun.max.fill"
        case .dark:
            return "moon.fill"
        }
    }
}

/// Available text size adjustments with guaranteed scale factor for dynamic scaling.
enum AppTextSize: String, CaseIterable, Identifiable {
    case standard = "Default"
    case medium = "Medium"
    case large = "Large"
    case extraLarge = "Extra Large"

    var id: String { rawValue }

    var dynamicTypeSize: DynamicTypeSize {
        switch self {
        case .standard:
            return .large
        case .medium:
            return .xLarge
        case .large:
            return .xxLarge
        case .extraLarge:
            return .accessibility2
        }
    }

    var scaleFactor: CGFloat {
        switch self {
        case .standard:
            return 1.0
        case .medium:
            return 1.15
        case .large:
            return 1.30
        case .extraLarge:
            return 1.45
        }
    }
}

/// Manages and persists accessibility and usability preferences locally across app launches.
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private let appearanceKey = "signbridge_pref_appearance_mode"
    private let textSizeKey = "signbridge_pref_text_size"
    private let soundKey = "signbridge_pref_sound_enabled"
    private let hapticsKey = "signbridge_pref_haptics_enabled"

    @Published var appearanceMode: AppearanceMode {
        didSet {
            UserDefaults.standard.set(appearanceMode.rawValue, forKey: appearanceKey)
        }
    }

    @Published var textSize: AppTextSize {
        didSet {
            UserDefaults.standard.set(textSize.rawValue, forKey: textSizeKey)
        }
    }

    @Published var isSoundEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isSoundEnabled, forKey: soundKey)
        }
    }

    @Published var isHapticsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isHapticsEnabled, forKey: hapticsKey)
        }
    }

    init() {
        // Appearance
        if let storedAppearance = UserDefaults.standard.string(forKey: appearanceKey),
           let mode = AppearanceMode(rawValue: storedAppearance) {
            self.appearanceMode = mode
        } else {
            self.appearanceMode = .light
        }

        // Text Size
        if let storedTextSize = UserDefaults.standard.string(forKey: textSizeKey),
           let size = AppTextSize(rawValue: storedTextSize) {
            self.textSize = size
        } else {
            self.textSize = .standard
        }

        // Sound Toggle (default: true)
        if UserDefaults.standard.object(forKey: soundKey) != nil {
            self.isSoundEnabled = UserDefaults.standard.bool(forKey: soundKey)
        } else {
            self.isSoundEnabled = true
        }

        // Haptics Toggle (default: true)
        if UserDefaults.standard.object(forKey: hapticsKey) != nil {
            self.isHapticsEnabled = UserDefaults.standard.bool(forKey: hapticsKey)
        } else {
            self.isHapticsEnabled = true
        }
    }

    /// Scaled point size calculator for explicit fonts.
    func scaled(_ base: CGFloat) -> CGFloat {
        base * textSize.scaleFactor
    }

    /// Resets all settings to default values.
    func resetToDefaults() {
        appearanceMode = .light
        textSize = .standard
        isSoundEnabled = true
        isHapticsEnabled = true
    }
}
