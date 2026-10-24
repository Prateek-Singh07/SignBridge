# SignBridge 🤟

An intelligent, native SwiftUI application for interactive **American Sign Language (ASL)** alphabet learning and fingerspelling recognition, built with **Apple Vision framework** hand tracking and real-time landmark classification.

---

## ✨ Features

- **Real-Time Hand Pose Recognition:**
  - Real-time hand detection and 21-point 3D skeleton landmark tracking using `VNDetectHumanHandPoseRequest`.
  - Multi-frame debouncing and orientation-adaptive geometric classification for ASL letters A–Z.
  - Interactive hand-skeleton overlay providing instant visual posture feedback.

- **Practice Mode & Coach:**
  - Learn all 26 ASL alphabet signs at your own pace with visual reference guides.
  - Real-time coaching hints ("Hold Steady", "Adjusting Handshape", contextual similar-letter comparisons like M vs N or U vs V).
  - Integrated **Alphabet Explorer**: clean A–Z grid popup with live mastery filtering (New, Learning, Mastered) and instant letter switching.

- **Daily Sign Challenge:**
  - Deterministic 5-letter daily challenge that refreshes every midnight.
  - Verified completion tracking (only genuine practice matches count toward progress).
  - Local persistence across app restarts with duplicate protection.
  - Celebration screen upon completing all 5 daily signs with streak recording.

- **Quiz Mode & Performance Analytics:**
  - Test fingerspelling recall from memory with timed rounds.
  - Quiz history tracking with score analytics, accuracy percentages, and performance trends over time.

- **Warm, Accessible Design:**
  - Custom warm design system (Terracotta, Peach, Sage, Amber).
  - Dynamic type text scaling, accessibility labels, and haptic/audio feedback chimes.

---

## 🛠️ Requirements

- **macOS / iOS:** macOS Sonoma or later (Mac Catalyst) / iOS 17.0+
- **Xcode:** Xcode 16.0+
- **Swift:** Swift 5.10 / Swift 6
- **Hardware:** Built-in camera or external webcam with camera permissions granted

---

## 🚀 Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/mmtxrc/SignBridge.git
   cd SignBridge
   ```

2. Open the Xcode project:
   ```bash
   open SignBridge_1.xcodeproj
   ```

3. Select your target destination (e.g., **My Mac (Mac Catalyst)** or an iOS device) and click **Run** (`⌘R`).

---

## 📄 License & Attribution

- See [ASSET_LICENSES.md](ASSET_LICENSES.md) for image assets and attribution details.
