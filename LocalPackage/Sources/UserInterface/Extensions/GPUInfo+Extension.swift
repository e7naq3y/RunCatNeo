/*
 GPUInfo+Extension.swift
 UserInterface

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

import DataSource
import SwiftUI

extension GPUInfo {
    static var icon: Image {
        Image(.gpu)
    }

    var summary: String {
        String(localized: "gpu\(Self.format(utilization))", bundle: .module)
    }

    var details: [String] {
        var details = [
            String(localized: "gpuRenderer\(Self.format(renderer))", bundle: .module),
            String(localized: "gpuTiler\(Self.format(tiler))", bundle: .module),
        ]
        if let model {
            if let coreCount {
                details.append(String(localized: "gpuModelCores\(model)\(coreCount)", bundle: .module))
            } else {
                details.append(model)
            }
        }
        return details
    }

    var menuBarDescription: String {
        String(format: utilization < 100 ? "%4.1f%%" : "%4.0f%%", locale: .current, utilization)
    }

    static let mock = GPUInfo(utilization: 42.0, renderer: 30.0, tiler: 12.0, model: "Apple M5 Max", coreCount: 40)

    private static func format(_ value: Double) -> String {
        String(format: "%4.1f%%", locale: .current, value)
    }
}
