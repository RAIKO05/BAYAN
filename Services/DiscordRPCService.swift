import Foundation
import Combine
import SwiftUI
import WebKit

// MARK: - Discord Rich Presence Connection State
public enum DiscordConnectionState: Equatable {
    case disconnected
    case connecting
    case connected(username: String, discriminator: String, avatarUrl: String?, isBot: Bool)
    case error(String)

    public var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }

    public var statusDescription: String {
        switch self {
        case .disconnected:
            return "Disconnected"
        case .connecting:
            return "Connecting to Gateway..."
        case .connected(let username, let disc, _, let isBot):
            let tag = disc == "0" || disc.isEmpty ? "@\(username)" : "\(username)#\(disc)"
            return isBot ? "\(tag) [BOT]" : tag
        case .error(let msg):
            return msg
        }
    }

    public var statusColor: Color {
        switch self {
        case .disconnected:
            return .gray
        case .connecting:
            return .orange
        case .connected:
            return Color(red: 0.18, green: 0.85, blue: 0.50)
        case .error:
            return .red
        }
    }
}

// MARK: - Discord Rich Presence Service (Gateway v10)
/// Manages real-time Discord Rich Presence (RPC) over Discord's WebSocket Gateway v10.
/// Supports both User Authorization Tokens and Bot Tokens, with automatic heartbeat,
/// close code diagnostics, and instant status updates.
@Observable
public final class DiscordRPCService: NSObject, URLSessionWebSocketDelegate, @unchecked Sendable {
    public static let shared = DiscordRPCService()

    // MARK: - Constants & Defaults
    public static let defaultApplicationId = "1343015403565977691" // Official "Holy Qur'an" Discord App
    private let gatewayURL = URL(string: "wss://gateway.discord.gg/?v=10&encoding=json")!
    private let keychainTokenKey = "bayan_discord_user_token"

    // MARK: - Stored Configuration (Persistent)
    private let kDiscordEnabled = "bayan_discord_rpc_enabled"
    private let kDiscordAppId = "bayan_discord_rpc_app_id"
    private let kDiscordShowAyah = "bayan_discord_rpc_show_ayah"
    private let kDiscordShowReciter = "bayan_discord_rpc_show_reciter"
    private let kDiscordShowTimeline = "bayan_discord_rpc_show_timeline"
    private let kDiscordClearOnPause = "bayan_discord_rpc_clear_on_pause"

