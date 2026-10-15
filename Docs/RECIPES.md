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

This older `amplitudes` method returns an envelope only. For playback-aligned FFT and true PCM, call `AudioFileWaveform.analyze(url:)` on a background task and pass `analysis.frame(at: player.currentTime)` to the renderer. Existing audio players may instead supply their own FFT/PCM frames.

## 4. Choosing a style

- Voice memo / waveform history: `.recordingHistory`, `.capsuleBars`
- Speech assistant: `.siriFlow`, `.ribbon`, `.neonRibbon`
- Frequency-responsive player: `.spectrum`, `.starburst`, `.radialSpectrum`
- Meditation / ambient interactive feedback: `.auroraCurtain`, `.lotus`, `.orbitingArcs`
- Engineering-themed voice UI: `.oscilloscope`, `.doubleHelix`

## 5. Accessibility

Use a meaningful parent accessibility label such as recording status or meter value if the visualization conveys actionable information. The renderer itself already exposes a generic description. Honor Reduced Motion in your host `TimelineView` and provide equivalent textual state when necessary.

## File FFT + true oscilloscope

```swift
// Run the synchronous file decode on a detached/background executor.
let analysis = try AudioFileWaveform.analyze(url: fileURL)
let frame = analysis.frame(at: player.currentTime)
AudioVisualizer(style: .oscilloscope, frame: frame) // uses signed PCM
AudioVisualizer(style: .starburst, frame: frame)    // uses FFT bands
```

`AudioFileAnalysis` bounds the number of stored snapshots to prevent unbounded memory use. A long audio file is still fully decoded for analysis, so expose progress/cancellation in a host app.
