import SwiftUI
import AVFoundation

struct ReciterPickerSheet: View {
    @Binding var selectedReciter: Reciter
    @Environment(\.dismiss) private var dismiss

    @State private var searchQuery = ""
    @State private var selectedFilter: ReciterFilter = .all
    @AppStorage("bayan_reciter_is_grid_view") private var isGridView: Bool = true
    @AppStorage("bayan_favorite_reciters") private var favoriteReciterIdsRaw: String = "omardiaa,alafasy,sudais,dosari"

    // Preview Audio Player
    @State private var previewPlayer: AVPlayer?
    @State private var previewingReciterId: String?
    @State private var isPreviewLoading: Bool = false

    private enum ReciterFilter: String, CaseIterable, Identifiable {
        case all = "All • الكل"
        case hafs = "Hafs • حفص"
        case warsh = "Warsh • ورش"
        case mujawwad = "Mujawwad • مجوّد"
        case teacher = "Teacher • المعلّم"
        case favorites = "Favorites • المفضلة"

        var id: String { rawValue }
    }

    private var favoriteIds: Set<String> {
        Set(favoriteReciterIdsRaw.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) })
    }

    private func isFavorite(_ reciterId: String) -> Bool {
        favoriteIds.contains(reciterId)
    }

    private func toggleFavorite(_ reciterId: String) {
        var current = favoriteIds
        if current.contains(reciterId) {
            current.remove(reciterId)
        } else {
            current.insert(reciterId)
        }
        favoriteReciterIdsRaw = current.joined(separator: ",")
    }

    private var filteredReciters: [Reciter] {
        let list = Reciter.standardCatalog.filter { reciter in
            let matchesQuery: Bool = {
                if searchQuery.trimmingCharacters(in: .whitespaces).isEmpty { return true }
                return reciter.nameEnglish.localizedCaseInsensitiveContains(searchQuery) ||
                       reciter.nameArabic.contains(searchQuery) ||
                       reciter.riwayah.rawValue.localizedCaseInsensitiveContains(searchQuery) ||
                       reciter.style.rawValue.localizedCaseInsensitiveContains(searchQuery)
            }()

            let matchesFilter: Bool = {
                switch selectedFilter {
                case .all:
                    return true
                case .hafs:
                    return reciter.riwayah == .hafs
                case .warsh:
                    return reciter.riwayah == .warsh
                case .mujawwad:
                    return reciter.style == .mujawwad
                case .teacher:
                    return reciter.style == .muallim
                case .favorites:
                    return isFavorite(reciter.id)
                }
            }()

            return matchesQuery && matchesFilter
        }

        // Sort: Favorites first when in .all mode, else standard catalog order
        if selectedFilter == .all && searchQuery.isEmpty {
            return list.sorted { first, second in
                let f1 = isFavorite(first.id)
                let f2 = isFavorite(second.id)
                if f1 && !f2 { return true }
                if !f1 && f2 { return false }
                return false
            }
        }

        return list
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BayanTheme.obsidian.ignoresSafeArea()

                VStack(spacing: 10) {
                    filterHeaderSection

                    if filteredReciters.isEmpty {
                        emptyStateView
                    } else if isGridView {
                        gridScrollView
                    } else {
                        listScrollView
                    }
                }
            }
            .navigationTitle("Reciters (القُرّاء)")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchQuery, prompt: "Search by English or Arabic name")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            isGridView.toggle()
                        }
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        #endif
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: isGridView ? "list.bullet" : "square.grid.3x3.fill")
                                .font(.system(size: 14, weight: .bold))
                            Text(isGridView ? "List" : "Grid")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(BayanTheme.gold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Capsule())
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        stopPreview()
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(BayanTheme.gold)
                }
            }
            .onDisappear {
                stopPreview()
            }
        }
    }

    // MARK: - Filter Header
    private var filterHeaderSection: some View {
        VStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ReciterFilter.allCases) { filter in
                        FilterPill(
                            title: filter.rawValue,
                            isSelected: selectedFilter == filter
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedFilter = filter
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 6)
            }

            HStack {
                Text("\(filteredReciters.count) Reciters • 30+ Famous Qura'a")
                    .font(.caption2.weight(.medium))
                    .foregroundColor(BayanTheme.goldSoft.opacity(0.85))

                Spacer()

                if !favoriteIds.isEmpty {
                    Label("\(favoriteIds.count) Pinned", systemImage: "star.fill")
                        .font(.caption2.weight(.medium))
                        .foregroundColor(BayanTheme.gold)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 2)
        }
    }

    // MARK: - Grid View (Screenshot 3 & 5 Aesthetic)
    private var gridScrollView: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 14),
                    GridItem(.flexible(), spacing: 14),
                    GridItem(.flexible(), spacing: 14)
                ],
                spacing: 20
            ) {
                ForEach(filteredReciters) { reciter in
                    ReciterGridCell(
                        reciter: reciter,
                        isSelected: reciter.id == selectedReciter.id,
                        isFavorite: isFavorite(reciter.id),
                        isPreviewing: previewingReciterId == reciter.id,
                        isPreviewLoading: isPreviewLoading && previewingReciterId == reciter.id,
                        onSelect: {
                            stopPreview()
                            selectedReciter = reciter
                            QuranSyncManager.shared.lastQariId = reciter.id
                            dismiss()
                        },
                        onTogglePreview: {
                            togglePreview(for: reciter)
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }

    // MARK: - List View
    private var listScrollView: some View {
        List {
            ForEach(filteredReciters) { reciter in
                ReciterRow(
                    reciter: reciter,
                    isSelected: reciter.id == selectedReciter.id,
                    isFavorite: isFavorite(reciter.id),
                    isPreviewing: previewingReciterId == reciter.id,
                    isPreviewLoading: isPreviewLoading && previewingReciterId == reciter.id,
                    onSelect: {
                        stopPreview()
                        selectedReciter = reciter
                        QuranSyncManager.shared.lastQariId = reciter.id
                        dismiss()
                    },
                    onToggleFavorite: {
                        toggleFavorite(reciter.id)
                    },
                    onTogglePreview: {
                        togglePreview(for: reciter)
                    }
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "person.slash")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("No reciters match your search")
                .font(.headline)
                .foregroundColor(.white)
            Text("Try searching by another name or clearing the filter")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding()
    }

    // MARK: - Audio Preview Player
    private func togglePreview(for reciter: Reciter) {
        if previewingReciterId == reciter.id {
            stopPreview()
            return
        }

        stopPreview()

        guard let sampleUrl = reciter.sampleAudioUrl else { return }

        previewingReciterId = reciter.id
        isPreviewLoading = true

        let playerItem = AVPlayerItem(url: sampleUrl)
        let player = AVPlayer(playerItem: playerItem)
        self.previewPlayer = player

        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { _ in
            self.stopPreview()
        }

        player.play()
        isPreviewLoading = false
    }

    private func stopPreview() {
        previewPlayer?.pause()
        previewPlayer = nil
        previewingReciterId = nil
        isPreviewLoading = false
    }
}

// MARK: - Reciter Grid Cell (Screenshots 3 & 5)
private struct ReciterGridCell: View {
    let reciter: Reciter
    let isSelected: Bool
    let isFavorite: Bool
    let isPreviewing: Bool
    let isPreviewLoading: Bool
    let onSelect: () -> Void
    let onTogglePreview: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            // Circular Portrait Avatar with Badges
            ZStack(alignment: .bottomTrailing) {
                ZStack(alignment: .topTrailing) {
                    ReciterAvatarView(
                        reciter: reciter,
                        size: 72,
                        isSelected: isSelected,
                        borderWidth: isSelected ? 2.5 : 1.5,
                        showWaveform: isPreviewing,
                        hasGlow: isSelected
                    )

                    // Audio Preview Play Button Mini-Pill
                    Button {
                        onTogglePreview()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.70))
                                .frame(width: 24, height: 24)
                                .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 0.8))

                            if isPreviewLoading {
                                ProgressView()
                                    .scaleEffect(0.5)
                                    .tint(BayanTheme.gold)
                            } else {
                                Image(systemName: isPreviewing ? "stop.fill" : "play.fill")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(isPreviewing ? BayanTheme.gold : .white)
                            }
                        }
                    }
                    .offset(x: 4, y: -4)
                }

                // Selected Checkmark Badge
                if isSelected {
                    ZStack {
                        Circle()
                            .fill(BayanTheme.gold)
                            .frame(width: 22, height: 22)
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .black))
                            .foregroundColor(.black)
                    }
                    .offset(x: 4, y: 4)
                }
            }
            .contentShape(Circle())
            .onTapGesture {
                onSelect()
            }

            // Names & Metadata
            VStack(spacing: 2) {
                Text(reciter.nameEnglish)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(isSelected ? BayanTheme.gold : .white)
                    .lineLimit(1)
                    .multilineTextAlignment(.center)

                Text(reciter.nameArabic)
                    .font(.system(size: 11))
                    .foregroundColor(BayanTheme.goldSoft.opacity(0.90))
                    .lineLimit(1)
                    .multilineTextAlignment(.center)

                if reciter.riwayah != .hafs {
                    Text(reciter.riwayah.rawValue.components(separatedBy: " ").first ?? "")
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1.5)
                        .background(BayanTheme.gold.opacity(0.18))
                        .foregroundColor(BayanTheme.gold)
                        .clipShape(Capsule())
                        .padding(.top, 1)
                }
            }
            .onTapGesture {
                onSelect()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

// MARK: - Reciter Row View (Screenshot 2 & 4)
private struct ReciterRow: View {
    let reciter: Reciter
    let isSelected: Bool
    let isFavorite: Bool
    let isPreviewing: Bool
    let isPreviewLoading: Bool
    let onSelect: () -> Void
    let onToggleFavorite: () -> Void
    let onTogglePreview: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Portrait Avatar
                ReciterAvatarView(
                    reciter: reciter,
                    size: 48,
                    isSelected: isSelected,
                    borderWidth: isSelected ? 2.0 : 1.0,
                    showWaveform: isPreviewing,
                    hasGlow: isSelected
                )

                // Reciter Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(reciter.nameEnglish)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        Spacer()
                        Text(reciter.nameArabic)
                            .font(.callout.weight(.medium))
                            .foregroundColor(BayanTheme.goldSoft)
                            .lineLimit(1)
                    }

                    HStack(spacing: 6) {
                        // Style Chip
                        Text(reciter.style.rawValue)
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(reciter.style == .mujawwad ? BayanTheme.gold.opacity(0.18) : Color.white.opacity(0.08))
                            .foregroundColor(reciter.style == .mujawwad ? BayanTheme.gold : .white.opacity(0.8))
                            .clipShape(Capsule())

                        Text("•")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        // Riwayah Text
                        Text(reciter.riwayah.rawValue)
                            .font(.caption2)
                            .foregroundColor(reciter.riwayah == .warsh ? BayanTheme.goldSoft : .secondary)

                        Spacer()
                    }
                }

                // Preview Button
                Button {
                    onTogglePreview()
                } label: {
                    ZStack {
                        Circle()
                            .fill(isPreviewing ? BayanTheme.gold.opacity(0.2) : Color.white.opacity(0.08))
                            .frame(width: 32, height: 32)

                        if isPreviewLoading {
                            ProgressView()
                                .scaleEffect(0.6)
                                .tint(BayanTheme.gold)
                        } else {
                            Image(systemName: isPreviewing ? "stop.fill" : "play.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(isPreviewing ? BayanTheme.gold : .white.opacity(0.8))
                        }
                    }
                }
                .buttonStyle(.borderless)

                // Favorite Star Button
                Button {
                    onToggleFavorite()
                } label: {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .font(.system(size: 15))
                        .foregroundColor(isFavorite ? BayanTheme.gold : .white.opacity(0.25))
                        .frame(width: 28, height: 32)
                }
                .buttonStyle(.borderless)

                // Selection Checkmark
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(BayanTheme.gold)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? BayanTheme.gold.opacity(0.08) : Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? BayanTheme.gold.opacity(0.4) : Color.white.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Filter Pill
private struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(isSelected ? BayanTheme.gold : Color.white.opacity(0.08))
                .foregroundColor(isSelected ? BayanTheme.obsidian : .white)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(isSelected ? Color.clear : Color.white.opacity(0.12), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
