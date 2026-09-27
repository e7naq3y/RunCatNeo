/*
 GPUInfoClient.swift
 DataSource

 Added by the RunCat Neo GPU fork (https://github.com/e7naq3y/RunCatNeo) on 2026/09/27.
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

import Foundation
import IOKit

public struct GPUInfoClient: DependencyClient {
    public var read: @Sendable () -> GPUInfo?

    public static let liveValue = Self(
        read: { IOAcceleratorReader.read() }
    )

    public static let testValue = Self(
        read: { nil }
    )
}

// App Sandbox 会拦截 IOAccelerator 的属性读取，所以这个 fork 关闭了沙盒
enum IOAcceleratorReader {
    static func read() -> GPUInfo? {
        var iterator = io_iterator_t()
        let result = IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("IOAccelerator"), &iterator)
        guard result == KERN_SUCCESS else { return nil }
        defer { IOObjectRelease(iterator) }
        var best: GPUInfo?
        while true {
            let entry = IOIteratorNext(iterator)
            guard entry != 0 else { break }
            defer { IOObjectRelease(entry) }
            guard let statistics = property(of: entry, key: "PerformanceStatistics") as? [String: Any] else {
                continue
            }
            let info = GPUInfo(
                utilization: number(statistics["Device Utilization %"]),
                renderer: number(statistics["Renderer Utilization %"]),
                tiler: number(statistics["Tiler Utilization %"]),
                model: string(property(of: entry, key: "model")),
                coreCount: (property(of: entry, key: "gpu-core-count") as? NSNumber)?.intValue
            )
            // 核显 + 独显的机器取最忙的那块
            if best.map({ info.utilization > $0.utilization }) ?? true {
                best = info
            }
        }
        return best
    }

    private static func property(of entry: io_registry_entry_t, key: String) -> AnyObject? {
        IORegistryEntryCreateCFProperty(entry, key as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue()
    }

    private static func number(_ value: Any?) -> Double {
        (value as? NSNumber)?.doubleValue ?? .zero
    }

    private static func string(_ value: AnyObject?) -> String? {
        if let string = value as? String {
            return string
        }
        // Intel 机型上 model 是以 \0 结尾的 CFData
        if let data = value as? Data {
            return String(decoding: data.prefix { $0 != 0 }, as: UTF8.self)
        }
        return nil
    }
}
