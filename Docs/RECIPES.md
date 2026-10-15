# Integration recipes

## 1. View from an existing recorder

Reuse an app-owned audio engine. Convert its analysis output to `AudioFrame` and pass it into the renderer. `amplitude`, `peak`, `levels`, and `spectrum` are **normalized 0...1 display values**.

```swift
let snapshot = AudioFrame(
    amplitude: rmsDisplayValue,
    peak: peakDisplayValue,
    levels: recentLevelHistory,
    spectrum: logFrequencyBands,
    timestamp: processTime
)

AudioVisualizer(style: .starburst, frame: snapshot)
    .frame(width: 200, height: 200)
```

**Do not** start `AudioCaptureController` in an app that already owns the microphone.

## 2. Many styles with one clock

```swift
TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { clock in
    let frame = DemoAudioSignal.frame(at: clock.date.timeIntervalSinceReferenceDate)
    HStack {
        AudioVisualizer(style: .doubleHelix, frame: frame)
        AudioVisualizer(style: .lotus, frame: frame)
    }
}
```

This avoids 24 separate timers. The system may deliver frames at a lower cadence than the requested 30 FPS.

## 3. Static file envelope

```swift
let envelope = try AudioFileWaveform.amplitudes(url: url, sampleCount: 100)
let frame = AudioFrame(amplitude: 0, levels: envelope)
AudioVisualizer(style: .recordingHistory, frame: frame)
```

This is a waveform history. **It is not FFT**. Use an existing audio player's PCM tap if your app needs real-time `spectrum` during playback.

## 4. Choosing a style

- Voice memo / waveform history: `.recordingHistory`, `.capsuleBars`
- Speech assistant: `.siriFlow`, `.ribbon`, `.neonRibbon`
- Frequency-responsive player: `.spectrum`, `.starburst`, `.radialSpectrum`
- Meditation / ambient interactive feedback: `.auroraCurtain`, `.lotus`, `.orbitingArcs`
- Engineering-themed voice UI: `.oscilloscope`, `.doubleHelix`

## 5. Accessibility

Use a meaningful parent accessibility label such as recording status or meter value if the visualization conveys actionable information. The renderer itself already exposes a generic description. Honor Reduced Motion in your host `TimelineView` and provide equivalent textual state when necessary.
