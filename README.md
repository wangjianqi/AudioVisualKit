<div align="center">

<img src="Docs/Assets/logo-mark.png" width="104" alt="AudioVisualKit logo">

# AudioVisualKit

**24 audio-reactive SwiftUI visualizations. One Swift Package. No external dependencies.**

A reusable audio visualization toolkit for voice interfaces, recorders, music players, and interactive experiences.

[中文说明](README.zh-CN.md) · [Getting Started](#getting-started) · [Effects](#effects) · [Demo](#run-the-demo) · [Contributing](CONTRIBUTING.md)

<img src="Docs/Assets/hero.png" alt="AudioVisualKit brand illustration showing wave, spectrum and radial effects">

*Brand artwork (not a screenshot of the running application).*

</div>

> **Development status:** This repository is an open-source starter and design implementation, not yet a device-validated release. Source syntax and project structure have been checked, but building the iOS target and performance testing on device are still required.

## Features

- **24 effects:** waveforms, fluid ribbons, music spectrum, generative ambient visuals.
- **Data-driven:** feed normalized `AudioFrame` data from any engine, recorder, or stream.
- **SwiftUI:** transparent `Canvas` views with configurable color and density.
- **Demo modes:** Gallery, Studio, and a dense Minimal view for recording preview GIFs.
- **Input adapters:** synthetic demonstration signal, an opt-in iOS microphone controller, offline audio file envelope extraction.
- **Zero external packages:** uses SwiftUI, Foundation, AVFoundation, and Accelerate from Apple SDKs.
- **Supported deployment targets:** iOS 17+ and macOS 14+ for the visualization library. The bundled microphone controller is iOS-only.

## Effects

| Family | Visualizations |
| --- | --- |
| Waveforms (6) | Bars, Mirrored Bars, Capsule Bars, Dot Wave, Recording History, **Oscilloscope** |
| Flow (7) | Sine Wave, Layered Waves, Siri Flow, Ribbon, **Double Helix**, **Aurora Curtain**, **Neon Ribbon** |
| Spectrum (4) | Spectrum, Mirrored Spectrum, Radial Spectrum, **Starburst** |
| Ambient (7) | Radial Wave, Pulse Rings, Energy Orb, Particles, **Orbiting Arcs**, **Lotus**, **Vortex** |

**Bold names** are the 8 styles added in this revision. All 16 original styles remain available with unchanged case names.

## Getting started

### Swift Package Manager

After pushing your fork or publishing this package to GitHub, use **Xcode → File → Add Package Dependencies**, enter *your repository's actual URL*, select a version, and `import AudioVisualKit`.

For local development, add this package using **Add Local…** from Xcode. No remote repository URL is required for the included Demo.

### One visualizer

```swift
import AudioVisualKit
import SwiftUI

struct Example: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30)) { clock in
            let audio = DemoAudioSignal.frame(at: clock.date.timeIntervalSinceReferenceDate)
            AudioVisualizer(style: .neonRibbon,
                            frame: audio,
                            color: .white,
                            secondaryColor: .gray,
                            density: 48)
                .frame(height: 140)
        }
    }
}
```

The library view **does not** capture audio or start its own display clock. Multiple views should share their parent timeline, as demonstrated by the Minimal gallery.

### Real-time input

On iOS the optional sample adapter supports live microphone input:

```swift
@StateObject private var microphone = AudioCaptureController()

var body: some View {
    AudioVisualizer(style: .starburst, frame: microphone.frame)
        .task { try? await microphone.start() }
        .onDisappear { microphone.stop() }
}
```

Set `NSMicrophoneUsageDescription` in your app's Info.plist. For an existing recorder, **do not create a second audio engine**: analyze its buffers and provide an `AudioFrame` directly. See [integration recipes](Docs/RECIPES.md).

### From an audio file

```swift
let levels = try AudioFileWaveform.amplitudes(url: localURL, sampleCount: 180)
let visualFrame = AudioFrame(amplitude: 0, levels: levels)
```

This extracts an **amplitude envelope**, not a synchronized FFT stream. File mode cannot produce real frequency-band data without an audio playback analysis adapter; spectrum styles will correctly remain at baseline when spectrum is unavailable.

## Run the demo

1. Open `Demo/AudioVisualKitDemo.xcodeproj` in Xcode.
2. Choose a simulator or iPhone and select your own development team if signing is required.
3. Select **Gallery** to browse grouped cards, **Minimal** for the full 24-style animation wall, or **Studio** to tune a chosen effect.
4. Demo signal runs without microphone permission. Microphone mode needs a compatible device and permission. Audio File imports a user-selected local audio file.

<img src="Docs/Assets/studio-concept.png" width="300" alt="Studio layout concept">

*Studio design concept. The real interface is rendered by SwiftUI; its appearance may differ.*

To create a GIF from a **real** simulator/device screen recording:

```bash
brew install ffmpeg
bash Scripts/make-gif.sh /path/to/Minimal.mov Docs/Assets/minimal-preview.gif
```

Do not present the designed concept image as evidence of tested runtime rendering.

## API overview

| API | Purpose |
| --- | --- |
| `AudioFrame(amplitude:peak:levels:spectrum:timestamp:)` | Normalized, immutable data snapshot, all values clamped to 0–1 |
| `AudioVisualizationStyle.allCases` | All 24 styles; `title`, `group`, `isNew` metadata |
| `AudioVisualizer(style:frame:color:secondaryColor:density:)` | Stateless SwiftUI renderer |
| `DemoAudioSignal.frame(at:count:)` | Deterministic preview data |
| `AudioCaptureController` | Optional iOS AVAudioEngine input adapter |
| `AudioFileWaveform.amplitudes(url:sampleCount:)` | Offline waveform-envelope extraction |

## Architecture & validation

[Design and constraints](Docs/DESIGN.md) · [Recipes](Docs/RECIPES.md) · [Test checklist](Docs/TESTING.md) · [Changelog](CHANGELOG.md)

- The presentation layer runs in SwiftUI `Canvas` and does not own timers or audio sessions.
- Demo visuals use a deterministic synthetic signal; audio-reactive does **not** imply microphone access.
- The sample microphone FFT and its allocations must be profiled using Instruments before production use.
- `30 FPS TARGET` is a scheduling target, not a measured performance guarantee.
- Only source syntax, Swift package manifest, and Xcode project structure can be checked in the current build environment. See [TESTING](Docs/TESTING.md) for device acceptance.

## Contributing and security

Pull requests welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md), [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md), and [SECURITY.md](SECURITY.md). This repository intentionally contains **no GitHub Actions workflow**.

## License

[MIT](LICENSE). Art and icons bundled in this repository may be redistributed under the same license by this project's contributors; please confirm provenance/rights before replacing them with third-party assets.
