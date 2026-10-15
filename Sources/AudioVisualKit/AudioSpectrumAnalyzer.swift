import Accelerate
import Foundation

/// Vectorized discrete Fourier transform and logarithmically spaced display bands.
/// Processing runs off the real-time audio callback on the presentation actor.
final class AudioSpectrumAnalyzer {
    private let fftSize = 1024
    private let bandCount = 32
    private var setup: vDSP_DFT_Setup?

    init() { setup = vDSP_DFT_zop_CreateSetup(nil, vDSP_Length(fftSize), .FORWARD) }
    deinit { if let setup { vDSP_DFT_DestroySetup(setup) } }

    func bands(samples: [Float]) -> [Float] {
        guard samples.count >= fftSize, let setup else { return Array(repeating: 0, count: bandCount) }
        var re = (0..<fftSize).map { i -> Float in
            let hann = 0.5 - 0.5 * cos(2 * Float.pi * Float(i) / Float(fftSize - 1))
            return samples[i] * hann
        }
        var im = [Float](repeating: 0, count: fftSize)
        var outRe = [Float](repeating: 0, count: fftSize)
        var outIm = [Float](repeating: 0, count: fftSize)
        re.withUnsafeMutableBufferPointer { inputRe in
            im.withUnsafeMutableBufferPointer { inputIm in
                outRe.withUnsafeMutableBufferPointer { outputRe in
                    outIm.withUnsafeMutableBufferPointer { outputIm in
                        vDSP_DFT_Execute(setup, inputRe.baseAddress!, inputIm.baseAddress!, outputRe.baseAddress!, outputIm.baseAddress!)
                    }
                }
            }
        }
        return (0..<bandCount).map { band in
            let u = Float(band) / Float(bandCount)
            let v = Float(band + 1) / Float(bandCount)
            let lo = max(1, min(fftSize / 2 - 1, Int(pow(Float(fftSize / 2), u))))
            let hi = max(lo + 1, min(fftSize / 2, Int(pow(Float(fftSize / 2), v))))
            var peak: Float = 0
            for k in lo..<hi {
                let magnitude = hypot(outRe[k], outIm[k]) / Float(fftSize)
                peak = max(peak, magnitude)
            }
            return min(1, max(0, log1p(peak * 28) / log1p(28)))
        }
    }
}
