//
//  ImportancePicker.swift
//  Traces
//

import SwiftUI

struct ImportancePicker: View {
    @Binding var selection: Importance

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Importance.allCases) { importance in
                Button {
                    selection = importance
                } label: {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(importance.color)
                            .frame(width: 8, height: 8)
                        Text(importance.label)
                            .font(.caption)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(selection == importance ? Color.secondary.opacity(0.15) : Color.clear)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}
