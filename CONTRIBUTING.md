# Contributing to AudioVisualKit

Thanks for improving the package. Please keep contributions portable and measurable.

## Before you send a pull request

1. Open an issue for breaking public-API changes or large changes to the rendering architecture.
2. Retain compatibility with the documented minimum platform targets (iOS 17+, macOS 14+).
3. Keep the visualization library independent of third-party packages and without direct microphone permission requests in View code.
4. For a new effect, add one enum case, its `title` / `group`, one painter method in the matching file under `Sources/AudioVisualKit/Painters/`, a dispatch case in `AudioPainter.draw(_:)`, and tests. The gallery and grid enumerate `allCases`, so no Demo change is needed.
5. Use normalized 0–1 `AudioFrame` data; do not fabricate FFT bins from volume readings.
6. Confirm basic Reduced Motion behavior and accessibility labels.
7. Add an entry to `CHANGELOG.md` when modifying public behavior.

## Testing

On a Mac with Xcode, CI runs exactly these two commands on every push and pull request:

```bash
swift build
swift test
```

Renderers are smoke-tested by drawing every style offscreen (`AudioVisualizerTests`), so a regression that traps or silently draws nothing fails locally the same way it fails in CI. To build the Demo app:

```bash
xcodebuild build \
  -project Demo/AudioVisualKitDemo.xcodeproj \
  -scheme AudioVisualKitDemo \
  -destination 'generic/platform=iOS Simulator' \
  -configuration Debug \
  CODE_SIGNING_ALLOWED=NO
```

Check `Docs/TESTING.md` for device and animation acceptance. Build success here does **not** prove real-device audio behavior or frame pacing.

## Style and performance

Use a single parent `TimelineView` for multi-style demos. Prefer size-relative Path/Canvas drawing instead of large nested animated view trees. Never allocate or block unnecessarily inside a real-time audio callback; consider moving expensive DSP off the main actor.

## Pull request checklist

- [ ] Public API changes documented
- [ ] Original style case names retained (unless deliberately breaking)
- [ ] Tests updated
- [ ] Xcode/simulator build results noted
- [ ] Before/after screenshot or screen recording for visual changes
- [ ] No copyrighted assets added without redistribution permission

Pull requests are validated by GitHub Actions (`swift build`, `swift test`, and an iOS Simulator build of the Demo). Please keep the workflow in `.github/workflows/ci.yml` green; if you intentionally skip a check, say why in the pull request description.
