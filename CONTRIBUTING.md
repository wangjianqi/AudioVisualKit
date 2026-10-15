# Contributing to AudioVisualKit

Thanks for improving the package. Please keep contributions portable and measurable.

## Before you send a pull request

1. Open an issue for breaking public-API changes or large changes to the rendering architecture.
2. Retain compatibility with the documented minimum platform targets (iOS 17+, macOS 14+).
3. Keep the visualization library independent of third-party packages and without direct microphone permission requests in View code.
4. For a new effect, add one enum case, its `title` / `group`, a new Canvas painter implementation, a gallery entry (automatic), and tests.
5. Use normalized 0–1 `AudioFrame` data; do not fabricate FFT bins from volume readings.
6. Confirm basic Reduced Motion behavior and accessibility labels.
7. Add an entry to `CHANGELOG.md` when modifying public behavior.

## Testing

On a Mac with Xcode:

```bash
swift test
xcodebuild -project Demo/AudioVisualKitDemo.xcodeproj \
  -scheme AudioVisualKitDemo -destination 'generic/platform=iOS Simulator' \
  -configuration Debug CODE_SIGNING_ALLOWED=NO build
```

Check `Docs/TESTING.md` for device and animation acceptance. The build command above is a suggested command, **not** proof this version already compiles in Xcode.

## Style and performance

Use a single parent `TimelineView` for multi-style demos. Prefer size-relative Path/Canvas drawing instead of large nested animated view trees. Never allocate or block unnecessarily inside a real-time audio callback; consider moving expensive DSP off the main actor.

## Pull request checklist

- [ ] Public API changes documented
- [ ] Original style case names retained (unless deliberately breaking)
- [ ] Tests updated
- [ ] Xcode/simulator build results noted
- [ ] Before/after screenshot or screen recording for visual changes
- [ ] No copyrighted assets added without redistribution permission

No GitHub Actions workflow is included or expected by default.
