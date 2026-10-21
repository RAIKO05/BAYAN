import SwiftUI

// MARK: - iCloud Sync & Backup Sheet
public struct CloudSyncSheet: View {
    @State private var cloudSync = BayanCloudSyncService.shared
    @State private var khatmahService = KhatmahService.shared
    @State private var bookmarkService = BookmarkService.shared
    @State private var themeManager = AppThemeManager.shared
    @Environment(\.dismiss) private var dismiss

    private var currentTheme: QuranTheme {
        themeManager.currentTheme
    }

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 1. Hero Cloud Status Card
                    heroStatusCard

                    // 2. Synced Records Summary Grid
                    syncedDataOverview

                    // 3. Sync Action Button
                    syncActionButton

                    // 4. Privacy & Encryption Note
                    privacyNoteCard
                }
                .padding(18)
            }
            .background(currentTheme.backgroundColor.ignoresSafeArea())
            .navigationTitle("iCloud Sync")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(currentTheme.prayerActiveAccent)
                }
            }
        }
    }

    // MARK: - Hero Cloud Status Card
    private var heroStatusCard: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(currentTheme.prayerActiveAccent.opacity(0.12))
                    .frame(width: 72, height: 72)

                Image(systemName: cloudSync.isSyncing ? "arrow.triangle.2.circlepath.icloud.fill" : "checkmark.icloud.fill")
                    .font(.system(size: 34))
                    .foregroundColor(currentTheme.prayerActiveAccent)
                    .rotationEffect(.degrees(cloudSync.isSyncing ? 360 : 0))
                    .animation(cloudSync.isSyncing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: cloudSync.isSyncing)
            }

            VStack(spacing: 4) {
                Text(cloudSync.syncStatusMessage)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(currentTheme.prayerTextColor)

                if let lastDate = cloudSync.lastSyncDate {
                    Text("Last synced: \(formattedDate(lastDate))")
                        .font(.system(size: 12))
                        .foregroundColor(currentTheme.prayerSecondaryTextColor)
                } else {
                    Text("Syncs automatically across your iPhone, iPad, and Mac")
                        .font(.system(size: 12))
                        .foregroundColor(currentTheme.prayerSecondaryTextColor)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(currentTheme.prayerCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(currentTheme.prayerCardBorder, lineWidth: 1)
        )
    }

    // MARK: - Synced Data Overview
    private var syncedDataOverview: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SYNCED CLOUD DATA")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.2)
                .foregroundColor(currentTheme.prayerActiveAccent)

            VStack(spacing: 8) {
                syncRow(
                    icon: "book.pages.fill",
                    title: "Khatmah Reading Progress",
                    subtitle: "Page \(khatmahService.currentPage) of 604 • Juz' \(khatmahService.currentJuz)",
                    badge: "\(khatmahService.progressPercentString)"
                )

                syncRow(
                    icon: "bookmark.fill",
                    title: "Ayah Bookmarks",
                    subtitle: "\(bookmarkService.bookmarks.count) saved verses in personal library",
                    badge: "\(bookmarkService.bookmarks.count)"
                )

                syncRow(
                    icon: "clock.badge.checkmark.fill",
                    title: "Daily Prayer Tracking",
                    subtitle: "Today's prayers and habit history",
                    badge: "Active"
                )

                syncRow(
                    icon: "paintpalette.fill",
                    title: "Theme & Preferences",
                    subtitle: "\(currentTheme.title) • Calculation conventions",
                    badge: "Synced"
                )
            }
        }
    }

    private func syncRow(icon: String, title: String, subtitle: String, badge: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(currentTheme.prayerActiveAccent)
                .frame(width: 34, height: 34)
                .background(currentTheme.prayerActiveAccent.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(currentTheme.prayerTextColor)
                Text(subtitle)
                    .font(.system(size: 11.5))
                    .foregroundColor(currentTheme.prayerSecondaryTextColor)
            }

            Spacer()

            Text(badge)
                .font(.system(size: 11, weight: .bold))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(currentTheme.prayerCardBorder.opacity(0.4))
                .foregroundColor(currentTheme.prayerActiveAccent)
                .clipShape(Capsule())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(currentTheme.prayerCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(currentTheme.prayerCardBorder, lineWidth: 1)
        )
    }

    // MARK: - Action Button
    private var syncActionButton: some View {
        Button {
            cloudSync.synchronizeNow()
            #if os(iOS)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            #endif
        } label: {
            HStack(spacing: 8) {
                if cloudSync.isSyncing {
                    ProgressView()
                        .tint(currentTheme.isDark ? BayanTheme.obsidian : .white)
                } else {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 14, weight: .bold))
                }
                Text(cloudSync.isSyncing ? "Syncing with iCloud..." : "Sync Now")
                    .font(.system(size: 15, weight: .bold))
            }
            .foregroundColor(currentTheme.isDark ? BayanTheme.obsidian : .white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(currentTheme.prayerActiveAccent)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(cloudSync.isSyncing)
    }

    // MARK: - Privacy Note
    private var privacyNoteCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 20))
                .foregroundColor(currentTheme.prayerActiveAccent)

            VStack(alignment: .leading, spacing: 2) {
                Text("Private & Encrypted")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(currentTheme.prayerTextColor)
                Text("All your Quran reading progress and prayer habits are securely stored in your personal Apple iCloud account with end-to-end encryption.")
                    .font(.system(size: 10.5))
                    .foregroundColor(currentTheme.prayerSecondaryTextColor)
                    .lineSpacing(2)
            }
        }
        .padding(14)
        .background(currentTheme.prayerCardBackground.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "'Today at' h:mm a"
        } else {
            formatter.dateFormat = "d MMM 'at' h:mm a"
        }
        return formatter.string(from: date)
    }
}
