import Foundation

/// A deterministic, reproducible complete audio signal for previews and GIF captures.
/// The PCM/history/frequency inputs are all populated; painters never have to fake FFT data.
public enum DemoAudioSignal {
    public static func frame(at time: TimeInterval, count: Int = 64) -> AudioFrame {
        let t = time.isFinite ? time : 0
        let n = min(max(count, 8), 256)
        func loudness(_ instant: Double) -> Float {
            let beat = pow(max(0, sin(instant * 3.4)), 4)
            return Float(max(0.06, min(1, 0.17 + beat * 0.67 + 0.08 * sin(instant * 1.3))))
        }
        let energy = loudness(t)
        let bars = (0..<n).map { index -> Float in
            let x = Double(index) / Double(max(1, n - 1))
            let envelope = pow(max(0, sin(.pi * x)), 0.7)
            let flutter = abs(sin(x * 24 - t * 5.7) * cos(x * 15 + t * 2.1))
            return Float(min(1, 0.05 + envelope * (0.22 + 0.75 * flutter) * Double(energy)))
        }
        let bands = (0..<32).map { index -> Float in
            let x = Double(index) / 31.0
            let beat = abs(sin(t * (2.6 + x) - 9 * x) * cos(t * 1.1 + x * 17))
            let weightedEnergy = 0.5 + Double(energy) * 0.62
            let spectralShape = pow(1.0 - x, 0.55)
            let magnitude = 0.09 + weightedEnergy * spectralShape * beat
            return Float(min(1.0, magnitude))
        }
        let history = (0..<64).map { index in
            loudness(t - Double(63 - index) / 18.0)
        }
        // Bipolar PCM model, using an effective 256-sample oscilloscope window.
        let samples = (0..<256).map { index -> Float in
            let x = Double(index) / 256.0
            let a = sin(2 * .pi * (5.0 * x + t * 0.8))
            let b = sin(2 * .pi * (11.0 * x - t * 0.21))
            return Float((0.71 * a + 0.29 * b) * Double(energy))
        }
        return AudioFrame(amplitude: energy, peak: min(1, energy * 1.15), levels: bars,
                          spectrum: bands, timestamp: t, history: history, samples: samples)
    }
}
