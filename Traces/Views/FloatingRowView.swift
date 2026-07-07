//
//  FloatingRowView.swift
//  Traces
//

import AppKit
import SwiftUI

struct FloatingRowView: View {
    @EnvironmentObject private var settings: AppSettings
    let item: ChecklistItem
    let isDragging: Bool
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
                // .pointerStyle relies on key-window tracking that never fires in this
                // nonactivating panel (same story as cursor rects); set NSCursor directly.
                .onHover { hovering in
                    (hovering ? NSCursor.pointingHand : NSCursor.arrow).set()
                }
                .gesture(
                    DragGesture(minimumDistance: 2)
                        .onChanged {
                            NSCursor.closedHand.set()
                            onDragChanged($0.translation)
                        }
                        .onEnded { _ in
                            NSCursor.arrow.set()
                            onDragEnded()
                        }
                )
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.dragAccent.opacity(isDragging ? 0.15 : 0))
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(Color.dragAccent.opacity(isDragging ? 0.5 : 0), lineWidth: 1)
            }
            .padding(.horizontal, 4)
        )
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
