import Foundation

/// Immutable normalized analysis data; views never own or start audio capture.
public struct AudioFrame: Sendable, Equatable {
    public var amplitude: Float
    public var peak: Float
    public var levels: [Float]
    public var spectrum: [Float]
    public var timestamp: TimeInterval

    public init(
        amplitude: Float,
        peak: Float = 0,
        levels: [Float] = [],
        spectrum: [Float] = [],
        timestamp: TimeInterval = 0
    ) {
        self.amplitude = Self.normalized(amplitude)
        self.peak = Self.normalized(peak)
        self.levels = levels.map(Self.normalized)
        self.spectrum = spectrum.map(Self.normalized)
        self.timestamp = timestamp.isFinite ? timestamp : 0
    }

    public static let silence = AudioFrame(amplitude: 0)

    private static func normalized(_ number: Float) -> Float {
        number.isFinite ? max(0, min(number, 1)) : 0
    }
}
