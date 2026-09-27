/*
 RunnerSpeedSource.swift
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

public enum RunnerSpeedSource: String, Sendable, Identifiable, CaseIterable {
    case cpu
    case gpu
    case max

    public var id: String { rawValue }

    public static let `default` = RunnerSpeedSource.max
}
