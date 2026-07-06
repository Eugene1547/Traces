//
//  PanelSettingsView.swift
//  Traces
//

import SwiftUI

struct PanelSettingsView: View {
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(L.opacityLabel.text(settings.language))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Slider(value: $settings.opacity, in: AppSettings.opacityRange)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(L.sortRuleLabel.text(settings.language))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("", selection: $settings.sortRule) {
                    ForEach(SortRule.allCases) { rule in
                        Text(rule.label(settings.language)).tag(rule)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
            }

            Toggle(L.pinLabel.text(settings.language), isOn: $settings.isPinned)
        }
        .padding(14)
        .frame(width: 200)
    }
}
