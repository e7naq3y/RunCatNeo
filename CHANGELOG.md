# Changelog

All changes below are relative to upstream [runcat-dev/RunCatNeo](https://github.com/runcat-dev/RunCatNeo) (branch `upstream-main`). Per Apache-2.0 §4(b), every modified source file also carries a "Modified by the RunCat Neo GPU fork" notice in its header.

## 1.1.0 – 2026-09-27

### Added
- GPU card on the dashboard: device utilization graph, renderer / tiler utilization, GPU model and core count (`GPUInfoClient`, IOKit `IOAccelerator`).
- CPU and GPU temperature lines (hottest core) read from AppleSMC (`ThermalClient`); Apple Silicon `Tp*`/`Te*`/`Tg*` families, fixed `Tf*` table for M3, `TC*`/`TG*` for Intel.
- "Speed follows" setting for the runner: CPU usage / GPU usage / higher of the two (default).
- "Enable GPU usage monitoring" and "Show GPU usage" (metrics bar) toggles.
- Custom `gpu` SF Symbol.
- Strings for the new UI in all 10 languages.
- 14 unit tests (`GPUMetricsTests`, `ThermalMetricsTests`).

### Changed
- App Sandbox disabled (`ENABLE_APP_SANDBOX = NO`): the sandbox blocks `IOAccelerator` statistics and the AppleSMC user client.
- Security-scoped bookmark access treats a non-sandboxed process as always allowed, so custom JSON metrics keep working without the sandbox.
- Bundle identifier `io.github.e7naq3y.RunCatNeoGPU`, display name "RunCat Neo GPU", version 1.1.0, so the fork never collides with the App Store app.
- "Report issue" / "About" links point to this repository.

### Removed
- Donation tab (depends on upstream's App Store in-app purchases, which cannot load outside the store).

### Touched files
- `CHANGELOG.md`
- `LocalPackage/Sources/DataSource/Dependencies/GPUInfoClient.swift`
- `LocalPackage/Sources/DataSource/Dependencies/ThermalClient.swift`
- `LocalPackage/Sources/DataSource/Dependencies/URLClient.swift`
- `LocalPackage/Sources/DataSource/Entities/Metrics/GPUInfo.swift`
- `LocalPackage/Sources/DataSource/Entities/Metrics/Metrics.swift`
- `LocalPackage/Sources/DataSource/Entities/Metrics/MetricsBarConfiguration.swift`
- `LocalPackage/Sources/DataSource/Entities/Metrics/RunnerSpeedSource.swift`
- `LocalPackage/Sources/DataSource/Entities/Metrics/SystemMetricsConfiguration.swift`
- `LocalPackage/Sources/DataSource/Entities/Metrics/ThermalInfo.swift`
- `LocalPackage/Sources/DataSource/Extensions/ProcessInfo+Extension.swift`
- `LocalPackage/Sources/DataSource/Extensions/String+Extension.swift`
- `LocalPackage/Sources/DataSource/Repositories/UserDefaultsRepository.swift`
- `LocalPackage/Sources/Model/AppDelegate.swift`
- `LocalPackage/Sources/Model/AppDependencies.swift`
- `LocalPackage/Sources/Model/Extensions/URL+Extension.swift`
- `LocalPackage/Sources/Model/Services/RunnerService.swift`
- `LocalPackage/Sources/Model/Services/SystemMetricsService.swift`
- `LocalPackage/Sources/Model/Stores/Dashboard.swift`
- `LocalPackage/Sources/Model/Stores/MetricsBar.swift`
- `LocalPackage/Sources/Model/Stores/MetricsBarSettings.swift`
- `LocalPackage/Sources/Model/Stores/MetricsSettings.swift`
- `LocalPackage/Sources/Model/Stores/RunnerSettings.swift`
- `LocalPackage/Sources/UserInterface/Extensions/GPUInfo+Extension.swift`
- `LocalPackage/Sources/UserInterface/Extensions/GraphicsContext+Extension.swift`
- `LocalPackage/Sources/UserInterface/Extensions/RunnerSpeedSource+Extension.swift`
- `LocalPackage/Sources/UserInterface/Extensions/ThermalInfo+Extension.swift`
- `LocalPackage/Sources/UserInterface/Resources/Localizable.xcstrings`
- `LocalPackage/Sources/UserInterface/Resources/Media.xcassets/Symbols/gpu.symbolset/Contents.json`
- `LocalPackage/Sources/UserInterface/Resources/Media.xcassets/Symbols/gpu.symbolset/gpu.svg`
- `LocalPackage/Sources/UserInterface/Views/MetricsBar/MetricsBarSettingsView.swift`
- `LocalPackage/Sources/UserInterface/Views/MetricsBar/MetricsBarView.swift`
- `LocalPackage/Sources/UserInterface/Views/RunnerBar/Dashboard/DashboardView.swift`
- `LocalPackage/Sources/UserInterface/Views/RunnerBar/Dashboard/SystemInfoStackView.swift`
- `LocalPackage/Sources/UserInterface/Views/RunnerBar/Dashboard/SystemInfoView.swift`
- `LocalPackage/Sources/UserInterface/Views/Settings/MetricsSettings/MetricsSettingsView.swift`
- `LocalPackage/Sources/UserInterface/Views/Settings/RunnerSettings/RunnerSettingsView.swift`
- `LocalPackage/Sources/UserInterface/Views/Settings/SettingsView.swift`
- `LocalPackage/Tests/ModelTests/ServiceTests/GPUMetricsTests.swift`
- `LocalPackage/Tests/ModelTests/ServiceTests/ThermalMetricsTests.swift`
- `LocalPackage/Tests/ModelTests/StoreTests/DashboardTests.swift`
- `README.md`
- `README.zh-CN.md`
- `RunCatNeo.xcodeproj/project.pbxproj`
- `RunCatNeo/InfoPlist.xcstrings`
