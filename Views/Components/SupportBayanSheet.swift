import SwiftUI

public struct SupportBayanSheet: View {
    @State private var tipService = TipJarService.shared
    @State private var themeManager = AppThemeManager.shared
    @Environment(\.dismiss) private var dismiss

    private var currentTheme: QuranTheme {
        themeManager.currentTheme
    }

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                currentTheme.backgroundColor.ignoresSafeArea()
                currentTheme.backgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 22) {
                        // 1. Hero Golden Header
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(BayanTheme.gold.opacity(0.18))
                                    .frame(width: 80, height: 80)
                                    .blur(radius: 8)

                                Image(systemName: "heart.circle.fill")
                                    .font(.system(size: 54))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [BayanTheme.goldSoft, BayanTheme.gold],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            }
                            .padding(.top, 10)

                            Text("Support Bayan")
                                .font(.title2.weight(.bold))
                                .foregroundColor(.white)

                            Text("Sadaqah Jariyah & Hadya • صدقة جارية")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(BayanTheme.goldSoft)

                            Text("Bayan is 100% free and completely ad-free. Your voluntary contribution directly funds high-bandwidth audio streaming servers, authentic Quranic datasets, and continuous development.")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                                .padding(.horizontal, 16)
                                .padding(.top, 4)
                        }

                        // 2. Honored Supporter Badge (if already contributed)
                        if tipService.isSupporter {
                            HStack(spacing: 12) {
                                Image(systemName: "seal.fill")
                                    .foregroundColor(BayanTheme.gold)
                                    .font(.title3)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("HONORED SUPPORTER OF BAYAN")
                                        .font(.caption2.weight(.black))
                                        .tracking(1)
                                        .foregroundColor(BayanTheme.gold)

                                    Text("جَزَاكُمُ اللَّهُ خَيْرًا • May Allah reward you with continuous blessings")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                }
                                Spacer()
                            }
                            .padding(16)
                            .background(BayanTheme.gold.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .overlay(RoundedRectangle(cornerRadius: 18).stroke(BayanTheme.gold.opacity(0.4), lineWidth: 1))
                            .padding(.horizontal, 4)
                        }

                        // 3. Hadith Quote Card
                        VStack(spacing: 6) {
                            Text("« إِذَا مَاتَ الإِنْسَانُ انْقَطَعَ عَنْهُ عَمَلُهُ إِلا مِنْ ثَلاثَةٍ: إِلا مِنْ صَدَقَةٍ جَارِيَةٍ، أَوْ عِلْمٍ يُنْتَفَعُ بِهِ، أَوْ وَلَدٍ صَالِحٍ يَدْعُو لَهُ »")
                                .font(.system(size: 14, weight: .medium, design: .serif))
                                .multilineTextAlignment(.center)
                                .foregroundColor(BayanTheme.goldSoft)
                                .padding(.horizontal, 10)

                            Text("— Prophet Muhammad ﷺ (Sahih Muslim)")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(16)
                        .liquidGlass(cornerRadius: 18)

                        // 4. Contribution Tiers Grid
                        VStack(spacing: 12) {
                            ForEach(tipService.defaultCatalog) { product in
                                Button {
                                    Task {
                                        _ = await tipService.purchase(product: product)
                                    }
                                } label: {
                                    HStack(spacing: 16) {
                                        Text(product.iconEmoji)
                                            .font(.system(size: 32))

                                        VStack(alignment: .leading, spacing: 3) {
                                            HStack(spacing: 6) {
                                                Text(product.title)
                                                    .font(.headline.weight(.bold))
                                                    .foregroundColor(.white)

                                                if product.isPopular {
                                                    Text("POPULAR")
                                                        .font(.system(size: 8, weight: .black))
                                                        .padding(.horizontal, 6)
                                                        .padding(.vertical, 2)
                                                        .background(BayanTheme.gold)
                                                        .foregroundColor(BayanTheme.obsidian)
                                                        .clipShape(Capsule())
                                                }
                                            }

                                            Text(product.subtitle)
                                                .font(.caption2)
                                                .foregroundColor(.white.opacity(0.65))
                                        }

                                        Spacer()

                                        Text(product.priceString)
                                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                                            .foregroundColor(BayanTheme.obsidian)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(BayanTheme.gold)
                                            .clipShape(Capsule())
                                    }
                                    .padding(16)
                                    .liquidGlass(cornerRadius: 20, isGoldBorder: product.isPopular)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        // 5. Restore Purchases & Ad-Free Guarantee
                        VStack(spacing: 12) {
                            Button {
                                Task {
                                    await tipService.restorePurchases()
                                }
                            } label: {
                                Text("Restore Purchases")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(BayanTheme.goldSoft.opacity(0.8))
                            }

                            Text("🔒 100% Free & Private Guarantee: All Quran recitations, prayer times, and Qibla features remain completely unrestricted regardless of contribution.")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.5))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                        .padding(.top, 10)
                        .padding(.bottom, 20)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Support Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(BayanTheme.gold)
                    .font(.body.weight(.semibold))
                }
            }
        }
    }
}
