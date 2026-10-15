<div align="center">
<img src="Docs/Assets/logo-mark.png" width="104" alt="AudioVisualKit 标志">

# AudioVisualKit

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%2017%20%7C%20macOS%2014-lightgrey.svg)](https://developer.apple.com)


**24 种 SwiftUI 声音可视化效果。原生 SPM，零第三方依赖。**

[English README](README.md) · [开发约定](CONTRIBUTING.md) · [测试清单](Docs/TESTING.md)

<img src="Docs/Assets/hero.png" alt="音频可视化项目品牌宣传图">

*上图为品牌宣传素材，并非应用实际运行截图。*

<img src="Docs/Assets/demo.gif" width="380" alt="AudioVisualKit 真机运行录屏">

*真机运行录屏。完整演示视频见 [Docs/demo.mp4](Docs/demo.mp4)。*

</div>

> **V3 状态：** 已完成语法检查和 Foundation 模型类型检查。V3 新代码尚未通过 Xcode/iOS SDK 编译和真机验收，不能将旧版的测试结果视为新版结果。详见[QA 报告](Docs/QA_REPORT.md)。

## 包含内容

- 原始 16 种 + 新增 8 种视觉效果，共 **24 种**。
- **Gallery**：分类浏览并选择效果。
- **Minimal**：3/4 列高密度动画矩阵，便于录制 GitHub GIF。
- **Studio**：大预览、样式选择、密度、强度、颜色及代码复制。
- **Demo / Microphone / Audio File**：模拟数据、实时麦克风和本地文件波形。
- **SwiftUI Canvas**：所有组件背景透明，业务工程提供 `AudioFrame`，组件不自动启动计时器或录音。

## 进阶可视化效果

| 分类 | 效果 | 特点 |
| --- | --- | --- |
| Waveforms | Oscilloscope | 随声音起伏的示波器曲线 |
| Flow | Double Helix | 双股螺旋曲线与连接线 |
| Flow | Aurora Curtain | 多层透明极光幕布 |
| Flow | Neon Ribbon | 多层高亮流动细线 |
| Spectrum | Starburst | 放射状频段尖芒 |
| Ambient | Orbiting Arcs | 多圈反向轨道与动态端点 |
| Ambient | Lotus | 随音量变化的十瓣花 |
| Ambient | Vortex | 三股旋转涡线 |

## 使用

在其他工程中通过 **Xcode → File → Add Package Dependencies** 添加：

```
https://github.com/YOUR_ACCOUNT/AudioVisualKit.git
```

请将 `YOUR_ACCOUNT` 替换为实际 GitHub 用户名，并在发布可用的版本 Tag 后使用 `from:` 锁定发行版本。本地开发可直接用 **Add Local…** 添加本目录，Demo 工程已通过本地 Swift Package 引用根目录 `Package.swift`，无需联网。

```swift
import AudioVisualKit

AudioVisualizer(
    style: .auroraCurtain,
    frame: audioFrame,
    color: .white,
    secondaryColor: .gray,
    density: 48
)
.frame(height: 120)
```

应用需要自备 `audioFrame`；演示阶段可通过 `DemoAudioSignal.frame(at:)` 生成模拟数据。请在上层视图使用统一的 `TimelineView` 驱动所有动画。

录音需要 `NSMicrophoneUsageDescription`。如果已有录音引擎，建议**复用现有 `AVAudioEngine` 并转换成 `AudioFrame`**，不要启动第二套录音会话。

本地文件现在支持 `AudioFileWaveform.analyze(url:)` 在后台分析实际 FFT 频段、PCM 与振幅包络，随后通过 `AudioFileAnalysis.frame(at:)` 按播放器的当前时间取帧。旧的 `amplitudes(url:)` 仍只提取振幅包络。见 [使用示例](Docs/RECIPES.md) 和 [测试清单](Docs/TESTING.md)。

## 运行 Demo

在 Xcode 中打开 `Demo/AudioVisualKitDemo.xcodeproj`，选择模拟器或真机（需要签名时填入自己的开发团队），即可切换 **Gallery / Minimal / Studio** 三种模式与 Demo / Microphone / Audio File 三种数据源。

## 本地校验

```bash
swift build
swift test
```

工程默认**不包含 GitHub Actions 工作流**，请先在自己的 macOS/Xcode 环境中验证。

## 待完成验收

- [ ] iPhone 真机麦克风授权、开始、停止、切后台、恢复
- [ ] 24 种动画视觉与缩放验收
- [ ] Minimal 多组件帧率、能耗和内存测试
- [x] 真机录制演示视频并转制 README 内联 GIF（`Docs/Assets/demo.gif`，完整视频 `Docs/demo.mp4`）
- [ ] 发布 Release Notes

其他材料：`LICENSE`、`CONTRIBUTING.md`、`CODE_OF_CONDUCT.md`、`SECURITY.md`、`CHANGELOG.md`。

## V3 数据与修复说明

现在 `AudioFrame` 区分四种输入：`levels`（波形包络）、`history`（时间递增的历史音量）、`spectrum`（实际 FFT 频段）与 `samples`（有符号 PCM）。其中示波器不再通过合成正弦波模拟真实 PCM。音频文件模式会在后台预分析，获得随播放时间变化的 FFT 与 PCM 快照。Minimal 模式固定使用完整模拟数据，并在进入时停止麦克风。已移除所有 `NEW` 徽标。

**验证说明：** 本次新版 V3 已完成 Swift 语法及纯模型类型检查，但还没有在当前环境中执行 Xcode/iOS SDK 编译和真机测试；以前版本的测试成功不等于本次新版已通过。详见 `Docs/QA_REPORT.md` 与 `Docs/TESTING.md`。
