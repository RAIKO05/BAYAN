import Foundation
import Combine
import SwiftUI

// MARK: - Discord Rich Presence Connection State
public enum DiscordConnectionState: Equatable {
    case disconnected
    case connecting
    case connected(username: String, discriminator: String, avatarUrl: String?)
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
        case .connected(let username, let disc, _):
            return disc == "0" || disc.isEmpty ? "@\(username)" : "\(username)#\(disc)"
        case .error(let msg):
            return "Error: \(msg)"
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
/// Displays "Listening to Holy Qur'an" with dynamic progress bar, Surah name,
/// reciter, and Bayan official artwork on the user's Discord profile.
@Observable
public final class DiscordRPCService: NSObject, @unchecked Sendable {
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
        return !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public var userToken: String {
        get {
            BayanKeychainService.shared.getString(forKey: keychainTokenKey) ?? ""
        }
        set {
            if newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                BayanKeychainService.shared.delete(forKey: keychainTokenKey)
            } else {
                _ = BayanKeychainService.shared.set(string: newValue.trimmingCharacters(in: .whitespacesAndNewlines), forKey: keychainTokenKey)
            }
        }
    }

    // MARK: - WebSocket Gateway State
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession?
    private var heartbeatTimer: DispatchSourceTimer?
    private var lastSequenceNumber: Int?
    private var heartbeatIntervalMs: Double = 41250
    private var isReconnecting = false
    private var reconnectAttempts = 0
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
        configuration.timeoutIntervalForRequest = 20
        self.urlSession = URLSession(configuration: configuration, delegate: nil, delegateQueue: nil)

        // Auto-connect on app launch if enabled and token present
        if self.isEnabled && self.hasToken {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.connect()
            }
        }
    }

    // MARK: - Token Management
    public func saveToken(_ token: String) {
        let clean = token.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\"", with: "")
        self.userToken = clean
        if isEnabled && !clean.isEmpty {
            disconnect()
            connect()
        }
    }

    public func removeToken() {
        self.userToken = ""
        disconnect()
    }

    // MARK: - Gateway Connection Management
    public func connect() {
        queue.async { [weak self] in
            guard let self = self else { return }
            guard self.isEnabled else { return }

            let token = self.userToken
            guard !token.isEmpty else {
                DispatchQueue.main.async {
                    self.connectionState = .error("Discord Token is missing")
                }
                return
            }

            self.stopHeartbeat()
            self.webSocketTask?.cancel(with: .normalClosure, reason: nil)

            DispatchQueue.main.async {
                self.connectionState = .connecting
            }

            let request = URLRequest(url: self.gatewayURL)
            self.webSocketTask = self.urlSession?.webSocketTask(with: request)
            self.webSocketTask?.resume()

            self.listenForMessages()
        }
    }

    public func disconnect() {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.stopHeartbeat()

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
                self.handleDisconnect(error: error)
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
            if let d = json["d"] as? [String: Any],
               let interval = d["heartbeat_interval"] as? Double {
                self.heartbeatIntervalMs = interval
                self.startHeartbeat(intervalMs: interval)
                self.sendIdentify()
            }

        case 11: // Heartbeat ACK
            // Heartbeat successfully received by Discord Gateway
            break

        case 0: // Dispatch Event
            if let t = json["t"] as? String {
                self.handleDispatchEvent(name: t, data: json["d"] as? [String: Any])
            }

        case 7: // Reconnect request from server
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
            if let user = data?["user"] as? [String: Any] {
                let username = user["username"] as? String ?? "Discord User"
                let disc = user["discriminator"] as? String ?? "0"
                let userId = user["id"] as? String ?? ""
                let avatar = user["avatar"] as? String

                var avatarUrl: String? = nil
                if let avatar = avatar, !userId.isEmpty {
                    avatarUrl = "https://cdn.discordapp.com/avatars/\(userId)/\(avatar).png?size=128"
                }

                DispatchQueue.main.async {
                    self.connectionState = .connected(username: username, discriminator: disc, avatarUrl: avatarUrl)
                }

                // If audio is currently playing in Bayan, immediately publish presence to Discord!
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.resendCurrentPlaybackPresence()
                }
            }

        case "RESUMED":
            // Connection successfully resumed
            break

        default:
            break
        }
    }

    // MARK: - Gateway Opcodes Emitters
    private func sendIdentify() {
        let token = self.userToken
        guard !token.isEmpty else { return }

        let identifyPayload: [String: Any] = [
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

        sendJSON(identifyPayload)
    }

    private func startHeartbeat(intervalMs: Double) {
        stopHeartbeat()
        let timer = DispatchSource.makeTimerSource(queue: queue)
        let intervalSeconds = max(5.0, intervalMs / 1000.0)

        // Discord docs: First heartbeat should be jittered: interval * jitter (0.0 to 1.0)
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

    private func handleDisconnect(error: Error) {
        stopHeartbeat()

        let nsError = error as NSError
        // Check for 4004 (Authentication Failed)
        if nsError.code == 4004 {
            DispatchQueue.main.async {
                self.connectionState = .error("Invalid Discord Token (Error 4004)")
            }
            return
        }

        DispatchQueue.main.async {
            if self.isEnabled && self.hasToken {
                self.connectionState = .connecting
            } else {
                self.connectionState = .disconnected
            }
        }

        if isEnabled && hasToken {
            scheduleReconnect(delaySeconds: min(30, Double(reconnectAttempts * 3 + 3)))
        }
    }

    private func scheduleReconnect(delaySeconds: Double) {
        guard !isReconnecting else { return }
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
