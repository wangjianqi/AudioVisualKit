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

    /// Three animated translucent sheets, rather than one flattened diamond shape.
    /// The two edges of every sheet use the same x domain and opposite offsets.
    private func ribbon() {
        let n = 150
        let strength = 0.32 + amp * 0.68
        for layer in (0..<3).reversed() {
            let offset = CGFloat(layer) * 0.95
            let thickness = h * (0.08 + amp * 0.105) * (1 - CGFloat(layer) * 0.17)
            let waveHeight = h * (0.12 + amp * 0.10)
            var top = [CGPoint]()
            var bottom = [CGPoint]()
            for i in 0...n {
                let x = CGFloat(i) / CGFloat(n)
                let edge = pow(max(0, sin(x * .pi)), 1.25)
                let sway = sin(x * (2.5 + CGFloat(layer) * 0.33) * .pi - t * (1.3 + CGFloat(layer) * 0.15) + offset)
                let drift = cos(x * 3.8 * .pi + t * 0.73 + offset) * 0.3
                let mid = h * 0.5 + (sway + drift) * waveHeight * edge * strength
                let half = thickness * edge * (0.52 + 0.48 * abs(cos(x * 3.1 * .pi - t * 0.55 + offset)))
                top.append(CGPoint(x: x * w, y: mid - half))
                bottom.append(CGPoint(x: x * w, y: mid + half))
            }
            var fill = Path()
            for (i, point) in top.enumerated() {
                if i == 0 { fill.move(to: point) } else { fill.addLine(to: point) }
            }
            for point in bottom.reversed() { fill.addLine(to: point) }
            fill.closeSubpath()
            let alpha = 0.14 + Double(2 - layer) * 0.09
            context.fill(fill, with: .linearGradient(
                Gradient(colors: [secondary.opacity(alpha), color.opacity(alpha + 0.22), secondary.opacity(alpha)]),
                startPoint: CGPoint(x: 0, y: h * 0.20), endPoint: CGPoint(x: w, y: h * 0.80)))
            var edge = Path()
            for (i, point) in top.enumerated() {
                if i == 0 { edge.move(to: point) } else { edge.addLine(to: point) }
            }
            context.stroke(edge, with: .color(color.opacity(0.25 + Double(2 - layer) * 0.23)),
                           style: StrokeStyle(lineWidth: layer == 0 ? 1.3 : 0.8, lineCap: .round))
        }
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

    // MARK: - Expanded visual collection

    private func oscilloscope() {
        let n = 180
        let mid = h / 2
        var baseline = Path()
        baseline.move(to: CGPoint(x: 0, y: mid))
        baseline.addLine(to: CGPoint(x: w, y: mid))
        context.stroke(baseline, with: .color(secondary.opacity(0.18)), lineWidth: 0.8)
        for trace in 0..<3 {
            var path = Path()
            for i in 0...n {
                let x = CGFloat(i) / CGFloat(n)
                let envelope = 0.18 + 0.82 * pow(max(0, sin(x * .pi)), 0.8)
                let v = sample(i, of: n)
                let y = mid + (sin(x * 12 * .pi - t * 6 + CGFloat(trace) * 0.27) * 0.70
                  + sin(x * 30 * .pi + t * 4.2 + CGFloat(trace)) * 0.30)
                    * h * 0.32 * (0.2 + amp * 0.75) * envelope * (0.55 + v * 0.45)
                let point = CGPoint(x: x * w, y: y)
                if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
            context.stroke(path, with: .color(color.opacity(trace == 0 ? 0.95 : 0.16)),
                           style: StrokeStyle(lineWidth: trace == 0 ? 2.0 : 4.0 + CGFloat(trace) * 2,
                                              lineCap: .round, lineJoin: .round))
        }
    }

    private func doubleHelix() {
        let n = 130
        let magnitude = h * (0.15 + amp * 0.19)
        for strand in 0..<2 {
            let phase: CGFloat = strand == 0 ? 0 : .pi
            var path = Path()
            for i in 0...n {
                let x = CGFloat(i) / CGFloat(n)
                let envelope = pow(max(0, sin(x * .pi)), 0.7)
                let y = center.y + sin(x * 5.2 * .pi - t * 2.2 + phase) * magnitude * envelope
                let point = CGPoint(x: w * x, y: y)
                if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
            context.stroke(path, with: .color((strand == 0 ? color : secondary).opacity(0.90)),
                           style: StrokeStyle(lineWidth: strand == 0 ? 2.4 : 1.9, lineCap: .round))
        }
        for i in 1..<24 {
            let x = CGFloat(i) / 24
            let envelope = pow(max(0, sin(x * .pi)), 0.7)
            let offset = sin(x * 5.2 * .pi - t * 2.2) * magnitude * envelope
            var rung = Path()
            rung.move(to: CGPoint(x: w * x, y: center.y - offset))
            rung.addLine(to: CGPoint(x: w * x, y: center.y + offset))
            context.stroke(rung, with: .color(color.opacity(0.10 + Double(amp) * 0.13)), lineWidth: 1)
        }
    }

    private func auroraCurtain() {
        let n = 100
        for layer in (0..<5).reversed() {
            let shift = CGFloat(layer) * 0.63
            let base = h * (0.38 + CGFloat(layer) * 0.035)
            var path = Path()
            path.move(to: CGPoint(x: 0, y: h * 0.94))
            for i in 0...n {
                let x = CGFloat(i) / CGFloat(n)
                let envelope = pow(max(0, sin(x * .pi)), 0.85)
                let y = base + sin(x * 3.7 * .pi - t * 1.2 + shift) * h * (0.1 + amp * 0.16) * envelope
                    + cos(x * 7.7 * .pi + t * 0.54 + shift) * h * 0.026 * envelope
                path.addLine(to: CGPoint(x: x * w, y: y))
            }
            path.addLine(to: CGPoint(x: w, y: h * 0.94))
            path.closeSubpath()
            context.fill(path, with: .linearGradient(
                Gradient(colors: [color.opacity(0.04 + Double(amp) * 0.05),
                                  (layer.isMultiple(of: 2) ? secondary : color).opacity(0.09 + Double(amp) * 0.13), .clear]),
                startPoint: CGPoint(x: w / 2, y: h * 0.32), endPoint: CGPoint(x: w / 2, y: h * 0.97)))
        }
    }

    private func neonRibbon() {
        let n = 160
        let envelope: (CGFloat) -> CGFloat = { pow(max(0, sin($0 * .pi)), 1.4) }
        for trail in 0..<4 {
            let phase = CGFloat(trail) * 0.55
            let attenuation = 1 - CGFloat(trail) * 0.12
            var path = Path()
            for i in 0...n {
                let x = CGFloat(i) / CGFloat(n)
                let y = center.y + (sin(x * 5.5 * .pi - t * 2.3 + phase) * 0.77
                      + cos(x * 9 * .pi + t * 1.1 + phase) * 0.23)
                      * h * (0.15 + amp * 0.19) * envelope(x) * attenuation
                let point = CGPoint(x: w * x, y: y)
                if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
            context.stroke(path, with: .color(color.opacity(trail == 0 ? 0.11 : 0.035)),
                           style: StrokeStyle(lineWidth: trail == 0 ? 11 : 7, lineCap: .round, lineJoin: .round))
            context.stroke(path, with: .color((trail.isMultiple(of: 2) ? color : secondary).opacity(0.87 - Double(trail) * 0.16)),
                           style: StrokeStyle(lineWidth: trail == 0 ? 2.3 : 1.2, lineCap: .round, lineJoin: .round))
        }
    }

    private func starburst() {
        let n = min(100, max(36, count * 2))
        let base = unit * 0.09
        let maximum = unit * 0.39
        for i in 0..<n {
            let theta = CGFloat(i) / CGFloat(n) * .pi * 2 - .pi / 2
            let power = sample(i, of: n, spectral: true)
            let start = base + (i.isMultiple(of: 2) ? 0 : unit * 0.015)
            let reach = start + unit * 0.04 + power * maximum
            var path = Path()
            path.move(to: CGPoint(x: center.x + cos(theta) * start, y: center.y + sin(theta) * start))
            path.addLine(to: CGPoint(x: center.x + cos(theta) * reach, y: center.y + sin(theta) * reach))
            context.stroke(path, with: .color((i.isMultiple(of: 4) ? secondary : color).opacity(0.44 + 0.52 * Double(power))),
                           style: StrokeStyle(lineWidth: max(1.2, unit * 0.005), lineCap: .round))
        }
        let r = base * 0.64 + amp * unit * 0.016
        context.fill(Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: 2*r, height: 2*r)),
                     with: .color(color.opacity(0.72)))
    }

    private func orbitingArcs() {
        for ring in 0..<4 {
            let r = unit * (0.12 + CGFloat(ring) * 0.072)
            let offset = t * (ring.isMultiple(of: 2) ? 0.52 : -0.4) + CGFloat(ring) * 1.1
            var path = Path()
            let segments = 38
            for i in 0...segments {
                let theta = offset + CGFloat(i) / CGFloat(segments) * (.pi * (0.42 + amp * 0.32))
                let point = CGPoint(x: center.x + cos(theta) * r, y: center.y + sin(theta) * r)
                if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
            context.stroke(path, with: .color((ring.isMultiple(of: 2) ? color : secondary).opacity(0.92 - Double(ring) * 0.15)),
                           style: StrokeStyle(lineWidth: 1.2 + CGFloat(ring % 2), lineCap: .round))
            let ending = offset + .pi * (0.42 + amp * 0.32)
            let size = unit * (0.009 + amp * 0.009)
            context.fill(Path(ellipseIn: CGRect(x: center.x + cos(ending)*r - size,
                                               y: center.y + sin(ending)*r - size,
                                               width: 2*size, height: 2*size)), with: .color(color.opacity(0.85)))
        }
    }

    private func lotus() {
        let count = 10
        let r = unit * (0.19 + amp * 0.07)
        for i in 0..<count {
            let angle = CGFloat(i) * 2 * .pi / CGFloat(count) + t * 0.11
            let length = r * (0.85 + sample(i, of: count) * 0.55)
            let end = CGPoint(x: center.x + cos(angle)*length, y: center.y + sin(angle)*length)
            let axis = CGPoint(x: -sin(angle), y: cos(angle))
            let spread = r * (0.31 + amp * 0.16)
            var petal = Path()
            petal.move(to: center)
            petal.addQuadCurve(to: end, control: CGPoint(x: center.x + cos(angle)*r*0.42 + axis.x*spread,
                                                        y: center.y + sin(angle)*r*0.42 + axis.y*spread))
            petal.addQuadCurve(to: center, control: CGPoint(x: center.x + cos(angle)*r*0.42 - axis.x*spread,
                                                           y: center.y + sin(angle)*r*0.42 - axis.y*spread))
            context.fill(petal, with: .color((i.isMultiple(of: 2) ? color : secondary).opacity(0.08 + Double(sample(i, of: count)) * 0.22)))
            context.stroke(petal, with: .color(color.opacity(0.23 + Double(sample(i, of: count)) * 0.5)), lineWidth: 1)
        }
        let dot = unit * (0.014 + amp * 0.02)
        context.fill(Path(ellipseIn: CGRect(x: center.x-dot, y: center.y-dot, width: dot*2, height: dot*2)),
                     with: .color(color.opacity(0.85)))
    }

    private func vortex() {
        let turns: CGFloat = 3.4
        let n = 240
        for strand in 0..<3 {
            var path = Path()
            for i in 0...n {
                let progress = CGFloat(i) / CGFloat(n)
                let angle = progress * turns * 2 * .pi + t * (0.36 + CGFloat(strand) * 0.09) + CGFloat(strand) * .pi * 2 / 3
                let radius = unit * (0.02 + progress * (0.32 + amp * 0.12))
                let point = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
                if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
            context.stroke(path, with: .color((strand == 0 ? color : secondary).opacity(0.81 - Double(strand) * 0.2)),
                           style: StrokeStyle(lineWidth: 1.2 + CGFloat(strand == 0 ? 0.8 : 0), lineCap: .round))
        }
    }

}
