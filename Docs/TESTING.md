# AudioVisualKit — Release acceptance (V3)

**Important:** V3 has not yet been compiled or executed with the Apple iOS SDK in the current environment. Previous build results from V2 must not be represented as verification of V3. Swift source syntax and Foundation-only model type-checking are verified; see `Docs/QA_REPORT.md` for detail.

## Package and Xcode

- [ ] `swift build` / `swift test` on macOS 14+ with Xcode (full suite; do not reuse V2 test counts).
- [ ] Build `Demo/AudioVisualKitDemo.xcodeproj` against an iPhone simulator (Debug and Release).
- [ ] Install and test on a physical iPhone; check current signing settings are not personal.
- [ ] Confirm app icon and brand image are rendered correctly.
- [ ] Import into a clean application as both local and remote Swift Package.

## 24-style visual acceptance

- [ ] **01 Bars:** square vertical bars grow from bottom baseline.
- [ ] **02 Mirrored Bars:** symmetric rectangular bars grow up/down from center.
- [ ] **03 Capsule Bars:** spaced round-ended pillars float at center.
- [ ] **04 Dot Wave:** one travelling dotted curve, not a stationary ellipse.
- [ ] **05 Recording History:** oldest on left/newest on right; right-side playhead, history scrolls.
- [ ] **06 Sine Wave:** one continuous signed smooth curve.
- [ ] **07 Layered Waves:** three differentiated phase layers.
- [ ] **08 Siri Flow:** central energy ribbon with independent flowing lines, distinct from 07.
- [ ] **09 Ribbon:** three closed translucent flowing sheets with no seams.
- [ ] **10 Spectrum:** bar heights visibly respond to supplied FFT bins.
- [ ] **11 Mirrored Spectrum:** spectrum heights extend above/below center.
- [ ] **12 Radial Spectrum:** live FFT changes radial spoke length.
- [ ] **13 Radial Wave:** coherent audio-reactive circular waveform.
- [ ] **14 Pulse Rings:** outward expansion & fading.
- [ ] **15 Energy Orb:** inner light plus at least four uneven responding contours.
- [ ] **16 Particles:** discrete particles with volume-reactive radius.
- [ ] **17 Oscilloscope:** actual positive/negative PCM; empty PCM yields just baseline.
- [ ] **18 Double Helix:** strands and rungs, visible crossings.
- [ ] **19 Aurora Curtain:** translucent descending vertical strips, not mountains.
- [ ] **20 Neon Ribbon:** prominent bright thin line plus restrained bloom.
- [ ] **21 Starburst:** FFT lengthens fine sunburst rays, not a solid disk.
- [ ] **22 Orbiting Arcs:** distinct rotating arcs and endpoint markers.
- [ ] **23 Lotus:** recognizable petal geometry with soft opacity.
- [ ] **24 Vortex:** spiral strands are identifiable and animate evenly.

## Data source and lifecycle

- [ ] Demo source produces non-empty history, frequency bins and signed PCM.
- [ ] Minimal always uses Demo signal even after switching sources in Studio.
- [ ] Minimal entering stops microphone and pauses file; returning to Studio can resume mic.
- [ ] Gallery, Studio: microphone permission approve/deny and repeated start/stop.
- [ ] Import a real WAV / M4A; loading must not freeze the UI; no stale imports overriding later ones.
- [ ] File FFT visualizers react to playback progression, not to static amplitude bins.
- [ ] The oscilloscope displays actual signed file samples, not synthetic traces.
- [ ] Test silence, corrupted input, huge (>1 hour) file, repeated import, background interruption.
- [ ] Verify no leaked temporary files on cancellation, error and scene dismissal.
- [ ] Verify Reduced Motion stops Demo animation and audio hardware remains off without permission.
- [ ] No `NEW` labels in any Demo mode.

## Performance (targets, not measured results)

| Target | Instrument | Accept when |
| --- | --- | --- |
| 24 effects @ 30 FPS | Animation Hitches / Core Animation | Sustained 30 FPS in Minimal on target phone |
| Main-thread audio file import | Time Profiler | No long main-thread stall while scanning file |
| Capture CPU and drops | Instruments + microphone | No sustained underruns or UI jank |
| Ten-minute preview | Allocations + Energy Log | Stable memory and acceptable battery draw |

## GitHub readiness

- [ ] Replace `Docs/Assets/studio-concept.png` with a real Demo screenshot if claiming it is an actual capture.
- [ ] Record an authentic Minimal mode MP4 and run `Scripts/make-gif.sh`.
- [ ] Ensure README, CHANGELOG and Version tags accurately report *tested* functionality.
- [ ] No CI or GitHub Actions are included by default.