    public var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: kDiscordEnabled)
            if isEnabled {
                connect()
            } else {
                disconnect()
            }
        }
    }

    public var applicationId: String {
        didSet {
            UserDefaults.standard.set(applicationId, forKey: kDiscordAppId)
            if isConnected {
                resendCurrentPlaybackPresence()
            }
        }
    }

    public var showAyahNumber: Bool {
        didSet {
            UserDefaults.standard.set(showAyahNumber, forKey: kDiscordShowAyah)
            resendCurrentPlaybackPresence()
        }
    }

    public var showReciter: Bool {
        didSet {
            UserDefaults.standard.set(showReciter, forKey: kDiscordShowReciter)
            resendCurrentPlaybackPresence()
        }
    }

    public var showTimeline: Bool {
        didSet {
            UserDefaults.standard.set(showTimeline, forKey: kDiscordShowTimeline)
            resendCurrentPlaybackPresence()
        }
    }

    public var clearWhenPaused: Bool {
        didSet {
            UserDefaults.standard.set(clearWhenPaused, forKey: kDiscordClearOnPause)
            resendCurrentPlaybackPresence()
        }
    }

    // MARK: - Live Observables
    public var connectionState: DiscordConnectionState = .disconnected
    public var currentPresenceDetails: String?
    public var currentPresenceState: String?
    public var currentPresenceStartTime: Date?
    public var currentPresenceEndTime: Date?

    public var isConnected: Bool {
        connectionState.isConnected
    }

    public var hasToken: Bool {
        let token = userToken
        return !cleanToken(token).isEmpty
    }

    public var userToken: String {
        get {
            // First check Keychain
            if let keychainVal = BayanKeychainService.shared.getString(forKey: keychainTokenKey),
               !keychainVal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return keychainVal
            }
            // Fallback to UserDefaults in sandboxed/sideloaded environments
            return UserDefaults.standard.string(forKey: keychainTokenKey) ?? ""
        }
        set {
            let clean = cleanToken(newValue)
            if clean.isEmpty {
                BayanKeychainService.shared.delete(forKey: keychainTokenKey)
                UserDefaults.standard.removeObject(forKey: keychainTokenKey)
            } else {
                _ = BayanKeychainService.shared.set(string: clean, forKey: keychainTokenKey)
                UserDefaults.standard.set(clean, forKey: keychainTokenKey)
            }
        }
    }

    // MARK: - WebSocket Gateway State
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession?
    private var heartbeatTimer: DispatchSourceTimer?
    private var connectionTimeoutTimer: DispatchSourceTimer?
    private var lastSequenceNumber: Int?
    private var heartbeatIntervalMs: Double = 41250
    private var isReconnecting = false
    private var reconnectAttempts = 0
    private var isIntentionalDisconnect = false
    private let queue = DispatchQueue(label: "tools.rea.Bayan.DiscordRPC", qos: .utility)

    // Current Track Cache for Re-Sync
    private var cachedSurah: Surah?
    private var cachedAyah: Int = 1
    private var cachedReciter: Reciter?
    private var cachedCurrentTime: Double = 0.0
    private var cachedDuration: Double = 1.0
    private var cachedIsPlaying: Bool = false

    private override init() {
        self.isEnabled = UserDefaults.standard.bool(forKey: kDiscordEnabled)
        self.applicationId = UserDefaults.standard.string(forKey: kDiscordAppId) ?? DiscordRPCService.defaultApplicationId
        self.showAyahNumber = UserDefaults.standard.object(forKey: kDiscordShowAyah) as? Bool ?? true
        self.showReciter = UserDefaults.standard.object(forKey: kDiscordShowReciter) as? Bool ?? true
        self.showTimeline = UserDefaults.standard.object(forKey: kDiscordShowTimeline) as? Bool ?? true
        self.clearWhenPaused = UserDefaults.standard.bool(forKey: kDiscordClearOnPause)
        super.init()

        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 15
        self.urlSession = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)

        // Auto-connect on app launch if enabled and token present
        if self.isEnabled && self.hasToken {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.connect()
            }
        }
    }

    // MARK: - Token Sanitization Helper
    public func cleanToken(_ raw: String) -> String {
        var str = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove surrounding single or double quotes
        if (str.hasPrefix("\"") && str.hasSuffix("\"")) || (str.hasPrefix("'") && str.hasSuffix("'")) {
            if str.count >= 2 {
                str = String(str.dropFirst().dropLast())
            }
        }

        // If user copied "Authorization: <token>" or "token: <token>"
        if let colonIdx = str.firstIndex(of: ":") {
            let prefix = str[..<colonIdx].lowercased().trimmingCharacters(in: .whitespaces)
            if prefix == "authorization" || prefix == "token" {
                str = String(str[str.index(after: colonIdx)...]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        return str.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Token Management
    public func saveToken(_ token: String) {
        let clean = cleanToken(token)
        self.userToken = clean
        if isEnabled && !clean.isEmpty {
            disconnect()
            connect()
        }
    }

    public func removeToken() {
        self.userToken = ""
        disconnect()
        clearDiscordWebSession()
    }

    /// Clears any cached Discord web login sessions and cookies
    public func clearDiscordWebSession(completion: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            let dataStore = WKWebsiteDataStore.default()
            let types = WKWebsiteDataStore.allWebsiteDataTypes()
            dataStore.fetchDataRecords(ofTypes: types) { records in
                let discordRecords = records.filter { $0.displayName.lowercased().contains("discord") }
                dataStore.removeData(ofTypes: types, for: discordRecords) {
                    if let cookies = HTTPCookieStorage.shared.cookies {
                        for cookie in cookies where cookie.domain.lowercased().contains("discord") {
                            HTTPCookieStorage.shared.deleteCookie(cookie)
                        }
                    }
                    DispatchQueue.main.async {
                        completion?()
                    }
                }
            }
        }
    }

    // MARK: - Gateway Connection Management
    public func connect() {
        queue.async { [weak self] in
            guard let self = self else { return }
            guard self.isEnabled else { return }

            let token = self.cleanToken(self.userToken)
            guard !token.isEmpty else {
                DispatchQueue.main.async {
                    self.connectionState = .error("Discord Token is missing")
                }
                return
            }

            self.isIntentionalDisconnect = false
            self.stopHeartbeat()
            self.stopConnectionTimeout()

            self.webSocketTask?.cancel(with: .normalClosure, reason: nil)

            DispatchQueue.main.async {
                self.connectionState = .connecting
            }

            // Create customized URLRequest with standard Discord Client headers
            var request = URLRequest(url: self.gatewayURL)
            request.timeoutInterval = 15
            request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 Discord/220.0", forHTTPHeaderField: "User-Agent")
            request.setValue("https://discord.com", forHTTPHeaderField: "Origin")

            self.webSocketTask = self.urlSession?.webSocketTask(with: request)
            self.webSocketTask?.resume()

            // Start 15s watchdog timer for connection handshake
            self.startConnectionTimeout()

            // Begin receive loop
            self.listenForMessages()
        }
    }

    public func disconnect() {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.isIntentionalDisconnect = true
            self.stopHeartbeat()
            self.stopConnectionTimeout()

            // Gracefully clear presence before closing
            self.sendRawPresenceUpdate(activities: [])

            self.webSocketTask?.cancel(with: .normalClosure, reason: nil)
            self.webSocketTask = nil
            self.lastSequenceNumber = nil
            self.reconnectAttempts = 0

            DispatchQueue.main.async {
                self.connectionState = .disconnected
                self.currentPresenceDetails = nil
                self.currentPresenceState = nil
                self.currentPresenceStartTime = nil
                self.currentPresenceEndTime = nil
            }
        }
    }

    // MARK: - URLSessionWebSocketDelegate
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        // Connected to Gateway socket, waiting for Opcode 10 Hello
    }

    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        let reasonStr = reason.flatMap { String(data: $0, encoding: .utf8) } ?? "No reason given"
        let code = closeCode.rawValue
        print("🔴 Discord Gateway didCloseWith code: \(code), reason: \(reasonStr)")
        handleCloseCode(code: code, reason: reasonStr)
    }

    private func handleCloseCode(code: Int, reason: String) {
        stopHeartbeat()
        stopConnectionTimeout()

        if isIntentionalDisconnect {
            DispatchQueue.main.async {
                self.connectionState = .disconnected
            }
            return
        }

        switch code {
        case 4004:
            DispatchQueue.main.async {
                self.connectionState = .error("Authentication Failed (Invalid or Expired Token)")
            }
            // Stop retrying permanently for invalid token
            isReconnecting = false

        case 4014:
            DispatchQueue.main.async {
                self.connectionState = .error("Disallowed Bot Intents (Check Developer Portal)")
            }
            isReconnecting = false

        case 4001, 4002, 4003, 4005, 4010, 4011, 4012, 4013:
            DispatchQueue.main.async {
                self.connectionState = .error("Discord Error \(code): \(reason)")
            }
            isReconnecting = false

        case 4008:
            DispatchQueue.main.async {
                self.connectionState = .error("Rate Limited by Discord Gateway")
            }
            scheduleReconnect(delaySeconds: 15)

        default:
            if isEnabled && hasToken {
                DispatchQueue.main.async {
                    self.connectionState = .error("Disconnected (\(code)). Reconnecting...")
                }
                scheduleReconnect(delaySeconds: min(30, Double(reconnectAttempts * 3 + 3)))
            } else {
                DispatchQueue.main.async {
                    self.connectionState = .disconnected
                }
            }
        }
    }

    // MARK: - Message Loop & Gateway Handler
    private func listenForMessages() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self.handleGatewayMessage(text: text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self.handleGatewayMessage(text: text)
                    }
                @unknown default:
                    break
                }
                // Continue listening
                self.listenForMessages()

            case .failure(let error):
                self.handleReceiveFailure(error: error)
            }
        }
    }

    private func handleReceiveFailure(error: Error) {
        stopHeartbeat()
        stopConnectionTimeout()

        guard !isIntentionalDisconnect else { return }

        // Inspect closeCode if available
        let rawCloseCode = webSocketTask?.closeCode.rawValue ?? 0
        if rawCloseCode > 0 && rawCloseCode != 1000 {
            handleCloseCode(code: rawCloseCode, reason: "Connection closed by remote")
            return
        }

        let nsError = error as NSError
        print("⚠️ Discord WebSocket receive error: \(nsError.domain) (\(nsError.code)): \(nsError.localizedDescription)")

        if isEnabled && hasToken {
            DispatchQueue.main.async {
                self.connectionState = .error("Network Connection Lost. Retrying...")
            }
            scheduleReconnect(delaySeconds: min(30, Double(reconnectAttempts * 3 + 3)))
        } else {
            DispatchQueue.main.async {
                self.connectionState = .disconnected
            }
        }
    }

    private func handleGatewayMessage(text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let op = json["op"] as? Int else {
            return
        }

        if let s = json["s"] as? Int {
            self.lastSequenceNumber = s
        }

        switch op {
        case 10: // Hello
            stopConnectionTimeout()
            if let d = json["d"] as? [String: Any],
               let interval = d["heartbeat_interval"] as? Double {
                self.heartbeatIntervalMs = interval
                self.startHeartbeat(intervalMs: interval)
                self.sendIdentify()
            }

        case 11: // Heartbeat ACK
            // Acknowledged
            break

        case 0: // Dispatch Event
            if let t = json["t"] as? String {
                self.handleDispatchEvent(name: t, data: json["d"] as? [String: Any])
            }

        case 7: // Reconnect request from Discord
            self.scheduleReconnect(delaySeconds: 2)

        case 9: // Invalid Session
            let resumable = json["d"] as? Bool ?? false
            self.scheduleReconnect(delaySeconds: resumable ? 2 : 5)

        default:
            break
        }
    }

    private func handleDispatchEvent(name: String, data: [String: Any]?) {
        switch name {
        case "READY":
            reconnectAttempts = 0
            stopConnectionTimeout()

            if let user = data?["user"] as? [String: Any] {
                let username = user["username"] as? String ?? "Discord User"
                let disc = user["discriminator"] as? String ?? "0"
                let userId = user["id"] as? String ?? ""
                let avatar = user["avatar"] as? String
                let isBot = user["bot"] as? Bool ?? false

                var avatarUrl: String? = nil
                if let avatar = avatar, !userId.isEmpty {
                    avatarUrl = "https://cdn.discordapp.com/avatars/\(userId)/\(avatar).png?size=128"
                }

                DispatchQueue.main.async {
                    self.connectionState = .connected(username: username, discriminator: disc, avatarUrl: avatarUrl, isBot: isBot)
                }

                // If audio is currently playing in Bayan, immediately publish presence to Discord!
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.resendCurrentPlaybackPresence()
                }
            }

        case "RESUMED":
            stopConnectionTimeout()
            break

        default:
            break
        }
    }

    // MARK: - Gateway Opcodes Emitters
    private func sendIdentify() {
        let token = cleanToken(self.userToken)
        guard !token.isEmpty else { return }

        // Determine if token is a Bot token or User token
        let isBotToken = token.lowercased().hasPrefix("bot ") || token.components(separatedBy: ".").count == 3 && token.contains("M")

        var identifyPayload: [String: Any] = [:]

        if isBotToken && token.lowercased().hasPrefix("bot ") {
            // Discord Bot Account
            identifyPayload = [
                "op": 2,
                "d": [
                    "token": token,
                    "intents": 0,
                    "properties": [
                        "os": "iOS",
                        "browser": "Bayan",
                        "device": "iPhone"
                    ],
                    "presence": [
                        "status": "online",
                        "since": 0,
                        "activities": [],
                        "afk": false
                    ]
                ]
            ]
        } else {
            // Discord User Account
            identifyPayload = [
                "op": 2,
                "d": [
                    "token": token,
                    "capabilities": 8189,
                    "properties": [
                        "os": "iOS",
                        "browser": "Discord iOS",
                        "device": "iPhone"
                    ],
                    "presence": [
                        "status": "online",
                        "since": 0,
                        "activities": [],
                        "afk": false
                    ]
                ]
            ]
        }

        sendJSON(identifyPayload)
    }

    private func startHeartbeat(intervalMs: Double) {
        stopHeartbeat()
        let timer = DispatchSource.makeTimerSource(queue: queue)
        let intervalSeconds = max(5.0, intervalMs / 1000.0)

        // Discord docs: First heartbeat should be jittered: interval * jitter (0.1 to 0.9)
        let firstDelay = intervalSeconds * Double.random(in: 0.1...0.9)
        timer.schedule(deadline: .now() + firstDelay, repeating: intervalSeconds)

        timer.setEventHandler { [weak self] in
            guard let self = self else { return }
            let payload: [String: Any] = [
                "op": 1,
                "d": self.lastSequenceNumber ?? NSNull()
            ]
            self.sendJSON(payload)
        }

        timer.resume()
        self.heartbeatTimer = timer
    }

    private func stopHeartbeat() {
        heartbeatTimer?.cancel()
        heartbeatTimer = nil
    }

    private func startConnectionTimeout() {
        stopConnectionTimeout()
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + 15.0)
        timer.setEventHandler { [weak self] in
            guard let self = self else { return }
            if self.connectionState == .connecting {
                print("⏱️ Discord Gateway handshake timed out after 15s")
                DispatchQueue.main.async {
                    self.connectionState = .error("Connection Timed Out. Check Token or Network.")
                }
                self.webSocketTask?.cancel(with: .normalClosure, reason: nil)
            }
        }
        timer.resume()
        self.connectionTimeoutTimer = timer
    }

    private func stopConnectionTimeout() {
        connectionTimeoutTimer?.cancel()
        connectionTimeoutTimer = nil
    }

    private func sendJSON(_ dictionary: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: dictionary),
              let string = String(data: data, encoding: .utf8) else {
            return
        }

        webSocketTask?.send(.string(string)) { error in
            if let error = error {
                print("⚠️ Discord Gateway send error: \(error.localizedDescription)")
            }
        }
    }

    private func scheduleReconnect(delaySeconds: Double) {
        guard !isReconnecting && !isIntentionalDisconnect else { return }
        isReconnecting = true
        reconnectAttempts += 1

        queue.asyncAfter(deadline: .now() + delaySeconds) { [weak self] in
            self?.isReconnecting = false
            self?.connect()
        }
    }

    // MARK: - Public Quran Presence Update API
    /// Updates Discord Rich Presence with current Quran playback metadata.
    public func updatePresence(
        surah: Surah,
        ayah: Int,
        reciter: Reciter,
        currentTime: Double,
        duration: Double,
        isPlaying: Bool
    ) {
        // Cache for reconnect and setting changes
        self.cachedSurah = surah
        self.cachedAyah = ayah
        self.cachedReciter = reciter
        self.cachedCurrentTime = currentTime
        self.cachedDuration = duration
        self.cachedIsPlaying = isPlaying

        guard isEnabled && isConnected else { return }

        queue.async { [weak self] in
            guard let self = self else { return }

            if !isPlaying && self.clearWhenPaused {
                self.sendRawPresenceUpdate(activities: [])
                DispatchQueue.main.async {
                    self.currentPresenceDetails = nil
                    self.currentPresenceState = nil
                    self.currentPresenceStartTime = nil
                    self.currentPresenceEndTime = nil
                }
                return
            }

            // Construct Rich Presence Card
            let surahTitle = "Surah \(surah.nameEnglish) (\(surah.nameArabic))"
            var stateParts: [String] = []

            if self.showReciter {
                stateParts.append(reciter.nameEnglish)
            }

            if self.showAyahNumber {
                stateParts.append("Ayah \(ayah)/\(surah.totalAyahs)")
            }

            let stateText = stateParts.joined(separator: " • ")
            let displayState = isPlaying ? stateText : "⏸ Paused • \(stateText)"

            var activity: [String: Any] = [
                "name": "Holy Qur'an",
                "type": 2, // 2 = "Listening to"
                "application_id": self.applicationId,
                "details": surahTitle,
                "state": displayState.isEmpty ? "Recitation" : displayState
            ]

            // Timestamps: Enable Discord's live scrubbing/elapsed progress bar
            var startTime: Date? = nil
            var endTime: Date? = nil

            if self.showTimeline && isPlaying && duration > 0 {
                let now = Date()
                let startMs = Int64((now.timeIntervalSince1970 - currentTime) * 1000)
                let endMs = Int64((now.timeIntervalSince1970 - currentTime + duration) * 1000)

                activity["timestamps"] = [
                    "start": startMs,
                    "end": endMs
                ]

                startTime = Date(timeIntervalSince1970: Double(startMs) / 1000.0)
                endTime = Date(timeIntervalSince1970: Double(endMs) / 1000.0)
            }

            // Assets (Artwork & Status Badges)
            var assets: [String: Any] = [
                "large_image": "bayan_logo",
                "large_text": "Bayan (بَيَان) — Shazam for Holy Qur'an"
            ]

            if isPlaying {
                assets["small_image"] = "play"
                assets["small_text"] = "Ayah \(ayah)"
            } else {
                assets["small_image"] = "pause"
                assets["small_text"] = "Paused"
            }
            activity["assets"] = assets

            // Buttons: Allow friends to open Bayan
            activity["buttons"] = ["Listen on Bayan"]
            activity["metadata"] = [
                "button_urls": ["https://bayan.rea.tools"]
            ]

            self.sendRawPresenceUpdate(activities: [activity])

            DispatchQueue.main.async {
                self.currentPresenceDetails = surahTitle
                self.currentPresenceState = displayState
                self.currentPresenceStartTime = startTime
                self.currentPresenceEndTime = endTime
            }
        }
    }

    /// Clears any active presence from Discord profile.
    public func clearPresence() {
        self.cachedIsPlaying = false
        guard isConnected else { return }

        queue.async { [weak self] in
            guard let self = self else { return }
            self.sendRawPresenceUpdate(activities: [])

            DispatchQueue.main.async {
                self.currentPresenceDetails = nil
                self.currentPresenceState = nil
                self.currentPresenceStartTime = nil
                self.currentPresenceEndTime = nil
            }
        }
    }

    /// Re-sends the last known track presence (e.g. after reconnect or config changes)
    public func resendCurrentPlaybackPresence() {
        if let surah = cachedSurah, let reciter = cachedReciter {
            updatePresence(
                surah: surah,
                ayah: cachedAyah,
                reciter: reciter,
                currentTime: cachedCurrentTime,
                duration: cachedDuration,
                isPlaying: cachedIsPlaying
            )
        } else if let surah = AudioPlayerService.shared.currentSurah {
            updatePresence(
                surah: surah,
                ayah: AudioPlayerService.shared.currentAyah,
                reciter: AudioPlayerService.shared.currentReciter,
                currentTime: AudioPlayerService.shared.currentTime,
                duration: AudioPlayerService.shared.duration,
                isPlaying: AudioPlayerService.shared.isPlaying
            )
        }
    }

    /// Test presence trigger to preview how it looks on Discord immediately
    public func sendTestPresence() {
        guard isConnected else { return }

        let sampleSurah = QuranDataService.shared.surah(for: 18) ?? Surah(
            id: 18,
            nameArabic: "الكهف",
            nameEnglish: "Al-Kahf",
            nameTranslation: "The Cave",
            revelationType: .meccan,
            totalAyahs: 110,
            startPage: 293
        )
        let sampleReciter = AudioPlayerService.shared.currentReciter

        updatePresence(
            surah: sampleSurah,
            ayah: 1,
            reciter: sampleReciter,
            currentTime: 45.0,
            duration: 240.0,
            isPlaying: true
        )
    }

    // MARK: - Low-Level Presence Dispatcher
    private func sendRawPresenceUpdate(activities: [[String: Any]]) {
        let presencePayload: [String: Any] = [
            "op": 3,
            "d": [
                "since": NSNull(),
                "activities": activities,
                "status": "online",
                "afk": false
            ]
        ]
        sendJSON(presencePayload)
    }
}
