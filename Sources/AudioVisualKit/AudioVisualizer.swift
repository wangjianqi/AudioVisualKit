import SwiftUI

/// A transparent, purely presentational view. Drive it from any `AudioFrame` producer.
/// The hosting view owns the display clock so a gallery can share one TimelineView.
public struct AudioVisualizer: View {
    public let style: AudioVisualizationStyle
    public let frame: AudioFrame
    public let color: Color
    public let secondaryColor: Color
    public let density: Int

    public init(
        style: AudioVisualizationStyle,
        frame: AudioFrame,
        color: Color = .white,
        secondaryColor: Color = .gray,
        density: Int = 48
    ) {
        self.style = style
        self.frame = frame
        self.color = color
        self.secondaryColor = secondaryColor
        self.density = min(max(density, 8), 128)
    }

    public var body: some View {
        Canvas(rendersAsynchronously: true) { context, size in
            var painter = AudioPainter(
                context: context, size: size, frame: frame,
                color: color, secondary: secondaryColor, count: density
            )
            painter.draw(style)
        }
        .accessibilityLabel("\(style.title) audio visualization")
        .accessibilityAddTraits(.isImage)
    }
}

/// One-shot renderer for a single `AudioVisualizationStyle`.
///
/// The painter is a pure function of `frame`, `size` and time: it allocates no state,
/// owns no timers and never touches audio hardware. Implementations are grouped per
/// effect family in `Painters/`.
struct AudioPainter {
    var context: GraphicsContext
    let size: CGSize
    let frame: AudioFrame
    let color: Color
    let secondary: Color
    let count: Int

    var w: CGFloat { max(size.width, 1) }
    var h: CGFloat { max(size.height, 1) }
    var center: CGPoint { CGPoint(x: w / 2, y: h / 2) }
    var amp: CGFloat { CGFloat(frame.amplitude) }
    var t: CGFloat { CGFloat(frame.timestamp) }
    var unit: CGFloat { min(w, h) }

    /// Dispatches a style to its painter. A new style needs a case here and one
    /// painter method in the matching family file.
    mutating func draw(_ style: AudioVisualizationStyle) {
        switch style {
        case .bars: bars(mirrored: false, capsule: false)
        case .mirroredBars: bars(mirrored: true, capsule: false)
        case .capsuleBars: bars(mirrored: false, capsule: true)
        case .dotWave: dots()
        case .recordingHistory: bars(mirrored: false, capsule: true, history: true)
        case .sineWave: waves(layers: 1)
        case .layeredWaves: waves(layers: 3)
        case .siriFlow: waves(layers: 5)
        case .ribbon: ribbon()
        case .spectrum: spectrum(mirrored: false)
        case .mirroredSpectrum: spectrum(mirrored: true)
        case .radialSpectrum: radial(spectrum: true)
        case .radialWave: radial(spectrum: false)
        case .pulseRings: rings()
        case .energyOrb: orb()
        case .particles: particles()
        case .oscilloscope: oscilloscope()
        case .doubleHelix: doubleHelix()
        case .auroraCurtain: auroraCurtain()
        case .neonRibbon: neonRibbon()
        case .starburst: starburst()
        case .orbitingArcs: orbitingArcs()
        case .lotus: lotus()
        case .vortex: vortex()
        }
    }

    /// Linear interpolation into the normalized history or spectrum bins.
    /// Falls back to the overall amplitude when a bin array was not supplied.
    func sample(_ index: Int, of total: Int, spectral: Bool = false) -> CGFloat {
        let values = spectral ? frame.spectrum : frame.levels
        guard !values.isEmpty else { return spectral ? 0 : amp * 0.75 }
        let position = CGFloat(index) / CGFloat(max(1, total - 1)) * CGFloat(values.count - 1)
        let first = min(Int(position), values.count - 1)
        let second = min(first + 1, values.count - 1)
        let f = position - CGFloat(first)
        return CGFloat(values[first]) * (1 - f) + CGFloat(values[second]) * f
    }

    func capsule(_ rect: CGRect, tint: Color) {
        context.fill(Path(roundedRect: rect, cornerRadius: min(rect.width, rect.height) / 2), with: .color(tint))
    }
}
