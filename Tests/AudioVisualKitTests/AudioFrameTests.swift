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

    func testDemoIsDeterministicAndBounded() {
        let first = DemoAudioSignal.frame(at: 1.234)
        XCTAssertEqual(first, DemoAudioSignal.frame(at: 1.234))
        XCTAssertEqual(first.spectrum.count, 32)
        XCTAssertEqual(first.levels.count, 64)
        XCTAssertTrue(first.spectrum.allSatisfy { $0 >= 0 && $0 <= 1 })
    }

    func testAllStylesHaveStableIDs() {
        XCTAssertEqual(AudioVisualizationStyle.allCases.count, 16)
        XCTAssertEqual(Set(AudioVisualizationStyle.allCases.map(\.id)).count, 16)
    }
}
