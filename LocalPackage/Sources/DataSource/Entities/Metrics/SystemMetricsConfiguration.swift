/*
 SystemMetricsConfiguration.swift
 DataSource

 Created by Takuto Nakamura on 2026/05/08.
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
public struct SystemMetricsConfiguration: Sendable, Equatable {
    public var monitorsMemory: Bool
    public var monitorsStorage: Bool
    public var monitorsBattery: Bool
    public var monitorsNetwork: Bool
    public var monitorsGPU: Bool = true

    static let `default` = Self(
        monitorsMemory: true,
        monitorsStorage: true,
        monitorsBattery: true,
        monitorsNetwork: true,
        monitorsGPU: true
    )
}

extension SystemMetricsConfiguration: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        monitorsMemory = try container.decode(Bool.self, forKey: .monitorsMemory)
        monitorsStorage = try container.decode(Bool.self, forKey: .monitorsStorage)
        monitorsBattery = try container.decode(Bool.self, forKey: .monitorsBattery)
        monitorsNetwork = try container.decode(Bool.self, forKey: .monitorsNetwork)
        // 官方版保存的配置里没有 GPU 键，缺省视为开启
        monitorsGPU = try container.decodeIfPresent(Bool.self, forKey: .monitorsGPU) ?? true
    }
}
