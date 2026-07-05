//
//  FloatingRowView.swift
//  Traces
//

import SwiftUI

struct FloatingRowView: View {
    let item: ChecklistItem
    let onComplete: () -> Void

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d HH:mm"
        return formatter
    }()

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onComplete) {
                Image(systemName: "square")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            Text(item.name)
                .font(.system(size: 13))
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer(minLength: 4)

            Text(Self.timeFormatter.string(from: item.dueTime))
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            Circle()
                .fill(item.importance.color)
                .frame(width: 8, height: 8)

            Image(systemName: "line.3.horizontal")
                .foregroundStyle(.tertiary)
                .font(.system(size: 11))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}
