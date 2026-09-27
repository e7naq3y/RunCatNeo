# RunCat Neo GPU

**RunCat Neo, plus the GPU.** An unofficial fork of [RunCat Neo](https://github.com/runcat-dev/RunCatNeo) that adds a GPU card, CPU/GPU temperatures and a GPU‑aware runner to the cute menu‑bar cat (or drop, or dog…) on macOS 26.

[中文说明 / Chinese README](README.zh-CN.md)

[![Release](https://img.shields.io/github/v/release/e7naq3y/RunCatNeo)](https://github.com/e7naq3y/RunCatNeo/releases/latest)
[![Downloads](https://img.shields.io/github/downloads/e7naq3y/RunCatNeo/total)](https://github.com/e7naq3y/RunCatNeo/releases)
[![License](https://img.shields.io/github/license/e7naq3y/RunCatNeo)](LICENSE)
[![Stars](https://img.shields.io/github/stars/e7naq3y/RunCatNeo)](https://github.com/e7naq3y/RunCatNeo/stargazers)

`macOS 26+` `Apple Silicon` `Swift 6` `SwiftUI` `no sudo` `no daemon`

## What this fork adds

| | RunCat Neo (App Store) | **RunCat Neo GPU** |
|---|:---:|:---:|
| CPU / memory / storage / battery / network cards | ✅ | ✅ |
| **GPU card**: utilization graph, renderer & tiler load, model and core count | ❌ | ✅ |
| **CPU temperature** and **GPU temperature** (hottest core) | ❌ | ✅ |
| GPU usage in the metrics bar | ❌ | ✅ |
| Runner speed follows **CPU / GPU / whichever is busier** | CPU only | ✅ |
| Custom runners, custom JSON metrics, 10 languages | ✅ | ✅ |
| App Sandbox / App Store | ✅ | ❌ (see [why](#why-is-this-not-on-the-app-store)) |

The dashboard on an M5 Max, for example:

```
CPU: 14.4%      System / User / Idle
                Temperature: 60.0°C            ▁▂▂▃▅▃▂▁▁▂
GPU: 41.0%      Renderer: 41.0%  Tiler: 12.0%
                Apple M5 Max · 40 cores
                Temperature: 55.2°C            ▃▅▇▇▆▅▃▂▂▃
Memory / Storage / Battery (with temperature) / Network as upstream
```

## Download

1. Get `RunCatNeoGPU-<version>.zip` from the **[latest release](https://github.com/e7naq3y/RunCatNeo/releases/latest)**.
2. Unzip it and drag `RunCatNeo.app` into `/Applications`.
3. **First launch** – macOS will refuse to open the app because this build is not notarized (there is no paid Apple Developer ID behind this fork). Do one of the following once:
   - open **System Settings → Privacy & Security**, scroll down to *Security* and click **Open Anyway**, or
   - run in Terminal: `xattr -dr com.apple.quarantine /Applications/RunCatNeo.app`
4. Click the runner in the menu bar to see the dashboard. If nothing shows up, make sure the app is allowed under **System Settings → Menu Bar** (macOS 26 can hide menu‑bar items per app).

Requirements: macOS 26 or later. Temperatures and the GPU card are built for Apple Silicon (M1 → M5); Intel Macs get CPU/GPU temperatures from the classic SMC keys and GPU usage where the driver reports it.

## Settings

- **Runner → Speed follows**: *CPU usage*, *GPU usage* or *Higher of CPU and GPU* (default). The drop, cat or whatever you picked speeds up with the load you choose.
- **Metrics → Enable GPU usage monitoring**: on by default; turning it off hides the card.
- **Metrics → Menu bar → Show GPU usage**: adds `GPU 41.0%` next to the CPU figure.

Everything else – custom runners from the [Runner Gallery](https://runcat-dev.github.io/RunnerGallery/), [custom JSON metrics](docs/CustomMetricsSchema.md), update interval, launch at login – works exactly like upstream.

## How it works

- **GPU usage** comes from IOKit: `IOAccelerator` → `PerformanceStatistics` (`Device`, `Renderer` and `Tiler Utilization %`), plus `model` and `gpu-core-count`. This is the same source Activity Monitor uses. No root, no helper, no `powermetrics`.
- **Temperatures** come from the AppleSMC user client. On Apple Silicon the `Tp*`/`Te*` keys are CPU cores and `Tg*` keys are GPU cores (M3 uses a fixed `Tf*` table); Intel Macs use `TC*`/`TG*`. All ~3,700 SMC keys are enumerated once at launch (≈0.6 s), afterwards only the ~100 relevant keys are read per refresh (a few milliseconds). The displayed value is the hottest core.
- **Runner speed** keeps upstream's formula (`load% ÷ 5`, clamped to 1×–20×); only the load source is selectable.
- Sampling runs on the same 3 / 5 / 10 s timer as the rest of RunCat Neo, so the extra cost is negligible.

## Why is this not on the App Store?

App Store apps run in the App Sandbox, and the sandbox blocks both the `IOAccelerator` statistics and the AppleSMC user client – which is exactly why upstream RunCat Neo has no GPU tab. This fork turns the sandbox off, so it can only be distributed outside the store and is signed ad‑hoc. Upstream's in‑app donation tab depends on App Store purchases and has been removed; if you like RunCat, please support the original author through the [App Store version](https://apps.apple.com/us/app/runcat-neo/id6757801838).

## Build from source

Requires Xcode 26.5+ (Swift 6.2).

```bash
git clone https://github.com/e7naq3y/RunCatNeo.git
cd RunCatNeo
xcodebuild -project RunCatNeo.xcodeproj -scheme RunCatNeo -configuration Release \
  -derivedDataPath build -destination 'platform=macOS' \
  CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM= PROVISIONING_PROFILE_SPECIFIER= \
  -skipPackagePluginValidation build
ditto build/Build/Products/Release/RunCatNeo.app /Applications/RunCatNeo.app
```

Unit tests (157, including the GPU and temperature cases):

```bash
cd LocalPackage && xcodebuild test -scheme LocalPackage-Package -destination 'platform=macOS'
```

## Branches

- `main` – this fork.
- `upstream-main` – an untouched mirror of `runcat-dev/RunCatNeo`, kept for rebasing. The complete list of touched files is in [CHANGELOG.md](CHANGELOG.md).

## Credits & license

RunCat Neo is created by [Takuto Nakamura (Kyome22)](https://github.com/Kyome22) and the [RunCat developers](https://github.com/runcat-dev) and is licensed under Apache‑2.0. This fork is **not affiliated with or endorsed by** the RunCat developers; “RunCat” is their project and their name. The changes in this fork are released under the same Apache‑2.0 license – see [LICENSE](LICENSE) and [CHANGELOG.md](CHANGELOG.md).
