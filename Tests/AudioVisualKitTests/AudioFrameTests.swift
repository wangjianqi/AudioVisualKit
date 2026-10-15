import XCTest
@testable import AudioVisualKit

final class AudioFrameTests: XCTestCase {
    func testNormalizesInvalidValues() {
        let frame = AudioFrame(amplitude: .infinity, peak: -1, levels: [-2, 2, .nan], spectrum: [.infinity])
        XCTAssertEqual(frame.amplitude, 0)
        XCTAssertEqual(frame.peak, 0)
        XCTAssertEqual(frame.levels, [0, 1, 0])
        XCTAssertEqual(frame.spectrum, [0])
    }

    func testPCMIsSignedAndInvalidSamplesAreSafe() {
        let frame = AudioFrame(amplitude: 0.5, history: [-1, 0.2, 2],
                               samples: [-2, -0.5, .nan, 0.7, 2])
        XCTAssertEqual(frame.history, [0, 0.2, 1])
        XCTAssertEqual(frame.samples, [-1, -0.5, 0, 0.7, 1])
        XCTAssertEqual(AudioFrame.silence.samples, [])
    }

    func testDemoIsDeterministicAndBounded() {
        let first = DemoAudioSignal.frame(at: 1.234)
        XCTAssertEqual(first, DemoAudioSignal.frame(at: 1.234))
        XCTAssertEqual(first.spectrum.count, 32)
        XCTAssertEqual(first.history.count, 64)
        XCTAssertEqual(first.samples.count, 256)
        XCTAssertTrue(first.samples.contains { $0 < 0 })
        XCTAssertTrue(first.samples.contains { $0 > 0 })
        XCTAssertEqual(first.levels.count, 64)
        XCTAssertTrue(first.spectrum.allSatisfy { $0 >= 0 && $0 <= 1 })
    }

    func testAllStylesHaveStableIDs() {
        XCTAssertEqual(AudioVisualizationStyle.allCases.count, 24)
        XCTAssertEqual(Set(AudioVisualizationStyle.allCases.map(\.id)).count, 24)
    }

    func testAllStylesHaveStableGroupMetadata() {
        XCTAssertEqual(Set(AudioVisualizationStyle.allCases.map(\.group)),
                       Set(["Waveforms", "Flow", "Spectrum", "Ambient"]))
        for style in AudioVisualizationStyle.allCases {
            XCTAssertFalse(style.title.isEmpty)
            XCTAssertFalse(style.id.isEmpty)
        }
    }

    func testDemoSignalRemainsBoundedAcrossManyFrames() {
        for step in 0..<200 {
            let frame = DemoAudioSignal.frame(at: Double(step) / 30)
            XCTAssertTrue((0...1).contains(frame.amplitude))
            XCTAssertTrue(frame.levels.allSatisfy { (0...1).contains($0) })
            XCTAssertTrue(frame.spectrum.allSatisfy { (0...1).contains($0) })
            XCTAssertTrue(frame.history.allSatisfy { (0...1).contains($0) })
            XCTAssertTrue(frame.samples.allSatisfy { (-1...1).contains($0) })
        }
    }
}
