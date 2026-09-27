/*
 SystemInfoView.swift
 UserInterface

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
import SwiftUI
import SystemInfoKit

struct SystemInfoView<Accessory: View>: View {
    var icon: Image
    var summary: String
    var details: [String]
    var isVisibleDetails: Bool
    @ViewBuilder var accessory: () -> Accessory

    init(
        icon: Image,
        summary: String,
        details: [String],
        isVisibleDetails: Bool = true,
        @ViewBuilder accessory: @escaping () -> Accessory
    ) {
        self.icon = icon
        self.summary = summary
        self.details = details
        self.isVisibleDetails = isVisibleDetails
        self.accessory = accessory
    }

    init(
        systemInfo: any SystemInfo,
        isVisibleDetails: Bool = true,
        @ViewBuilder accessory: @escaping () -> Accessory
    ) {
        self.init(
            icon: Image(systemName: systemInfo.icon),
            summary: systemInfo.summary,
            details: systemInfo.details,
            isVisibleDetails: isVisibleDetails,
            accessory: accessory
        )
    }

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            icon
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: summary)
                Group {
                    if isVisibleDetails {
                        ForEach(details.indices, id: \.self) { index in
                            Text(verbatim: details[index])
                                .font(.caption)
                        }
                    }
                    accessory()
                }
                .padding(.leading, 12)
            }
        }
        .fixedSize()
        .padding(.leading, 8)
    }
}
