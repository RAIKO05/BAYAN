import SwiftUI
import WebKit

// MARK: - Discord 1-Click Login Web Sheet
/// Presents Discord's official web login page in a secure WKWebView sandbox.
/// Automatically detects successful authentication, extracts the session token,
/// saves it to Apple Keychain, and connects Discord RPC with zero manual copy-pasting.
public struct DiscordLoginSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var isLoading = true
    @State private var authDetected = false
    @State private var errorMessage: String?

    private let discordBlurple = Color(red: 0.35, green: 0.40, blue: 0.95)
    private let goldAccent = Color(red: 0.95, green: 0.78, blue: 0.35)

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.08, green: 0.09, blue: 0.11).ignoresSafeArea()

                VStack(spacing: 0) {
                    if isLoading {
                        LinearProgressView()
                            .frame(height: 3)
                    }

                    if authDetected {
                        VStack(spacing: 16) {
                            Spacer()
                            ProgressView()
                                .scaleEffect(1.4)
                                .tint(discordBlurple)

                            Text("Connecting your Discord account...")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)

                            Text("Authenticating session with Holy Qur'an RPC")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.6))
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(red: 0.08, green: 0.09, blue: 0.11))
                    } else {
                        DiscordAuthWebView(
                            isLoading: $isLoading,
                            onTokenReceived: { token in
                                handleReceivedToken(token)
                            }
                        )
                    }
                }
            }
            .navigationTitle("Discord Login")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 4) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 11))
                            .foregroundColor(goldAccent)
                        Text("Official")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(goldAccent)
                    }
                }
            }
        }
    }

    private func handleReceivedToken(_ token: String) {
        guard !authDetected else { return }
        authDetected = true

        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif

        DiscordRPCService.shared.saveToken(token)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            dismiss()
        }
    }
}

// MARK: - Animated Progress Bar
private struct LinearProgressView: View {
    @State private var isAnimating = false

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Color.white.opacity(0.1)

                Color(red: 0.35, green: 0.40, blue: 0.95)
                    .frame(width: geo.size.width * 0.4)
                    .offset(x: isAnimating ? geo.size.width : -geo.size.width * 0.4)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - WKWebView Representable with Token Extraction Script
private struct DiscordAuthWebView: UIViewRepresentable {
    @Binding var isLoading: Bool
    let onTokenReceived: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let contentController = WKUserContentController()

        // 1. Script Message Handler to bridge JS token extraction to Swift
        contentController.add(context.coordinator, name: "discordAuth")

        // 2. Token Extraction JavaScript
        let extractionJS = """
        (function() {
            function extractAndSendToken() {
                try {
                    // Method A: Query webpack chunks
                    if (window.webpackChunkdiscord_app) {
                        var mods = [];
                        window.webpackChunkdiscord_app.push([['bayan_eval_' + Date.now()], {}, function(e) {
                            for (var c in e.c) mods.push(e.c[c]);
                        }]);
                        var found = mods.find(function(m) {
                            return m && m.exports && m.exports.default && typeof m.exports.default.getToken === 'function';
                        });
                        if (found) {
                            var t = found.exports.default.getToken();
                            if (t && typeof t === 'string' && t.length > 20) {
                                window.webkit.messageHandlers.discordAuth.postMessage(t);
                                return true;
                            }
                        }
                    }
                } catch(e) {}

                try {
                    // Method B: Clean iframe local storage trick
                    var f = document.createElement('iframe');
                    f.style.display = 'none';
                    document.body.appendChild(f);
                    var t = f.contentWindow.localStorage.getItem('token');
                    document.body.removeChild(f);
                    if (t && typeof t === 'string' && t.length > 20) {
                        var clean = t.replace(/^"|"$/g, '');
                        window.webkit.messageHandlers.discordAuth.postMessage(clean);
                        return true;
                    }
                } catch(e) {}

                try {
                    // Method C: Window direct local storage
                    var t2 = window.localStorage.getItem('token');
                    if (t2 && typeof t2 === 'string' && t2.length > 20) {
                        var clean2 = t2.replace(/^"|"$/g, '');
                        window.webkit.messageHandlers.discordAuth.postMessage(clean2);
                        return true;
                    }
                } catch(e) {}

                return false;
            }

            // Expose globally
            window.bayanExtractToken = extractAndSendToken;

            // Run on load and periodically
            setInterval(function() {
                if (location.pathname.indexOf('/channels') !== -1 ||
                    location.pathname.indexOf('/app') !== -1 ||
                    location.pathname.indexOf('/guild-discovery') !== -1) {
                    extractAndSendToken();
                }
            }, 800);
        })();
        """

        let userScript = WKUserScript(source: extractionJS, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        contentController.addUserScript(userScript)

        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        config.defaultWebpagePreferences.allowsContentJavaScript = true

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.bounces = false
        webView.isOpaque = false
        webView.backgroundColor = UIColor(red: 0.08, green: 0.09, blue: 0.11, alpha: 1.0)

        // Set Discord Desktop/Mobile User-Agent for modern web app compatibility
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 Discord/220.0"

        // Load official Discord login page
        if let loginURL = URL(string: "https://discord.com/login") {
            let request = URLRequest(url: loginURL, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 20)
            webView.load(request)
        }

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: DiscordAuthWebView

        init(_ parent: DiscordAuthWebView) {
            self.parent = parent
        }

        // JavaScript message receiver
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "discordAuth", let tokenString = message.body as? String {
                let clean = tokenString.trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: "\"", with: "")
                if clean.count > 20 {
                    DispatchQueue.main.async {
                        self.parent.onTokenReceived(clean)
                    }
                }
            }
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = true
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }

            // Trigger extraction directly once page finishes loading
            webView.evaluateJavaScript("window.bayanExtractToken ? window.bayanExtractToken() : false") { _, _ in }
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url {
                let path = url.path.lowercased()
                // If user reached app dashboard, trigger token extraction aggressively
                if path.contains("/channels") || path.contains("/app") {
                    webView.evaluateJavaScript("window.bayanExtractToken ? window.bayanExtractToken() : false") { _, _ in }
                }
            }
            decisionHandler(.allow)
        }
    }
}
