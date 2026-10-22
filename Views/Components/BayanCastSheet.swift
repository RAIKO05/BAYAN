import SwiftUI
import AVKit

// MARK: - Native AirPlay Route Picker Representable
public struct AirPlayRoutePickerButton: UIViewRepresentable {
    public var tintColor: UIColor = .systemGreen
    public var activeTintColor: UIColor = .systemGreen

    public init(tintColor: UIColor = .systemGreen, activeTintColor: UIColor = .systemGreen) {
        self.tintColor = tintColor
        self.activeTintColor = activeTintColor
    }

    public func makeUIView(context: Context) -> AVRoutePickerView {
        let routePicker = AVRoutePickerView()
        routePicker.tintColor = tintColor
        routePicker.activeTintColor = activeTintColor
        routePicker.prioritizesVideoDevices = false
        routePicker.backgroundColor = .clear
        return routePicker
    }

    public func updateUIView(_ uiView: AVRoutePickerView, context: Context) {
        uiView.tintColor = tintColor
        uiView.activeTintColor = activeTintColor
    }
}

// MARK: - Unified Universal Cast & Connect Sheet
public struct BayanCastSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var castService = BayanCastService.shared
    @State private var showingQRCode = false
    @State private var copiedToClipboard = false
    @State private var showingShareSheet = false

    private let spotifyGreen = Color(red: 0.18, green: 0.85, blue: 0.50)

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.07, green: 0.08, blue: 0.09)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 22) {
                        // MARK: - Header Status Card
                        headerStatusCard

                        // MARK: - Section 1: Apple AirPlay & Bluetooth
                        airplaySection

                        // MARK: - Section 2: Android & Google Cast
                        androidCastSection

                        // MARK: - Section 3: Windows PC & DLNA
                        windowsDlnaSection

                        // MARK: - Section 4: Direct Web Cast (Instant Wi-Fi Stream)
                        webCastSection

                        // MARK: - Disconnect Button (if active)
                        if castService.isCasting {
                            disconnectButton
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                    .frame(maxWidth: 620)
                }
            }
            .navigationTitle("Cast & Connect")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(spotifyGreen)
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let urlString = castService.webCastURL, let url = URL(string: urlString) {
                    ShareSheetView(activityItems: [url, "Listen live to Holy Quran recitation on Bayan Cast: \(urlString)"])
                }
            }
        }
    }

    // MARK: - Header Status Card
    private var headerStatusCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(castService.isCasting ? spotifyGreen.opacity(0.18) : Color.white.opacity(0.08))
                    .frame(width: 48, height: 48)

                Image(systemName: castService.isCasting ? castService.activeDeviceIcon : "speaker.wave.2.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(castService.isCasting ? spotifyGreen : .white.opacity(0.8))
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(castService.isCasting ? spotifyGreen : Color.white.opacity(0.4))
                        .frame(width: 7, height: 7)

                    Text(castService.isCasting ? "CASTING AUDIO" : "CURRENT DEVICE")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundColor(castService.isCasting ? spotifyGreen : .white.opacity(0.5))
                        .tracking(1.0)
                }

                Text(castService.connectedDeviceName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(castService.isCasting ? "Streaming Quran recitation live" : castService.currentAudioRoute)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(red: 0.11, green: 0.13, blue: 0.15))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(castService.isCasting ? spotifyGreen.opacity(0.35) : Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - Section 1: Apple AirPlay & Bluetooth
    private var airplaySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: "Apple AirPlay & Bluetooth", icon: "airplayaudio")

            // AirPlay Trigger Card with Native AVRoutePicker
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 42, height: 42)

                    Image(systemName: "airplayaudio")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("AirPlay to iPhone, Mac & Apple TV")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)

                    Text(castService.isAirPlayRouteActive ? "Connected: \(castService.currentAudioRoute)" : "HomePod, Apple TV, Mac, AirPods")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.55))
                }

                Spacer()

                // Native AirPlay Picker Trigger Overlay
                ZStack {
                    Capsule()
                        .fill(spotifyGreen.opacity(0.18))
                        .frame(width: 82, height: 32)

                    HStack(spacing: 4) {
                        Text("AirPlay")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(spotifyGreen)
                    }

                    // Transparent native route picker on top
                    AirPlayRoutePickerButton(tintColor: UIColor(spotifyGreen), activeTintColor: UIColor(spotifyGreen))
                        .frame(width: 82, height: 32)
                }
            }
            .padding(14)
            .background(Color(red: 0.12, green: 0.13, blue: 0.16))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    // MARK: - Section 2: Android & Google Cast
    private var androidCastSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: "Android & Google Cast", icon: "tv.and.mediabox")

            VStack(spacing: 8) {
                ForEach(castService.androidCastDevices) { device in
                    deviceRow(
                        device: device,
                        icon: "tv.and.mediabox",
                        action: {
                            castService.castToAndroid(device: device)
                            #if os(iOS)
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            #endif
                        }
                    )
                }
            }
        }
    }

    // MARK: - Section 3: Windows PC & DLNA
    private var windowsDlnaSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: "Windows PC & DLNA", icon: "display")

            VStack(spacing: 8) {
                ForEach(castService.windowsDlnaDevices) { device in
                    deviceRow(
                        device: device,
                        icon: "display",
                        action: {
                            castService.castToWindows(device: device)
                            #if os(iOS)
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            #endif
                        }
                    )
                }
            }
        }
    }

    // MARK: - Section 4: Web Cast (Any Browser / Local Wi-Fi Stream)
    private var webCastSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: "Instant Web Cast (Android, Windows, TV)", icon: "globe")

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 42, height: 42)

                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(spotifyGreen)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Cast to Any Browser on Wi-Fi")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)

                        if let urlString = castService.webCastURL {
                            Text(urlString)
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundColor(spotifyGreen)
                        } else {
                            Text("Connect to local Wi-Fi to start streaming")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }

                    Spacer()

                    // QR Code Toggle
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            showingQRCode.toggle()
                        }
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        #endif
                    } label: {
                        Image(systemName: showingQRCode ? "chevron.up.circle.fill" : "qrcode")
                            .font(.system(size: 20))
                            .foregroundColor(spotifyGreen)
                            .padding(6)
                    }
                }

                // Action Buttons: Copy Link & Share Link
                if let urlString = castService.webCastURL {
                    HStack(spacing: 10) {
                        Button {
                            #if os(iOS)
                            UIPasteboard.general.string = urlString
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            #endif
                            copiedToClipboard = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                copiedToClipboard = false
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: copiedToClipboard ? "checkmark" : "doc.on.doc")
                                Text(copiedToClipboard ? "Copied!" : "Copy Link")
                            }
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(copiedToClipboard ? .black : .white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(copiedToClipboard ? spotifyGreen : Color.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }

                        Button {
                            showingShareSheet = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share Link")
                            }
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(Color.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                    }
                }

                // Expandable QR Code Card for Android & Windows Scanning
                if showingQRCode, let urlString = castService.webCastURL, let qrImage = castService.generateQRCode(from: urlString) {
                    VStack(spacing: 10) {
                        Image(uiImage: qrImage)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 170, height: 170)
                            .padding(12)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: Color.black.opacity(0.4), radius: 8)

                        Text("Scan with Android phone camera or Windows PC webcam to stream recitation live")
                            .font(.system(size: 11.5))
                            .foregroundColor(.white.opacity(0.65))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }
                    .padding(.top, 6)
                }
            }
            .padding(14)
            .background(Color(red: 0.12, green: 0.13, blue: 0.16))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    // MARK: - Device Row Helper
    private func deviceRow(device: CastDevice, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(device.isConnected ? spotifyGreen.opacity(0.18) : Color.white.opacity(0.08))
                        .frame(width: 42, height: 42)

                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(device.isConnected ? spotifyGreen : .white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(device.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)

                    Text(device.subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.55))
                }

                Spacer()

                if device.isConnected {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(spotifyGreen)
                            .frame(width: 6, height: 6)
                        Text("Connected")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(spotifyGreen)
                    }
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
            .padding(14)
            .background(Color(red: 0.12, green: 0.13, blue: 0.16))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Section Header Helper
    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(spotifyGreen)
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white.opacity(0.6))
                .tracking(0.8)
        }
        .padding(.leading, 4)
    }

    // MARK: - Disconnect Button
    private var disconnectButton: some View {
        Button {
            castService.disconnectCast()
            #if os(iOS)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            #endif
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "xmark.circle.fill")
                Text("Disconnect & Play on This iPhone")
            }
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(Color.red.opacity(0.9))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.red.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .padding(.top, 10)
    }
}

// MARK: - ShareSheet Helper
private struct ShareSheetView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
