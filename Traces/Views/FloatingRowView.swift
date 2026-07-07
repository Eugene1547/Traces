//
//  FloatingRowView.swift
//  Traces
//

import AppKit
import SwiftUI

struct FloatingRowView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @State private var isHandleHovered = false
    @State private var isCheckboxHovered = false
    @State private var isCompleting = false
    let item: ChecklistItem
    let isDragging: Bool
    let onComplete: () -> Void
    /// Fires at the click, before the completion beat delays `onComplete` — this is the moment
    /// celebration effects should launch from.
    let onCompletionBegan: () -> Void
    let onDragChanged: (CGSize) -> Void
    let onDragEnded: () -> Void

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d HH:mm"
        return formatter
    }()

    var body: some View {
        // Re-evaluates every minute so an item sitting in the always-on panel turns red the
        // moment it passes its due time, not just on the next interaction-driven re-render.
        TimelineView(.periodic(from: .now, by: 60)) { context in
            rowContent(isOverdue: item.isOverdue(at: context.date))
        }
    }

    private func rowContent(isOverdue: Bool) -> some View {
        HStack(spacing: 8) {
            checkboxButton
            colorDot
            nameText(isOverdue: isOverdue)
            Spacer(minLength: 4)
            HStack(spacing: 2) {
                dueTimeText(isOverdue: isOverdue)
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
        .opacity(isCompleting ? 0.55 : 1)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: isCompleting)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(
                    (colorScheme == .dark ? Color(white: 0.35).opacity(0.35) : Color.gray.opacity(0.1))
                        .opacity(isDragging ? 1 : 0)
                )
                .padding(.horizontal, 4)
        )
    }

    /// Hovering previews the outcome: a faint checkmark fades into the empty box, so the
    /// affordance explains itself before the click (motion conveying state, not decoration).
    /// Clicking plays a short completion beat — the checkmark commits in brand color, the row
    /// dims, and only then does the row actually complete (the parent animates it out).
    private var checkboxButton: some View {
        Button {
            guard !isCompleting else { return }
            if reduceMotion {
                onComplete()
                return
            }
            onCompletionBegan()
            isCompleting = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onComplete()
            }
        } label: {
            ZStack {
                Image(systemName: "square")
                Image(systemName: "checkmark")
                    .font(.system(size: 7, weight: .semibold))
                    .opacity(isCompleting ? 1 : (isCheckboxHovered ? 0.5 : 0))
                    .scaleEffect(isCompleting || isCheckboxHovered ? 1 : 0.5)
            }
            .foregroundStyle(
                isCompleting
                    ? AnyShapeStyle(Color.dragAccent)
                    : (isCheckboxHovered ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary))
            )
        }
        .buttonStyle(PressableCheckboxStyle())
        .onHover { isCheckboxHovered = $0 }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: isCheckboxHovered)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: isCompleting)
    }

    private var colorDot: some View {
        Circle()
            .fill(item.displayColor)
            .frame(width: 8, height: 8)
    }

    private func nameText(isOverdue: Bool) -> some View {
        Text(item.name)
            .font(.system(size: 13))
            .foregroundStyle(isOverdue ? AnyShapeStyle(Color.red) : AnyShapeStyle(.primary))
            .lineLimit(1)
            .truncationMode(.tail)
    }

    private func dueTimeText(isOverdue: Bool) -> some View {
        Text(item.dueTime.map { Self.timeFormatter.string(from: $0) } ?? L.noDeadlineShort.text(settings.language))
            .font(.system(size: 11))
            .foregroundStyle(isOverdue ? AnyShapeStyle(Color.red) : AnyShapeStyle(.secondary))
    }

    private var dragHandle: some View {
        DragHandleGlyph()
            .frame(width: 13, height: 20)
            .contentShape(Rectangle())
    }
}

/// Press feedback only (0.9 dip, 100ms); hover is handled by the checkbox itself since its
/// preview needs the hover state for more than styling.
private struct PressableCheckboxStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.1), value: configuration.isPressed)
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
