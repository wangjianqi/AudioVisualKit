import SwiftUI

extension AudioPainter {
    /// Ordinary bars grow upward from a bottom baseline; mirrored bars grow about the center;
    /// capsules float at midline. These are distinct geometries, not variations of one capsule.
    func bars(mirrored: Bool, capsule isCapsule: Bool) {
        let n = count
        let pitch = w / CGFloat(n)
        let barWidth = pitch * (isCapsule ? 0.42 : 0.65)
        let baseline = h * 0.88
        for i in 0..<n {
            let strength = max(0.018, sample(i, of: n))
            let x = pitch * (CGFloat(i) + 0.5) - barWidth / 2
            let tint = color.opacity(0.50 + Double(strength) * 0.5)
            if mirrored {
                let half = max(1.3, h * 0.43 * strength)
                let rect = CGRect(x: x, y: center.y - half, width: barWidth, height: half * 2)
                context.fill(Path(rect), with: .color(tint))
            } else if isCapsule {
                let height = max(barWidth, h * 0.74 * strength)
                let rect = CGRect(x: x, y: center.y - height / 2, width: barWidth, height: height)
                capsule(rect, tint: tint)
            } else {
                let height = max(1.5, h * 0.80 * strength)
                context.fill(Path(CGRect(x: x, y: baseline - height, width: barWidth, height: height)), with: .color(tint))
            }
        }
        if !isCapsule && !mirrored {
            var line = Path()
            line.move(to: CGPoint(x: 0, y: baseline + 1))
            line.addLine(to: CGPoint(x: w, y: baseline + 1))
            context.stroke(line, with: .color(secondary.opacity(0.19)), lineWidth: 0.8)
        }
    }

    /// Time-ordered loudness history, newest on the right, with a visible recording head.
    func recordingHistory() {
        let n = min(count, 72)
        let pitch = w / CGFloat(n)
        let barWidth = pitch * 0.50
        for i in 0..<n {
            let value = historySample(i, of: n)
            let height = max(1.6, value * h * 0.80)
            let x = pitch * (CGFloat(i) + 0.5) - barWidth / 2
            let recency = CGFloat(i) / CGFloat(max(1, n - 1))
            let opacity = 0.24 + Double(recency) * 0.72
            capsule(CGRect(x: x, y: center.y - height / 2, width: barWidth, height: height), tint: color.opacity(opacity))
        }
        var head = Path()
        head.move(to: CGPoint(x: w - 1, y: h * 0.12))
        head.addLine(to: CGPoint(x: w - 1, y: h * 0.88))
        context.stroke(head, with: .color(color.opacity(0.8)), lineWidth: 1.2)
    }

    /// A dotted oscillating signal line, not an elliptical block of dots.
    func dots() {
        let n = min(count, 72)
        let radius = max(1.2, min(w / CGFloat(n) * 0.24, 3.2))
        for i in 0..<n {
            let x = CGFloat(i) / CGFloat(max(1, n - 1))
            let energy = sample(i, of: n)
            let envelope = pow(max(0, sin(x * .pi)), 0.6)
            let y = center.y + sin(x * .pi * 7 - t * 2.8) * h * 0.40 * energy * envelope
            let r = radius * (0.75 + energy * 0.48)
            context.fill(Path(ellipseIn: CGRect(x: x * w - r, y: y - r, width: 2*r, height: 2*r)),
                         with: .color(color.opacity(0.38 + 0.62 * Double(energy))))
        }
    }

    /// Real signed PCM trace. Missing PCM is an intentionally flat baseline.
    func oscilloscope() {
        let n = min(256, max(96, frame.samples.count))
        var baseline = Path()
        baseline.move(to: CGPoint(x: 0, y: center.y))
        baseline.addLine(to: CGPoint(x: w, y: center.y))
        context.stroke(baseline, with: .color(secondary.opacity(0.22)), lineWidth: 0.8)
        guard !frame.samples.isEmpty else { return }
        var trace = Path()
        for i in 0...n {
            let x = CGFloat(i) / CGFloat(n)
            let value = pcmSample(i, of: n + 1)
            let point = CGPoint(x: x*w, y: center.y - value * h * 0.43)
            if i == 0 { trace.move(to: point) } else { trace.addLine(to: point) }
        }
        context.stroke(trace, with: .color(color.opacity(0.10)), style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
        context.stroke(trace, with: .color(color.opacity(0.23)), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
        context.stroke(trace, with: .color(color.opacity(0.96)), style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
    }
}
