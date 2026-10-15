import AVFoundation
import AudioVisualKit
import SwiftUI
import UniformTypeIdentifiers

private enum DisplayMode: String, CaseIterable {
    case gallery = "Gallery"
    case minimal = "Minimal"
    case studio = "Studio"
}

private enum SignalSource: String, CaseIterable {
    case demo = "Demo"
    case microphone = "Microphone"
    case file = "Audio File"
}

struct DemoHomeView: View {
    @StateObject private var microphone = AudioCaptureController()
    @State private var display: DisplayMode = .gallery
    @State private var source: SignalSource = .demo
    @State private var currentStyle: AudioVisualizationStyle = .siriFlow
    @State private var density: Double = 48
    @State private var intensity: Double = 1.0
    @State private var tint = Color.white
    @State private var showingFilePicker = false
    @State private var fileAmplitudes: [Float] = []
    @State private var audioPlayer: AVAudioPlayer?
    @State private var fileTitle: String = "Select an audio file"
    @State private var importError: String?
    @State private var isDemoPaused = false
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let ink = Color(red: 0.055, green: 0.06, blue: 0.065)
    private let panel = Color(red: 0.11, green: 0.12, blue: 0.13)

    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: isDemoPaused && source == .demo)) { clock in
                let frame = presentationFrame(at: clock.date.timeIntervalSinceReferenceDate)
                ScrollView {
                    VStack(alignment: .leading, spacing: display == .minimal ? 14 : 24) {
                        if display != .minimal { header }
                        modeBar
                        switch display {
                        case .gallery: gallery(frame: frame, width: geometry.size.width)
                        case .minimal: minimalGrid(frame: frame, width: geometry.size.width)
                        case .studio: studio(frame: frame)
                        }
                        if display != .minimal { footer }
                    }
                    .padding(display == .minimal ? 12 : 22)
                    .frame(maxWidth: 860)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .background(ink.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .fileImporter(isPresented: $showingFilePicker, allowedContentTypes: [.audio]) { result in
            do { try importAudio(result.get()) }
            catch { importError = error.localizedDescription }
        }
        .alert("Audio import failed", isPresented: Binding(get: { importError != nil }, set: { if !$0 { importError = nil } })) {
            Button("OK", role: .cancel) { importError = nil }
        } message: { Text(importError ?? "Unknown error") }
        .onChange(of: source) { _, newValue in
            if newValue != .microphone { microphone.stop() }
            if newValue == .microphone {
                Task {
                    do { try await microphone.start() }
                    catch { importError = error.localizedDescription; source = .demo }
                }
            }
            if newValue != .file { audioPlayer?.stop() }
            if newValue == .file && fileAmplitudes.isEmpty { showingFilePicker = true }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { microphone.stop(); audioPlayer?.pause() }
        }
        .onDisappear { microphone.stop(); audioPlayer?.stop() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 10) {
                Image(systemName: "waveform.path")
                    .font(.system(size: 21, weight: .medium))
                    .frame(width: 36, height: 36)
                    .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 11))
                Spacer()
                Text("SWIFTUI · SPM")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .tracking(2)
                    .foregroundStyle(.gray)
            }
            Text("Sound in motion.")
                .font(.system(size: 35, weight: .semibold, design: .rounded))
                .tracking(-1.6)
            Text("16 audio-reactive visualizations. Pure SwiftUI.")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.46))
        }
    }

    private var modeBar: some View {
        HStack(spacing: 5) {
            ForEach(DisplayMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { display = mode }
                } label: {
                    Text(mode.rawValue)
                        .font(.system(size: display == .minimal ? 11 : 12, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, display == .minimal ? 9 : 11)
                        .background(display == mode ? Color.white : Color.clear, in: RoundedRectangle(cornerRadius: 11))
                        .foregroundStyle(display == mode ? .black : .white.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(panel, in: RoundedRectangle(cornerRadius: 15))
    }

    private func gallery(frame: AudioFrame, width: CGFloat) -> some View {
        let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
        return VStack(alignment: .leading, spacing: 24) {
            sourceBar
            ForEach(["Waveforms", "Flow", "Spectrum", "Ambient"], id: \.self) { section in
                VStack(alignment: .leading, spacing: 13) {
                    HStack {
                        Text(section.uppercased())
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .tracking(2)
                            .foregroundStyle(.gray)
                        Spacer()
                        Text("\(AudioVisualizationStyle.allCases.filter { $0.group == section }.count) styles")
                            .font(.system(size: 10))
                            .foregroundStyle(.gray)
                    }
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(AudioVisualizationStyle.allCases.filter { $0.group == section }) { style in
                            Button {
                                currentStyle = style
                                display = .studio
                            } label: {
                                visualCard(style, frame: frame)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private func visualCard(_ style: AudioVisualizationStyle, frame: AudioFrame) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            visual(style: style, frame: frame)
                .frame(height: 92)
                .frame(maxWidth: .infinity)
            HStack(spacing: 6) {
                Text(style.title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.84))
                    .lineLimit(1)
                Spacer(minLength: 1)
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 9))
                    .foregroundStyle(.gray)
            }
        }
        .padding(14)
        .background(panel, in: RoundedRectangle(cornerRadius: 18))
    }

    private func minimalGrid(frame: AudioFrame, width: CGFloat) -> some View {
        let compact = width < 640
        let columns = Array(repeating: GridItem(.flexible(), spacing: 5), count: compact ? 3 : 4)
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("AUDIO VISUAL KIT")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .tracking(2)
                Spacer()
                Text("16 / 16")
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .foregroundStyle(.gray)
                Button { isDemoPaused.toggle() } label: {
                    Image(systemName: isDemoPaused ? "play.fill" : "pause.fill")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
            }
            LazyVGrid(columns: columns, spacing: 5) {
                ForEach(AudioVisualizationStyle.allCases) { style in
                    VStack(spacing: 4) {
                        visual(style: style, frame: frame)
                            .frame(height: compact ? 63 : 86)
                            .frame(maxWidth: .infinity)
                        Text(style.title)
                            .font(.system(size: compact ? 8 : 9, weight: .medium))
                            .foregroundStyle(.white.opacity(0.58))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .padding(.horizontal, 5)
                    .padding(.vertical, compact ? 9 : 14)
                    .background(panel, in: RoundedRectangle(cornerRadius: 10))
                }
            }
            Text("DEMO SIGNAL  ·  NO MIC REQUIRED")
                .font(.system(size: 8, weight: .medium, design: .monospaced))
                .tracking(1)
                .foregroundStyle(.gray)
                .frame(maxWidth: .infinity)
                .padding(.top, 5)
        }
    }

    private func studio(frame: AudioFrame) -> some View {
        VStack(alignment: .leading, spacing: 17) {
            sourceBar
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(currentStyle.group.uppercased())
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .tracking(1.8)
                            .foregroundStyle(.gray)
                        Text(currentStyle.title)
                            .font(.system(size: 23, weight: .medium))
                    }
                    Spacer()
                    Text(String(format: "%02d", (AudioVisualizationStyle.allCases.firstIndex(of: currentStyle) ?? 0) + 1))
                        .font(.system(size: 18, weight: .light, design: .monospaced))
                        .foregroundStyle(.gray)
                }
                visual(style: currentStyle, frame: frame)
                    .frame(height: 210)
                    .frame(maxWidth: .infinity)
                HStack {
                    Label("LIVE PREVIEW", systemImage: "circle.fill")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(.gray)
                    Spacer()
                    Text("30 FPS CAP")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.gray)
                }
            }
            .padding(22)
            .background(panel, in: RoundedRectangle(cornerRadius: 23))
            VStack(alignment: .leading, spacing: 12) {
                Text("VISUALIZATION")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .tracking(2)
                    .foregroundStyle(.gray)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(AudioVisualizationStyle.allCases) { style in
                            Button {
                                withAnimation(.easeInOut(duration: 0.15)) { currentStyle = style }
                            } label: {
                                Text(style.title)
                                    .font(.system(size: 11, weight: .medium))
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 13)
                                    .foregroundStyle(style == currentStyle ? Color.black : Color.white.opacity(0.65))
                                    .background(style == currentStyle ? Color.white : panel, in: Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            VStack(spacing: 16) {
                HStack {
                    Text("Density")
                    Spacer()
                    Text("\(Int(density))")
                        .foregroundStyle(.gray)
                }
                Slider(value: $density, in: 16...96, step: 8).tint(.white)
                HStack {
                    Text("Intensity")
                    Spacer()
                    Text(String(format: "%.1fx", intensity))
                        .foregroundStyle(.gray)
                }
                Slider(value: $intensity, in: 0.2...2.0, step: 0.1).tint(.white)
                HStack {
                    Text("Color")
                    Spacer()
                    ForEach([Color.white, .mint, .purple], id: \.self) { option in
                        Button { tint = option } label: {
                            Circle().fill(option).frame(width: 23, height: 23)
                                .overlay(Circle().strokeBorder(.white.opacity(tint == option ? 0.9 : 0), lineWidth: 2).padding(-4))
                        }.buttonStyle(.plain)
                    }
                }
                if source == .file {
                Text("File mode provides the waveform envelope; spectrum views stay at baseline until connected to an FFT playback source.")
                    .font(.system(size: 10))
                    .foregroundStyle(.gray)
                fileControl
            }
            }
            .font(.system(size: 12))
            .padding(18)
            .background(panel, in: RoundedRectangle(cornerRadius: 19))
            Text("AudioVisualizer(style: .\(currentStyle.rawValue), frame: frame)")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.gray)
                .textSelection(.enabled)
        }
    }

    private var sourceBar: some View {
        HStack(spacing: 6) {
            Text("SOURCE")
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .tracking(1.3)
                .foregroundStyle(.gray)
            Spacer(minLength: 4)
            ForEach(SignalSource.allCases, id: \.self) { choice in
                Button { source = choice } label: {
                    Text(choice.rawValue)
                        .font(.system(size: 10, weight: .medium))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 9)
                        .foregroundStyle(source == choice ? .black : .white.opacity(0.55))
                        .background(source == choice ? Color.white : panel, in: Capsule())
                }.buttonStyle(.plain)
            }
        }
    }

    private var fileControl: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider().overlay(.white.opacity(0.14))
            Button { showingFilePicker = true } label: {
                Label(fileTitle, systemImage: "doc.badge.plus")
                    .lineLimit(1)
                    .foregroundStyle(.white)
            }
            if let player = audioPlayer {
                HStack {
                    Button {
                        if player.isPlaying { player.pause() } else { player.play() }
                    } label: { Label(player.isPlaying ? "Pause" : "Play", systemImage: player.isPlaying ? "pause.fill" : "play.fill") }
                    Spacer()
                    Text(String(format: "%.0fs / %.0fs", player.currentTime, player.duration))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.gray)
                }
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule().fill(.gray.opacity(0.3))
                        Capsule().fill(.white).frame(width: geometry.size.width * CGFloat(player.duration > 0 ? player.currentTime / player.duration : 0))
                    }
                    .frame(height: 3)
                }.frame(height: 5)
            }
        }
    }

    private var footer: some View {
        HStack {
            Text("ZERO EXTERNAL DEPENDENCIES")
            Spacer()
            Text("SWIFT PACKAGE")
        }
        .font(.system(size: 9, weight: .medium, design: .monospaced))
        .tracking(1)
        .foregroundStyle(.gray)
    }

    private func visual(style: AudioVisualizationStyle, frame: AudioFrame) -> some View {
        AudioVisualizer(style: style, frame: frame, color: tint, secondaryColor: .gray, density: Int(density))
    }

    private func presentationFrame(at time: TimeInterval) -> AudioFrame {
        var result: AudioFrame
        switch source {
        case .demo:
            result = DemoAudioSignal.frame(at: reduceMotion || isDemoPaused ? 1.1 : time)
        case .microphone:
            result = microphone.frame
        case .file:
            guard !fileAmplitudes.isEmpty else { return .silence }
            let progress = audioPlayer.map { $0.duration > 0 ? $0.currentTime / $0.duration : 0 } ?? 0
            let idx = min(fileAmplitudes.count - 1, max(0, Int(progress * Double(fileAmplitudes.count))))
            result = AudioFrame(amplitude: fileAmplitudes[idx], levels: fileAmplitudes, timestamp: time)
        }
        let multiplier = Float(intensity)
        return AudioFrame(amplitude: min(1, result.amplitude * multiplier), peak: result.peak,
                          levels: result.levels.map { min(1, $0 * multiplier) },
                          spectrum: result.spectrum.map { min(1, $0 * multiplier) },
                          timestamp: result.timestamp)
    }

    private func importAudio(_ url: URL) throws {
        let granted = url.startAccessingSecurityScopedResource()
        defer { if granted { url.stopAccessingSecurityScopedResource() } }
        let name = url.lastPathComponent
        let temp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "-" + name)
        try FileManager.default.copyItem(at: url, to: temp)
        fileAmplitudes = try AudioFileWaveform.amplitudes(url: temp, sampleCount: 160)
        audioPlayer?.stop()
        audioPlayer = try AVAudioPlayer(contentsOf: temp)
        audioPlayer?.prepareToPlay()
        fileTitle = name
    }
}
