# Changelog

## Unreleased — V3 quality pass

- Fixed four FFT styles by adding playback-time-indexed file FFT analysis; Minimal uses full synthetic signal independent of previously selected sources.
- Separated plain Bars, Mirrored Bars and Capsule Bars drawing geometry.
- Added loudness history and actual bipolar PCM to `AudioFrame` without breaking existing initializer calls.
- Rebuilt Recording History, Dot Wave, Siri Flow, Aurora Curtain, Energy Orb and Double Helix; improved readability of radial FFT / Starburst.
- Moved file import and preprocessing to a background task with stale-import rejection and cleanup.
- Removed all Gallery/Studio `NEW` labels and removed `isNew` metadata.
- Added audio-file analysis tests and a V3 release acceptance/QA report.
- No GitHub Actions workflow added.

This project follows a lightweight [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format.

## [1.0.0] - 2026-10-15

### Added
- Eight styles: Oscilloscope, Double Helix, Aurora Curtain, Neon Ribbon, Starburst, Orbiting Arcs, Lotus, and Vortex (24 total).
- Auto-counted Gallery and Minimal layouts, without promotional badges.
- Brand logo in the Demo assets and an opaque 1024px App Icon.
- Bilingual readmes, test checklist, integration recipes, and community guidelines.
- Studio sample-code copy action and style auto-scroll.
- `AudioVisualizer` initialization tests and offline file-envelope adapter tests.

### Changed
- `Ribbon` painter now uses three animated translucent layers instead of a single shallow filled shape.
- Studio's preview hierarchy, source selection, control spacing and layout.
- Removed hardcoded personal Development Team from the Xcode project.
- Split `AudioFrame.swift` into `AudioFrame`, `AudioVisualizationStyle` and `DemoAudioSignal`; split the renderer into one file per effect family under `Sources/AudioVisualKit/Painters/`.
- `AudioCaptureController` now deactivates the audio session when startup fails after the session was activated.
- Added repository URL examples and license/platform badges. Replace placeholder repository URL before publishing.

### Fixed
- Audio session leak in `AudioCaptureController.start()` when the input format guard rejected a device after the session had been activated.

### Validation
- `swift build` succeeds on macOS (Swift 6.4).
- `swift test`: 5 tests in `AudioFrameTests` plus renderer and file-adapter tests, 0 failures.
- Xcode 27.1 Debug build of `Demo/AudioVisualKitDemo` for `generic/platform=iOS Simulator` succeeds with no warnings.
- Still outstanding: physical-device microphone permission/lifecycle, frame pacing, energy and memory measurements, and a recorded Minimal-mode GIF.

## [0.1.0] - 2026-10-15

- 16 visualizers, immutable `AudioFrame`, deterministic Demo signal, microphone adapter, audio file waveform envelope, Gallery/Minimal/Studio Demo modes.
