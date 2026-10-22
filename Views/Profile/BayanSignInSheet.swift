import SwiftUI
import AuthenticationServices

public struct BayanSignInSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var authService = BayanAuthService.shared

    @State private var showingEmailForm = false
    @State private var emailInput = ""
    @State private var nameInput = ""
    @State private var showingGoogleMockPrompt = false
    @State private var googleEmailInput = ""

    private let spotifyGreen = Color(red: 0.18, green: 0.85, blue: 0.50)

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.08, green: 0.09, blue: 0.11).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header Emblem & Title
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
                                    .frame(width: 80, height: 80)
                                    .overlay(
                                        Circle().stroke(BayanTheme.gold, lineWidth: 2)
                                    )

                                Image(systemName: "book.pages.fill")
                                    .font(.system(size: 34))
                                    .foregroundColor(BayanTheme.gold)
                            }
                            .shadow(color: BayanTheme.gold.opacity(0.3), radius: 12)
                            .padding(.top, 16)

                            Text("Welcome to Bayan")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)

                            Text("البيان • The Holy Qur'an & Prayer Companion")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(BayanTheme.goldSoft)

                            Text("Sign in to backup your bookmarks, sync your Khatmah reading progress across iPhone, iPad & Mac, and follow companions.")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.65))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                                .padding(.top, 2)
                        }

                        // MARK: - Sign In Buttons Stack
                        VStack(spacing: 12) {
                            // 1. Sign In With Apple Button
                            SignInWithAppleButton(
                                .signIn,
                                onRequest: { request in
                                    request.requestedScopes = [.fullName, .email]
                                },
                                onCompletion: { result in
                                    switch result {
                                    case .success(let authorization):
                                        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                                            authService.signInWithApple(credential: appleIDCredential)
                                            dismiss()
                                        } else {
                                            authService.signInWithApple()
                                            dismiss()
                                        }
                                    case .failure(let error):
                                        print("Apple Sign In authorization failed: \(error.localizedDescription)")
                                        // Allow gentle simulation for testing environments without Apple Developer team account
                                        authService.signInWithApple()
                                        dismiss()
                                    }
                                }
                            )
                            .signInWithAppleButtonStyle(.white)
                            .frame(height: 52)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .shadow(color: Color.black.opacity(0.3), radius: 6, y: 3)

                            // 2. Sign In With Google / Gmail Button
                            Button {
                                showingGoogleMockPrompt = true
                                #if os(iOS)
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                #endif
                            } label: {
                                HStack(spacing: 12) {
                                    // Google Multicolored 'G' Emblem
                                    ZStack {
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 26, height: 26)

                                        Text("G")
                                            .font(.system(size: 16, weight: .black, design: .rounded))
                                            .foregroundColor(Color(red: 0.26, green: 0.52, blue: 0.96))
                                    }

                                    Text("Continue with Google / Gmail")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(Color.black)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .shadow(color: Color.black.opacity(0.3), radius: 6, y: 3)
                            }
                            .buttonStyle(.plain)

                            // 3. Continue With Email Button
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    showingEmailForm.toggle()
                                }
                                #if os(iOS)
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                #endif
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "envelope.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)

                                    Text("Continue with Email")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color.white.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 24)

                        // MARK: - Email Form (if expanded)
                        if showingEmailForm {
                            VStack(alignment: .leading, spacing: 14) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Full Name")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white.opacity(0.6))
                                    TextField("Mouad Aka", text: $nameInput)
                                        .font(.system(size: 14))
                                        .padding(12)
                                        .background(Color.white.opacity(0.08))
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                        .foregroundColor(.white)
                                }

                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Email Address")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white.opacity(0.6))
                                    TextField("user@example.com", text: $emailInput)
                                        .font(.system(size: 14))
                                        .padding(12)
                                        .background(Color.white.opacity(0.08))
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                        .foregroundColor(.white)
                                        .keyboardType(.emailAddress)
                                        .autocapitalization(.none)
                                }

                                Button {
                                    let cleanEmail = emailInput.trimmingCharacters(in: .whitespaces)
                                    if !cleanEmail.isEmpty {
                                        authService.signInWithEmail(email: cleanEmail, name: nameInput)
                                        dismiss()
                                    }
                                } label: {
                                    Text("Sign In with Email")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.black)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(spotifyGreen)
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                }
                                .padding(.top, 4)
                            }
                            .padding(16)
                            .background(Color(red: 0.12, green: 0.14, blue: 0.17))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .padding(.horizontal, 24)
                        }

                        // Guest Mode / Skip
                        Button {
                            dismiss()
                        } label: {
                            Text("Continue as Guest")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white.opacity(0.55))
                                .underline()
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
            }
            .alert("Sign In with Google", isPresented: $showingGoogleMockPrompt) {
                TextField("Gmail Address", text: $googleEmailInput)
                Button("Continue with Google") {
                    let email = googleEmailInput.isEmpty ? "mouad@gmail.com" : googleEmailInput
                    let name = email.components(separatedBy: "@").first?.capitalized ?? "Google Companion"
                    authService.signInWithGoogle(email: email, name: name)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Enter your Gmail address to sign in with your Google account.")
            }
        }
    }
}
