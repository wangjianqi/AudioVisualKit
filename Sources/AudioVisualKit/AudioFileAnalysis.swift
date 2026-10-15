import AVFoundation
import Foundation

/// Bounded, time-indexed frequency and PCM snapshots derived from an actual audio file.
/// Analysis is synchronous; call `analyze` on a background executor (as the Demo does).
public struct AudioFileAnalysis: Sendable {
    public let duration: TimeInterval
    public let levels: [Float]
    public let snapshots: [AudioFrame]

    public init(duration: TimeInterval, levels: [Float], snapshots: [AudioFrame]) {
        self.duration = max(0, duration)
        self.levels = levels
        self.snapshots = snapshots
    }

    /// Returns amplitude and a real FFT/PCM sample nearest to playback time.
    /// The envelope and recording history are aligned to playback progress.
    public func frame(at playbackTime: TimeInterval) -> AudioFrame {
        guard !snapshots.isEmpty else { return .silence }
        let moment = max(0, min(playbackTime.isFinite ? playbackTime : 0, duration))
        var low = 0
        var high = snapshots.count
        while low < high {
            let middle = (low + high) / 2
            if snapshots[middle].timestamp < moment { low = middle + 1 }
            else { high = middle }
        }
        let index = min(low, snapshots.count - 1)
        let nearest = index > 0 && abs(snapshots[index - 1].timestamp - moment) < abs(snapshots[index].timestamp - moment) ? snapshots[index - 1] : snapshots[index]
        let progress = duration > 0 ? min(1, moment / duration) : 0
        let newestIndex = min(max(levels.count - 1, 0), Int(progress * Double(levels.count)))
        let history = (0..<64).map { offset -> Float in
            let idx = newestIndex - (63 - offset)
            return levels.indices.contains(idx) ? levels[idx] : 0
        }
        return AudioFrame(amplitude: nearest.amplitude, peak: nearest.peak,
                          levels: levels, spectrum: nearest.spectrum, timestamp: moment,
                          history: history, samples: nearest.samples)
    }
}

public extension AudioFileWaveform {
    /// Extracts a complete frequency/PCM playback timeline without decoding the entire file to RAM.
    /// `maximumSnapshots` limits memory for long files; analysis remains O(file duration).
    static func analyze(url: URL, sampleCount: Int = 256,
                        snapshotsPerSecond: Double = 12, maximumSnapshots: Int = 2400) throws -> AudioFileAnalysis {
        let file = try AVAudioFile(forReading: url)
        guard file.length > 0 else { throw AudioFileWaveformError.emptyAudio }
        let format = file.processingFormat
        let channels = Int(format.channelCount)
        guard channels > 0, format.sampleRate > 0 else { throw AudioFileWaveformError.unsupportedSampleFormat }
        let count = min(4096, max(8, sampleCount))
        let chunkSize: AVAudioFrameCount = 1024
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: chunkSize) else {
            throw AudioFileWaveformError.unsupportedSampleFormat
        }
        let sampleRate = format.sampleRate
        let duration = Double(file.length) / sampleRate
        let boundedSnapshots = min(6000, max(1, maximumSnapshots))
        let cadence = max(1, min(30, snapshotsPerSecond.isFinite ? snapshotsPerSecond : 12))
        let snapshotStride = max(Int64(chunkSize), Int64(ceil(Double(file.length) / Double(boundedSnapshots))),
                                 Int64(ceil(sampleRate / cadence)))
        var envelopes = [Float](repeating: 0, count: count)
        var snapshots = [AudioFrame]()
        snapshots.reserveCapacity(min(boundedSnapshots, Int(ceil(duration * cadence)) + 1))
        let spectrum = AudioSpectrumAnalyzer()
        var cursor: Int64 = 0
        var nextSnapshot: Int64 = 0
        var blocks = 0
        while cursor < file.length {
            if blocks.isMultiple(of: 128) { try Task<Never, Never>.checkCancellation() }
            blocks += 1
            try file.read(into: buffer, frameCount: chunkSize)
            let readCount = Int(buffer.frameLength)
            guard readCount > 0 else { break }
            guard let pointers = buffer.floatChannelData else { throw AudioFileWaveformError.unsupportedSampleFormat }
            var mono = [Float](repeating: 0, count: 1024)
            var peak: Float = 0
            var sumSquares: Float = 0
            for i in 0..<readCount {
                var mixed: Float = 0
                var loudest: Float = 0
                for ch in 0..<channels {
                    let value = pointers[ch][i]
                    mixed += value
                    loudest = max(loudest, abs(value))
                }
                mono[i] = mixed / Float(channels)
                peak = max(peak, loudest)
                sumSquares += mono[i] * mono[i]
                let bin = min(count - 1, Int(Double(cursor + Int64(i)) / Double(file.length) * Double(count)))
                envelopes[bin] = max(envelopes[bin], loudest)
            }
            if cursor >= nextSnapshot && snapshots.count < boundedSnapshots {
                let rms = sqrt(sumSquares / Float(readCount))
                let amplitude = min(1, sqrt(rms) * 1.8)
                // 256 real bipolar PCM samples, not a synthetic sine wave.
                let pcm = (0..<256).map { i -> Float in
                    mono[min(readCount - 1, i * readCount / 256)]
                }
                snapshots.append(AudioFrame(amplitude: amplitude, peak: peak,
                                            spectrum: spectrum.bands(samples: mono),
                                            timestamp: Double(cursor) / sampleRate, samples: pcm))
                nextSnapshot = cursor + snapshotStride
            }
            cursor += Int64(readCount)
        }
        let maximum = envelopes.max() ?? 0
        // Normalize only the visual envelope. Raw loudness and PCM retain input strength.
        if maximum > 0 { envelopes = envelopes.map { min(1, $0 / maximum) } }
        return AudioFileAnalysis(duration: duration, levels: envelopes, snapshots: snapshots)
    }
}
