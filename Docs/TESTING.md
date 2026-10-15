# Release acceptance checklist

**Current status:** The package builds and its tests pass on macOS (Swift 6.4 toolchain), and the Demo app builds for iOS Simulator with Xcode 27.1 — zero build warnings. What remains unverified is real-device audio capture, frame pacing, energy and memory.

## Build and packaging

- [x] `swift build` on macOS
- [x] `swift test` on macOS (5 tests, 0 failures)
- [x] Xcode 27.1 Debug build of `AudioVisualKitDemo` for `generic/platform=iOS Simulator`
- [ ] Release configuration build for iPhone simulator
- [ ] Build the package and Demo on a physical iPhone
- [ ] Confirm the Demo App icon and top-left BrandMark render on device
- [ ] Confirm no stale personal development team or signing credentials are committed
- [ ] Confirm package can be added to a clean app as a local package and as a remote SPM dependency

## Visual correctness

- [ ] Validate all 24 effect names and groups; none are blank or truncated.
- [ ] Verify `Ribbon` has 3 independent translucent layers with no sharp diamond seam.
- [ ] Validate eight additions individually at low/high amplitude and with spectrum present/absent.
- [ ] Check `.silence`, zero-size host frames, different aspect ratios, and iPad layout.
- [ ] Set Density 16/48/96, Intensity 0.2/1.0/2.0, and each Color swatch.
- [ ] Check Gallery → Studio navigation, auto-scroll to selected style, and Copy Code button.
- [ ] Confirm Minimal grid shows 24 styles and its pause/play control works.
- [ ] Test with Reduce Motion enabled, light/dark device environment, and large Dynamic Type.

## Audio and lifecycle

- [ ] Microphone: allow permission, deny permission, repeated start/stop, background/foreground.
- [ ] Audio file: import supported format, play/pause, and test non-file or corrupt input.
- [ ] No FFT fabricated for file playback: spectrum remains at baseline until an FFT adapter is added.
- [ ] Verify audio session interactions with background playback / other apps.
- [ ] Observe memory, CPU, and power usage for at least 10 continuous minutes.

## Measurement (record actual values before Release)

| Target | Device | Measurement | Status |
| --- | --- | --- | --- |
| Dense Minimal gallery ~30 FPS | iPhone 14 Pro+ | Instruments Animation Hitches | Not measured |
| Audio callback CPU and dropped samples | physical iPhone | Time Profiler + signposts | Not measured |
| Wake/restart after interruption | physical iPhone | manual test | Not tested |
| Memory during 10-minute gallery loop | physical iPhone | Allocations | Not measured |

## Github presentation

- [ ] Record **real** Minimal-mode screen video and generate GIF with `Scripts/make-gif.sh`.
- [ ] Capture actual Studio/Gallery screenshots; keep generated design illustration labeled as concept.
- [x] Check logo contrast at tiny icon sizes; verify no transparent pixels in App Store icon. *(AppIcon.png is 1024×1024 RGB, opaque)*
- [x] Repository description and topics updated to 24 visualizations.
- [ ] Create a tagged release with notes drawn from `CHANGELOG.md`.
