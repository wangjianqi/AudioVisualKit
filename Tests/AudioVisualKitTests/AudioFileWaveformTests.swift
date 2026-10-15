import AVFoundation
import XCTest

@testable import AudioVisualKit

/// Tests for the offline envelope extractor against synthesized audio files,
/// written to a temporary directory and removed afterwards.
final class AudioFileWaveformTests: XCTestCase {

    private var scratch: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        scratch = FileManager.default.temporaryDirectory
            .appendingPathComponent("AudioFileWaveformTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: scratch, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let scratch { try? FileManager.default.removeItem(at: scratch) }
        scratch = nil
        try super.tearDownWithError()
    }

    func testEnvelopeMatchesWrittenAmplitudes() throws {
        let url = try writeSineWav(samplesPerCycle: 8, cycles: 40)
        let levels = try AudioFileWaveform.amplitudes(url: url, sampleCount: 24)

        XCTAssertEqual(levels.count, 24)
        XCTAssertEqual(levels.max() ?? 0, 1, accuracy: 0.0001, "the loudest bucket should normalize to 1")
        XCTAssertTrue(levels.allSatisfy { $0 >= 0 && $0 <= 1 })
        // First half is a sustained sine wave, second half is digital silence.
        XCTAssertTrue(levels[0..<12].allSatisfy { $0 > 0 }, "loud half lost its signal")
        XCTAssertTrue(levels[12...].allSatisfy { $0 == 0 }, "silent half should stay at zero")
    }

    func testSampleCountIsClamped() throws {
        let url = try writeSineWav(samplesPerCycle: 8, cycles: 40)
        XCTAssertEqual(try AudioFileWaveform.amplitudes(url: url, sampleCount: 4).count, 8)
        XCTAssertEqual(try AudioFileWaveform.amplitudes(url: url, sampleCount: 99_999).count, 4096)
    }

    func testSilentFileProducesFlatEnvelope() throws {
        let url = try writeWav(samples: Array(repeating: 0, count: 2048))
        let levels = try AudioFileWaveform.amplitudes(url: url, sampleCount: 16)
        XCTAssertEqual(Set(levels), [0])
    }

    func testMissingFileThrows() {
        XCTAssertThrowsError(try AudioFileWaveform.amplitudes(url: scratch.appendingPathComponent("nope.wav")))
    }

    func testUnsupportedPayloadThrows() throws {
        let url = scratch.appendingPathComponent("garbage.wav")
        try Data("not audio".utf8).write(to: url)
        XCTAssertThrowsError(try AudioFileWaveform.amplitudes(url: url))
    }

    // MARK: - Helpers

    /// Writes a 16-bit PCM WAV: loud sine for the first half, silence afterwards.
    private func writeSineWav(samplesPerCycle: Int, cycles: Int) throws -> URL {
        var samples = [Float]()
        for _ in 0..<(cycles / 2) {
            for i in 0..<samplesPerCycle {
                samples.append(sin(2 * .pi * Float(i) / Float(samplesPerCycle)) * 0.8)
            }
        }
        samples.append(contentsOf: Array(repeating: 0, count: samplesPerCycle * (cycles / 2)))
        return try writeWav(samples: samples)
    }

    private func writeWav(samples: [Float]) throws -> URL {
        let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
        let url = scratch.appendingPathComponent("\(UUID().uuidString).wav")
        let file = try AVAudioFile(forWriting: url, settings: format.settings)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count)) else {
            throw AudioFileWaveformError.unsupportedSampleFormat
        }
        buffer.frameLength = buffer.frameCapacity
        for (index, sample) in samples.enumerated() { buffer.floatChannelData?[0][index] = sample }
        try file.write(from: buffer)
        return url
    }
}
