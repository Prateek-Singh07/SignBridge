//
//  AlphabetExplorerView.swift
//  SignBridge_1
//
//  Created by KIET2 on 24/10/26.
//

import SwiftUI
import UIKit

/// Filter options for filtering letters by mastery progress in Alphabet Explorer.
enum AlphabetExplorerMasteryFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case mastered = "Mastered"
    case learning = "Learning"
    case new = "New"

    var id: String { rawValue }
}

/// Compact centered modal popup providing a clean, comprehensive A–Z Alphabet Explorer grid in Practice Mode.
/// Displays all 26 letters with existing ASL reference images and live mastery status,
/// highlights the currently practiced letter, and allows immediate navigation to any letter on tap.
struct AlphabetExplorerPopupView: View {
    @Binding var isPresented: Bool
    var currentLetter: ASLLetter? = nil
    var onSelectLetter: (ASLLetter) -> Void

    @ObservedObject private var masteryManager = LetterMasteryManager.shared
    @State private var searchText: String = ""
    @State private var selectedFilter: AlphabetExplorerMasteryFilter = .all

    private var filteredLetters: [ASLLetter] {
        ASLLetter.allCases.filter { letter in
            // Search text filter
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let matchesSearch = query.isEmpty || letter.name.localizedCaseInsensitiveContains(query)

            // Mastery status filter
            let status = masteryManager.status(for: letter)
            let matchesMastery: Bool
            switch selectedFilter {
            case .all:
                matchesMastery = true
            case .mastered:
                matchesMastery = (status == .mastered)
            case .learning:
                matchesMastery = (status == .learning)
            case .new:
                matchesMastery = (status == .new)
            }

            return matchesSearch && matchesMastery
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            headerBar

            Divider()
                .background(Theme.border)

            // Searchable Grid View
            gridView
        }
        .frame(maxWidth: 520)
        .frame(maxHeight: 620)
        .background(Theme.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                .strokeBorder(Theme.border, lineWidth: 1)
        )
        .shadow(color: Theme.terracotta.opacity(0.12), radius: 20, x: 0, y: 8)
        .contentShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
        .onTapGesture { /* Consume taps inside popup */ }
        .padding(.horizontal, 20)
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack(alignment: .center) {
            HStack(spacing: 8) {
                Image(systemName: "square.grid.3x3.fill")
                    .font(.headline)
                    .foregroundStyle(Theme.terracotta)

                Text("Alphabet Explorer")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(Theme.primaryText)

                Text("\(filteredLetters.count) of 26")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Theme.terracotta.opacity(0.12))
                    .foregroundStyle(Theme.terracotta)
                    .clipShape(Capsule())
            }

            Spacer()

            Button {
                FeedbackService.shared.playTap()
                withAnimation(.easeInOut(duration: 0.2)) {
                    isPresented = false
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Theme.secondaryText.opacity(0.8))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close Alphabet Explorer")
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 12)
    }

    // MARK: - Searchable Grid View

