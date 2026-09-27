# RunCat Neo GPU

**给 RunCat Neo 补上 GPU。** 这是 [RunCat Neo](https://github.com/runcat-dev/RunCatNeo) 的非官方 fork：在 macOS 26 的菜单栏小猫（或水滴、小狗……）基础上，加上 GPU 卡片、CPU/GPU 温度，并让跑者按 GPU 负载变速。

[English README](README.md)

[![Release](https://img.shields.io/github/v/release/e7naq3y/RunCatNeo)](https://github.com/e7naq3y/RunCatNeo/releases/latest)
[![Downloads](https://img.shields.io/github/downloads/e7naq3y/RunCatNeo/total)](https://github.com/e7naq3y/RunCatNeo/releases)
[![License](https://img.shields.io/github/license/e7naq3y/RunCatNeo)](LICENSE)
[![Stars](https://img.shields.io/github/stars/e7naq3y/RunCatNeo)](https://github.com/e7naq3y/RunCatNeo/stargazers)

`macOS 26+` `Apple Silicon` `Swift 6` `SwiftUI` `无需 sudo` `无常驻服务`

## 这个 fork 多了什么

| | RunCat Neo（App Store 版） | **RunCat Neo GPU** |
|---|:---:|:---:|
| CPU / 内存 / 储存 / 电池 / 网络卡片 | ✅ | ✅ |
| **GPU 卡片**：占用率折线图、渲染器与分块器占用、型号与核心数 | ❌ | ✅ |
| **CPU 温度**与 **GPU 温度**（最热核心） | ❌ | ✅ |
| 菜单栏指标里显示 GPU 使用率 | ❌ | ✅ |
| 跑者速度依据 **CPU / GPU / 两者较高者** | 仅 CPU | ✅ |
| 自定义跑者、自定义 JSON 指标、10 种语言 | ✅ | ✅ |
| App Sandbox / App Store 上架 | ✅ | ❌（[原因](#为什么不上-app-store)） |

在 M5 Max 上的面板大致是这样：

```
CPU：14.4%      系统 / 用户 / 闲置
                温度：60.0°C                  ▁▂▂▃▅▃▂▁▁▂
GPU：41.0%      渲染器：41.0%  分块器：12.0%
                Apple M5 Max · 40 核心
                温度：55.2°C                  ▃▅▇▇▆▅▃▂▂▃
内存 / 储存 / 电池（含温度）/ 网络 与上游一致
```

## 下载安装

1. 到 **[最新 Release](https://github.com/e7naq3y/RunCatNeo/releases/latest)** 下载 `RunCatNeoGPU-<版本>.zip`。
2. 解压，把 `RunCatNeo.app` 拖进「应用程序」。
3. **第一次打开**会被 macOS 拦下，因为这个构建没有经过公证（这个 fork 背后没有付费的 Apple Developer ID）。任选一种方式，只需做一次：
   - 打开 **系统设置 → 隐私与安全性**，往下拉到「安全性」，点 **仍要打开**；或
   - 在终端执行：`xattr -dr com.apple.quarantine /Applications/RunCatNeo.app`
4. 点菜单栏里的跑者即可看到面板。如果菜单栏里没出现，去 **系统设置 → 菜单栏** 确认允许了它（macOS 26 可以按 App 隐藏菜单栏项目）。

系统要求：macOS 26 或更高。温度与 GPU 卡片按 Apple Silicon（M1 → M5）设计；Intel 机型的温度走传统 SMC 键，GPU 占用视驱动是否上报而定。

## 设置项

- **跑者 → 跑者速度依据**：*CPU 使用率* / *GPU 使用率* / *CPU 与 GPU 中较高者*（默认）。你选的水滴、小猫会按这个负载加速。
- **指标 → 启用 GPU 使用率监控**：默认开启，关掉即隐藏卡片。
- **指标 → 菜单栏 → 显示 GPU 使用率**：在 CPU 数字旁边加上 `GPU 41.0%`。

其它功能——[Runner Gallery](https://runcat-dev.github.io/RunnerGallery/) 的自定义跑者、[自定义 JSON 指标](docs/CustomMetricsSchema.md)、刷新间隔、登录时启动——和上游完全一样。

## 实现原理

- **GPU 占用**来自 IOKit：`IOAccelerator` → `PerformanceStatistics`（`Device` / `Renderer` / `Tiler Utilization %`），外加 `model` 与 `gpu-core-count`。这和活动监视器用的是同一个来源，不需要 root、不需要辅助进程、不用 `powermetrics`。
- **温度**来自 AppleSMC 用户客户端。Apple Silicon 上 `Tp*` / `Te*` 是 CPU 核心、`Tg*` 是 GPU 核心（M3 系列用固定的 `Tf*` 键表）；Intel 用 `TC*` / `TG*`。启动时把约 3700 个 SMC 键枚举一遍（约 0.6 秒），之后每次刷新只读约 100 个相关键（几毫秒）。显示的是最热的核心。
- **跑者速度**沿用上游公式（`负载% ÷ 5`，限制在 1×–20×），只是负载来源可选。
- 采样与 RunCat Neo 其余部分共用同一个 3 / 5 / 10 秒定时器，额外开销可以忽略。

## 为什么不上 App Store

App Store 的 App 必须运行在沙盒里，而沙盒同时挡住了 `IOAccelerator` 统计和 AppleSMC 用户客户端——这正是上游 RunCat Neo 没有 GPU 的原因。这个 fork 关闭了沙盒，所以只能在商店外分发，签名是 ad-hoc 的。上游的「捐赠」页依赖 App 内购，已移除；如果你喜欢 RunCat，请通过 [App Store 版](https://apps.apple.com/us/app/runcat-neo/id6757801838)支持原作者。

## 从源码构建

需要 Xcode 26.5+（Swift 6.2）。

```bash
git clone https://github.com/e7naq3y/RunCatNeo.git
cd RunCatNeo
xcodebuild -project RunCatNeo.xcodeproj -scheme RunCatNeo -configuration Release \
  -derivedDataPath build -destination 'platform=macOS' \
  CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM= PROVISIONING_PROFILE_SPECIFIER= \
  -skipPackagePluginValidation build
ditto build/Build/Products/Release/RunCatNeo.app /Applications/RunCatNeo.app
```

单元测试（157 个，含 GPU 与温度用例）：

```bash
cd LocalPackage && xcodebuild test -scheme LocalPackage-Package -destination 'platform=macOS'
```

## 分支

- `main`——这个 fork。
- `upstream-main`——`runcat-dev/RunCatNeo` 的原样镜像，用来同步上游。改动过的文件清单见 [CHANGELOG.md](CHANGELOG.md)。

## 致谢与许可

RunCat Neo 由 [Takuto Nakamura（Kyome22）](https://github.com/Kyome22) 与 [RunCat 开发者社区](https://github.com/runcat-dev)创作，采用 Apache-2.0 许可。本 fork **与 RunCat 开发者无关，也未获其背书**；"RunCat" 是他们的项目与名称。本 fork 的改动同样以 Apache-2.0 发布，见 [LICENSE](LICENSE) 与 [CHANGELOG.md](CHANGELOG.md)。
