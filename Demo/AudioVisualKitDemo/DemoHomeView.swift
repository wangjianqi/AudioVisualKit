import AVFoundation
import AudioVisualKit
import SwiftUI
import UniformTypeIdentifiers
import UIKit

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

/// All 24 effects share one presentation clock: the library itself owns no timers.
struct DemoHomeView: View {
    @StateObject private var microphone = AudioCaptureController()
    @State private var display: DisplayMode = .gallery
    @State private var source: SignalSource = .demo
    @State private var currentStyle: AudioVisualizationStyle = .ribbon
    @State private var density: Double = 48
    @State private var intensity: Double = 1.0
    @State private var tint = Color.white
    @State private var showingFilePicker = false
    @State private var fileAmplitudes: [Float] = []
    @State private var audioPlayer: AVAudioPlayer?
    @State private var importedTempURL: URL?
    @State private var fileTitle: String = "Select audio file"
    @State private var importError: String?
    @State private var isDemoPaused = false
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let background = Color(red: 0.045, green: 0.048, blue: 0.052)
    private let surface = Color(red: 0.106, green: 0.113, blue: 0.123)
    private let outline = Color.white.opacity(0.065)
    private let sections = ["Waveforms", "Flow", "Spectrum", "Ambient"]

    private var styleCount: Int { AudioVisualizationStyle.allCases.count }

    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation(minimumInterval: 1.0 / 30.0,
                                    paused: (reduceMotion || isDemoPaused) && source == .demo)) { clock in
                let frame = presentationFrame(at: clock.date.timeIntervalSinceReferenceDate)
                ScrollView {
                    VStack(alignment: .leading, spacing: display == .minimal ? 12 : 20) {
                        if display != .minimal { header }
                        modeBar
                        switch display {
                        case .gallery: gallery(frame: frame)
                        case .minimal: minimalGrid(frame: frame, width: geometry.size.width)
                        case .studio: studio(frame: frame)
                        }
                        if display != .minimal { footer }
                    }
                    .padding(.horizontal, display == .minimal ? 12 : 20)
                    .padding(.top, display == .minimal ? 8 : 18)
                    .padding(.bottom, 24)
                    .frame(maxWidth: 850)
                    .frame(maxWidth: .infinity)
                }
                .scrollIndicators(.hidden)
            }
        }
        .background(background.ignoresSafeArea())
        .fileImporter(isPresented: $showingFilePicker, allowedContentTypes: [.audio]) { result in
            do { try importAudio(result.get()) }
            catch { importError = error.localizedDescription }
        }
        .alert("Audio import failed", isPresented: Binding(
            get: { importError != nil },
            set: { if !$0 { importError = nil } }
        )) {
            Button("OK", role: .cancel) { importError = nil }
        } message: {
            Text(importError ?? "Unknown error")
        }
        .onChange(of: source) { _, value in changeSource(value) }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active {
                microphone.stop()
                audioPlayer?.pause()
            } else if source == .microphone {
                startMicrophone()
            }
        }
        .onDisappear {
            microphone.stop()
            audioPlayer?.stop()
            if let importedTempURL { try? FileManager.default.removeItem(at: importedTempURL) }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image("BrandMark")
                .resizable()
                .scaledToFit()
                .frame(width: 42, height: 42)
                .padding(7)
                .background(surface, in: RoundedRectangle(cornerRadius: 15))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("AudioVisualKit")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .tracking(-0.8)
                Text("\(styleCount) audio visualizations · Pure SwiftUI")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.5))
            }
            Spacer(minLength: 4)
            Image(systemName: "waveform.path")
                .foregroundStyle(.white.opacity(0.4))
                .accessibilityHidden(true)
        }
    }

    private var modeBar: some View {
        HStack(spacing: 3) {
            ForEach(DisplayMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) { display = mode }
                } label: {
                    Text(mode.rawValue)
                        .font(.system(size: 13, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .frame(height: display == .minimal ? 32 : 40)
                        .foregroundStyle(display == mode ? .black : .white.opacity(0.65))
                        .background(display == mode ? Color.white : Color.clear,
                                    in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(display == mode ? .isSelected : [])
            }
        }
        .padding(4)
        .background(surface, in: RoundedRectangle(cornerRadius: 16))
    }

    private var sourceBar: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                sectionLabel("AUDIO SOURCE")
                Spacer()
                if source == .microphone && microphone.isRunning {
                    Label("LIVE", systemImage: "circle.fill")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.mint)
                }
            }
            HStack(spacing: 8) {
                ForEach(SignalSource.allCases, id: \.self) { option in
                    Button { source = option } label: {
                        Text(option.rawValue)
                            .font(.system(size: 12, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .foregroundStyle(source == option ? .black : .white.opacity(0.62))
                            .background(source == option ? Color.white : surface, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func sectionLabel(_ value: String) -> some View {
        Text(value)
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
            .tracking(1.6)
            .foregroundStyle(.white.opacity(0.45))
    }

    private func gallery(frame: AudioFrame) -> some View {
        VStack(alignment: .leading, spacing: 22) {
            sourceBar
            ForEach(sections, id: \.self) { group in
                let styles = AudioVisualizationStyle.allCases.filter { $0.group == group }
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        sectionLabel(group.uppercased())
                        Spacer()
                        Text("\(styles.count) EFFECTS")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.35))
                    }
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 10),
                                        GridItem(.flexible(), spacing: 10)], spacing: 10) {
                        ForEach(styles) { style in
                            Button {
                                currentStyle = style
                                withAnimation(.easeInOut(duration: 0.2)) { display = .studio }
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
        VStack(alignment: .leading, spacing: 8) {
            visual(style: style, frame: frame)
                .frame(height: 100)
                .frame(maxWidth: .infinity)
            HStack(spacing: 4) {
                Text(style.title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                Spacer(minLength: 1)
                if style.isNew {
                    Text("NEW")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 3)
                        .background(.white, in: Capsule())
                } else {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 10))
                        .foregroundStyle(.gray)
                }
            }
        }
        .padding(13)
        .background(surface, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(outline))
    }

    private func minimalGrid(frame: AudioFrame, width: CGFloat) -> some View {
        let compact = width < 620
        let columns = Array(repeating: GridItem(.flexible(), spacing: 6),
                            count: compact ? 3 : 4)
        return VStack(alignment: .leading, spacing: 11) {
            HStack(spacing: 8) {
                Image("BrandMark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                Text("AUDIOVISUALKIT")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .tracking(1)
                Spacer()
                Text("\(styleCount) EFFECTS")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.gray)
                Button { isDemoPaused.toggle() } label: {
                    Image(systemName: isDemoPaused ? "play.fill" : "pause.fill")
                        .frame(width: 30, height: 30)
                        .background(surface, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isDemoPaused ? "Play animation" : "Pause animation")
            }
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(AudioVisualizationStyle.allCases) { style in
                    VStack(spacing: 7) {
                        visual(style: style, frame: frame)
                            .frame(height: compact ? 64 : 90)
                        Text(style.title)
                            .font(.system(size: compact ? 8 : 10, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, compact ? 10 : 13)
                    .frame(maxWidth: .infinity)
                    .background(surface, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            Text("DEMO SIGNAL · ONE SHARED CLOCK · NO MIC REQUIRED")
                .font(.system(size: 8, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.42))
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
        }
    }

    private func studio(frame: AudioFrame) -> some View {
        VStack(alignment: .leading, spacing: 17) {
            sourceBar
            preview(frame: frame)
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    sectionLabel("VISUALIZATION")
                    Spacer()
                    Text("\(styleCount) STYLES")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.gray)
                }
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 7) {
                            ForEach(AudioVisualizationStyle.allCases) { style in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.18)) { currentStyle = style }
                                } label: {
                                    Text(style.title)
                                        .font(.system(size: 11, weight: .medium))
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 12)
                                        .foregroundStyle(style == currentStyle ? .black : .white.opacity(0.7))
                                        .background(style == currentStyle ? Color.white : surface,
                                                    in: Capsule())
                                }
                                .buttonStyle(.plain)
                                .id(style)
                            }
                        }
                    }
                    .onAppear { proxy.scrollTo(currentStyle, anchor: .center) }
                    .onChange(of: currentStyle) { _, style in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            proxy.scrollTo(style, anchor: .center)
                        }
                    }
                }
            }
            controls
            codeBlock
        }
    }

    private func preview(frame: AudioFrame) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    sectionLabel(currentStyle.group.uppercased())
                    HStack(spacing: 8) {
                        Text(currentStyle.title)
                            .font(.system(size: 26, weight: .semibold, design: .rounded))
                            .tracking(-0.5)
                        if currentStyle.isNew {
                            Text("NEW")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 4)
                                .background(.white, in: Capsule())
                        }
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                }
                Spacer()
                Text(String(format: "%02d", (AudioVisualizationStyle.allCases.firstIndex(of: currentStyle) ?? 0) + 1))
                    .font(.system(size: 19, weight: .light, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.38))
            }
            visual(style: currentStyle, frame: frame)
                .frame(height: 170)
                .frame(maxWidth: .infinity)
                .clipped()
            HStack(spacing: 6) {
                Circle()
                    .fill(source == .microphone && microphone.isRunning ? Color.mint : Color.white.opacity(0.5))
                    .frame(width: 6, height: 6)
                Text(source == .demo ? "LIVE PREVIEW" : source == .microphone ? "MIC INPUT" : "FILE PREVIEW")
                Spacer()
                Text("30 FPS TARGET")
            }
            .font(.system(size: 9, weight: .medium, design: .monospaced))
            .tracking(0.5)
            .foregroundStyle(.white.opacity(0.43))
        }
        .padding(20)
        .background(surface, in: RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(outline))
    }

    private var controls: some View {
        VStack(spacing: 17) {
            VStack(spacing: 5) {
                HStack {
                    Text("Density")
                    Spacer()
                    Text("\(Int(density))").foregroundStyle(.white.opacity(0.5))
                }
                Slider(value: $density, in: 16...96, step: 8).tint(.white)
                    .accessibilityLabel("Density")
            }
            VStack(spacing: 5) {
                HStack {
                    Text("Intensity")
                    Spacer()
                    Text(String(format: "%.1fx", intensity)).foregroundStyle(.white.opacity(0.5))
                }
                Slider(value: $intensity, in: 0.2...2.0, step: 0.1).tint(.white)
                    .accessibilityLabel("Intensity")
            }
            Rectangle().fill(.white.opacity(0.08)).frame(height: 1)
            HStack {
                Text("Color")
                Spacer()
                ForEach([Color.white, .mint, .purple], id: \.self) { option in
                    Button { tint = option } label: {
                        Circle()
                            .fill(option)
                            .frame(width: 25, height: 25)
                            .padding(4)
                            .overlay(Circle().strokeBorder(.white.opacity(tint == option ? 0.95 : 0), lineWidth: 2))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(option == .white ? "White" : option == .mint ? "Mint" : "Purple")
                    .accessibilityAddTraits(tint == option ? .isSelected : [])
                }
            }
            if source == .file {
                Text("File mode uses the waveform envelope. Frequency-spectrum styles need a playback FFT adapter.")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.45))
                    .frame(maxWidth: .infinity, alignment: .leading)
                fileControl
            }
        }
        .font(.system(size: 12, weight: .medium))
        .padding(18)
        .background(surface, in: RoundedRectangle(cornerRadius: 19))
    }

    private var codeBlock: some View {
        let snippet = "AudioVisualizer(style: .\(currentStyle.rawValue), frame: frame)"
        return HStack(spacing: 7) {
            Image(systemName: "chevron.left.forwardslash.chevron.right")
                .foregroundStyle(.white.opacity(0.35))
            Text(snippet)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.white.opacity(0.75))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .textSelection(.enabled)
            Spacer(minLength: 0)
            Button { UIPasteboard.general.string = snippet } label: {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 14))
                    .frame(width: 36, height: 36)
                    .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Copy Swift code")
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 9)
        .background(surface, in: RoundedRectangle(cornerRadius: 15))
    }

    private var fileControl: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button { showingFilePicker = true } label: {
                Label(fileTitle, systemImage: "doc.badge.plus")
                    .lineLimit(1)
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            if let player = audioPlayer {
                HStack {
                    Button {
                        if player.isPlaying { player.pause() } else { player.play() }
                    } label: {
                        Label(player.isPlaying ? "Pause" : "Play",
                              systemImage: player.isPlaying ? "pause.fill" : "play.fill")
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    Text(String(format: "%.0fs / %.0fs", player.currentTime, player.duration))
                        .foregroundStyle(.gray)
                        .font(.system(size: 10, design: .monospaced))
                }
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule().fill(.gray.opacity(0.3))
                        Capsule().fill(.white).frame(width: geometry.size.width *
                            CGFloat(player.duration > 0 ? player.currentTime / player.duration : 0))
                    }
                    .frame(height: 3)
                }
                .frame(height: 6)
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
        .tracking(0.6)
        .foregroundStyle(.white.opacity(0.34))
    }

    private func visual(style: AudioVisualizationStyle, frame: AudioFrame) -> some View {
        AudioVisualizer(style: style, frame: frame,
                        color: tint, secondaryColor: .gray, density: Int(density))
    }

    private func presentationFrame(at time: TimeInterval) -> AudioFrame {
        let result: AudioFrame
        switch source {
        case .demo:
            result = DemoAudioSignal.frame(at: reduceMotion || isDemoPaused ? 1.1 : time)
        case .microphone:
            result = microphone.frame
        case .file:
            guard !fileAmplitudes.isEmpty else { return .silence }
            let progress = audioPlayer.map { $0.duration > 0 ? $0.currentTime / $0.duration : 0 } ?? 0
            let idx = min(fileAmplitudes.count - 1,
                          max(0, Int(progress * Double(fileAmplitudes.count))))
            result = AudioFrame(amplitude: fileAmplitudes[idx],
                                levels: fileAmplitudes, timestamp: time)
        }
        let m = Float(intensity)
        return AudioFrame(amplitude: min(1, result.amplitude * m),
                          peak: min(1, result.peak * m),
                          levels: result.levels.map { min(1, $0 * m) },
                          spectrum: result.spectrum.map { min(1, $0 * m) },
                          timestamp: result.timestamp)
    }

    private func changeSource(_ option: SignalSource) {
        if option != .microphone { microphone.stop() }
        if option != .file { audioPlayer?.stop() }
        if option == .microphone { startMicrophone() }
        if option == .file && fileAmplitudes.isEmpty { showingFilePicker = true }
    }

    private func startMicrophone() {
        Task {
            do { try await microphone.start() }
            catch {
                if source == .microphone {
                    importError = error.localizedDescription
                    source = .demo
                }
            }
        }
    }

    private func importAudio(_ url: URL) throws {
        let granted = url.startAccessingSecurityScopedResource()
        defer { if granted { url.stopAccessingSecurityScopedResource() } }
        let name = url.lastPathComponent
        let temp = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + "-" + name)
        do {
            try FileManager.default.copyItem(at: url, to: temp)
            let levels = try AudioFileWaveform.amplitudes(url: temp, sampleCount: 180)
            let player = try AVAudioPlayer(contentsOf: temp)
            player.prepareToPlay()
            audioPlayer?.stop()
            if let importedTempURL { try? FileManager.default.removeItem(at: importedTempURL) }
            importedTempURL = temp
            fileAmplitudes = levels
            audioPlayer = player
            fileTitle = name
        } catch {
            try? FileManager.default.removeItem(at: temp)
            throw error
        }
    }
}
