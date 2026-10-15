import SwiftUI

// Ambient family: radial wave, pulse rings, energy orb, particles,
// orbiting arcs, lotus and vortex.

extension AudioPainter {
    func rings() {
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

    /// Pulsing energy core with audio-modulated orbital contours and luminous lobes.
    func orb() {
        let base = unit * (0.15 + amp * 0.07)
        let aura = base * 2.35
        let halo = CGRect(x: center.x-aura, y: center.y-aura, width: 2*aura, height: 2*aura)
        context.fill(Path(ellipseIn: halo), with: .radialGradient(
            Gradient(colors: [color.opacity(0.33), secondary.opacity(0.13), .clear]),
            center: center, startRadius: 0, endRadius: aura))
        let coreRadius = base * (0.78 + 0.06 * sin(t * 2.8))
        let core = CGRect(x: center.x-coreRadius, y: center.y-coreRadius,
                          width: 2*coreRadius, height: 2*coreRadius)
        context.fill(Path(ellipseIn: core), with: .radialGradient(
            Gradient(colors: [color.opacity(0.92), color.opacity(0.3), secondary.opacity(0.08)]),
            center: CGPoint(x: center.x-coreRadius*0.25, y: center.y-coreRadius*0.3),
            startRadius: 0, endRadius: coreRadius*1.4))
        for contour in 0..<4 {
            let segments = 120
            var path = Path()
            let baseRadius = base * (1.15 + CGFloat(contour) * 0.23)
            for i in 0...segments {
                let theta = CGFloat(i) / CGFloat(segments) * 2 * .pi
                let fluctuation = sin(theta * CGFloat(6 + contour * 2) - t * (1.9 + CGFloat(contour)*0.2))
                    * base * (0.045 + amp * 0.19)
                let radius = baseRadius + fluctuation
                let point = CGPoint(x: center.x + cos(theta)*radius, y: center.y + sin(theta)*radius)
                if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
            context.stroke(path, with: .color((contour.isMultiple(of: 2) ? color : secondary)
                .opacity(0.48 - Double(contour)*0.085)),
                style: StrokeStyle(lineWidth: contour == 0 ? 1.55 : 0.8, lineCap: .round))
        }
    }

    func particles() {
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

    func orbitingArcs() {
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

    func lotus() {
        let petals = 10
        let r = unit * (0.19 + amp * 0.07)
        for i in 0..<petals {
            let angle = CGFloat(i) * 2 * .pi / CGFloat(petals) + t * 0.11
            let length = r * (0.85 + sample(i, of: petals) * 0.55)
            let end = CGPoint(x: center.x + cos(angle)*length, y: center.y + sin(angle)*length)
            let axis = CGPoint(x: -sin(angle), y: cos(angle))
            let spread = r * (0.31 + amp * 0.16)
            var petal = Path()
            petal.move(to: center)
            petal.addQuadCurve(to: end, control: CGPoint(x: center.x + cos(angle)*r*0.42 + axis.x*spread,
                                                        y: center.y + sin(angle)*r*0.42 + axis.y*spread))
            petal.addQuadCurve(to: center, control: CGPoint(x: center.x + cos(angle)*r*0.42 - axis.x*spread,
                                                           y: center.y + sin(angle)*r*0.42 - axis.y*spread))
            context.fill(petal, with: .color((i.isMultiple(of: 2) ? color : secondary).opacity(0.08 + Double(sample(i, of: petals)) * 0.22)))
            context.stroke(petal, with: .color(color.opacity(0.23 + Double(sample(i, of: petals)) * 0.5)), lineWidth: 1)
        }
        let dot = unit * (0.014 + amp * 0.02)
        context.fill(Path(ellipseIn: CGRect(x: center.x-dot, y: center.y-dot, width: dot*2, height: dot*2)),
                     with: .color(color.opacity(0.85)))
    }

    func vortex() {
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
