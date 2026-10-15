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

    func testOfflineFFTAndPCMFollowPlaybackTime() throws {
        let url = try writeSineWav(samplesPerCycle: 8, cycles: 8000)
        let analysis = try AudioFileWaveform.analyze(url: url, sampleCount: 64,
                                                     snapshotsPerSecond: 30, maximumSnapshots: 100)
        XCTAssertEqual(analysis.levels.count, 64)
        XCTAssertGreaterThan(analysis.duration, 0)
        XCTAssertFalse(analysis.snapshots.isEmpty)
        let early = analysis.frame(at: analysis.duration * 0.25)
        XCTAssertEqual(early.spectrum.count, 32)
        XCTAssertGreaterThan(early.spectrum.max() ?? 0, 0)
        XCTAssertTrue(early.samples.contains { $0 > 0 })
        XCTAssertTrue(early.samples.contains { $0 < 0 })
        XCTAssertEqual(early.history.count, 64)
        let late = analysis.frame(at: analysis.duration * 0.85)
        XCTAssertLessThan(late.amplitude, early.amplitude)
    }

    func testSilentFFTDoesNotInventFrequencyData() throws {
        let url = try writeWav(samples: Array(repeating: 0, count: 8192))
        let analysis = try AudioFileWaveform.analyze(url: url)
        XCTAssertFalse(analysis.snapshots.isEmpty)
        for snapshot in analysis.snapshots {
            XCTAssertEqual(snapshot.spectrum.count, 32)
            XCTAssertTrue(snapshot.spectrum.allSatisfy { $0 == 0 })
            XCTAssertTrue(snapshot.samples.allSatisfy { $0 == 0 })
        }
    }

    func testTimeIndexedSnapshotsAndHistoryAreClamped() {
        let quiet = AudioFrame(amplitude: 0.1, spectrum: [0.1], timestamp: 0, samples: [-0.1, 0.1])
        let loud = AudioFrame(amplitude: 0.9, spectrum: [0.9], timestamp: 2, samples: [-0.9, 0.9])
        let data = AudioFileAnalysis(duration: 2, levels: [0, 0.4, 0.9, 0.2], snapshots: [quiet, loud])
        XCTAssertEqual(data.frame(at: -5).amplitude, 0.1)
        XCTAssertEqual(data.frame(at: 200).amplitude, 0.9)
        XCTAssertEqual(data.frame(at: 200).history.last, 0.2)
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
