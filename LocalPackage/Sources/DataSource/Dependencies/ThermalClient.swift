/*
 ThermalClient.swift
 DataSource

 Added by the GPU fork on 2026/09/27.
 Copyright 2026 Kyome22 (Takuto Nakamura)

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import AllocatedUnfairLock
import Darwin
import Foundation
import IOKit

public struct ThermalClient: DependencyClient {
    public var read: @Sendable () -> ThermalInfo?

    public static let liveValue = Self(
        read: { SMCThermalReader.shared.read() }
    )

    public static let testValue = Self(
        read: { nil }
    )
}

// 通过 AppleSMC 读芯片温度键。App Sandbox 会拒绝 IOServiceOpen(AppleSMC)，所以这个 fork 关闭了沙盒。
// 键名规律：Tp/Te 是 CPU 核心，Tg 是 GPU 核心；M3 系列两者都在 Tf 家族，只能用固定键表。
final class SMCThermalReader: @unchecked Sendable {
    static let shared = SMCThermalReader()

    struct SMCKeyInfoData {
        var dataSize: UInt32 = 0
        var dataType: UInt32 = 0
        var dataAttributes: UInt8 = 0
    }

    private struct SMCVersion {
        var major: UInt8 = 0
        var minor: UInt8 = 0
        var build: UInt8 = 0
        var reserved: UInt8 = 0
        var release: UInt16 = 0
    }

    private struct SMCPLimitData {
        var version: UInt16 = 0
        var length: UInt16 = 0
        var cpuPLimit: UInt32 = 0
        var gpuPLimit: UInt32 = 0
        var memPLimit: UInt32 = 0
    }

    private typealias SMCBytes = (
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8
    )

    // 与 AppleSMC 用户客户端约定的 80 字节结构
    private struct SMCParamStruct {
        var key: UInt32 = 0
        var vers = SMCVersion()
        var pLimitData = SMCPLimitData()
        var keyInfo = SMCKeyInfoData()
        var padding: UInt16 = 0
        var result: UInt8 = 0
        var status: UInt8 = 0
        var data8: UInt8 = 0
        var data32: UInt32 = 0
        var bytes: SMCBytes = (
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        )
    }

    private struct SMCKey {
        let code: UInt32
        let info: SMCKeyInfoData
    }

    private struct State {
        var isPrepared = false
        var connection: io_connect_t = 0
        var cpuKeys = [SMCKey]()
        var gpuKeys = [SMCKey]()
    }

    private static let selectorHandleYPCEvent: UInt32 = 2
    private static let commandReadKey: UInt8 = 5
    private static let commandGetKeyFromIndex: UInt8 = 8
    private static let commandGetKeyInfo: UInt8 = 9
    private static let plausibleRange = 5.0 ... 125.0

    private let state = AllocatedUnfairLock<State>(initialState: State())

    func read() -> ThermalInfo? {
        state.withLock { state in
            if !state.isPrepared {
                state.isPrepared = true
                Self.prepare(&state)
            }
            guard state.connection != 0 else { return nil }
            let cpu = Self.hottest(of: state.cpuKeys, connection: state.connection)
            let gpu = Self.hottest(of: state.gpuKeys, connection: state.connection)
            guard cpu != nil || gpu != nil else { return nil }
            return ThermalInfo(cpu: cpu, gpu: gpu)
        }
    }

    static func candidateKeys(chip: String, available: Set<String>) -> (cpu: [String], gpu: [String]) {
        func family(_ prefix: String) -> [String] {
            available.filter { $0.hasPrefix(prefix) }.sorted()
        }
        func present(_ keys: [String]) -> [String] {
            keys.filter(available.contains)
        }
        if chip.contains("Intel") {
            return (
                present(["TC0D", "TC0E", "TC0F", "TC0P", "TC1C", "TC2C", "TC3C", "TC4C", "TC5C", "TC6C", "TC7C", "TC8C"]),
                present(["TG0D", "TG0P", "TG1D"])
            )
        }
        let generation = chip
            .split(separator: " ")
            .compactMap { part -> Int? in part.hasPrefix("M") ? Int(part.dropFirst()) : nil }
            .first
        if generation == 3 {
            return (
                present(["Te05", "Te0L", "Te0P", "Te0S", "Tf04", "Tf09", "Tf0A", "Tf0B", "Tf0D", "Tf0E", "Tf44", "Tf49", "Tf4A", "Tf4B", "Tf4D", "Tf4E"]),
                present(["Tf14", "Tf18", "Tf19", "Tf1A", "Tf24", "Tf28", "Tf29", "Tf2A"])
            )
        }
        return (family("Tp") + family("Te"), family("Tg"))
    }

    private static func prepare(_ state: inout State) {
        guard MemoryLayout<SMCParamStruct>.size == 80 else { return }
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC"))
        guard service != 0 else { return }
        defer { IOObjectRelease(service) }
        var connection: io_connect_t = 0
        guard IOServiceOpen(service, mach_task_self_, 0, &connection) == KERN_SUCCESS else { return }
        let available = Set(allKeys(connection).filter { $0.hasPrefix("T") })
        let candidates = candidateKeys(chip: chipName, available: available)
        state.connection = connection
        state.cpuKeys = candidates.cpu.compactMap { resolve($0, connection: connection) }
        state.gpuKeys = candidates.gpu.compactMap { resolve($0, connection: connection) }
    }

    private static var chipName: String {
        var size = 0
        sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0)
        guard size > 0 else { return "" }
        var buffer = [CChar](repeating: 0, count: size)
        sysctlbyname("machdep.cpu.brand_string", &buffer, &size, nil, 0)
        return String(cString: buffer)
    }

    private static func call(_ connection: io_connect_t, _ input: inout SMCParamStruct) -> SMCParamStruct? {
        var output = SMCParamStruct()
        var outputSize = MemoryLayout<SMCParamStruct>.size
        let result = IOConnectCallStructMethod(
            connection,
            selectorHandleYPCEvent,
            &input,
            MemoryLayout<SMCParamStruct>.size,
            &output,
            &outputSize
        )
        guard result == KERN_SUCCESS, output.result == 0 else { return nil }
        return output
    }

    private static func allKeys(_ connection: io_connect_t) -> [String] {
        guard let countKey = resolve("#KEY", connection: connection),
              let bytes = readBytes(countKey, connection: connection) else {
            return []
        }
        let count = bytes.reduce(UInt32.zero) { ($0 << 8) | UInt32($1) }
        var keys = [String]()
        keys.reserveCapacity(Int(count))
        for index in 0 ..< count {
            var input = SMCParamStruct()
            input.data8 = commandGetKeyFromIndex
            input.data32 = index
            if let output = call(connection, &input) {
                keys.append(string(of: output.key))
            }
        }
        return keys
    }

    private static func resolve(_ name: String, connection: io_connect_t) -> SMCKey? {
        guard name.utf8.count == 4 else { return nil }
        let code = name.utf8.reduce(UInt32.zero) { ($0 << 8) | UInt32($1) }
        var input = SMCParamStruct()
        input.key = code
        input.data8 = commandGetKeyInfo
        guard let output = call(connection, &input), output.keyInfo.dataSize > 0 else { return nil }
        return SMCKey(code: code, info: output.keyInfo)
    }

    private static func readBytes(_ key: SMCKey, connection: io_connect_t) -> [UInt8]? {
        var input = SMCParamStruct()
        input.key = key.code
        input.keyInfo = key.info
        input.data8 = commandReadKey
        guard let output = call(connection, &input) else { return nil }
        return withUnsafeBytes(of: output.bytes) { Array($0.prefix(Int(min(key.info.dataSize, 32)))) }
    }

    private static func temperature(_ key: SMCKey, connection: io_connect_t) -> Double? {
        guard let bytes = readBytes(key, connection: connection) else { return nil }
        let value: Double
        switch string(of: key.info.dataType) {
        case "flt " where bytes.count == 4:
            value = Double(bytes.withUnsafeBytes { $0.loadUnaligned(as: Float32.self) })
        case "sp78" where bytes.count == 2:
            value = Double(Int16(bitPattern: UInt16(bytes[0]) << 8 | UInt16(bytes[1]))) / 256.0
        default:
            return nil
        }
        // 传感器偶尔给 0 或几千度的垃圾值
        return plausibleRange.contains(value) ? value : nil
    }

    private static func hottest(of keys: [SMCKey], connection: io_connect_t) -> Double? {
        keys.compactMap { temperature($0, connection: connection) }.max()
    }

    private static func string(of code: UInt32) -> String {
        let bytes = [UInt8(code >> 24 & 0xff), UInt8(code >> 16 & 0xff), UInt8(code >> 8 & 0xff), UInt8(code & 0xff)]
        return String(decoding: bytes, as: UTF8.self)
    }
}
