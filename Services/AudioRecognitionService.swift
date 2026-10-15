import Foundation
import AVFoundation
import Combine

@Observable
public final class AudioRecognitionService: NSObject {
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

    private var audioEngine: AVAudioEngine?
    private var recognitionTimer: Timer?
    private var simulatedListeningTask: Task<Void, Never>?

    public override init() {
        super.init()
    }

    public func startListening() {
        guard state == .idle || state != .analyzing else { return }
        
        self.state = .listening(decibels: 0.2)

        // Simulate waveform dynamics and match flow
        simulatedListeningTask?.cancel()
        simulatedListeningTask = Task { @MainActor in
            for i in 1...25 {
                try? await Task.sleep(nanoseconds: 120_000_000)
                if Task.isCancelled { return }
                
                // Pulsing audio decibels for the Liquid Glass Radar Orb
                let randomWave = Float.random(in: 0.25...0.95)
                self.currentDecibels = randomWave
                self.state = .listening(decibels: randomWave)
            }

            self.state = .analyzing
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            if Task.isCancelled { return }

            // Sample high-confidence match
            let match = RecognitionResult.sample
            QuranSyncManager.shared.addRecognition(match)
            self.state = .matched(match)
        }
    }

    public func reset() {
        simulatedListeningTask?.cancel()
        simulatedListeningTask = nil
        audioEngine?.stop()
        state = .idle
        currentDecibels = 0.0
    }
}
