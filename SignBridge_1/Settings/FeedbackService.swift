//
//  FeedbackService.swift
//  SignBridge_1
//
//  Created by KIET2 on 24/10/26.
//

import AudioToolbox
import AVFoundation
import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Provides native, reliable tactile and auditory feedback honoring user accessibility toggles.
/// Uses in-memory synthesized PCM WAV playback with ambient audio session configuration
/// to guarantee audio playback across both iOS and macOS (Mac Catalyst).
final class FeedbackService {
    static let shared = FeedbackService()

    private var audioPlayer: AVAudioPlayer?
    private let successSoundData: Data
    private let incorrectSoundData: Data
    private let tapSoundData: Data

    private init() {
        // Pre-synthesize brief, pleasant feedback audio tones in-memory
        self.successSoundData = Self.createTwoToneWav(freq1: 880.0, freq2: 1320.0, durationPerTone: 0.08)
        self.incorrectSoundData = Self.createToneWav(frequency: 280.0, duration: 0.14)
        self.tapSoundData = Self.createToneWav(frequency: 1000.0, duration: 0.025)

        configureAudioSession()
    }

    private func configureAudioSession() {
        #if os(iOS) || targetEnvironment(macCatalyst)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            // Audio session ambient configuration fallback
        }
        #endif
    }

    // MARK: - Public Triggers

    /// Plays positive feedback for a confirmed sign match or correct quiz response.
    func playSuccess() {
        guard AppSettings.shared.isSoundEnabled || AppSettings.shared.isHapticsEnabled else { return }

        if AppSettings.shared.isSoundEnabled {
            playSound(data: successSoundData, fallbackSystemSoundId: 1025)
        }

        #if canImport(UIKit)
        if AppSettings.shared.isHapticsEnabled {
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.success)
        }
        #endif
    }

    /// Plays alert feedback for an incorrect sign or wrong quiz answer.
    func playIncorrect() {
        guard AppSettings.shared.isSoundEnabled || AppSettings.shared.isHapticsEnabled else { return }

        if AppSettings.shared.isSoundEnabled {
            playSound(data: incorrectSoundData, fallbackSystemSoundId: 1053)
        }

        #if canImport(UIKit)
        if AppSettings.shared.isHapticsEnabled {
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.warning)
        }
        #endif
    }

    /// Plays subtle tap feedback for button presses.
    func playTap() {
        guard AppSettings.shared.isSoundEnabled || AppSettings.shared.isHapticsEnabled else { return }

        if AppSettings.shared.isSoundEnabled {
            playSound(data: tapSoundData, fallbackSystemSoundId: 1104)
        }

        #if canImport(UIKit)
        if AppSettings.shared.isHapticsEnabled {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
            generator.impactOccurred()
        }
        #endif
    }

    /// Test trigger specifically for verifying the Sound toggle.
    @discardableResult
    func triggerSoundTest() -> Bool {
        guard AppSettings.shared.isSoundEnabled else { return false }
        playSound(data: successSoundData, fallbackSystemSoundId: 1025)
        return true
    }

    /// Test trigger specifically for verifying the Haptic toggle.
    @discardableResult
    func triggerHapticTest() -> Bool {
        guard AppSettings.shared.isHapticsEnabled else { return false }
        #if canImport(UIKit)
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
        #endif
        return true
    }

    // MARK: - Internal Audio Playback

    private func playSound(data: Data, fallbackSystemSoundId: SystemSoundID) {
        configureAudioSession()

        do {
            audioPlayer?.stop()
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.volume = 1.0
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            // Secondary fallback using AudioServices
            AudioServicesPlaySystemSound(fallbackSystemSoundId)
        }
    }

    // MARK: - In-Memory Tone Synthesizer (WAV PCM)

    private static func createToneWav(frequency: Double, duration: Double, sampleRate: Double = 44100.0) -> Data {
        let numSamples = Int(duration * sampleRate)
        var pcmData = [Int16]()
        pcmData.reserveCapacity(numSamples)

        for i in 0..<numSamples {
            let t = Double(i) / sampleRate
            let envelope = sin(Double.pi * (Double(i) / Double(numSamples)))
            let sample = sin(2.0 * Double.pi * frequency * t) * envelope
            let pcmSample = Int16(max(-32768, min(32767, sample * 26000.0)))
            pcmData.append(pcmSample)
        }

        return makeWavData(samples: pcmData, sampleRate: sampleRate)
    }

    private static func createTwoToneWav(freq1: Double, freq2: Double, durationPerTone: Double, sampleRate: Double = 44100.0) -> Data {
        let samplesPerTone = Int(durationPerTone * sampleRate)
        var pcmData = [Int16]()
        pcmData.reserveCapacity(samplesPerTone * 2)

        for i in 0..<samplesPerTone {
            let t = Double(i) / sampleRate
            let envelope = sin(Double.pi * (Double(i) / Double(samplesPerTone)))
            let sample = sin(2.0 * Double.pi * freq1 * t) * envelope
            pcmData.append(Int16(max(-32768, min(32767, sample * 26000.0))))
        }

        for i in 0..<samplesPerTone {
            let t = Double(i) / sampleRate
            let envelope = sin(Double.pi * (Double(i) / Double(samplesPerTone)))
            let sample = sin(2.0 * Double.pi * freq2 * t) * envelope
            pcmData.append(Int16(max(-32768, min(32767, sample * 26000.0))))
        }

        return makeWavData(samples: pcmData, sampleRate: sampleRate)
    }

    private static func makeWavData(samples: [Int16], sampleRate: Double) -> Data {
        let byteRate = Int(sampleRate) * 2
        let blockAlign = 2
        let dataSize = samples.count * 2
        let chunkSize = 36 + dataSize

        var data = Data()
        data.append(contentsOf: "RIFF".utf8)
        data.append(contentsOf: withUnsafeBytes(of: UInt32(chunkSize).littleEndian) { Array($0) })
        data.append(contentsOf: "WAVE".utf8)
        data.append(contentsOf: "fmt ".utf8)
        data.append(contentsOf: withUnsafeBytes(of: UInt32(16).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Array($0) }) // PCM
        data.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Array($0) }) // Mono
        data.append(contentsOf: withUnsafeBytes(of: UInt32(sampleRate).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt32(byteRate).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt16(blockAlign).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt16(16).littleEndian) { Array($0) }) // 16-bit
        data.append(contentsOf: "data".utf8)
        data.append(contentsOf: withUnsafeBytes(of: UInt32(dataSize).littleEndian) { Array($0) })

        samples.withUnsafeBufferPointer { buffer in
            data.append(buffer)
        }

        return data
    }
}
