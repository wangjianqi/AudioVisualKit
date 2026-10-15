import SwiftUI

// Real FFT amplitude bins are required for frequency effects. If not supplied,
// spectra deliberately show a low neutral baseline, never fabricated frequencies.

extension AudioPainter {
    func spectrum(mirrored: Bool) {
        let n = min(count, 56)
        let pitch = w / CGFloat(n)
        let limit = mirrored ? h * 0.43 : h * 0.80
        for i in 0..<n {
            let power = sample(i, of: n, spectral: true)
            let height = max(1.5, power * limit)
            let width = max(1.1, pitch * 0.63)
            let x = CGFloat(i) * pitch + (pitch - width) / 2
            let y = mirrored ? center.y - height : h * 0.90 - height
            let tint = (i.isMultiple(of: 4) ? color : color.opacity(0.75))
            let bar = CGRect(x: x, y: y, width: width, height: mirrored ? height * 2 : height)
            capsule(bar, tint: tint)
        }
        if !mirrored {
            var axis = Path()
            axis.move(to: CGPoint(x: 0, y: h * 0.91))
            axis.addLine(to: CGPoint(x: w, y: h * 0.91))
            context.stroke(axis, with: .color(secondary.opacity(0.16)), lineWidth: 0.8)
        }
    }

    func radial(spectrum: Bool) {
        let n = min(76, max(24, count))
        let radius = unit * 0.21
        let extensionLimit = unit * 0.32
        for i in 0..<n {
            let angle = CGFloat(i) / CGFloat(n) * .pi * 2 - .pi / 2
            let level = sample(i, of: n, spectral: spectrum)
            let r1 = radius + 1
            let r2 = r1 + max(1.8, extensionLimit * level)
            var path = Path()
            path.move(to: CGPoint(x: center.x + cos(angle) * r1, y: center.y + sin(angle) * r1))
            path.addLine(to: CGPoint(x: center.x + cos(angle) * r2, y: center.y + sin(angle) * r2))
            context.stroke(path, with: .color(color.opacity(spectrum ? 0.65 + Double(level)*0.35 : 0.55 + Double(level)*0.45)),
                           style: StrokeStyle(lineWidth: max(1.1, unit / 150), lineCap: .round))
        }
        context.stroke(Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius,
                                               width: radius * 2, height: radius * 2)),
                       with: .color(secondary.opacity(0.22)), lineWidth: 0.8)
    }

    func starburst() {
        let n = min(80, max(32, count))
        let base = unit * 0.08
        let maximum = unit * 0.34
        for i in 0..<n {
            let theta = CGFloat(i) / CGFloat(n) * .pi * 2 - .pi / 2
            let power = sample(i, of: n, spectral: true)
            let start = base + (i.isMultiple(of: 2) ? 0 : unit * 0.01)
            let reach = start + unit * 0.03 + power * maximum
            var path = Path()
            path.move(to: CGPoint(x: center.x + cos(theta) * start, y: center.y + sin(theta) * start))
            path.addLine(to: CGPoint(x: center.x + cos(theta) * reach, y: center.y + sin(theta) * reach))
            context.stroke(path, with: .color((i.isMultiple(of: 4) ? secondary : color).opacity(0.50 + 0.50 * Double(power))),
                           style: StrokeStyle(lineWidth: max(1.1, unit * 0.009), lineCap: .round))
        }
        let r = base * 0.30 + amp * unit * 0.009
        context.fill(Path(ellipseIn: CGRect(x: center.x-r, y: center.y-r, width: r*2, height: r*2)),
                     with: .color(color.opacity(0.65)))
    }
}
