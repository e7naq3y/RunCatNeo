/*
 ThermalInfo.swift
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

public struct ThermalInfo: Sendable, Equatable {
    /// 最热的 CPU 核心温度（°C）
    public var cpu: Double?
    /// 最热的 GPU 核心温度（°C）
    public var gpu: Double?

    public init(cpu: Double? = nil, gpu: Double? = nil) {
        self.cpu = cpu
        self.gpu = gpu
    }
}
