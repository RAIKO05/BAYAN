import Foundation
import Network
import AVFoundation
import MediaPlayer
import CoreImage.CIFilterBuiltins
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Cast Device Types
public enum CastPlatform: String, CaseIterable, Identifiable {
    case airplay = "Apple AirPlay"
    case googleCast = "Android & Google Cast"
    case windowsDlna = "Windows PC & DLNA"
    case webCast = "Web Cast (Any Browser)"

    public var id: String { rawValue }

    public var systemIcon: String {
        switch self {
        case .airplay: return "airplayaudio"
        case .googleCast: return "tv.and.mediabox"
        case .windowsDlna: return "display"
        case .webCast: return "globe"
        }
    }
}

public struct CastDevice: Identifiable, Hashable {
    public let id: String
    public let name: String
    public let platform: CastPlatform
    public let subtitle: String
    public let host: String?
    public let port: Int?
    public let isConnected: Bool

    public init(id: String, name: String, platform: CastPlatform, subtitle: String, host: String? = nil, port: Int? = nil, isConnected: Bool = false) {
        self.id = id
        self.name = name
        self.platform = platform
        self.subtitle = subtitle
        self.host = host
        self.port = port
        self.isConnected = isConnected
    }
}

// MARK: - Universal Cast & Streaming Service
@Observable
public final class BayanCastService: NSObject {
    public static let shared = BayanCastService()

    // MARK: - State Properties
    public var isCasting: Bool = false
    public var connectedDeviceName: String = "This iPhone"
    public var activePlatform: CastPlatform? = nil
    public var activeDeviceIcon: String = "tv.and.mediabox"

    // Discovered Devices
    public var airplayDevices: [CastDevice] = []
    public var androidCastDevices: [CastDevice] = []
    public var windowsDlnaDevices: [CastDevice] = []

    // Current AirPlay Route
    public var currentAudioRoute: String = "iPhone Speaker"
    public var isAirPlayRouteActive: Bool = false

    // Local Web Cast Server
    public var webCastPort: UInt16 = 8088
    public var localIPAddress: String? = nil
    public var webCastURL: String? = nil
    public var isWebCastServerRunning: Bool = false
    public var connectedWebClientsCount: Int = 0

    // Private Networking
    private var webListener: NWListener?
    private var castBrowser: NWBrowser?
    private var ssdpSocket: NWConnection?

    override private init() {
        super.init()
        setupAudioRouteMonitoring()
        refreshLocalIP()
        startWebCastServer()
        startDiscovery()
    }

    // MARK: - Audio Route Monitoring (AirPlay / Bluetooth)
    private func setupAudioRouteMonitoring() {
        updateCurrentAudioRoute()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(audioRouteChanged),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
    }

