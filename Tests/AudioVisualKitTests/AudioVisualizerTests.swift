import SwiftUI
import XCTest

@testable import AudioVisualKit

/// Smoke tests for the presentation layer: every style must construct and render
/// without crashing, for silence, normal and saturated frames, at extreme density.
@MainActor
final class AudioVisualizerTests: XCTestCase {

    private let styles = AudioVisualizationStyle.allCases

    func testDensityIsClampedToSupportedRange() {
        XCTAssertEqual(AudioVisualizer(style: .bars, frame: .silence, density: 1).density, 8)
        XCTAssertEqual(AudioVisualizer(style: .bars, frame: .silence, density: 500).density, 128)
        XCTAssertEqual(AudioVisualizer(style: .bars, frame: .silence, density: 48).density, 48)
    }

    func testDefaultsMatchDocumentedAPI() {
        let view = AudioVisualizer(style: .ribbon, frame: .silence)
        XCTAssertEqual(view.color, .white)
        XCTAssertEqual(view.secondaryColor, .gray)
        XCTAssertEqual(view.density, 48)
    }

    func testEveryStyleRendersWithoutCrashing() throws {
        let frames: [AudioFrame] = [
            .silence,
            AudioFrame(amplitude: 1, levels: Array(repeating: 1, count: 64), spectrum: Array(repeating: 1, count: 32)),
            AudioFrame(amplitude: 0.5, levels: Array(repeating: 0.5, count: 12), spectrum: []),
            AudioFrame(amplitude: 0, levels: [], spectrum: []),
            DemoAudioSignal.frame(at: 2.5)
        ]
        var rendered = 0
        var missing = 0
        for style in styles {
            for (index, frame) in frames.enumerated() {
                if render(style: style, frame: frame, density: index == 0 ? 8 : 96) != nil {
                    rendered += 1
                } else {
                    missing += 1
                    XCTFail("style \(style.rawValue) frame #\(index) rendered no image")
                }
            }
        }
        if rendered == 0 {
            throw XCTSkip("Offscreen image rendering is unavailable in this environment")
        }
        XCTAssertEqual(missing, 0)
        XCTAssertEqual(rendered, styles.count * frames.count)
    }

    /// Renders a visualizer offscreen and returns the image, or `nil` when image
    /// rendering is unavailable in the current environment (for example a headless
    /// host without a window server).
    private func render(style: AudioVisualizationStyle, frame: AudioFrame, density: Int) -> PlatformImage? {
        let renderer = ImageRenderer(content: AudioVisualizer(
            style: style,
            frame: frame,
            color: .white,
            secondaryColor: .gray,
            density: density
        ).frame(width: 120, height: 80))
        renderer.scale = 1
        #if os(macOS)
        return renderer.nsImage
        #else
        return renderer.uiImage
        #endif
    }

    /// Silent input must still paint something: a flat, uniformly transparent image
    /// would mean the painter silently skipped drawing.
    func testSilentFrameStillDrawsSignal() throws {
        #if os(macOS)
        let image = try XCTUnwrap(render(style: .spectrum, frame: .silence, density: 48))
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw XCTSkip("Could not read back rendered pixels on this host")
        }
        let opaquePixels = Self.countOpaquePixels(in: cgImage)
        XCTAssertGreaterThan(opaquePixels, 0, "silent frame rendered no visible content")
        #else
        throw XCTSkip("Pixel readback is only exercised on macOS")
        #endif
    }

    static func countOpaquePixels(in image: CGImage) -> Int {
        let width = image.width
        let height = image.height
        let bytesPerRow = width * 4
        var buffer = [UInt8](repeating: 0, count: bytesPerRow * height)
        guard let space = image.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(data: &buffer,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: 8,
                                      bytesPerRow: bytesPerRow,
                                      space: space,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return -1 }
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        var opaque = 0
        for y in 0..<height {
            for x in 0..<width {
                if buffer[(y * bytesPerRow) + (x * 4) + 3] > 8 { opaque += 1 }
            }
        }
        return opaque
    }
}

#if os(macOS)
typealias PlatformImage = NSImage
#else
typealias PlatformImage = UIImage
#endif
