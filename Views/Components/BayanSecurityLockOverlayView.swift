import SwiftUI

// MARK: - Bayan Security Privacy Shield & Biometric Lock Overlay
public struct BayanSecurityLockOverlayView: View {
    @State private var securityManager = BayanSecurityManager.shared

    public init() {}

    public var body: some View {
        ZStack {
            // Sacred Deep Obsidian Glass Canvas
            Color(red: 0.05, green: 0.06, blue: 0.08)
                .ignoresSafeArea()

            // Subtle Background Radial Glow
            RadialGradient(
                colors: [
                    BayanTheme.gold.opacity(0.12),
                    Color.clear
                ],
                center: .center,
                startRadius: 20,
                endRadius: 280
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                // Sacred Emblem with Glowing Ring
                ZStack {
                    Circle()
                        .stroke(BayanTheme.gold.opacity(0.35), lineWidth: 1.5)
                        .frame(width: 104, height: 104)

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.16, green: 0.14, blue: 0.10),
                                    Color(red: 0.08, green: 0.08, blue: 0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 90, height: 90)

                    Image(systemName: securityManager.supportedBiometricType.iconName)
                        .font(.system(size: 38, weight: .semibold))
                        .foregroundColor(BayanTheme.gold)
                }
                .shadow(color: BayanTheme.gold.opacity(0.25), radius: 16)

                // Title & Security Details
                VStack(spacing: 8) {
                    Text("البيان • Bayan")
                        .font(.system(size: 24, weight: .bold, design: .serif))
                        .foregroundColor(.white)

                    Text("Protected with Hardware AES-256 & \(securityManager.supportedBiometricType.title)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(BayanTheme.goldSoft)

                    if let err = securityManager.authenticationErrorMessage {
                        Text(err)
                            .font(.system(size: 12))
                            .foregroundColor(.red.opacity(0.85))
                            .padding(.top, 4)
                    }
                }

                Spacer()

                // Unlock Action Button
                if securityManager.isAppLocked {
                    Button {
                        Task {
                            await securityManager.authenticateUser()
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: securityManager.supportedBiometricType.iconName)
                                .font(.system(size: 16, weight: .bold))

                            Text("Unlock with \(securityManager.supportedBiometricType.title)")
                                .font(.system(size: 15, weight: .bold))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [
                                    BayanTheme.gold,
                                    BayanTheme.goldSoft
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: BayanTheme.gold.opacity(0.35), radius: 10, y: 3)
                    }
                    .padding(.horizontal, 36)
                    .padding(.bottom, 48)
                }
            }
        }
        .onAppear {
            if securityManager.isAppLocked {
                Task {
                    await securityManager.authenticateUser()
                }
            }
        }
    }
}
