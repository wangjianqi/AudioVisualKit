import SwiftUI

// Waveform family: bars, mirrored bars, capsule bars, dot wave,
// recording history and the oscilloscope trace.

extension AudioPainter {
    func bars(mirrored: Bool, capsule isCapsule: Bool, history: Bool = false) {
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

    func dots() {
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

    /// Three phosphor traces over a faint center baseline.
    func oscilloscope() {
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
}
