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

    /// A continuous voice-energy envelope with two travelling bright filaments.
    /// Unlike `layeredWaves`, energy is centered and each band has its own phase/decay.
    func siriFlow() {
        let segments = 180
        let energy = 0.20 + amp * 0.80
        for layer in (0..<6).reversed() {
            let phase = CGFloat(layer) * .pi / 3
            let frequency = 2.6 + CGFloat(layer % 3) * 0.5
            let width = layer == 0 ? 2.4 : 1.1
            var path = Path()
            for i in 0...segments {
                let x = CGFloat(i) / CGFloat(segments)
                let envelope = pow(max(0, sin(x * .pi)), 2.0)
                let carrier = sin(x * .pi * frequency * 2 - t * (1.4 + CGFloat(layer) * 0.09) + phase)
                let modulation = cos(x * .pi * 3.2 + t * 0.71 - phase) * 0.35
                let y = center.y + (carrier + modulation) * h * 0.36 * energy * envelope
                let point = CGPoint(x: x*w, y: y)
                if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
            let tint = layer.isMultiple(of: 2) ? color : secondary
            if layer == 0 {
                context.stroke(path, with: .color(color.opacity(0.12)), style: StrokeStyle(lineWidth: 9, lineCap: .round))
            }
            context.stroke(path, with: .color(tint.opacity(layer == 0 ? 1 : 0.24 + Double(5 - layer) * 0.09)),
                           style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
        }
        // A fine stationary energy axis anchors the assistant wave near silence.
        var axis = Path()
        axis.move(to: CGPoint(x: 0, y: center.y))
        axis.addLine(to: CGPoint(x: w, y: center.y))
        context.stroke(axis, with: .color(secondary.opacity(0.16)), lineWidth: 0.7)
    }

    /// A two-strand helix: the front strand changes with depth and the rungs
    /// fade at crossings. It remains legible even in the small Minimal cells.
    func doubleHelix() {
        let n = 150
        let magnitude = h * (0.13 + amp * 0.23)
        func point(_ x: CGFloat, phase: CGFloat) -> CGPoint {
            let envelope = pow(max(0, sin(x * .pi)), 0.65)
            let theta = x * 5.5 * .pi - t * 1.9 + phase
            return CGPoint(x: x*w, y: center.y + sin(theta) * magnitude * envelope)
        }
        for i in 1..<36 {
            let x = CGFloat(i) / 36
            let angle = x * 5.5 * .pi - t * 1.9
            let a = point(x, phase: 0)
            let b = point(x, phase: .pi)
            var rung = Path()
            rung.move(to: a)
            rung.addLine(to: b)
            context.stroke(rung, with: .color(secondary.opacity(0.10 + 0.25 * abs(Double(cos(angle))))), lineWidth: 1)
        }
        // Draw behind strand first, then highlight near-facing half of helix.
        for strand in 0..<2 {
            let phase: CGFloat = strand == 0 ? 0 : .pi
            var path = Path()
            for i in 0...n {
                let x = CGFloat(i) / CGFloat(n)
                let p = point(x, phase: phase)
                if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
            }
            context.stroke(path, with: .color((strand == 0 ? color : secondary).opacity(0.54)),
                           style: StrokeStyle(lineWidth: 1.55, lineCap: .round))
            // Short highlights alternate at each twist to convey crossing depth.
            for turn in 0..<6 {
                var highlight = Path()
                for j in 0...24 {
                    let x = (CGFloat(turn) + CGFloat(j) / 24 * 0.48) / 5.8
                    let p = point(min(1, x), phase: phase)
                    if j == 0 { highlight.move(to: p) } else { highlight.addLine(to: p) }
                }
                context.stroke(highlight, with: .color(color.opacity(0.55)),
                               style: StrokeStyle(lineWidth: 2.0, lineCap: .round))
            }
        }
    }

    /// Translucent vertical aurora curtains rather than solid mountain-shaped sheets.
    func auroraCurtain() {
        let columns = 32
        let strength = 0.20 + amp * 0.80
        for layer in (0..<4).reversed() {
            let phase = CGFloat(layer) * 0.85
            let topBase = h * (0.20 + CGFloat(layer) * 0.07)
            let height = h * (0.34 + amp * 0.25 - CGFloat(layer) * 0.035)
            // Each strip fades vertically; shifting wave phase imparts curtain-like motion.
            for column in 0..<columns {
                let x0 = CGFloat(column) / CGFloat(columns)
                let x1 = CGFloat(column + 1) / CGFloat(columns)
                let x = (x0 + x1) * 0.5
                let envelope = pow(max(0, sin(x * .pi)), 0.55)
                let rippling = sin(x * 5 * .pi - t * 1.1 + phase) * h * 0.095 * strength
                    + sin(x * 13 * .pi + t * 0.6 + phase) * h * 0.02
                let top = topBase + rippling * envelope
                let bottom = top + height * envelope
                var strip = Path()
                strip.move(to: CGPoint(x: x0*w, y: top))
                strip.addLine(to: CGPoint(x: x1*w, y: top + h * 0.01))
                strip.addLine(to: CGPoint(x: x1*w, y: bottom))
                strip.addLine(to: CGPoint(x: x0*w, y: bottom))
                strip.closeSubpath()
                let brightness = 0.08 + 0.14 * (1 + cos(x*12 + phase)) * 0.5
                context.fill(strip, with: .linearGradient(
                    Gradient(colors: [color.opacity(Double(brightness) + Double(amp)*0.08),
                                      (layer.isMultiple(of: 2) ? color : secondary).opacity(0.11), .clear]),
                    startPoint: CGPoint(x: x*w, y: top), endPoint: CGPoint(x: x*w, y: bottom)))
            }
            var crest = Path()
            for i in 0...120 {
                let x = CGFloat(i) / 120
                let envelope = pow(max(0, sin(x * .pi)), 0.55)
                let y = topBase + (sin(x * 5 * .pi - t * 1.1 + phase) * h * 0.095 * strength
                    + sin(x * 13 * .pi + t * 0.6 + phase) * h * 0.02) * envelope
                if i == 0 { crest.move(to: CGPoint(x: x*w, y: y)) }
                else { crest.addLine(to: CGPoint(x: x*w, y: y)) }
            }
            context.stroke(crest, with: .color(color.opacity(0.24)), lineWidth: 0.8)
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
