import Foundation

/// A normalized, immutable snapshot of audio analysis values.
/// - `levels`: non-negative waveform/envelope bins ordered from left to right.
/// - `history`: past loudness measurements ordered oldest to newest.
/// - `spectrum`: frequency-band energy; empty means unavailable (never synthesized by a painter).
/// - `samples`: signed PCM samples in [-1, 1], suitable for a true oscilloscope.
public struct AudioFrame: Sendable, Equatable {
    public var amplitude: Float
    public var peak: Float
    public var levels: [Float]
    public var history: [Float]
    public var spectrum: [Float]
    public var samples: [Float]
    public var timestamp: TimeInterval

    public init(
        amplitude: Float,
        peak: Float = 0,
        levels: [Float] = [],
        spectrum: [Float] = [],
        timestamp: TimeInterval = 0,
        history: [Float] = [],
        samples: [Float] = []
    ) {
        self.amplitude = Self.unit(amplitude)
        self.peak = Self.unit(peak)
        self.levels = levels.map(Self.unit)
        self.spectrum = spectrum.map(Self.unit)
        self.history = history.map(Self.unit)
        self.samples = samples.map { $0.isFinite ? max(-1, min(1, $0)) : 0 }
        self.timestamp = timestamp.isFinite ? timestamp : 0
    }

    public static let silence = AudioFrame(amplitude: 0)

    private static func unit(_ value: Float) -> Float {
        value.isFinite ? max(0, min(1, value)) : 0
    }
}
