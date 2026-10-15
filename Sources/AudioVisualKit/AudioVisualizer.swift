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

private struct AudioPainter {
    var context: GraphicsContext
    let size: CGSize
    let frame: AudioFrame
    let color: Color
    let secondary: Color
    let count: Int

    private var w: CGFloat { max(size.width, 1) }
    private var h: CGFloat { max(size.height, 1) }
    private var center: CGPoint { CGPoint(x: w / 2, y: h / 2) }
    private var amp: CGFloat { CGFloat(frame.amplitude) }
    private var t: CGFloat { CGFloat(frame.timestamp) }
    private var unit: CGFloat { min(w, h) }

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
        }
    }

    private func sample(_ index: Int, of total: Int, spectral: Bool = false) -> CGFloat {
        let values = spectral ? frame.spectrum : frame.levels
        guard !values.isEmpty else { return spectral ? 0 : amp * 0.75 }
        let position = CGFloat(index) / CGFloat(max(1, total - 1)) * CGFloat(values.count - 1)
        let first = min(Int(position), values.count - 1)
        let second = min(first + 1, values.count - 1)
        let f = position - CGFloat(first)
        return CGFloat(values[first]) * (1 - f) + CGFloat(values[second]) * f
    }

    private func capsule(_ rect: CGRect, tint: Color) {
        context.fill(Path(roundedRect: rect, cornerRadius: min(rect.width, rect.height) / 2), with: .color(tint))
    }

    private func bars(mirrored: Bool, capsule isCapsule: Bool, history: Bool = false) {
        let n = count
        let pitch = w / CGFloat(n)
        let width = pitch * (isCapsule ? 0.47 : 0.55)
        let limit = mirrored ? h * 0.43 : h * 0.83
        for i in 0..<n {
            let strength = sample(i, of: n)
            let value = history ? strength : max(0.035, strength)
            let barHeight = max(2, limit * value)
            let x = pitch * (CGFloat(i) + 0.5) - width / 2
            let y = mirrored ? h / 2 - barHeight : (h - barHeight) / 2
            let tint = history && i < n / 2 ? color.opacity(0.42) : color.opacity(0.9)
            capsule(CGRect(x: x, y: y, width: width, height: mirrored ? barHeight * 2 : barHeight), tint: tint)
        }
    }

    private func dots() {
        let n = min(count, 56)
        for i in 0..<n {
            let value = sample(i, of: n)
            let radius = max(1.5, min(w / CGFloat(n) * 0.24, 3.6))
            let extent = value * h * 0.38
            let positions = max(1, Int(extent / max(4, radius * 3)))
            for j in -positions...positions {
                let y = h / 2 + CGFloat(j) * radius * 2.9
                let fade = 1 - CGFloat(abs(j)) / CGFloat(positions + 1)
                let dot = CGRect(x: (CGFloat(i) + 0.5) * w / CGFloat(n) - radius, y: y - radius, width: radius * 2, height: radius * 2)
                context.fill(Path(ellipseIn: dot), with: .color(color.opacity(Double(0.35 + fade * 0.65))))
            }
        }
    }

    private func waves(layers: Int) {
        let n = 120
        for layer in 0..<layers {
            let phase = CGFloat(layer) * 0.91
            let gain = max(0.08, amp) * (0.83 - CGFloat(layer) * 0.11)
            var path = Path()
            for i in 0...n {
                let progress = CGFloat(i) / CGFloat(n)
                let envelope = pow(max(0, 1 - abs(progress * 2 - 1)), 1.65)
                let frequency = CGFloat(layer % 2 == 0 ? 2.7 : 3.8)
                let height = sin(progress * .pi * frequency * 2 - t * (1.7 + CGFloat(layer) * 0.15) + phase)
                    * envelope * h * 0.43 * gain
                let drift = layers >= 4 ? sin(progress * 10 + t * 0.8 + phase) * h * 0.025 : 0
                let point = CGPoint(x: progress * w, y: h / 2 + height + drift)
                if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
            let tint = layer == 0 ? color : secondary.opacity(0.42 + Double(layer % 3) * 0.15)
            context.stroke(path, with: .color(tint), style: StrokeStyle(lineWidth: layer == 0 ? 2.4 : 1.3, lineCap: .round, lineJoin: .round))
        }
    }

    private func ribbon() {
        let n = 144
        var path = Path()
        for pass in 0..<2 {
            for i in 0...n {
                let p = CGFloat(i) / CGFloat(n)
                let idx = pass == 0 ? i : n - i
                let x = CGFloat(idx) / CGFloat(n) * w
                let envelope = pow(max(0, 1 - abs(p * 2 - 1)), 1.35)
                let offset = sin(x / w * 10 - t * 1.8) * h * 0.19 * amp * envelope
                let thickness = (0.04 + amp * 0.19) * h * envelope
                let point = CGPoint(x: x, y: h / 2 + offset + (pass == 0 ? -thickness : thickness))
                if pass == 0 && i == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
        }
        path.closeSubpath()
        context.fill(path, with: .linearGradient(Gradient(colors: [color.opacity(0.8), secondary.opacity(0.32), color.opacity(0.68)]), startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: w, y: h)))
    }

    private func spectrum(mirrored: Bool) {
        let n = min(count, 64)
        let pitch = w / CGFloat(n)
        let limit = mirrored ? h * 0.45 : h * 0.85
        for i in 0..<n {
            let height = max(1.4, sample(i, of: n, spectral: true) * limit)
            let width = pitch * 0.54
            let x = CGFloat(i) * pitch + (pitch - width) / 2
            let y = mirrored ? h / 2 - height : h - height - h * 0.075
            let tint = i % 4 == 0 ? color : color.opacity(0.68)
            capsule(CGRect(x: x, y: y, width: width, height: height * (mirrored ? 2 : 1)), tint: tint)
        }
    }

    private func radial(spectrum: Bool) {
        let n = min(96, max(24, count * 2))
        let radius = unit * 0.21
        let extensionLimit = unit * 0.24
        for i in 0..<n {
            let angle = CGFloat(i) / CGFloat(n) * .pi * 2 - .pi / 2
            let level = sample(i, of: n, spectral: spectrum)
            let r1 = radius + 1
            let r2 = r1 + max(2.5, extensionLimit * level)
            var path = Path()
            path.move(to: CGPoint(x: center.x + cos(angle) * r1, y: center.y + sin(angle) * r1))
            path.addLine(to: CGPoint(x: center.x + cos(angle) * r2, y: center.y + sin(angle) * r2))
            context.stroke(path, with: .color(color.opacity(spectrum ? 0.8 : 0.55 + Double(level) * 0.45)), style: StrokeStyle(lineWidth: max(1.2, unit / 180), lineCap: .round))
        }
        context.stroke(Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)), with: .color(secondary.opacity(0.3)), lineWidth: 1)
    }

    private func rings() {
        let base = unit * 0.12
        for i in 0..<4 {
            let phase = (t * 0.48 + CGFloat(i) / 4).truncatingRemainder(dividingBy: 1)
            let radius = base + phase * unit * (0.27 + amp * 0.13)
            let opacity = Double((1 - phase) * (0.12 + amp * 0.78))
            let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
            context.stroke(Path(ellipseIn: rect), with: .color(color.opacity(opacity)), lineWidth: max(1, 3 * (1 - phase)))
        }
        context.fill(Path(ellipseIn: CGRect(x: center.x - base, y: center.y - base, width: base * 2, height: base * 2)), with: .color(color.opacity(0.65)))
    }

    private func orb() {
        let radius = unit * (0.16 + amp * 0.12)
        let outer = radius * 1.65
        let bounds = CGRect(x: center.x - outer, y: center.y - outer, width: outer * 2, height: outer * 2)
        context.fill(Path(ellipseIn: bounds), with: .radialGradient(Gradient(colors: [color.opacity(0.42), secondary.opacity(0.19), .clear]), center: center, startRadius: 0, endRadius: outer))
        let core = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        context.fill(Path(ellipseIn: core), with: .radialGradient(Gradient(colors: [color.opacity(0.96), color.opacity(0.43)]), center: CGPoint(x: center.x - radius * 0.3, y: center.y - radius * 0.4), startRadius: 1, endRadius: radius * 1.65))
        for i in 0..<3 {
            let r = radius + CGFloat(i + 1) * unit * 0.055 + sin(t * 1.5 + CGFloat(i)) * unit * 0.008
            context.stroke(Path(ellipseIn: CGRect(x: center.x-r, y: center.y-r, width: r*2, height: r*2)), with: .color(secondary.opacity(Double(max(0.09, amp * 0.37)))), lineWidth: 1)
        }
    }

    private func particles() {
        let n = min(96, count * 2)
        for i in 0..<n {
            let seed = CGFloat(i) * 2.39996323
            let radial = sqrt((CGFloat(i) + 0.5) / CGFloat(n))
            let angle = seed + t * (0.16 + 0.2 * amp)
            let r = radial * unit * (0.3 + amp * 0.15)
            let x = center.x + cos(angle) * r
            let y = center.y + sin(angle) * r * 0.7
            let pointRadius = max(0.8, (1 - radial) * 2.2 + amp)
            let opacity = 0.2 + (1 - radial) * 0.7
            context.fill(Path(ellipseIn: CGRect(x: x-pointRadius, y: y-pointRadius, width: pointRadius*2, height: pointRadius*2)), with: .color(color.opacity(Double(opacity))))
        }
    }
}
