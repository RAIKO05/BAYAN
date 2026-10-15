import SwiftUI

struct ReciterPickerSheet: View {
    @Binding var selectedReciter: Reciter
    @Environment(\.dismiss) private var dismiss
    @State private var searchQuery = ""
    @State private var selectedRiwayah: Reciter.Riwayah? = nil

    private var filteredReciters: [Reciter] {
        Reciter.standardCatalog.filter { reciter in
            let matchesQuery = searchQuery.isEmpty ||
                reciter.nameEnglish.localizedCaseInsensitiveContains(searchQuery) ||
                reciter.nameArabic.contains(searchQuery)
            let matchesRiwayah = selectedRiwayah == nil || reciter.riwayah == selectedRiwayah
            return matchesQuery && matchesRiwayah
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BayanTheme.obsidian.ignoresSafeArea()

                VStack(spacing: 16) {
                    // Riwayah Filter Pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            FilterPill(title: "All Riwayahs", isSelected: selectedRiwayah == nil) {
                                selectedRiwayah = nil
                            }
                            ForEach(Reciter.Riwayah.allCases, id: \.self) { riwayah in
                                FilterPill(title: riwayah.rawValue, isSelected: selectedRiwayah == riwayah) {
                                    selectedRiwayah = riwayah
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }

                    // Reciters List
                    List {
                        ForEach(filteredReciters) { reciter in
                            Button {
                                selectedReciter = reciter
                                QuranSyncManager.shared.lastQariId = reciter.id
                                dismiss()
                            } label: {
                                HStack(spacing: 14) {
                                    // Avatar Badge
                                    ZStack {
                                        Circle()
                                            .fill(reciter.id == selectedReciter.id ? BayanTheme.gold.opacity(0.2) : Color.white.opacity(0.06))
                                            .frame(width: 44, height: 44)
                                        Image(systemName: "person.wave.2.fill")
                                            .font(.subheadline)
                                            .foregroundColor(reciter.id == selectedReciter.id ? BayanTheme.gold : .white.opacity(0.7))
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(reciter.nameEnglish)
                                                .font(.headline)
                                                .foregroundColor(.white)
                                            Spacer()
                                            Text(reciter.nameArabic)
                                                .font(.subheadline)
                                                .foregroundColor(BayanTheme.goldSoft)
                                        }

                                        HStack(spacing: 8) {
                                            Text(reciter.style.rawValue)
                                                .font(.caption2.weight(.bold))
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 2)
                                                .background(Color.white.opacity(0.08))
                                                .clipShape(Capsule())

                                            Text("•")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)

                                            Text(reciter.riwayah.rawValue)
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }

                                    if reciter.id == selectedReciter.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(BayanTheme.gold)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Reciters (القُرّاء)")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchQuery, prompt: "Search by English or Arabic name")
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

private struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? BayanTheme.gold : Color.white.opacity(0.08))
                .foregroundColor(isSelected ? BayanTheme.obsidian : .white)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(isSelected ? Color.clear : Color.white.opacity(0.12), lineWidth: 1)
                )
        }
    }
}