    @objc private func audioRouteChanged(notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            self?.updateCurrentAudioRoute()
        }
    }

    public func updateCurrentAudioRoute() {
        let session = AVAudioSession.sharedInstance()
        let outputs = session.currentRoute.outputs
        if let first = outputs.first {
            let portType = first.portType
            let portName = first.portName

            if portType == .airPlay {
                self.isAirPlayRouteActive = true
                self.isCasting = true
                self.connectedDeviceName = "AirPlay • \(portName)"
                self.activePlatform = .airplay
                self.activeDeviceIcon = "airplayaudio"
                self.currentAudioRoute = portName
            } else if portType == .bluetoothA2DP || portType == .bluetoothHFP || portType == .bluetoothLE {
                self.currentAudioRoute = "Bluetooth • \(portName)"
                if activePlatform == .airplay {
                    self.connectedDeviceName = portName
                }
            } else if portType == .headphones {
                self.currentAudioRoute = "Headphones"
            } else {
                self.currentAudioRoute = portName.isEmpty ? "iPhone Speaker" : portName
                if activePlatform == .airplay {
                    self.isCasting = false
                    self.connectedDeviceName = "This iPhone"
                    self.activePlatform = nil
                    self.activeDeviceIcon = "tv.and.mediabox"
                }
            }
        }
    }

    // MARK: - Local IP Address & Single-Session Authentication Token
    private var sessionAccessToken: String = UUID().uuidString.prefix(8).lowercased()

    public func refreshLocalIP() {
        self.localIPAddress = getWiFiAddress()
        if let ip = localIPAddress {
            self.webCastURL = "http://\(ip):\(webCastPort)?token=\(sessionAccessToken)"
        } else {
            self.webCastURL = nil
        }
    }

    private func getWiFiAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return nil }
        defer { freeifaddrs(ifaddr) }

        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ptr.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) {
                let name = String(cString: interface.ifa_name)
                if name == "en0" || name == "en1" {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(
                        interface.ifa_addr,
                        socklen_t(interface.ifa_addr.pointee.sa_len),
                        &hostname,
                        socklen_t(hostname.count),
                        nil,
                        socklen_t(0),
                        NI_NUMERICHOST
                    )
                    address = String(cString: hostname)
                    if address != nil && address != "127.0.0.1" {
                        break
                    }
                }
            }
        }
        return address
    }

    // MARK: - Device Discovery (Google Cast & Windows DLNA)
    public func startDiscovery() {
        startGoogleCastDiscovery()
        startWindowsDlnaDiscovery()
    }

    private func startGoogleCastDiscovery() {
        // Browse for Google Cast mDNS services: _googlecast._tcp
        let parameters = NWParameters()
        let browser = NWBrowser(for: .bonjour(type: "_googlecast._tcp", domain: "local."), using: parameters)
        browser.browseResultsChangedHandler = { [weak self] results, changes in
            DispatchQueue.main.async {
                guard let self = self else { return }
                var discovered: [CastDevice] = []
                for result in results {
                    if case let .service(name, _, _, _) = result.endpoint {
                        let cleanName = name.replacingOccurrences(of: "-", with: " ")
                        let device = CastDevice(
                            id: "gcast_\(name)",
                            name: cleanName,
                            platform: .googleCast,
                            subtitle: "Chromecast / Android TV",
                            isConnected: self.connectedDeviceName.contains(cleanName)
                        )
                        discovered.append(device)
                    }
                }
                // Provide quick-access fallback entries if no mDNS devices answer immediately
                if discovered.isEmpty {
                    discovered = [
                        CastDevice(
                            id: "gcast_android_phone",
                            name: "Android Phone / Tablet",
                            platform: .googleCast,
                            subtitle: "Scan QR code or open link in Chrome",
                            isConnected: self.activePlatform == .googleCast
                        ),
                        CastDevice(
                            id: "gcast_tv",
                            name: "Android TV / Chromecast",
                            platform: .googleCast,
                            subtitle: "Google Cast & Android TV receiver",
                            isConnected: false
                        )
                    ]
                }
                self.androidCastDevices = discovered
            }
        }
        self.castBrowser = browser
        browser.start(queue: .global(qos: .utility))
    }

    private func startWindowsDlnaDiscovery() {
        // Broadcast SSDP M-SEARCH for DLNA Media Renderers (Windows Media Player, Smart TVs)
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            self.sendSSDPDiscovery()
        }

        // Set default Windows targets ready for 1-tap connect
        DispatchQueue.main.async {
            self.windowsDlnaDevices = [
                CastDevice(
                    id: "win_pc_dlna",
                    name: "Windows PC (Media Player)",
                    platform: .windowsDlna,
                    subtitle: "Cast to Windows 10/11 Media Player / DLNA",
                    isConnected: self.activePlatform == .windowsDlna && self.connectedDeviceName.contains("Windows")
                ),
                CastDevice(
                    id: "win_edge_browser",
                    name: "Windows PC (Microsoft Edge)",
                    platform: .windowsDlna,
                    subtitle: "Full-screen desktop player with Quran text",
                    isConnected: self.activePlatform == .windowsDlna && self.connectedDeviceName.contains("Edge")
                )
            ]
        }
    }

    private func sendSSDPDiscovery() {
        let host = NWEndpoint.Host("239.255.255.250")
        let port: NWEndpoint.Port = 1900

        let params = NWParameters.udp
        let connection = NWConnection(host: host, port: port, using: params)
        self.ssdpSocket = connection

        connection.stateUpdateHandler = { state in
            if case .ready = state {
                let ssdpPacket = "M-SEARCH * HTTP/1.1\r\nHOST: 239.255.255.250:1900\r\nMAN: \"ssdp:discover\"\r\nMX: 2\r\nST: urn:schemas-upnp-org:service:AVTransport:1\r\n\r\n"
                if let data = ssdpPacket.data(using: .utf8) {
                    connection.send(content: data, completion: .contentProcessed({ _ in }))
                }
            }
        }
        connection.start(queue: .global(qos: .utility))
    }

    // MARK: - Connect & Cast Actions
    public func castToWindows(device: CastDevice) {
        self.isCasting = true
        self.connectedDeviceName = device.name
        self.activePlatform = .windowsDlna
        self.activeDeviceIcon = "display"

        // Send DLNA SOAP Action if host is present or start desktop web bridge
        if let host = device.host, let port = device.port {
            sendDlnaPlayCommand(host: host, port: port)
        }
    }

    public func castToAndroid(device: CastDevice) {
        self.isCasting = true
        self.connectedDeviceName = device.name
        self.activePlatform = .googleCast
        self.activeDeviceIcon = "tv.and.mediabox"
    }

    public func castToWeb(browserName: String) {
        self.isCasting = true
        self.connectedDeviceName = browserName
        self.activePlatform = .webCast
        self.activeDeviceIcon = "globe"
    }

    public func disconnectCast() {
        self.isCasting = false
        self.connectedDeviceName = "This iPhone"
        self.activePlatform = nil
        self.activeDeviceIcon = "tv.and.mediabox"
    }

    // MARK: - DLNA AVTransport Remote Control (Windows Media Player)
    private func sendDlnaPlayCommand(host: String, port: Int) {
        guard let audioUrl = currentPlaybackAudioUrl() else { return }
        let endpoint = "http://\(host):\(port)/AVTransport/control"
        guard let url = URL(string: endpoint) else { return }

        // XML-escape the media URI to prevent SOAP parameter injection (VULN-01)
        let safeMediaUri = audioUrl.absoluteString.xmlEscaped

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("text/xml; charset=\"utf-8\"", forHTTPHeaderField: "Content-Type")
        request.setValue("\"urn:schemas-upnp-org:service:AVTransport:1#SetAVTransportURI\"", forHTTPHeaderField: "SOAPACTION")

        let soapBody = """
        <?xml version="1.0" encoding="utf-8"?>
        <s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
          <s:Body>
            <u:SetAVTransportURI xmlns:u="urn:schemas-upnp-org:service:AVTransport:1">
              <InstanceID>0</InstanceID>
              <CurrentURI>\(safeMediaUri)</CurrentURI>
              <CurrentURIMetaData></CurrentURIMetaData>
            </u:SetAVTransportURI>
          </s:Body>
        </s:Envelope>
        """
        request.httpBody = soapBody.data(using: .utf8)

        URLSession.shared.dataTask(with: request) { _, _, _ in
            // Send Play action
            var playRequest = URLRequest(url: url)
            playRequest.httpMethod = "POST"
            playRequest.setValue("text/xml; charset=\"utf-8\"", forHTTPHeaderField: "Content-Type")
            playRequest.setValue("\"urn:schemas-upnp-org:service:AVTransport:1#Play\"", forHTTPHeaderField: "SOAPACTION")
            let playBody = """
            <?xml version="1.0" encoding="utf-8"?>
            <s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
              <s:Body>
                <u:Play xmlns:u="urn:schemas-upnp-org:service:AVTransport:1">
                  <InstanceID>0</InstanceID>
                  <Speed>1</Speed>
                </u:Play>
              </s:Body>
            </s:Envelope>
            """
            playRequest.httpBody = playBody.data(using: .utf8)
            URLSession.shared.dataTask(with: playRequest).resume()
        }.resume()
    }

    private func currentPlaybackAudioUrl() -> URL? {
        let player = AudioPlayerService.shared
        guard let surah = player.currentSurah else { return nil }
        return player.currentReciter.audioUrl(surah: surah.id, ayah: player.currentAyah)
    }

    // MARK: - Embedded Local HTTP Web Cast Server (Android / Windows / Any Browser)
    public func startWebCastServer() {
        guard webListener == nil else { return }
        self.sessionAccessToken = UUID().uuidString.prefix(8).lowercased()
        refreshLocalIP()

        do {
            let port = NWEndpoint.Port(rawValue: webCastPort) ?? NWEndpoint.Port(8088)
            let listener = try NWListener(using: .tcp, on: port)
            self.webListener = listener

            listener.stateUpdateHandler = { [weak self] state in
                DispatchQueue.main.async {
                    switch state {
                    case .ready:
                        self?.isWebCastServerRunning = true
                        print("✅ Bayan Web Cast Server listening on port \(port)")
                    case .failed(let err):
                        self?.isWebCastServerRunning = false
                        print("⚠️ Bayan Web Cast Server failed: \(err)")
                    default:
                        break
                    }
                }
            }

            listener.newConnectionHandler = { [weak self] connection in
                self?.handleIncomingWebConnection(connection)
            }

            listener.start(queue: .global(qos: .utility))
        } catch {
            print("⚠️ Could not initialize NWListener on port \(webCastPort): \(error)")
        }
    }

    private func handleIncomingWebConnection(_ connection: NWConnection) {
        connection.start(queue: .global(qos: .utility))
        connection.receive(minimumIncompleteLength: 1, maximumLength: 4096) { [weak self] content, _, isComplete, _ in
            guard let self = self, let content = content, let requestString = String(data: content, encoding: .utf8) else {
                connection.cancel()
                return
            }

            let responseData = self.processHTTPRequest(requestString)
            connection.send(content: responseData, completion: .contentProcessed({ _ in
                connection.cancel()
            }))
        }
    }

    private func processHTTPRequest(_ request: String) -> Data {
        let firstLine = request.components(separatedBy: "\r\n").first ?? ""
        let parts = firstLine.components(separatedBy: " ")
        guard parts.count >= 2 else { return "HTTP/1.1 400 Bad Request\r\n\r\n".data(using: .utf8)! }

        let rawPath = parts[1]
        let urlComponents = URLComponents(string: rawPath)
        let path = urlComponents?.path ?? rawPath
        let token = urlComponents?.queryItems?.first(where: { $0.name == "token" })?.value

        // Enforce Single-Session Token Authentication on all API endpoints (VULN-06)
        if path.hasPrefix("/api/") {
            guard token == sessionAccessToken else {
                let unauth = "HTTP/1.1 401 Unauthorized\r\nContent-Type: text/plain\r\nAccess-Control-Allow-Origin: null\r\nContent-Length: 43\r\n\r\nUnauthorized: Missing or invalid access token."
                return unauth.data(using: .utf8)!
            }

            if path.hasPrefix("/api/status") {
                return generateStatusJSONResponse()
            } else if path.hasPrefix("/api/toggle") {
                DispatchQueue.main.async {
                    AudioPlayerService.shared.togglePlayPause()
                }
                return generateStatusJSONResponse()
            } else if path.hasPrefix("/api/next") {
                DispatchQueue.main.async {
                    AudioPlayerService.shared.nextAyah()
                }
                return generateStatusJSONResponse()
            } else if path.hasPrefix("/api/prev") {
                DispatchQueue.main.async {
                    AudioPlayerService.shared.previousAyah()
                }
                return generateStatusJSONResponse()
            }
        }

        // Default: Serve Full-Screen HTML5 Web Player for Android & Windows
        return generateHTMLWebPlayerResponse()
    }

    private func generateStatusJSONResponse() -> Data {
        let player = AudioPlayerService.shared
        let surah = player.currentSurah
        let surahName = surah?.nameEnglish ?? "The Holy Qur'an"
        let surahArabic = surah?.nameArabic ?? "القرآن الكريم"
        let reciterName = player.currentReciter.nameEnglish
        let audioUrlString = currentPlaybackAudioUrl()?.absoluteString ?? ""

        let json: [String: Any] = [
            "surah": surahName,
            "surahArabic": surahArabic,
            "ayah": player.currentAyah,
            "reciter": reciterName,
            "isPlaying": player.isPlaying,
            "currentTime": player.currentTime,
            "duration": player.duration,
            "audioUrl": audioUrlString
        ]

        let data = (try? JSONSerialization.data(withJSONObject: json, options: [])) ?? Data()
        // Restrict Access-Control-Allow-Origin from wildcard to local origin (VULN-06)
        let headers = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nAccess-Control-Allow-Origin: null\r\nContent-Length: \(data.count)\r\n\r\n"
        var full = headers.data(using: .utf8)!
        full.append(data)
        return full
    }

    private func generateHTMLWebPlayerResponse() -> Data {
        let player = AudioPlayerService.shared
        let surah = player.currentSurah
        let surahName = (surah?.nameEnglish ?? "Surah Al-Mulk").htmlEscaped
        let surahArabic = (surah?.nameArabic ?? "الملك").htmlEscaped
        let ayahNumber = player.currentAyah
        let reciterName = player.currentReciter.nameEnglish.htmlEscaped
        let audioUrl = (currentPlaybackAudioUrl()?.absoluteString ?? "").htmlEscaped
        let activeToken = sessionAccessToken

        let html = """
        <!DOCTYPE html>
        <html lang="en">
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>Bayan Cast • \(surahName)</title>
          <style>
            :root {
              --bg: #070d0b;
              --card: #0f1c18;
              --emerald: #10b981;
              --gold: #d4af37;
              --text: #f3f4f6;
              --subtext: #9ca3af;
            }
            * { box-sizing: border-box; margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; }
            body {
              background: radial-gradient(circle at top, #132822 0%, var(--bg) 100%);
              color: var(--text);
              min-height: 100vh;
              display: flex;
              flex-direction: column;
              align-items: center;
              justify-content: center;
              padding: 24px;
            }
            .container {
              background: var(--card);
              border: 1px solid rgba(212, 175, 55, 0.25);
              border-radius: 24px;
              padding: 36px 32px;
              max-width: 520px;
              width: 100%;
              text-align: center;
              box-shadow: 0 20px 40px rgba(0,0,0,0.6);
            }
            .badge {
              display: inline-flex;
              align-items: center;
              gap: 6px;
              background: rgba(16, 185, 129, 0.15);
              color: var(--emerald);
              padding: 6px 14px;
              border-radius: 20px;
              font-size: 13px;
              font-weight: 600;
              margin-bottom: 20px;
            }
            .dot { width: 8px; height: 8px; background: var(--emerald); border-radius: 50%; box-shadow: 0 0 10px var(--emerald); }
            h1 { font-size: 28px; font-weight: 800; color: #fff; margin-bottom: 4px; }
            .arabic-title { font-size: 32px; color: var(--gold); font-family: 'Amiri', serif; margin-bottom: 12px; }
            .reciter { font-size: 16px; color: var(--emerald); margin-bottom: 24px; display: flex; align-items: center; justify-content: center; gap: 8px; }
            audio { width: 100%; margin: 18px 0; border-radius: 12px; outline: none; }
            .controls { display: flex; justify-content: center; gap: 16px; margin-top: 16px; }
            button {
              background: rgba(255, 255, 255, 0.08);
              border: 1px solid rgba(255,255,255,0.15);
              color: #fff;
              padding: 12px 24px;
              border-radius: 14px;
              font-size: 15px;
              font-weight: 600;
              cursor: pointer;
              transition: all 0.2s;
            }
            button:hover { background: rgba(255,255,255,0.18); transform: translateY(-1px); }
            .play-btn { background: var(--emerald); color: #000; font-weight: 700; border: none; }
            .play-btn:hover { background: #34d399; }
            .footer { margin-top: 24px; font-size: 12px; color: var(--subtext); }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="badge"><div class="dot"></div> BAYAN CAST LIVE</div>
            <div class="arabic-title" id="arTitle">\(surahArabic)</div>
            <h1 id="surahTitle">\(surahName)</h1>
            <p style="color:var(--subtext); margin-bottom:8px;">Ayah <span id="ayahNum">\(ayahNumber)</span></p>
            <div class="reciter"><span>🗣️</span> <span id="reciterName">\(reciterName)</span></div>

            <audio id="audioEl" controls autoplay src="\(audioUrl)"></audio>

            <div class="controls">
              <button onclick="apiCall('/api/prev')">⏮ Previous</button>
              <button class="play-btn" onclick="togglePlay()">⏯ Play / Pause</button>
              <button onclick="apiCall('/api/next')">⏭ Next</button>
            </div>

            <p class="footer">Casting live from Bayan iOS • High-Fidelity Recitation</p>
          </div>

          <script>
            const audio = document.getElementById('audioEl');
            const sessionToken = "\(activeToken)";
            let currentUrl = "\(audioUrl)";

            function apiCall(endpoint) {
              const url = endpoint + '?token=' + encodeURIComponent(sessionToken);
              fetch(url).then(r => r.json()).then(updateUI).catch(() => {});
            }

            function togglePlay() {
              if (audio.paused) {
                audio.play();
                apiCall('/api/toggle');
              } else {
                audio.pause();
                apiCall('/api/toggle');
              }
            }

            function updateUI(data) {
              if (!data) return;
              if (data.surah) document.getElementById('surahTitle').innerText = data.surah;
              if (data.surahArabic) document.getElementById('arTitle').innerText = data.surahArabic;
              if (data.ayah) document.getElementById('ayahNum').innerText = data.ayah;
              if (data.reciter) document.getElementById('reciterName').innerText = data.reciter;
              if (data.audioUrl && data.audioUrl !== currentUrl) {
                currentUrl = data.audioUrl;
                audio.src = data.audioUrl;
                audio.play().catch(() => {});
              }
            }

            // Real-time synchronization polling every 2.5 seconds with session token
            setInterval(() => {
              fetch('/api/status?token=' + encodeURIComponent(sessionToken))
                .then(r => r.json())
                .then(updateUI)
                .catch(() => {});
            }, 2500);

            // Auto-advance to next Ayah when finished
            audio.onended = () => {
              apiCall('/api/next');
            };
          </script>
        </body>
        </html>
        """

        let bodyData = html.data(using: .utf8)!
        let headers = "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nAccess-Control-Allow-Origin: null\r\nContent-Length: \(bodyData.count)\r\n\r\n"
        var res = headers.data(using: .utf8)!
        res.append(bodyData)
        return res
    }

    // MARK: - QR Code Generator for Android & Windows Pairing
    public func generateQRCode(from string: String) -> UIImage? {
        let context = CIContext()
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(Data(string.utf8), forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")

        guard let outputImage = filter.outputImage else { return nil }
        let scaled = outputImage.transformed(by: CGAffineTransform(scaleX: 8, y: 8))
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - String Sanitization Extensions (VULN-01 / VULN-06)
extension String {
    public var xmlEscaped: String {
        return self
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }

    public var htmlEscaped: String {
        return self
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
}
