//
//  FloatingChecklistView.swift
//  Traces
//

import SwiftUI
import UniformTypeIdentifiers

struct FloatingChecklistView: View {
    @EnvironmentObject private var store: ChecklistStore
    @EnvironmentObject private var settings: AppSettings
    @State private var showSettings = false
    @State private var draggingItemID: UUID?
    @State private var hoveredGap: Int?

    let onOpenMainWindow: () -> Void

    private var displayedItems: [ChecklistItem] {
        switch settings.sortRule {
        case .manual:
            return store.todoItems.sorted { $0.sortOrder < $1.sortOrder }
        case .nameAsc:
            return store.todoItems.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        case .importanceDesc:
            return store.todoItems.sorted { $0.importance.sortWeight < $1.importance.sortWeight }
        case .timeAsc:
            return store.todoItems.sorted { Self.compareDueTime($0.dueTime, $1.dueTime, ascending: true) }
        case .timeDesc:
            return store.todoItems.sorted { Self.compareDueTime($0.dueTime, $1.dueTime, ascending: false) }
        }
    }

    /// Items without a due time always sort after items with one, regardless of direction.
    private static func compareDueTime(_ lhs: Date?, _ rhs: Date?, ascending: Bool) -> Bool {
        switch (lhs, rhs) {
        case let (l?, r?): return ascending ? l < r : l > r
        case (nil, nil): return false
        case (nil, _): return false
        case (_, nil): return true
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().opacity(0.3)
            if displayedItems.isEmpty {
                Text(L.emptyTodo.text(settings.language))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 24)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(displayedItems.enumerated()), id: \.element.id) { index, item in
                        GapDropZone(index: index, hoveredGap: $hoveredGap, onDrop: performReorder)
                        FloatingRowView(item: item, isDragging: draggingItemID == item.id) {
                            store.complete(item.id)
                        } onDragStart: {
                            draggingItemID = item.id
                        }
                    }
                    GapDropZone(index: displayedItems.count, hoveredGap: $hoveredGap, onDrop: performReorder)
                }
            }
        }
        .padding(.bottom, 8)
        .background(
            Color(nsColor: .windowBackgroundColor).opacity(settings.opacity)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .frame(width: settings.panelWidth)
        .preferredColorScheme(settings.isDarkMode ? .dark : .light)
    }

    private var header: some View {
        HStack {
            Text("Traces")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Button(action: onOpenMainWindow) {
                Image(systemName: "macwindow")
            }
            .buttonStyle(.plain)
            .help(L.openMainWindowButton.text(settings.language))
            Button {
                showSettings.toggle()
            } label: {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showSettings, arrowEdge: .bottom) {
                PanelSettingsView()
                    .environmentObject(settings)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .gesture(WindowDragGesture())
    }

    /// Inserts the item currently being dragged before `displayedItems[gapIndex]`
    /// (or at the end, when `gapIndex == displayedItems.count`).
    private func performReorder(at gapIndex: Int) -> Bool {
        guard let draggedID = draggingItemID else { return false }
        var order = displayedItems.map(\.id)
        guard let from = order.firstIndex(of: draggedID) else { return false }
        order.remove(at: from)
        let insertAt = from < gapIndex ? gapIndex - 1 : gapIndex
        order.insert(draggedID, at: min(insertAt, order.count))
        withAnimation(.easeInOut(duration: 0.2)) {
            store.reorder(ids: order)
        }
        settings.sortRule = .manual
        draggingItemID = nil
        return true
    }
}

/// A custom, unregistered UTI for reorder drags. Using `.text` here previously let macOS treat
/// the drag as a droppable text clipping, so dropping outside the app (e.g. on the Desktop)
/// created a stray file from the dragged item's id — Finder only knows how to conjure files out
/// of recognized types like plain text, so a type it's never seen is never offered as one.
///
/// Note: don't pair this with `visibility: .ownProcess` on the item provider. Even an in-app drag
/// is brokered through the system pasteboard server, which isn't literally "the same process" as
/// either side, so `.ownProcess` silently drops the data before our own `onDrop` ever sees it.
/// `.all` is what actually reaches `performDrop` here.
extension UTType {
    static let checklistItemID = UTType(exportedAs: "com.traces.app.checklist-item-id")
}

/// A thin drop target sitting between (and around) rows, representing "insert here" rather than
/// "swap with this row". Shows a highlighted insertion line while a drag hovers over it.
private struct GapDropZone: View {
    let index: Int
    @Binding var hoveredGap: Int?
    let onDrop: (Int) -> Bool

    var body: some View {
        ZStack {
            if hoveredGap == index {
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(height: 2)
                    .padding(.horizontal, 32)
            } else {
                Divider().opacity(0.15).padding(.leading, 34)
            }
        }
        .frame(height: 9)
        .contentShape(Rectangle())
        .onDrop(of: [.checklistItemID], delegate: GapDropDelegate(index: index, hoveredGap: $hoveredGap, onDrop: onDrop))
    }
}

private struct GapDropDelegate: DropDelegate {
    let index: Int
    @Binding var hoveredGap: Int?
    let onDrop: (Int) -> Bool

    func dropEntered(info: DropInfo) {
        withAnimation(.easeOut(duration: 0.15)) { hoveredGap = index }
    }

    func dropExited(info: DropInfo) {
        withAnimation(.easeOut(duration: 0.15)) {
            if hoveredGap == index { hoveredGap = nil }
        }
    }

    func performDrop(info: DropInfo) -> Bool {
        defer { hoveredGap = nil }
        return onDrop(index)
    }
}
