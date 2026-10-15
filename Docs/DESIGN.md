# AudioVisualKit · Architecture and Design

## Goals

- A reusable SwiftUI visual-only library with 16 styles and a single `AudioFrame` contract.
- A simple iOS microphone input adapter that applications may opt into.
- An offline audio-file envelope extractor without loading entire files.
- A showcase with Gallery, Minimal (GIF capture), and Studio (configuration) modes.
- No forced external dependencies, transparent backgrounds, customizable color and density.

## Signal flow

`AVAudioEngine input tap` → fixed 1024-frame copy → UI-side 30 Hz consumption → RMS / FFT → normalized `AudioFrame` → `AudioVisualizer` → `Canvas`.

Apps with existing recorders, voice sessions, video capture, or DSP engines should NOT start a second AVAudioEngine. Feed their data into `AudioFrame` directly.

All values are normalized to the closed range 0...1. The renderer must not infer frequency content from RMS except as an expressly labeled fallback.

## Components

| Group | Styles | Input |
|---|---|---|
| Waveforms | bars, mirroredBars, capsuleBars, dotWave, recordingHistory | levels |
| Flow | sineWave, layeredWaves, siriFlow, ribbon | amplitude + time |
| Spectrum | spectrum, mirroredSpectrum, radialSpectrum | spectrum |
| Ambient | radialWave, pulseRings, energyOrb, particles | amplitude + time / levels |

## Demo

### Gallery
Two columns of rich transparent preview cards, grouped by four categories. Tap a card to configure it in Studio.

### Minimal
16 visualizations packed into a 3-column phone grid or 4-column wider grid. One shared `TimelineView` drives them all at up to 30 fps. The demo signal is deterministic and needs no permission. Recommended GIF size: 900 px wide, 8–12 sec, 12–20 fps.

### Studio
Full-size live preview; 16-style selector; density, intensity and color controls; source toggle (Demo/Microphone/Audio File); file playback.

## Notes and limitations

1. This starter project is source-generated and has not been built with Xcode or device-tested in this environment.
2. The bundled microphone adapter is best-effort and uses the legacy `installTap` compatibility API. It contains a skip-on-contention preallocated capture window, but it is not a formal certified hard-real-time audio component.
3. FFT windowing is performed downstream of the audio callback, but its allocation/performance require Instruments verification.
4. Audio File mode shows truthful file amplitude envelope. A full synchronized decoded spectrum for playback is a separate milestone; it must not be falsely represented as real FFT.
5. Demo snapshots/GIF should label their source as synthetic demo signal if there is no microphone input.
6. The demo app has iOS microphone usage text in generated Info.plist. Consumers must provide their own usage description.
7. Reduced Motion: the demo freezes synthetic motion when system accessibility Reduce Motion is enabled.
8. The package is licensed MIT. Verify third-party source/image rights before adding assets.

## Performance acceptance (targets; not measured)

- 16 minimal cells simultaneously: target 30 fps on iPhone 14 Pro or later.
- Input-to-visual latency: target < 100 ms at 30 Hz, measured by timestamps with Instruments.
- Idle/background: stop tap and audio engine; avoid updating visualizations in background.
- CPU, power and dropped-frame thresholds must be measured on real devices.

## Planned V1.1 improvements

- Switch to the modern `installAudioTap` where minimum SDK/version allows.
- Playback engine providing time-aligned amplitude and FFT bins, not just file envelope.
- Strict Swift 6 concurrency pass and Swift Testing/instrumented screenshot tests.
- Color palette tokens and recorder state transitions with haptics disabled by default.
- CI builds on iOS simulator; README rendered previews and GIF exports.
