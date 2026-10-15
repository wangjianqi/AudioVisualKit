<div align="center">
<img src="Docs/Assets/logo-mark.png" width="104" alt="AudioVisualKit 标志">

# AudioVisualKit

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%2017%20%7C%20macOS%2014-lightgrey.svg)](https://developer.apple.com)
[![CI](https://github.com/wangjianqi/AudioVisualKit/actions/workflows/ci.yml/badge.svg)](https://github.com/wangjianqi/AudioVisualKit/actions/workflows/ci.yml)

**24 种 SwiftUI 声音可视化效果。原生 SPM，零第三方依赖。**

[English README](README.md) · [开发约定](CONTRIBUTING.md) · [测试清单](Docs/TESTING.md)

<img src="Docs/Assets/hero.png" alt="音频可视化项目品牌宣传图">

*上图为品牌宣传素材，并非应用实际运行截图。*
</div>

> **状态声明：** 库与 Demo 已通过 macOS 编译、iOS 模拟器编译，包测试全部通过。真机录音、帧率与功耗尚未实测，详见[测试清单](Docs/TESTING.md)。

## 包含内容

- 原始 16 种 + 新增 8 种视觉效果，共 **24 种**。
- **Gallery**：分类浏览并选择效果。
- **Minimal**：3/4 列高密度动画矩阵，便于录制 GitHub GIF。
- **Studio**：大预览、样式选择、密度、强度、颜色及代码复制。
- **Demo / Microphone / Audio File**：模拟数据、实时麦克风和本地文件波形。
- **SwiftUI Canvas**：所有组件背景透明，业务工程提供 `AudioFrame`，组件不自动启动计时器或录音。

## 新增 8 种效果

| 分类 | 新增效果 | 特点 |
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
https://github.com/wangjianqi/AudioVisualKit.git
```

或在 `Package.swift` 中声明依赖（`from: "1.0.0"` 起）。本地开发可直接用 **Add Local…** 添加本目录，Demo 工程已通过本地 Swift Package 引用根目录 `Package.swift`，无需联网。

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

本地音频文件目前只提取振幅包络，不会自动生成实时 FFT 频谱。见 [使用示例](Docs/RECIPES.md) 和 [测试清单](Docs/TESTING.md)。

## 运行 Demo

在 Xcode 中打开 `Demo/AudioVisualKitDemo.xcodeproj`，选择模拟器或真机（需要签名时填入自己的开发团队），即可切换 **Gallery / Minimal / Studio** 三种模式与 Demo / Microphone / Audio File 三种数据源。

## 本地校验

```bash
swift build
swift test
```

CI（GitHub Actions）在每次 push 与 PR 时执行同样命令。

## 待完成验收

- [ ] iPhone 真机麦克风授权、开始、停止、切后台、恢复
- [ ] 24 种动画视觉与缩放验收
- [ ] Minimal 多组件帧率、能耗和内存测试
- [ ] 真机或模拟器录制 GIF，替换 README 中的概念图
- [ ] 发布 Release Notes

其他材料：`LICENSE`、`CONTRIBUTING.md`、`CODE_OF_CONDUCT.md`、`SECURITY.md`、`CHANGELOG.md`。
