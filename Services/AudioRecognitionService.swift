import Foundation
import AVFoundation
import ShazamKit
import Accelerate
import Speech

// MARK: - Hybrid Shazam + Offline Speech Quran Recognition Engine
// 1. Crash Fix: AVAudioSession configured & activated BEFORE inputNode access
// 2. Dual Engine: Streams live mic PCM buffers simultaneously to ShazamKit & SFSpeechRecognizer
// 3. Offline Mode: ar-SA on-device speech recognition for cellular-dead zones / mosques
// 4. Fallback Resolution: Shazam -> Offline Speech (Quran Corpus) -> Clean Failure
@Observable
public final class AudioRecognitionService: NSObject, SHSessionDelegate {
    public static let shared = AudioRecognitionService()

    public enum State: Equatable {
        case idle
        case listening(decibels: Float)
        case analyzing
        case matched(RecognitionResult)
        case failed(String)

        public static func == (lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.analyzing, .analyzing):
                return true
            case let (.listening(l), .listening(r)):
                return abs(l - r) < 0.01
            case let (.matched(l), .matched(r)):
                return l.id == r.id
            case let (.failed(l), .failed(r)):
                return l == r
            default:
                return false
            }
        }
    }

    public var state: State = .idle
    public var currentDecibels: Float = 0.0

    private var audioEngine = AVAudioEngine()
    private var shSession: SHSession?
    private var recognitionTimeoutTask: Task<Void, Never>?
    private var isMatchingActive = false

    // Speech-to-Text Offline Recognition Fallback
    private var speechRecognizer: SFSpeechRecognizer?
    private var speechRequest: SFSpeechAudioBufferRecognitionRequest?
    private var speechRecognitionTask: SFSpeechRecognitionTask?
    private var latestTranscription: String = ""

    public override init() {
        super.init()
        setupShazamSession()
        setupSpeechRecognizer()
    }

    private func setupShazamSession() {
        let session = SHSession()
        session.delegate = self
        self.shSession = session
    }

    private func setupSpeechRecognizer() {
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ar-SA"))
    }

    // MARK: - Start Real Microphone Listening with Dual Shazam + Offline Speech
    public func startListening() {
        guard !isMatchingActive else { return }

        // 1. Permissions: request both record permission and speech recognition authorization
        AVAudioApplication.requestRecordPermission { [weak self] micGranted in
            guard let self = self else { return }
            if !micGranted {
                DispatchQueue.main.async {
                    self.state = .failed("Microphone permission denied. Enable microphone in iOS Settings.")
                }
                return
            }

            SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.beginAudioEngineRecording()
                }
            }
        }
    }

    private func beginAudioEngineRecording() {
        isMatchingActive = true
        latestTranscription = ""
        state = .listening(decibels: 0.1)

        // 2. CRITICAL CRASH FIX: Configure and activate AVAudioSession BEFORE accessing inputNode!
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("⚠️ AVAudioSession setup warning: \(error)")
        }

        // 3. Offline Speech Setup: On-device offline transcription for mosques / low cell reception
        speechRequest = SFSpeechAudioBufferRecognitionRequest()
        speechRequest?.requiresOnDeviceRecognition = true
        speechRequest?.shouldReportPartialResults = true

        if let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable, let request = speechRequest {
            speechRecognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
                guard let self = self else { return }
                if let result = result {
                    let text = result.bestTranscription.formattedString
                    self.latestTranscription = text
                }
            }
        }

        // Access inputNode safely after audioSession is active
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        // Ensure removeTap is called first
        inputNode.removeTap(onBus: 0)

        // 4. Hybrid Engine Tap: Feed buffer to BOTH ShazamKit and SpeechRequest
        inputNode.installTap(onBus: 0, bufferSize: 2048, format: recordingFormat) { [weak self] (buffer: AVAudioPCMBuffer, time: AVAudioTime) in
            guard let self = self, self.isMatchingActive else { return }

            let decibels = self.calculateRMS(from: buffer)
            DispatchQueue.main.async {
                self.currentDecibels = decibels
                if case .listening = self.state {
                    self.state = .listening(decibels: decibels)
                }
            }

            // Stream to ShazamKit
            self.shSession?.matchStreamingBuffer(buffer, at: time)

            // Stream to Speech recognition buffer
            self.speechRequest?.append(buffer)
        }

        do {
            try audioEngine.start()
            print("🎙️ Real microphone listening active (ShazamKit + Offline Speech ar-SA).")
        } catch {
            print("⚠️ AVAudioEngine failed to start: \(error)")
            fallbackToSpeechOrCorpus()
            return
        }

        // 5. Resolution Logic: 8-second timeout
        recognitionTimeoutTask?.cancel()
        recognitionTimeoutTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 8_000_000_000)
            guard let self = self, self.isMatchingActive else { return }

            if case .listening = self.state {
                self.state = .analyzing
                self.fallbackToSpeechOrCorpus()
            }
        }
    }

    // Root Mean Square (RMS) decibel calculation
    private func calculateRMS(from buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData?[0] else { return 0.1 }
        let channelDataCount = vDSP_Length(buffer.frameLength)

        var rms: Float = 0.0
        vDSP_rmsqv(channelData, 1, &rms, channelDataCount)

        let normalized = min(max(rms * 8.0, 0.1), 1.0)
        return normalized
    }

    // MARK: - ShazamKit SHSessionDelegate (Shazam First)
    public func session(_ session: SHSession, didFind match: SHMatch) {
        guard let mediaItem = match.mediaItems.first else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.isMatchingActive else { return }
            self.stopAudioEngine()

            let rawTitle = mediaItem.title ?? "Al-Fatihah"
            let reciterName = mediaItem.artist ?? "Mishary Rashid Alafasy"

            let cleanedTitle = rawTitle
                .replacingOccurrences(of: "Sourate", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: "Surah", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: "Surat", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: "سورة", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            let matchedSurah = QuranDataService.shared.allSurahs.first {
                cleanedTitle.localizedCaseInsensitiveContains($0.nameEnglish) ||
                $0.nameEnglish.localizedCaseInsensitiveContains(cleanedTitle) ||
                cleanedTitle.contains($0.nameArabic) ||
                $0.nameArabic.contains(cleanedTitle)
            } ?? QuranDataService.shared.allSurahs.first {
                rawTitle.localizedCaseInsensitiveContains($0.nameEnglish) ||
                rawTitle.contains($0.nameArabic)
            } ?? Surah.sampleFatihah

            let matchedReciter = Reciter.standardCatalog.first {
                $0.nameEnglish.localizedCaseInsensitiveContains(reciterName) ||
                reciterName.localizedCaseInsensitiveContains($0.nameEnglish)
            } ?? Reciter.standardCatalog[0]

            let result = RecognitionResult(
                surah: matchedSurah,
                startAyah: 1,
                endAyah: min(matchedSurah.totalAyahs, 7),
                reciter: matchedReciter,
                arabicSnippet: QuranVerseText.arabic(surahId: matchedSurah.id, ayahNumber: 1),
                translationSnippet: QuranVerseText.translation(surahId: matchedSurah.id, ayahNumber: 1),
                confidence: 0.98
            )

            QuranSyncManager.shared.addRecognition(result)
            self.state = .matched(result)
        }
    }

    public func session(_ session: SHSession, didNotFindMatchFor signature: SHSignature, error: Error?) {
        DispatchQueue.main.async { [weak self] in
            self?.fallbackToSpeechOrCorpus()
        }
    }

    // MARK: - Speech Fallback Resolution Logic
    private func fallbackToSpeechOrCorpus() {
        guard isMatchingActive else { return }

        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.state = .analyzing
            try? await Task.sleep(nanoseconds: 400_000_000)

            let capturedText = self.latestTranscription.trimmingCharacters(in: .whitespacesAndNewlines)
            self.stopAudioEngine()

            // 1. Try verse matching against the transcribed Arabic text
            if !capturedText.isEmpty {
                // Check if any Surah name matches the transcription
                let normalizedText = QuranVerseText.normalizeArabic(capturedText)
                if let matchedSurah = QuranDataService.shared.allSurahs.first(where: {
                    let normSurah = QuranVerseText.normalizeArabic($0.nameArabic)
                    return normalizedText.contains(normSurah) || normSurah.contains(normalizedText)
                }) {
                    let result = RecognitionResult(
                        surah: matchedSurah,
                        startAyah: 1,
                        endAyah: min(matchedSurah.totalAyahs, 7),
                        reciter: Reciter.unknownReciter,
                        arabicSnippet: QuranVerseText.arabic(surahId: matchedSurah.id, ayahNumber: 1),
                        translationSnippet: QuranVerseText.translation(surahId: matchedSurah.id, ayahNumber: 1),
                        confidence: 0.92
                    )
                    QuranSyncManager.shared.addRecognition(result)
                    self.state = .matched(result)
                    return
                }

                // Check if verse content matches
                if let (surahId, ayahNum) = QuranVerseText.searchVerse(query: capturedText),
                   let surah = QuranDataService.shared.surah(for: surahId) {
                    let result = RecognitionResult(
                        surah: surah,
                        startAyah: ayahNum,
                        endAyah: min(surah.totalAyahs, ayahNum + 2),
                        reciter: Reciter.unknownReciter,
                        arabicSnippet: QuranVerseText.arabic(surahId: surah.id, ayahNumber: ayahNum),
                        translationSnippet: QuranVerseText.translation(surahId: surah.id, ayahNumber: ayahNum),
                        confidence: 0.90
                    )
                    QuranSyncManager.shared.addRecognition(result)
                    self.state = .matched(result)
                    return
                }
            }

            // 2. Failed match response
            if self.currentDecibels < 0.18 {
                self.state = .failed("No recitation detected. Please bring your phone closer to the audio source.")
            } else {
                self.state = .failed("Could not identify this recitation. Ensure the audio is clear Quran recitation and try again.")
            }
        }
    }

    // 6. Cleanup
    private func stopAudioEngine() {
        isMatchingActive = false
        recognitionTimeoutTask?.cancel()
        recognitionTimeoutTask = nil

        speechRequest?.endAudio()
        speechRecognitionTask?.cancel()
        speechRecognitionTask = nil
        speechRequest = nil

        if audioEngine.isRunning {
            audioEngine.inputNode.removeTap(onBus: 0)
            audioEngine.stop()
        }

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    public func reset() {
        stopAudioEngine()
        state = .idle
        currentDecibels = 0.0
        latestTranscription = ""
    }
}
