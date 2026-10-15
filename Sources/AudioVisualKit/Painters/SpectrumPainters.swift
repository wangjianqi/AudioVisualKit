import SwiftUI

// Spectrum family: mirrored and normal bar spectra, radial spectrum,
// and the radial starburst. `radial(spectrum: false)` also renders the
// Ambient style `.radialWave` with the same geometry.

extension AudioPainter {
    func spectrum(mirrored: Bool) {
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

    func radial(spectrum: Bool) {
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

    func starburst() {
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
}
