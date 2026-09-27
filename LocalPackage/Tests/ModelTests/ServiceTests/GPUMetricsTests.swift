import AllocatedUnfairLock
import Foundation
import SystemInfoKit
import Testing

@testable import DataSource
@testable import Model

struct GPUMetricsTests {
    private func cpuInfo(_ rawValue: Double) -> CPUInfo {
        CPUInfo(percentage: Percentage(rawValue: rawValue), system: .zero, user: .zero, idle: .zero)
    }

    @Test
    func updateMetrics_stores_gpu_info_and_appends_ring_buffer() {
        let appState = AllocatedUnfairLock<AppState>(initialState: .init())
        let sut = SystemMetricsService(.testDependencies(
            appStateClient: .testDependency(appState),
            gpuInfoClient: testDependency(of: GPUInfoClient.self) {
                $0.read = { GPUInfo(utilization: 60.0, renderer: 25.0, tiler: 12.0) }
            }
        ))
        let gpuInfo = sut.updateMetrics(from: SystemInfoBundle())
        #expect(gpuInfo?.utilization == 60.0)
        let metrics = appState.withLock(\.metrics.latestValue)
        #expect(metrics?.gpuInfo?.renderer == 25.0)
        #expect(metrics?.gpuRingBuffer.values.last == 60.0)
    }

    @Test
    func updateMetrics_skips_gpu_when_card_is_hidden_and_speed_follows_cpu() throws {
        let appState = AllocatedUnfairLock<AppState>(initialState: .init())
        let configuration = SystemMetricsConfiguration(
            monitorsMemory: true,
            monitorsStorage: true,
            monitorsBattery: true,
            monitorsNetwork: true,
            monitorsGPU: false
        )
        let configurationData = try JSONEncoder().encode(configuration)
        let readCount = AllocatedUnfairLock<Int>(initialState: 0)
        let sut = SystemMetricsService(.testDependencies(
            appStateClient: .testDependency(appState),
            gpuInfoClient: testDependency(of: GPUInfoClient.self) {
                $0.read = {
                    readCount.withLock { $0 += 1 }
                    return GPUInfo(utilization: 60.0)
                }
            },
            userDefaultsClient: testDependency(of: UserDefaultsClient.self) {
                $0.data = { _ in configurationData }
                $0.string = { _ in RunnerSpeedSource.cpu.rawValue }
            }
        ))
        let gpuInfo = sut.updateMetrics(from: SystemInfoBundle())
        #expect(gpuInfo == nil)
        #expect(readCount.withLock(\.self) == 0)
        #expect(appState.withLock(\.metrics.latestValue)?.gpuInfo == nil)
    }

    @Test
    func updateMetrics_reads_gpu_for_runner_speed_even_when_card_is_hidden() throws {
        let appState = AllocatedUnfairLock<AppState>(initialState: .init())
        let configuration = SystemMetricsConfiguration(
            monitorsMemory: true,
            monitorsStorage: true,
            monitorsBattery: true,
            monitorsNetwork: true,
            monitorsGPU: false
        )
        let configurationData = try JSONEncoder().encode(configuration)
        let sut = SystemMetricsService(.testDependencies(
            appStateClient: .testDependency(appState),
            gpuInfoClient: testDependency(of: GPUInfoClient.self) {
                $0.read = { GPUInfo(utilization: 60.0) }
            },
            userDefaultsClient: testDependency(of: UserDefaultsClient.self) {
                $0.data = { _ in configurationData }
                $0.string = { _ in RunnerSpeedSource.max.rawValue }
            }
        ))
        let gpuInfo = sut.updateMetrics(from: SystemInfoBundle())
        #expect(gpuInfo?.utilization == 60.0)
        let metrics = appState.withLock(\.metrics.latestValue)
        #expect(metrics?.gpuInfo == nil)
        #expect(metrics?.gpuRingBuffer.values == RingBuffer().values)
    }

