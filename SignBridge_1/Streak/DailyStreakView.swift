//
//  DailyStreakView.swift
//  SignBridge_1
//
//  Created by KIET2 on 24/10/26.
//

import SwiftUI

/// Compact, polished popup card displaying the learner's daily practice streak,
/// weekly calendar consistency, and personalized encouragement.
/// Designed to appear centered horizontally and vertically in the app window.
struct DailyStreakView: View {
    @Binding var isPresented: Bool
    @ObservedObject private var streakManager = DailyStreakManager.shared
    @ObservedObject private var settings = AppSettings.shared

    var body: some View {
        VStack(spacing: 18) {
            // Header with Close Button
            HStack {
                Text("🔥 Daily Streak")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)

                Spacer()

                Button {
                    FeedbackService.shared.playTap()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isPresented = false
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close Streak Popup")
            }

            // Streak Flame Hero
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Theme.amber.opacity(0.35), Color.clear],
                                center: .center,
                                startRadius: 15,
                                endRadius: 55
                            )
                        )
                        .frame(width: 90, height: 90)

                    Text("🔥")
                        .font(.system(size: settings.scaled(44)))
                }

                Text("\(streakManager.currentStreak) Day\(streakManager.currentStreak == 1 ? "" : "s")")
                    .font(.system(size: settings.scaled(32), weight: .heavy, design: .rounded))
                    .foregroundStyle(.primary)

                Text(streakManager.currentStreak == 0 ? "Daily Practice Streak" : "Consecutive Practice Streak")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }

            // Today's Status Badge
            HStack(spacing: 6) {
                Image(systemName: streakManager.hasPracticedToday ? "checkmark.circle.fill" : "clock.fill")
                    .font(.caption)
                    .foregroundStyle(streakManager.hasPracticedToday ? .green : .orange)

                Text(streakManager.hasPracticedToday ? "Practiced Today (+1 Day)" : "Practice Pending for Today")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(streakManager.hasPracticedToday ? .green : .orange)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background((streakManager.hasPracticedToday ? Theme.sage : Theme.amber).opacity(0.12))
            .clipShape(Capsule())

            // Streak Stats Row: Current vs Longest
            HStack(spacing: 10) {
                VStack(spacing: 3) {
                    Text("Current Streak")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("\(streakManager.currentStreak)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(Theme.terracotta)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Theme.fieldSurface)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(spacing: 3) {
                    Text("Longest Streak")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("\(streakManager.longestStreak)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(Theme.amber)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Theme.fieldSurface)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            // Weekly Practice Calendar (7 Days)
            VStack(alignment: .leading, spacing: 10) {
                Text("This Week's Consistency")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)

                HStack(spacing: 6) {
                    ForEach(streakManager.currentWeekDays) { day in
                        VStack(spacing: 4) {
                            Text(day.weekdaySymbol)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.secondary)

                            ZStack {
                                Circle()
                                    .fill(day.isPracticed ? Theme.amber : (day.isToday ? Theme.terracotta.opacity(0.15) : Theme.fieldSurface))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(day.isToday ? Theme.terracotta : Color.clear, lineWidth: 1.5)
                                    )

                                if day.isPracticed {
                                    Image(systemName: "flame.fill")
                                        .font(.caption2)
                                        .foregroundStyle(.white)
                                } else {
                                    Text(day.dayNumber)
                                        .font(.system(size: 11, weight: day.isToday ? .bold : .regular))
                                        .foregroundStyle(day.isToday ? Theme.terracotta : .secondary)
                                }
                            }

                            if day.isToday {
                                Text("Today")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(Theme.terracotta)
                            } else {
                                Text(" ")
                                    .font(.system(size: 8))
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(12)
            .background(Theme.fieldSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Encouraging Message Card
            HStack(spacing: 10) {
                Image(systemName: "lightbulb.fill")
                    .font(.subheadline)
                    .foregroundStyle(Theme.amber)

                Text(streakManager.encouragingMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineSpacing(2)
                    .multilineTextAlignment(.leading)

                Spacer()
            }
            .padding(10)
            .background(Theme.fieldSurface)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // Action Button
            Button {
                FeedbackService.shared.playTap()
                withAnimation(.easeInOut(duration: 0.2)) {
                    isPresented = false
                }
            } label: {
                Text("Done")
            }
            .buttonStyle(WarmPrimaryButtonStyle(backgroundColor: Theme.terracotta))
        }
        .padding(22)
        .frame(maxWidth: 440)
        .background(Theme.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                .strokeBorder(Theme.border, lineWidth: 1)
        )
        .shadow(color: Theme.terracotta.opacity(0.12), radius: 20, x: 0, y: 8)
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .onTapGesture { /* Consume taps inside card */ }
        .padding(.horizontal, 24)
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.4)
            .ignoresSafeArea()
        DailyStreakView(isPresented: .constant(true))
    }
}
