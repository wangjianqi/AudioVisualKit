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

public enum AudioVisualizationStyle: String, CaseIterable, Identifiable, Sendable {
    case bars, mirroredBars, capsuleBars, dotWave, recordingHistory
    case sineWave, layeredWaves, siriFlow, ribbon
    case spectrum, mirroredSpectrum, radialSpectrum
    case radialWave, pulseRings, energyOrb, particles

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .bars: "Bars"
        case .mirroredBars: "Mirrored Bars"
        case .capsuleBars: "Capsule Bars"
        case .dotWave: "Dot Wave"
        case .recordingHistory: "Recording History"
        case .sineWave: "Sine Wave"
        case .layeredWaves: "Layered Waves"
        case .siriFlow: "Siri Flow"
        case .ribbon: "Ribbon"
        case .spectrum: "Spectrum"
        case .mirroredSpectrum: "Mirrored Spectrum"
        case .radialSpectrum: "Radial Spectrum"
        case .radialWave: "Radial Wave"
        case .pulseRings: "Pulse Rings"
        case .energyOrb: "Energy Orb"
        case .particles: "Particles"
        }
    }

    public var group: String {
        switch self {
        case .bars, .mirroredBars, .capsuleBars, .dotWave, .recordingHistory: "Waveforms"
        case .sineWave, .layeredWaves, .siriFlow, .ribbon: "Flow"
        case .spectrum, .mirroredSpectrum, .radialSpectrum: "Spectrum"
        default: "Ambient"
        }
    }
}

public enum DemoAudioSignal {
    /// Deterministic synthetic signal. No microphone permission is needed.
    public static func frame(at time: TimeInterval, count: Int = 64) -> AudioFrame {
        let t = time.isFinite ? time : 0
        let n = min(max(count, 8), 256)
        let beat = pow(max(0, sin(t * 3.4)), 4)
        let energy = Float(max(0.06, min(1, 0.19 + beat * 0.66 + 0.09 * sin(t * 1.3))))
        let bars = (0..<n).map { index -> Float in
            let x = Double(index) / Double(max(1, n - 1))
            let envelope = pow(max(0, sin(.pi * x)), 0.7)
            let flutter = abs(sin(x * 24.0 - t * 5.7) * cos(x * 15.0 + t * 2.1))
            return Float(min(1, 0.06 + envelope * (0.18 + 0.77 * flutter) * Double(energy)))
        }
        let bands = (0..<32).map { index -> Float in
            let x = Double(index) / 31.0
            let bandBeat = abs(sin(t * (2.6 + x) - 9 * x) * cos(t * 1.1 + x * 17))
            return Float(min(1, 0.04 + (0.4 + beat * 0.62) * pow(1 - x, 0.62) * bandBeat))
        }
        return AudioFrame(amplitude: energy, peak: min(1, energy * 1.12), levels: bars, spectrum: bands, timestamp: t)
    }
}
