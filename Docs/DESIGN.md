# AudioVisualKit · Rendering and Architecture

## Goals

- 24 audio-reactive SwiftUI styles, compatible with existing 16 style names.
- Transparent visual layer and a stable immutable `AudioFrame` contract.
- Optional microphone and offline audio-file FFT/envelope/PCM adapters.
- No third-party runtime dependencies and no timers inside each visualizer.

## Frame pipeline

`PCM (app-owned AVAudioEngine / sample adapter)` → `RMS, peaks, FFT bins` → normalized `AudioFrame` → `AudioVisualizer` → `SwiftUI Canvas`.

`DemoAudioSignal` is deterministic; use it for zero-permission animations and screenshot/GIF previews. Sound-reactive visualization is different from a calibrated SPL meter.

## Source layout

| Path | Contents |
| --- | --- |
| `Sources/AudioVisualKit/AudioFrame.swift` | Immutable normalized data snapshot |
| `Sources/AudioVisualKit/AudioVisualizationStyle.swift` | 24 cases with `title` and `group` metadata |
| `Sources/AudioVisualKit/DemoAudioSignal.swift` | Deterministic preview signal |
| `Sources/AudioVisualKit/AudioVisualizer.swift` | `AudioVisualizer` view plus `AudioPainter` dispatch and shared sampling helpers |
| `Sources/AudioVisualKit/Painters/` | One file per effect family: `WaveformPainters`, `FlowPainters`, `SpectrumPainters`, `AmbientPainters` |
| `Sources/AudioVisualKit/AudioCaptureController.swift` | Optional iOS-only `AVAudioEngine` microphone adapter |
| `Sources/AudioVisualKit/AudioFileWaveform.swift` | Offline envelope extraction |
| `Sources/AudioVisualKit/AudioFileAnalysis.swift` | Time-indexed file FFT/PCM/envelope snapshots |
| `Sources/AudioVisualKit/AudioSpectrumAnalyzer.swift` | Shared Accelerate DFT for microphone/file analysis |

`AudioPainter` is `internal`: painters are plain extensions of it in the family files and stay invisible to consumers. A painter is a pure function of the frame and the view size — it owns no state and no timer.

## Visual styles

| Family | Styles | Required signals |
| --- | --- | --- |
| Waveforms (6) | bars, mirroredBars, capsuleBars, dotWave, recordingHistory, oscilloscope | levels / history / signed PCM |
| Flow (7) | sineWave, layeredWaves, siriFlow, ribbon, doubleHelix, auroraCurtain, neonRibbon | amplitude / time / levels |
| Spectrum (4) | spectrum, mirroredSpectrum, radialSpectrum, starburst | spectrum |
| Ambient (7) | radialWave, pulseRings, energyOrb, particles, orbitingArcs, lotus, vortex | amplitude / time / levels |

The renderer handles empty signals deterministically. It does not invent FFT frequency bins when absent.

## Drawing discipline

- Prefer Canvas vector primitives and a shared `TimelineView` schedule.
- Clamp input analysis and drawing density to avoid out-of-range paths.
- Use the view's bounds, never hardcode iPhone coordinates.
- `Ribbon` now uses three opposing-edge translucent sheets with independent phase shifts; it is not just one filled diamond.
- Each new style must respond to `AudioFrame` changes and must not require network or device permission.
- Keep animations responsive to `.accessibilityReduceMotion` at the host level. The sample Demo pauses synthetic motion when enabled.

## Input adapter constraints

- The microphone adapter requests permission only when explicitly started.
- `AVAudioEngine.inputNode.installTap` is a compatibility implementation and should not be duplicated in apps that already own audio capture.
- The callback uses a fixed-size capture buffer with skip-on-lock-contention, intended as a **demo-grade** adapter rather than a certified real-time DSP subsystem.
- FFT processing currently occurs downstream from the tap, on the presentation actor, with temporary allocations. For high-throughput use, move DSP to a worker and use bounded transfer of the latest frame.
- Audio file mode extracts bounded **time-indexed real FFT/PCM snapshots** on a detached executor. The displayed spectrum tracks playback time; snapshot cadence adapts to input duration, and is not calibrated frequency analysis.

## Demo UI

- Gallery: two-column cards, four groups, no promotional `NEW` labels.
- Minimal: 3 columns on phones, 4 on wider layouts, one shared clock and automatic count. Always runs a complete synthetic spectrum/PCM Demo signal, and pauses other input sources while displayed.
- Studio: more prominent multi-layer effects, auto-scrolling selected style, controls, source, and copyable sample code.
- `Docs/Assets/studio-concept.png` is a concept rendering. Replace it with a real simulator screenshot before public release if showing actual UI behavior is important.

## Performance and acceptance

These are **targets, not benchmarks**:

- Aim for 30 FPS in dense Minimal mode; verify actual frame pacing on devices.
- Check UI updates and frame rates with Instruments/Animation Hitches, Time Profiler, and Energy Log.
- Verify app lifecycle: suspend microphone and audio playback when inactive; restore only when appropriate.
- Measure input-to-presentation latency; do not advertise unmeasured values.
- Compare brightness / amplitude at silent and loud signal levels. Validate the visual character of every style, not merely whether it moves.

See `Docs/TESTING.md` for reproducible acceptance steps.

## V3 sample contracts

- `history` is ordered **oldest to newest**; it scrolls into the Recording History visualization.
- `samples` are actual **bipolar PCM** in [-1,1], not positive envelope bins. Empty PCM draws a baseline only.
- `spectrum` are normalized 0...1 log-spaced FFT bands. Empty FFT does **not** get fabricated frequency content.
- `AudioFileWaveform.analyze` is synchronous I/O; invoke it off-main, as shown by the Demo importer.

See `Docs/QA_REPORT.md` for known unverified behaviors.
