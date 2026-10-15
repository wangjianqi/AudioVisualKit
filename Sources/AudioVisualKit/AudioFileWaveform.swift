import AVFoundation
import Foundation

public enum AudioFileWaveformError: Error {
    case unsupportedSampleFormat
    case emptyAudio
}

/// Offline file envelope analysis, downsampled in chunks instead of loading the whole file.
public enum AudioFileWaveform {
    public static func amplitudes(url: URL, sampleCount: Int = 160) throws -> [Float] {
        let count = min(4096, max(8, sampleCount))
        let file = try AVAudioFile(forReading: url)
        guard file.length > 0 else { throw AudioFileWaveformError.emptyAudio }
        let format = file.processingFormat
        let chunkSize: AVAudioFrameCount = 4096
        guard let pcm = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: chunkSize) else {
            throw AudioFileWaveformError.unsupportedSampleFormat
        }
        var outputs = [Float](repeating: 0, count: count)
        var frameCursor: Int64 = 0
        repeat {
            try file.read(into: pcm, frameCount: chunkSize)
            let length = Int(pcm.frameLength)
            guard length > 0 else { break }
            guard let channelData = pcm.floatChannelData else {
                throw AudioFileWaveformError.unsupportedSampleFormat
            }
            let channels = Int(format.channelCount)
            for i in 0..<length {
                var absolute: Float = 0
                for ch in 0..<channels { absolute = max(absolute, abs(channelData[ch][i])) }
                let bucket = min(count - 1, Int((Double(frameCursor) + Double(i)) / Double(file.length) * Double(count)))
                outputs[bucket] = max(outputs[bucket], absolute)
            }
            frameCursor += Int64(length)
        } while frameCursor < file.length
        let maxValue = outputs.max() ?? 0
        return maxValue > 0 ? outputs.map { min(1, $0 / maxValue) } : outputs
    }
}