    private var gridView: some View {
        VStack(spacing: 12) {
            // Search Bar & Filter Chips
            VStack(spacing: 10) {
                // Search Input Field
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.secondaryText)

                    TextField("Search letters (e.g. A, B, C)...", text: $searchText)
                        .font(.system(size: 14, design: .rounded))
                        .foregroundStyle(Theme.primaryText)
                        .autocorrectionDisabled()

                    if !searchText.isEmpty {
                        Button {
                            FeedbackService.shared.playTap()
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(Theme.secondaryText)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Clear search")
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(Theme.fieldSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Theme.border, lineWidth: 1)
                )

                // Mastery Status Filter Chips
                HStack(spacing: 6) {
                    filterChip(title: "All", count: ASLLetter.allCases.count, filter: .all, color: Theme.terracotta)
                    filterChip(title: "Mastered", count: masteryManager.masteredCount, filter: .mastered, color: Theme.masteryMastered)
                    filterChip(title: "Learning", count: masteryManager.learningCount, filter: .learning, color: Theme.masteryLearning)
                    filterChip(title: "New", count: masteryManager.newCount, filter: .new, color: Theme.masteryNew)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            // Grid Content / Empty State
            if filteredLetters.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "text.magnifyingglass")
                        .font(.system(size: 38))
                        .foregroundStyle(Theme.secondaryText.opacity(0.6))

                    Text("No matching letters found")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.primaryText)

                    Text("No letters match your search query or filter selection.")
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)

                    Button {
                        FeedbackService.shared.playTap()
                        searchText = ""
                        selectedFilter = .all
                    } label: {
                        Text("Reset Search")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.terracotta)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(Theme.fieldSurface)
                            .clipShape(Capsule())
                            .overlay(Capsule().strokeBorder(Theme.border, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.bottom, 20)
            } else {
                ScrollView {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 95, maximum: 130), spacing: 10)],
                        spacing: 10
                    ) {
                        ForEach(filteredLetters) { letter in
                            letterGridCard(for: letter)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
            }
        }
    }

    private func filterChip(
        title: String,
        count: Int,
        filter: AlphabetExplorerMasteryFilter,
        color: Color
    ) -> some View {
        let isSelected = selectedFilter == filter
        return Button {
            FeedbackService.shared.playTap()
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedFilter = filter
            }
        } label: {
            HStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 11, weight: isSelected ? .bold : .medium, design: .rounded))

                Text("\(count)")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(isSelected ? Color.white.opacity(0.3) : color.opacity(0.15))
                    .clipShape(Capsule())
            }
            .foregroundStyle(isSelected ? Color.white : Theme.primaryText)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(isSelected ? color : Theme.fieldSurface)
            .clipShape(Capsule())
            .overlay(
                Capsule().strokeBorder(isSelected ? Color.clear : Theme.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Letter Grid Card

    private func letterGridCard(for letter: ASLLetter) -> some View {
        let status = masteryManager.status(for: letter)
        let isCurrent = (letter == currentLetter)
        let imageName = letter.referenceImageName

        return Button {
            FeedbackService.shared.playTap()
            onSelectLetter(letter)
            withAnimation(.easeInOut(duration: 0.2)) {
                isPresented = false
            }
        } label: {
            VStack(spacing: 6) {
                // Top row: Letter badge, Practising chip (if current), and mastery icon
                HStack(spacing: 4) {
                    Text(letter.name)
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(isCurrent ? Theme.terracotta : status.badgeColor)
                        .clipShape(Circle())

                    if isCurrent {
                        Text("Current")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.terracotta)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Theme.peach.opacity(0.4))
                            .clipShape(Capsule())
                    }

                    Spacer()

                    Image(systemName: status.iconName)
                        .font(.system(size: 11))
                        .foregroundStyle(status.badgeColor)
                }

                // Center: ASL Reference Image or Empty State
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(isCurrent ? Theme.terracotta.opacity(0.4) : Theme.border.opacity(0.7), lineWidth: 1)
                        )

                    if UIImage(named: imageName) != nil {
                        Image(imageName)
                            .resizable()
                            .scaledToFit()
                            .padding(4)
                            .frame(height: 64)
                    } else {
                        VStack(spacing: 2) {
                            Image(systemName: "photo")
                                .font(.system(size: 16))
                                .foregroundStyle(Theme.secondaryText.opacity(0.6))
                            Text("No image")
                                .font(.system(size: 8))
                                .foregroundStyle(Theme.secondaryText)
                        }
                        .frame(height: 64)
                    }
                }
                .frame(height: 64)

                // Bottom row: Mastery label
                Text(status.rawValue)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(status.badgeColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .frame(maxWidth: .infinity)
                    .background(status.badgeColor.opacity(0.12))
                    .clipShape(Capsule())
            }
            .padding(8)
            .background(isCurrent ? Theme.peach.opacity(0.25) : Theme.fieldSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(isCurrent ? Theme.terracotta : Theme.border, lineWidth: isCurrent ? 2.5 : 1)
            )
            .shadow(color: isCurrent ? Theme.terracotta.opacity(0.25) : Color.clear, radius: 8, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            isCurrent
                ? "Letter \(letter.name), Currently Practising, Mastery: \(status.rawValue). Tap to select."
                : "Letter \(letter.name), Mastery: \(status.rawValue). Tap to practise."
        )
    }
}