    @Test
    func toggleGPUMonitoring_off_clears_gpu_info_and_ring_buffer() {
        let appState = AllocatedUnfairLock<AppState>(initialState: .init())
        appState.withLock {
            var ringBuffer = RingBuffer()
            ringBuffer.append(80.0)
            $0.metrics.send(Metrics(gpuInfo: GPUInfo(utilization: 80.0), gpuRingBuffer: ringBuffer))
        }
        let sut = SystemMetricsService(.testDependencies(appStateClient: .testDependency(appState)))
        sut.toggleGPUMonitoring(isOn: false)
        let metrics = appState.withLock(\.metrics.latestValue)
        #expect(metrics?.gpuInfo == nil)
        #expect(metrics?.gpuRingBuffer.values == RingBuffer().values)
    }

    @Test
    func configurations_decode_legacy_json_without_gpu_keys() throws {
        let systemJSON = #"{"monitorsMemory":true,"monitorsStorage":false,"monitorsBattery":true,"monitorsNetwork":false}"#
        let system = try JSONDecoder().decode(SystemMetricsConfiguration.self, from: Data(systemJSON.utf8))
        #expect(system.monitorsGPU)
        #expect(!system.monitorsStorage)
        let barJSON = #"{"showsCPU":true,"showsMemory":false,"showsStorage":false,"showsBattery":false,"showsNetwork":false,"visibleCustomMetricsSourceIDs":[]}"#
        let bar = try JSONDecoder().decode(MetricsBarConfiguration.self, from: Data(barJSON.utf8))
        #expect(!bar.showsGPU)
        #expect(bar.showsCPU)
    }

    @Test
    func updateRunnerSpeed_uses_higher_of_cpu_and_gpu_by_default() {
        let appState = AllocatedUnfairLock<AppState>(initialState: .init())
        let sut = RunnerService(.testDependencies(appStateClient: .testDependency(appState)))
        sut.updateRunnerSpeed(from: cpuInfo(0.2), gpuInfo: GPUInfo(utilization: 80.0))
        #expect(appState.withLock(\.runnerSpeeds.latestValue) == 16.0)
        sut.updateRunnerSpeed(from: cpuInfo(0.9), gpuInfo: GPUInfo(utilization: 10.0))
        #expect(appState.withLock(\.runnerSpeeds.latestValue) == 18.0)
    }

    @Test
    func updateRunnerSpeed_follows_gpu_only_when_source_is_gpu() {
        let appState = AllocatedUnfairLock<AppState>(initialState: .init())
        let sut = RunnerService(.testDependencies(
            appStateClient: .testDependency(appState),
            userDefaultsClient: testDependency(of: UserDefaultsClient.self) {
                $0.string = { _ in RunnerSpeedSource.gpu.rawValue }
            }
        ))
        sut.updateRunnerSpeed(from: cpuInfo(0.9), gpuInfo: GPUInfo(utilization: 10.0))
        #expect(appState.withLock(\.runnerSpeeds.latestValue) == 2.0)
    }

    @Test
    func updateRunnerSpeed_falls_back_to_cpu_when_gpu_is_unavailable() {
        let appState = AllocatedUnfairLock<AppState>(initialState: .init())
        let sut = RunnerService(.testDependencies(
            appStateClient: .testDependency(appState),
            userDefaultsClient: testDependency(of: UserDefaultsClient.self) {
                $0.string = { _ in RunnerSpeedSource.gpu.rawValue }
            }
        ))
        sut.updateRunnerSpeed(from: cpuInfo(0.5), gpuInfo: nil)
        #expect(appState.withLock(\.runnerSpeeds.latestValue) == 10.0)
    }

    @Test
    func updateRunnerSpeed_ignores_gpu_when_source_is_cpu() {
        let appState = AllocatedUnfairLock<AppState>(initialState: .init())
        let sut = RunnerService(.testDependencies(
            appStateClient: .testDependency(appState),
            userDefaultsClient: testDependency(of: UserDefaultsClient.self) {
                $0.string = { _ in RunnerSpeedSource.cpu.rawValue }
            }
        ))
        sut.updateRunnerSpeed(from: cpuInfo(0.2), gpuInfo: GPUInfo(utilization: 100.0))
        #expect(appState.withLock(\.runnerSpeeds.latestValue) == 4.0)
    }
}
