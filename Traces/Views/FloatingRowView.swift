//
//  FloatingRowView.swift
//  Traces
//

import AppKit
import SwiftUI

struct FloatingRowView: View {
    @EnvironmentObject private var settings: AppSettings
    @State private var isHandleHovered = false
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
            HStack(spacing: 2) {
                dueTimeText
                dragHandle
                // Hidden until hovered; while dragging it also hides here because a floating
                // copy follows the cursor instead (drawn by FloatingChecklistView's overlay).
                .opacity(isHandleHovered && !isDragging ? 1 : 0)
                // .pointerStyle relies on key-window tracking that never fires in this
                // nonactivating panel (same story as cursor rects); set NSCursor directly.
                .onHover { hovering in
                    isHandleHovered = hovering
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
        }
        .padding(.leading, 14)
        .padding(.trailing, 4)
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
        DragHandleGlyph()
            .frame(width: 13, height: 20)
            .contentShape(Rectangle())
    }
}

/// Hand-drawn stand-in for SF Symbol "line.3.horizontal": same three bars, but with adjustable
/// line spacing (the symbol's built-in ~2pt can't be tweaked) and pre-narrowed to fit the
/// 13pt-wide handle column. Also used by FloatingChecklistView for the cursor-following copy.
struct DragHandleGlyph: View {
    var body: some View {
        VStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { _ in
                Capsule()
                    .fill(.tertiary)
                    .frame(width: 9, height: 1)
            }
        }
    }
}
