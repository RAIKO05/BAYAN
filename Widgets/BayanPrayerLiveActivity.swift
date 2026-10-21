import ActivityKit
import WidgetKit
import SwiftUI

public struct BayanPrayerLiveActivity: Widget {
    public init() {}

    public var body: some WidgetConfiguration {
        ActivityConfiguration(for: PrayerActivityAttributes.self) { context in
            // Lock Screen / Standby Banner
            LockScreenPrayerLiveActivityView(state: context.state)
                .activityBackgroundTint(Color.black.opacity(0.85))
                .activitySystemActionForegroundColor(Color(red: 0.85, green: 0.70, blue: 0.40))
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded Dynamic Island
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        Image(systemName: "moon.stars.fill")
                            .font(.title3)
                            .foregroundColor(Color(red: 0.85, green: 0.70, blue: 0.40))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(context.state.prayerNameEnglish)
                                .font(.caption.weight(.bold))
                                .foregroundColor(.white)
                            Text(context.state.cityName)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.leading, 8)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(context.state.prayerNameArabic)
                            .font(.caption.weight(.bold))
                            .foregroundColor(Color(red: 0.85, green: 0.70, blue: 0.40))
                        Text(context.state.prayerDate, style: .time)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.trailing, 8)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 6) {
                        HStack {
                            Text("Next Prayer in")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(context.state.prayerDate, style: .relative)
                                .font(.caption.weight(.bold))
                                .foregroundColor(Color(red: 0.85, green: 0.70, blue: 0.40))
                        }
                        // Progress bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.white.opacity(0.12))
                                    .frame(height: 5)
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color(red: 0.85, green: 0.70, blue: 0.40))
                                    .frame(width: geo.size.width * CGFloat(context.state.progress), height: 5)
                            }
                        }
                        .frame(height: 5)
                    }
                    .padding(.horizontal, 10)
                    .padding(.bottom, 6)
                }
            } compactLeading: {
                HStack(spacing: 4) {
                    Image(systemName: "moon.stars.fill")
                        .foregroundColor(Color(red: 0.85, green: 0.70, blue: 0.40))
                    Text(context.state.prayerNameEnglish.prefix(3).uppercased())
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.leading, 4)
            } compactTrailing: {
                Text(context.state.prayerDate, style: .relative)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(red: 0.85, green: 0.70, blue: 0.40))
                    .padding(.trailing, 4)
            } minimal: {
                Image(systemName: "moon.stars.fill")
                    .foregroundColor(Color(red: 0.85, green: 0.70, blue: 0.40))
            }
        }
    }
}

// MARK: - Lock Screen Banner Presentation
private struct LockScreenPrayerLiveActivityView: View {
    let state: PrayerActivityAttributes.ContentState

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color(red: 0.85, green: 0.70, blue: 0.40).opacity(0.18))
                    .frame(width: 46, height: 46)
                Image(systemName: "moon.stars.fill")
                    .font(.title3)
                    .foregroundColor(Color(red: 0.85, green: 0.70, blue: 0.40))
            }

            // Info
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(state.prayerNameEnglish)
                        .font(.headline.weight(.bold))
                        .foregroundColor(.white)
                    Text("•")
                        .foregroundColor(.secondary)
                    Text(state.prayerNameArabic)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color(red: 0.85, green: 0.70, blue: 0.40))
                }

                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.caption2)
                    Text(state.cityName)
                        .font(.caption2)
                    Text("• Qibla \(Int(state.qiblaDegrees))°")
                        .font(.caption2)
                }
                .foregroundColor(.secondary)
            }

            Spacer()

            // Countdown Timer Pill
            VStack(alignment: .trailing, spacing: 2) {
                Text(state.prayerDate, style: .time)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white.opacity(0.8))
                Text(state.prayerDate, style: .relative)
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(Color(red: 0.85, green: 0.70, blue: 0.40))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(red: 0.05, green: 0.07, blue: 0.09))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color(red: 0.85, green: 0.70, blue: 0.40).opacity(0.3), lineWidth: 1)
        )
    }
}
