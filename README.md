# AudioVisualKit

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)
![Platforms](https://img.shields.io/badge/Platforms-iOS%2017%20%7C%20macOS%2014-lightgrey.svg)

**16 SwiftUI sound visualizations in one zero-dependency Swift Package.**

A transparent and reusable visual layer for voice interfaces, recording apps, audio players and interactive demos.

## Requirements

- Swift 5.9+ / Xcode 15+
- iOS 17+ or macOS 14+
- No third-party dependencies

## Run the Demo

1. Open `Demo/AudioVisualKitDemo.xcodeproj` in Xcode (recommended Xcode 16+, test with Xcode 27).
2. Select an iPhone simulator or a connected device.
3. Run. **Gallery** lists all effects; **Minimal** shows a dense GIF-friendly grid; **Studio** lets you change styles, colors, density and input.
4. **Demo** mode runs without permissions. **Microphone** mode requests permission and works on a physical device. **Audio File** mode loads a local audio file for waveform preview/playback.

The Xcode demo refers to this package as a *local Swift Package*. Keep the `Demo` directory inside the package root.

## SPM Integration

Add the package in Xcode → File → Add Package Dependencies:

```
https://github.com/wangjianqi/AudioVisualKit.git
```

Then import and use:

```swift
import AudioVisualKit

AudioVisualizer(
    style: .siriFlow,
    frame: DemoAudioSignal.frame(at: Date().timeIntervalSinceReferenceDate),
    color: .white,
    density: 48
)
.frame(height: 100)
```

The application owns the frame source and redraw cadence. For example, a gallery uses **one shared** `TimelineView`:

```swift
TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { time in
    let signal = DemoAudioSignal.frame(at: time.date.timeIntervalSinceReferenceDate)
    VStack {
        AudioVisualizer(style: .siriFlow, frame: signal)
        AudioVisualizer(style: .radialSpectrum, frame: signal)
    }
}
```

### Live microphone

On iOS, use `AudioCaptureController` for a simple integrated microphone pipeline:

```swift
@StateObject private var audio = AudioCaptureController()

var body: some View {
    AudioVisualizer(style: .radialSpectrum, frame: audio.frame)
        .task { try? await audio.start() }
        .onDisappear { audio.stop() }
}
```

Your target must set `NSMicrophoneUsageDescription`. For existing recording/voice apps, **reuse the existing audio engine** and build your own `AudioFrame` instead of opening an additional microphone tap.

### File envelope

```swift
let values = try AudioFileWaveform.amplitudes(url: fileURL, sampleCount: 180)
let frame = AudioFrame(amplitude: 0, levels: values)
```

## Architecture and QA

- `AudioFrame` = immutable normalized input contract.
- `AudioVisualizer` = 16 vector styles in SwiftUI `Canvas`.
- `DemoAudioSignal` = deterministic simulator, no permission.
- `AudioCaptureController` = optional iOS AVAudioEngine input adapter.
- `AudioFileWaveform` = chunked offline waveform envelope extraction.
- `Docs/DESIGN.md` = rendering, audio, interaction and performance specifications.

> **Validation status:** `swift build` and `swift test` pass on macOS (Swift 6.2 toolchain, macOS 14 destination). The iOS demo `.xcodeproj` and microphone/file input paths have not been exercised on a simulator or device in CI — run them in Xcode before shipping a production release.

## License

MIT. Copyright (c) 2026 AudioVisualKit contributors.

## Export a real GIF for GitHub

The **Minimal** screen is specifically arranged for a compact 16-effect recording. Record it from your iOS Simulator via Xcode, then run:

```bash
./Scripts/make-gif.sh minimal-demo.mov Docs/minimal-preview.gif
```

The script uses FFmpeg (installed via `brew install ffmpeg` if needed). This outputs an actual Demo recording, not a concept animation.
