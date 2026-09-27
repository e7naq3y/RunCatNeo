import AllocatedUnfairLock
import Foundation
import SystemInfoKit
import Testing

@testable import DataSource
@testable import Model

struct ThermalMetricsTests {
    @Test
    func updateMetrics_stores_thermal_info() {
        let appState = AllocatedUnfairLock<AppState>(initialState: .init())
        let sut = SystemMetricsService(.testDependencies(
            appStateClient: .testDependency(appState),
            thermalClient: testDependency(of: ThermalClient.self) {
                $0.read = { ThermalInfo(cpu: 61.5, gpu: 58.0) }
            }
        ))
        sut.updateMetrics(from: SystemInfoBundle())
        #expect(appState.withLock(\.metrics.latestValue)?.thermalInfo == ThermalInfo(cpu: 61.5, gpu: 58.0))
    }

    @Test
    func updateMetrics_leaves_thermal_info_nil_when_unavailable() {
        let appState = AllocatedUnfairLock<AppState>(initialState: .init())
        let sut = SystemMetricsService(.testDependencies(appStateClient: .testDependency(appState)))
        sut.updateMetrics(from: SystemInfoBundle())
        #expect(appState.withLock(\.metrics.latestValue)?.thermalInfo == nil)
    }

    @Test
    func candidateKeys_use_tp_te_and_tg_families_on_m5() {
        let keys = SMCThermalReader.candidateKeys(
            chip: "Apple M5 Max",
            available: ["Tp00", "Tp0y", "Te05", "Tg0U", "Tg7L", "Tf04", "Tf14", "TB0T"]
        )
        #expect(keys.cpu == ["Tp00", "Tp0y", "Te05"])
        #expect(keys.gpu == ["Tg0U", "Tg7L"])
    }

    @Test
    func candidateKeys_use_fixed_tf_table_on_m3() {
        let keys = SMCThermalReader.candidateKeys(
            chip: "Apple M3 Pro",
            available: ["Tf04", "Tf09", "Tf14", "Tf18", "Tf06", "Tp00"]
        )
        #expect(keys.cpu == ["Tf04", "Tf09"])
        #expect(keys.gpu == ["Tf14", "Tf18"])
    }

    @Test
    func candidateKeys_use_intel_proximity_keys() {
        let keys = SMCThermalReader.candidateKeys(
            chip: "Intel(R) Core(TM) i9-9980HK CPU @ 2.40GHz",
            available: ["TC0P", "TC1C", "TG0P", "Tp00"]
        )
        #expect(keys.cpu == ["TC0P", "TC1C"])
        #expect(keys.gpu == ["TG0P"])
    }
}
