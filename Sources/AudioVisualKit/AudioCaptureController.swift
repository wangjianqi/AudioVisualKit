#if os(iOS)
import AVFoundation
import Combine
import Foundation

public enum AudioCaptureError: Error {
    case permissionDenied
    case unavailableInput
    case cancelled
}

/// Lightweight microphone adapter for the demo and consumers without another audio engine.
/// Apps already recording should feed their own AudioFrame instead of opening a second engine.
@MainActor
public final class AudioCaptureController: ObservableObject {
    @Published public private(set) var frame: AudioFrame = .silence
    @Published public private(set) var isRunning = false
    @Published public private(set) var errorDescription: String?

    private var engine: AVAudioEngine?
    private var startGeneration: UInt64 = 0
    private var isStarting = false
    private var observationTask: Task<Void, Never>?
    private let buffer = MicrophoneWindow()
    private let spectrumProcessor = AudioSpectrumAnalyzer()
    private var history = [Float](repeating: 0, count: 64)

    public init() {}

    public func start() async throws {
        guard !isRunning, !isStarting else { return }
        isStarting = true
        startGeneration &+= 1
        let generation = startGeneration
        defer { if generation == startGeneration { isStarting = false } }
        let granted = await AVAudioApplication.requestRecordPermission()
        guard generation == startGeneration else { throw AudioCaptureError.cancelled }
        guard granted else {
            errorDescription = "Microphone permission denied"
            throw AudioCaptureError.permissionDenied
        }
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .mixWithOthers])
        do {
            try session.setActive(true)
        } catch {
            errorDescription = error.localizedDescription
            throw error
        }

        buffer.clear()
        let audioEngine = AVAudioEngine()
        let input = audioEngine.inputNode
        let format = input.outputFormat(forBus: 0)
        guard format.channelCount > 0, format.sampleRate > 0 else {
            deactivateSession()
            errorDescription = "No usable audio input on this device"
            throw AudioCaptureError.unavailableInput
        }
        // Compatibility tap. A newer installAudioTap API exists in recent SDKs;
        // guard its use by SDK/OS availability before migrating this adapter.
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [buffer] pcm, _ in
            buffer.receive(pcm)
        }
        do {
            try audioEngine.start()
        } catch {
            input.removeTap(onBus: 0)
            deactivateSession()
            errorDescription = error.localizedDescription
            throw error
        }
        engine = audioEngine
        errorDescription = nil
        isRunning = true
        observationTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                let window = self.buffer.snapshot()
                self.publish(window)
                try? await Task.sleep(for: .milliseconds(33))
            }
        }
    }

    /// Releases the audio session so other apps are notified again. Safe to call
    /// when no session was ever activated.
    private func deactivateSession() {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func publish(_ samples: [Float]) {
        guard !samples.isEmpty else { return }
        var sum: Float = 0
        var peak: Float = 0
        for value in samples {
            sum += value * value
            peak = max(peak, abs(value))
        }
        let rms = sqrt(sum / Float(samples.count))
        // Light perceptual gain for UI visualization, not a calibrated SPL meter.
        let level = min(1, sqrt(rms) * 1.8)
        history.removeFirst()
        history.append(level)
        frame = AudioFrame(
            amplitude: level,
            peak: min(1, peak),
            levels: history,
            spectrum: spectrumProcessor.bands(samples: samples),
            timestamp: Date().timeIntervalSinceReferenceDate,
            history: history,
            samples: samples
        )
    }

    public func stop() {
        startGeneration &+= 1
        isStarting = false
        observationTask?.cancel()
        observationTask = nil
        if let engine {
            engine.inputNode.removeTap(onBus: 0)
            engine.stop()
        }
        engine = nil
        isRunning = false
        frame = .silence
        history = [Float](repeating: 0, count: 64)
        buffer.clear()
        deactivateSession()
    }

    deinit {
        // The hosting view must call stop() on disappearance. The owning engine
        // releases when this controller is deallocated.
        observationTask?.cancel()
    }
}

/// Fixed-size capture window; callback copies into preallocated storage.
/// Synchronization is intentionally isolated from SwiftUI. For ultra-low-latency
/// production audio processing, replace this adapter with a lock-free SPSC buffer.
private final class MicrophoneWindow: @unchecked Sendable {
    private let lock = NSLock()
    private var values = [Float](repeating: 0, count: 1024)
    private var hasData = false

    func receive(_ pcm: AVAudioPCMBuffer) {
        guard let channels = pcm.floatChannelData else { return }
        guard lock.try() else { return } // Never wait for UI-side snapshot.
        defer { lock.unlock() }
        let count = min(Int(pcm.frameLength), values.count)
        guard count > 0 else { return }
        let channel = channels[0]
        for i in 0..<count { values[i] = channel[i] }
        if count < values.count {
            for i in count..<values.count { values[i] = 0 }
        }
        hasData = true
    }

    func clear() {
        lock.lock()
        defer { lock.unlock() }
        hasData = false
        values = [Float](repeating: 0, count: 1024)
    }

    func snapshot() -> [Float] {
        lock.lock()
        defer { lock.unlock() }
        return hasData ? values : []
    }
}
#endif
