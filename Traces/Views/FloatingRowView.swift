//
//  FloatingRowView.swift
//  Traces
//

import SwiftUI
import UniformTypeIdentifiers

struct FloatingRowView: View {
    @EnvironmentObject private var settings: AppSettings
    let item: ChecklistItem
    let isDragging: Bool
    let onComplete: () -> Void
    let onDragStart: () -> Void

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
                .onDrag {
                    onDragStart()
                    let provider = NSItemProvider()
                    provider.registerDataRepresentation(
                        forTypeIdentifier: UTType.checklistItemID.identifier,
                        visibility: .all
                    ) { completion in
                        completion(Data(item.id.uuidString.utf8), nil)
                        return nil
                    }
                    return provider
                }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .opacity(isDragging ? 0.3 : 1)
    }

    // Shared pieces, reused by both the live row above and `previewCard` below — kept as
    // independent subviews (rather than one composed "row content" property) so the drag
    // preview doesn't recursively reference the view that defines it.
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
