import SwiftUI

struct HisnAlMuslimView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: DhikrCategory = .morning
    @State private var currentIndex: Int = 0
    @State private var counts: [String: Int] = [:]
    @State private var showSearch: Bool = false
    @State private var searchQuery: String = ""

    private var currentItems: [DhikrItem] {
        if searchQuery.isEmpty {
            return HisnAlMuslimDataService.shared.adhkar(for: selectedCategory)
        } else {
            return HisnAlMuslimDataService.shared.allAdhkar.filter { item in
                item.arabicText.contains(searchQuery) ||
                item.translation.localizedCaseInsensitiveContains(searchQuery) ||
                item.transliteration.localizedCaseInsensitiveContains(searchQuery)
            }
        }
    }

    private var currentItem: DhikrItem? {
        guard !currentItems.isEmpty, currentIndex < currentItems.count else { return nil }
        return currentItems[currentIndex]
    }

    private func currentCount(for item: DhikrItem) -> Int {
        counts[item.id] ?? 0
    }

    private func increment(for item: DhikrItem) {
        let current = currentCount(for: item)
        if current < item.targetCount {
            counts[item.id] = current + 1
            #if os(iOS)
            if current + 1 == item.targetCount {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } else {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
            #endif
        } else {
            #if os(iOS)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
        }
    }

    private func resetCurrent() {
        if let item = currentItem {
            counts[item.id] = 0
            #if os(iOS)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
        }
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                BayanTheme.obsidian.ignoresSafeArea()

                VStack(spacing: 16) {
                    // Category Selector Pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(DhikrCategory.allCases) { category in
                                let isSelected = selectedCategory == category
                                Button {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        selectedCategory = category
                                        currentIndex = 0
                                    }
                                    #if os(iOS)
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    #endif
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: category.iconName)
                                            .font(.caption2)
                                        Text(category.titleArabic)
                                            .font(.caption.weight(.semibold))
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(isSelected ? BayanTheme.gold : Color.white.opacity(0.06))
                                    .foregroundColor(isSelected ? BayanTheme.obsidian : .white)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule().stroke(isSelected ? Color.clear : Color.white.opacity(0.1), lineWidth: 1)
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 4)
                    }

                    if let item = currentItem {
                        let count = currentCount(for: item)
                        let isCompleted = count >= item.targetCount
                        let progress = min(1.0, Double(count) / Double(max(1, item.targetCount)))

                        // Main Dhikr Card with Tap to Count
                        VStack(spacing: 16) {
                            // Header Index & Reference
                            HStack {
                                Text("\(currentIndex + 1) of \(currentItems.count)")
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(BayanTheme.gold)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(BayanTheme.gold.opacity(0.12))
                                    .clipShape(Capsule())

                                Spacer()

                                if isCompleted {
                                    Label("Completed • اكتمل", systemImage: "checkmark.circle.fill")
                                        .font(.caption.weight(.bold))
                                        .foregroundColor(BayanTheme.gold)
                                } else {
                                    Text("Tap card to count")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }

                            // Arabic Dhikr Text
                            ScrollView {
                                VStack(alignment: .trailing, spacing: 14) {
                                    Text(item.arabicText)
                                        .font(.custom("AmiriQuran-Regular", size: 22))
                                        .multilineTextAlignment(.trailing)
                                        .lineSpacing(10)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity, alignment: .trailing)

                                    Divider()
                                        .background(Color.white.opacity(0.1))

                                    // Transliteration & English
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(item.transliteration)
                                            .font(.caption)
                                            .italic()
                                            .foregroundColor(BayanTheme.goldSoft.opacity(0.9))

                                        Text(item.translation)
                                            .font(.subheadline)
                                            .foregroundColor(.white.opacity(0.85))

                                        HStack(alignment: .top, spacing: 6) {
                                            Image(systemName: "sparkles")
                                                .font(.caption2)
                                                .foregroundColor(BayanTheme.gold)
                                            Text(item.virtue)
                                                .font(.caption2)
                                                .foregroundColor(BayanTheme.goldSoft.opacity(0.8))
                                        }
                                        .padding(.top, 4)

                                        Text(item.reference)
                                            .font(.system(size: 10))
                                            .foregroundColor(.secondary)
                                            .padding(.top, 2)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(.horizontal, 4)
                            }
                            .frame(maxHeight: 280)

                            // Interactive Counter Dial
                            Button {
                                increment(for: item)
                            } label: {
                                ZStack {
                                    Circle()
                                        .stroke(Color.white.opacity(0.1), lineWidth: 8)
                                        .frame(width: 100, height: 100)

                                    Circle()
                                        .trim(from: 0, to: progress)
                                        .stroke(
                                            isCompleted ? BayanTheme.gold : BayanTheme.gold.opacity(0.85),
                                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                                        )
                                        .frame(width: 100, height: 100)
                                        .rotationEffect(.degrees(-90))
                                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: progress)

                                    VStack(spacing: 2) {
                                        if isCompleted {
                                            Image(systemName: "checkmark")
                                                .font(.title2.weight(.bold))
                                                .foregroundColor(BayanTheme.gold)
                                        } else {
                                            Text("\(count)")
                                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                                .foregroundColor(.white)
                                            Text("/ \(item.targetCount)")
                                                .font(.caption2.weight(.semibold))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color.white.opacity(0.04))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(isCompleted ? BayanTheme.gold.opacity(0.4) : Color.white.opacity(0.08), lineWidth: 1.5)
                        )
                        .padding(.horizontal)

                        // Bottom Navigation & Reset Bar
                        HStack(spacing: 20) {
                            Button {
                                if currentIndex > 0 {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        currentIndex -= 1
                                    }
                                }
                            } label: {
                                Image(systemName: "chevron.backward.circle.fill")
                                    .font(.title)
                                    .foregroundColor(currentIndex > 0 ? BayanTheme.gold : Color.white.opacity(0.2))
                            }
                            .disabled(currentIndex == 0)

                            Button {
                                resetCurrent()
                            } label: {
                                Label("Reset", systemImage: "arrow.counterclockwise")
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.white.opacity(0.08))
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
                            }

                            Button {
                                if currentIndex < currentItems.count - 1 {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        currentIndex += 1
                                    }
                                }
                            } label: {
                                Image(systemName: "chevron.forward.circle.fill")
                                    .font(.title)
                                    .foregroundColor(currentIndex < currentItems.count - 1 ? BayanTheme.gold : Color.white.opacity(0.2))
                            }
                            .disabled(currentIndex >= currentItems.count - 1)
                        }
                        .padding(.bottom, 12)
                    } else {
                        Spacer()
                        Text("No Adhkar in this category")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }
            .navigationTitle("Hisn al-Muslim (حصن المسلم)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(BayanTheme.gold)
                }
            }
        }
    }
}
