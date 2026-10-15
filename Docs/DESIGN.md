# AudioVisualKit · Rendering and Architecture

## Goals

- 24 audio-reactive SwiftUI styles, compatible with existing 16 style names.
- Transparent visual layer and a stable immutable `AudioFrame` contract.
- Optional microphone and offline file-envelope adapters.
- No third-party runtime dependencies and no timers inside each visualizer.

## Frame pipeline

`PCM (app-owned AVAudioEngine / sample adapter)` → `RMS, peaks, FFT bins` → normalized `AudioFrame` → `AudioVisualizer` → `SwiftUI Canvas`.

`DemoAudioSignal` is deterministic; use it for zero-permission animations and screenshot/GIF previews. Sound-reactive visualization is different from a calibrated SPL meter.

## Visual styles

| Family | Styles | Required signals |
| --- | --- | --- |
| Waveforms (6) | bars, mirroredBars, capsuleBars, dotWave, recordingHistory, oscilloscope | levels / amplitude / time |
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
- The audio-file adapter extracts **envelope data**, not aligned playback FFT bins. Do not claim that `spectrum` visualizations reflect audio-file frequencies.

## Demo UI

- Gallery: two-column cards, four groups, `NEW` badge for eight additions.
- Minimal: 3 columns on phones, 4 on wider layouts, one shared clock and automatic count.
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
