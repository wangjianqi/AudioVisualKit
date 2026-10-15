# Release acceptance checklist

**Current status:** Static checks only in a Linux host environment; Xcode iOS targets and real-time audio are NOT verified.

## Build and packaging

- [ ] Open `Demo/AudioVisualKitDemo.xcodeproj` on Xcode 27.
- [ ] Build Debug and Release for iPhone simulator (iOS 17+).
- [ ] Build the package and Demo on a physical iPhone.
- [ ] Confirm the Demo App icon and top-left BrandMark render.
- [ ] Confirm no stale personal development team or signing credentials are committed.
- [ ] Confirm package can be added to a clean app as a local package.

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
- [ ] Check logo contrast at tiny icon sizes; verify no transparent pixels in App Store icon.
- [ ] Set a real repo URL in GitHub and create tagged release notes when verified.
