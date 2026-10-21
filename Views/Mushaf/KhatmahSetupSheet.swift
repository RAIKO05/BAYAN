import SwiftUI

// MARK: - Khatmah Goal Setup Sheet
// Allows user to configure target completion days (e.g., 30 days for Ramadan, 60 days, etc.)
// and manually adjust current page.
public struct KhatmahSetupSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var khatmahService = KhatmahService.shared

    @State private var selectedDays: Int = 30
    @State private var selectedPage: Int = 1

    let presetGoals: [(title: String, days: Int, subtitle: String)] = [
        ("Ramadan / 30 Days", 30, "1 Juz' (~20 pages) per day"),
        ("Steady / 60 Days", 60, "~10 pages per day"),
        ("Gentle / 90 Days", 90, "~7 pages per day"),
        ("Intense / 15 Days", 15, "~40 pages per day")
    ]

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                BayanTheme.obsidian.ignoresSafeArea()
                RadialGradient(
                    colors: [BayanTheme.deepEmerald.opacity(0.4), Color.clear],
                    center: .top,
                    startRadius: 40,
                    endRadius: 400
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header Card
                        VStack(spacing: 8) {
                            Image(systemName: "book.closed.fill")
                                .font(.system(size: 36))
                                .foregroundColor(BayanTheme.gold)

                            Text("خطة ختم القرآن الكريم")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)

                            Text("Set your personal Quran Khatmah schedule and track your daily reading pace.")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.75))
                                .multilineTextAlignment(.center)
                        }
                        .padding(20)
                        .liquidGlass(cornerRadius: 20, isGoldBorder: true)

                        // Preset Goal Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("TARGET SCHEDULE")
                                .font(.system(size: 11, weight: .bold))
                                .tracking(1.2)
                                .foregroundColor(BayanTheme.goldSoft.opacity(0.9))

                            ForEach(presetGoals, id: \.days) { goal in
                                let isSelected = selectedDays == goal.days
                                Button {
                                    selectedDays = goal.days
                                    #if os(iOS)
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    #endif
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(goal.title)
                                                .font(.system(size: 15, weight: .bold))
                                                .foregroundColor(.white)
                                            Text(goal.subtitle)
                                                .font(.caption)
                                                .foregroundColor(BayanTheme.goldSoft)
                                        }

                                        Spacer()

                                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                            .font(.title3)
                                            .foregroundColor(isSelected ? BayanTheme.gold : .white.opacity(0.3))
                                    }
                                    .padding(14)
                                    .liquidGlass(cornerRadius: 16, isGoldBorder: isSelected)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        // Current Page Picker
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("CURRENT PAGE (1 - 604)")
                                    .font(.system(size: 11, weight: .bold))
                                    .tracking(1.2)
                                    .foregroundColor(BayanTheme.goldSoft.opacity(0.9))

                                Spacer()

                                Text("Page \(selectedPage)")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(BayanTheme.gold)
                            }

                            Stepper("Page \(selectedPage)", value: $selectedPage, in: 1...604)
                                .labelsHidden()
                                .padding(12)
                                .frame(maxWidth: .infinity)
                                .background(Color.white.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        // Save Button
                        Button {
                            khatmahService.targetDays = selectedDays
                            khatmahService.setPage(selectedPage)
                            #if os(iOS)
                            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                            #endif
                            dismiss()
                        } label: {
                            Text("Save Khatmah Goal • حفظ الخطة")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(BayanTheme.obsidian)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(BayanTheme.gold)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: BayanTheme.gold.opacity(0.4), radius: 8)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 8)
                    }
                    .padding(18)
                }
            }
            .navigationTitle("إعداد الختمة")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .onAppear {
                selectedDays = khatmahService.targetDays
                selectedPage = khatmahService.currentPage
            }
        }
    }
}
