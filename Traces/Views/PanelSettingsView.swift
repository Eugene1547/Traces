//
//  PanelSettingsView.swift
//  Traces
//

import SwiftUI

struct PanelSettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    let onOpenMainWindow: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("透明度")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Slider(value: $settings.opacity, in: AppSettings.opacityRange)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("排序规则")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("", selection: $settings.sortRule) {
                    ForEach(SortRule.allCases) { rule in
                        Text(rule.label).tag(rule)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
            }

            Toggle("置顶", isOn: $settings.isPinned)

            Divider()

            Button("打开主窗口", action: onOpenMainWindow)
        }
        .padding(14)
        .frame(width: 200)
    }
}
