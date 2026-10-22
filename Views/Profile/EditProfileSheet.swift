import SwiftUI

public struct EditProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var socialService = BayanSocialService.shared

    @State private var name: String = ""
    @State private var handle: String = ""
    @State private var bio: String = ""
    @State private var selectedEmoji: String = "👑"
    @State private var isBroadcasting: Bool = true

    private let availableEmojis = ["👑", "🌙", "🕋", "📿", "🕊️", "🕌", "📖", "🦅", "🌸", "🌿"]
    private let spotifyGreen = Color(red: 0.18, green: 0.85, blue: 0.50)

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.08, green: 0.09, blue: 0.11).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Avatar Selection Row
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [BayanTheme.gold.opacity(0.3), Color(red: 0.08, green: 0.16, blue: 0.14)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 88, height: 88)
                                    .overlay(
                                        Circle().stroke(BayanTheme.gold, lineWidth: 2)
                                    )

                                Text(selectedEmoji)
                                    .font(.system(size: 42))
                            }
                            .shadow(color: BayanTheme.gold.opacity(0.25), radius: 10)

                            Text("Choose Avatar Badge")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))

                            // Emoji Picker Horizontal Row
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(availableEmojis, id: \.self) { emoji in
                                        Button {
                                            selectedEmoji = emoji
                                            #if os(iOS)
                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                            #endif
                                        } label: {
                                            Text(emoji)
                                                .font(.system(size: 24))
                                                .frame(width: 44, height: 44)
                                                .background(selectedEmoji == emoji ? spotifyGreen.opacity(0.25) : Color.white.opacity(0.06))
                                                .clipShape(Circle())
                                                .overlay(
                                                    Circle().stroke(selectedEmoji == emoji ? spotifyGreen : Color.clear, lineWidth: 2)
                                                )
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                        .padding(.top, 16)

                        // Form Fields
                        VStack(alignment: .leading, spacing: 18) {
                            // Display Name
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Display Name")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white.opacity(0.6))

                                TextField("Your Name", text: $name)
                                    .font(.system(size: 15))
                                    .padding(14)
                                    .background(Color.white.opacity(0.07))
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .foregroundColor(.white)
                            }

                            // Handle
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Username Handle")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white.opacity(0.6))

                                TextField("@handle", text: $handle)
                                    .font(.system(size: 15, design: .monospaced))
                                    .padding(14)
                                    .background(Color.white.opacity(0.07))
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .foregroundColor(spotifyGreen)
                                    .autocapitalization(.none)
                            }

                            // Bio / Favorite Ayah
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Bio & Favorite Ayah")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white.opacity(0.6))

                                TextField("Bio or reflection...", text: $bio, axis: .vertical)
                                    .lineLimit(3...5)
                                    .font(.system(size: 14))
                                    .padding(14)
                                    .background(Color.white.opacity(0.07))
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .foregroundColor(.white)
                            }

                            // Privacy Toggle
                            Toggle(isOn: $isBroadcasting) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Broadcast Listening Activity")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                    Text("Let followed companions see which Surah and reciter you're listening to live.")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.55))
                                }
                            }
                            .tint(spotifyGreen)
                            .padding(.top, 4)
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white.opacity(0.7))
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        socialService.updateProfile(
                            name: name,
                            handle: handle,
                            bio: bio,
                            avatarEmoji: selectedEmoji,
                            isBroadcasting: isBroadcasting
                        )
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        #endif
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(spotifyGreen)
                }
            }
            .onAppear {
                name = socialService.profile.name
                handle = socialService.profile.handle
                bio = socialService.profile.bio
                selectedEmoji = socialService.profile.avatarEmoji
                isBroadcasting = socialService.profile.isBroadcastingListening
            }
        }
    }
}
