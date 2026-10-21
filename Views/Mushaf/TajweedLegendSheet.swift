import SwiftUI

struct TajweedLegendSheet: View {
    @Environment(\.dismiss) private var dismiss

    public var body: some View {
        NavigationStack {
            ZStack {
                BayanTheme.obsidian.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Header Banner
                        VStack(spacing: 8) {
                            Image(systemName: "paintpalette.fill")
                                .font(.system(size: 36))
                                .foregroundColor(BayanTheme.gold)
                            Text("Tajweed Color Guide")
                                .font(.title2.weight(.bold))
                                .foregroundColor(.white)
                            Text("دليل أحكام التجويد الملونة")
                                .font(.headline)
                                .foregroundColor(BayanTheme.goldSoft)
                            Text("Visual color rules to perfect your pronunciation and recitation according to the authentic rules of Tajweed.")
                                .font(.caption)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.horizontal)
                        }
                        .padding(.top, 12)

                        // Rule Cards
                        VStack(spacing: 12) {
                            ForEach(TajweedRule.allRules) { rule in
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Circle()
                                            .fill(rule.color)
                                            .frame(width: 14, height: 14)
                                        Text(rule.nameEnglish)
                                            .font(.subheadline.weight(.bold))
                                            .foregroundColor(.white)
                                        Spacer()
                                        Text(rule.nameArabic)
                                            .font(.callout.weight(.semibold))
                                            .foregroundColor(rule.color)
                                    }

                                    Text(rule.descriptionEnglish)
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))

                                    Text(rule.descriptionArabic)
                                        .font(.caption2)
                                        .foregroundColor(BayanTheme.goldSoft.opacity(0.8))
                                        .multilineTextAlignment(.trailing)
                                        .frame(maxWidth: .infinity, alignment: .trailing)

                                    // Example Box
                                    HStack {
                                        Text("Example • مثال:")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text(rule.exampleArabic)
                                            .font(.custom("AmiriQuran-Regular", size: 16))
                                            .foregroundColor(rule.color)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.white.opacity(0.04))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.04))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(rule.color.opacity(0.3), lineWidth: 1)
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Tajweed Rules (التجويد)")
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
