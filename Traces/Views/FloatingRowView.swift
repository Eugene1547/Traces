//
//  FloatingRowView.swift
//  Traces
//

import SwiftUI

struct FloatingRowView: View {
    @EnvironmentObject private var settings: AppSettings
    let item: ChecklistItem
    let isDragging: Bool
    let dragOffset: CGFloat
    let onComplete: () -> Void
    let onDragChanged: (CGSize) -> Void
    let onDragEnded: () -> Void

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d HH:mm"
        return formatter
    }()

    var body: some View {
        HStack(spacing: 8) {
            checkboxButton
            colorDot
            nameText
            Spacer(minLength: 4)
            dueTimeText
            dragHandle
                .gesture(
                    DragGesture(minimumDistance: 2)
                        .onChanged { onDragChanged($0.translation) }
                        .onEnded { _ in onDragEnded() }
                )
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor))
                .opacity(isDragging ? 1 : 0)
                .shadow(color: .black.opacity(isDragging ? 0.25 : 0), radius: 6, y: 3)
        )
        .offset(y: dragOffset)
        .zIndex(isDragging ? 1 : 0)
    }

    private var checkboxButton: some View {
        Button(action: onComplete) {
            Image(systemName: "square")
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
    }

    private var colorDot: some View {
        Circle()
            .fill(item.displayColor)
            .frame(width: 8, height: 8)
    }

    private var nameText: some View {
        Text(item.name)
            .font(.system(size: 13))
            .lineLimit(1)
            .truncationMode(.tail)
    }

    private var dueTimeText: some View {
        Text(item.dueTime.map { Self.timeFormatter.string(from: $0) } ?? L.noDeadlineShort.text(settings.language))
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
    }

    private var dragHandle: some View {
        Image(systemName: "line.3.horizontal")
            .foregroundStyle(.tertiary)
            .font(.system(size: 11))
            .frame(width: 20, height: 20)
            .contentShape(Rectangle())
    }
}
