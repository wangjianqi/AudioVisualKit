import Foundation

/// Deterministic synthetic signal for previews, tests and recorded GIFs.
///
/// No microphone permission and no audio file are required, so the same frames
/// can be reproduced on CI and in App Store screenshots.
public enum DemoAudioSignal {
    /// Deterministic synthetic signal. No microphone permission is needed.
    public static func frame(at time: TimeInterval, count: Int = 64) -> AudioFrame {
        let t = time.isFinite ? time : 0
        let n = min(max(count, 8), 256)
        let beat = pow(max(0, sin(t * 3.4)), 4)
        let energy = Float(max(0.06, min(1, 0.19 + beat * 0.66 + 0.09 * sin(t * 1.3))))
        let bars = (0..<n).map { index -> Float in
            let x = Double(index) / Double(max(1, n - 1))
            let envelope = pow(max(0, sin(.pi * x)), 0.7)
            let flutter = abs(sin(x * 24.0 - t * 5.7) * cos(x * 15.0 + t * 2.1))
            return Float(min(1, 0.06 + envelope * (0.18 + 0.77 * flutter) * Double(energy)))
        }
        let bands = (0..<32).map { index -> Float in
            let x = Double(index) / 31.0
            let bandBeat = abs(sin(t * (2.6 + x) - 9 * x) * cos(t * 1.1 + x * 17))
            return Float(min(1, 0.04 + (0.4 + beat * 0.62) * pow(1 - x, 0.62) * bandBeat))
        }
        return AudioFrame(amplitude: energy, peak: min(1, energy * 1.12), levels: bars, spectrum: bands, timestamp: t)
    }
}
