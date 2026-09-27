/*
 GPUInfo.swift
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

public struct GPUInfo: Sendable, Equatable {
    /// IOAccelerator 的 "Device Utilization %"，0...100
    public var utilization: Double
    public var renderer: Double
    public var tiler: Double
    public var model: String?
    public var coreCount: Int?

    public init(
        utilization: Double,
        renderer: Double = .zero,
        tiler: Double = .zero,
        model: String? = nil,
        coreCount: Int? = nil
    ) {
        self.utilization = utilization
        self.renderer = renderer
        self.tiler = tiler
        self.model = model
        self.coreCount = coreCount
    }

    public static let zero = GPUInfo(utilization: .zero)
}
