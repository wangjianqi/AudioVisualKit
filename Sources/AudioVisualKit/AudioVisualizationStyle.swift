import Foundation

/// Every shipped visualization, grouped for gallery presentation.
///
/// Add a new style by appending a case, its `title`, its `group`, and the painter
/// implementation under `Sources/AudioVisualKit/Painters/`.
public enum AudioVisualizationStyle: String, CaseIterable, Identifiable, Sendable {
    case bars, mirroredBars, capsuleBars, dotWave, recordingHistory
    case sineWave, layeredWaves, siriFlow, ribbon
    case spectrum, mirroredSpectrum, radialSpectrum
    case radialWave, pulseRings, energyOrb, particles
    case oscilloscope, doubleHelix, auroraCurtain, neonRibbon
    case starburst, orbitingArcs, lotus, vortex

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
        case .oscilloscope: "Oscilloscope"
        case .doubleHelix: "Double Helix"
        case .auroraCurtain: "Aurora Curtain"
        case .neonRibbon: "Neon Ribbon"
        case .starburst: "Starburst"
        case .orbitingArcs: "Orbiting Arcs"
        case .lotus: "Lotus"
        case .vortex: "Vortex"
        }
    }

    public var group: String {
        switch self {
        case .bars, .mirroredBars, .capsuleBars, .dotWave, .recordingHistory, .oscilloscope: "Waveforms"
        case .sineWave, .layeredWaves, .siriFlow, .ribbon, .doubleHelix, .auroraCurtain, .neonRibbon: "Flow"
        case .spectrum, .mirroredSpectrum, .radialSpectrum, .starburst: "Spectrum"
        default: "Ambient"
        }
    }
}
