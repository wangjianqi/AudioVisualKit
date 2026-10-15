#if os(iOS)
import AVFoundation
import Accelerate
import Combine
import Foundation

public enum AudioCaptureError: Error {
    case permissionDenied
    case unavailableInput
}

/// Lightweight microphone adapter for the demo and consumers without another audio engine.
/// Apps already recording should feed their own AudioFrame instead of opening a second engine.
@MainActor
public final class AudioCaptureController: ObservableObject {
    @Published public private(set) var frame: AudioFrame = .silence
    @Published public private(set) var isRunning = false
    @Published public private(set) var errorDescription: String?

    private var engine: AVAudioEngine?
    private var observationTask: Task<Void, Never>?
    private let buffer = MicrophoneWindow()
    private let spectrumProcessor = AudioSpectrumProcessor()
    private var history = [Float](repeating: 0, count: 64)

    public init() {}

    public func start() async throws {
        guard !isRunning else { return }
        guard await AVAudioApplication.requestRecordPermission() else {
            errorDescription = "Microphone permission denied"
            throw AudioCaptureError.permissionDenied
        }
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .mixWithOthers])
        try session.setActive(true)

        let audioEngine = AVAudioEngine()
        let input = audioEngine.inputNode
        let format = input.outputFormat(forBus: 0)
        guard format.channelCount > 0, format.sampleRate > 0 else {
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
            timestamp: Date().timeIntervalSinceReferenceDate
        )
    }

    public func stop() {
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
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
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

    func snapshot() -> [Float] {
        lock.lock()
        defer { lock.unlock() }
        return hasData ? values : []
    }
}

/// Vectorized discrete Fourier transform and logarithmically spaced display bands.
/// Processing runs off the real-time audio callback on the presentation actor.
private final class AudioSpectrumProcessor {
    private let fftSize = 1024
    private let bandCount = 32
    private var setup: vDSP_DFT_Setup?

    init() { setup = vDSP_DFT_zop_CreateSetup(nil, vDSP_Length(fftSize), .FORWARD) }
    deinit { if let setup { vDSP_DFT_DestroySetup(setup) } }

    func bands(samples: [Float]) -> [Float] {
        guard samples.count >= fftSize, let setup else { return Array(repeating: 0, count: bandCount) }
        var re = (0..<fftSize).map { i -> Float in
            let hann = 0.5 - 0.5 * cos(2 * Float.pi * Float(i) / Float(fftSize - 1))
            return samples[i] * hann
        }
        var im = [Float](repeating: 0, count: fftSize)
        var outRe = [Float](repeating: 0, count: fftSize)
        var outIm = [Float](repeating: 0, count: fftSize)
        re.withUnsafeMutableBufferPointer { inputRe in
            im.withUnsafeMutableBufferPointer { inputIm in
                outRe.withUnsafeMutableBufferPointer { outputRe in
                    outIm.withUnsafeMutableBufferPointer { outputIm in
                        vDSP_DFT_Execute(setup, inputRe.baseAddress!, inputIm.baseAddress!, outputRe.baseAddress!, outputIm.baseAddress!)
                    }
                }
            }
        }
        return (0..<bandCount).map { band in
            let u = Float(band) / Float(bandCount)
            let v = Float(band + 1) / Float(bandCount)
            let lo = max(1, min(fftSize / 2 - 1, Int(pow(Float(fftSize / 2), u))))
            let hi = max(lo + 1, min(fftSize / 2, Int(pow(Float(fftSize / 2), v))))
            var peak: Float = 0
            for k in lo..<hi {
                let magnitude = hypot(outRe[k], outIm[k]) / Float(fftSize)
                peak = max(peak, magnitude)
            }
            return min(1, max(0, log1p(peak * 28) / log1p(28)))
        }
    }
}
#endif
