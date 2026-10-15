import SwiftUI

// Flow family: layered waves, ribbon sheets, double helix, aurora curtain
// and the neon ribbon trail.

extension AudioPainter {
    /// `layers` selects the style: 1 = Sine Wave, 3 = Layered Waves, 5 = Siri Flow.
    func waves(layers: Int) {
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
    func ribbon() {
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

    func doubleHelix() {
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

    func auroraCurtain() {
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

    /// Wide low-opacity bloom beneath a thin bright core line.
    func neonRibbon() {
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
}
