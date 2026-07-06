//
//  FloatingChecklistView.swift
//  Traces
//

import SwiftUI

struct FloatingChecklistView: View {
    @EnvironmentObject private var store: ChecklistStore
    @EnvironmentObject private var settings: AppSettings
    @State private var showSettings = false
    @State private var draggingItemID: UUID?
    @State private var dragTranslation: CGFloat = 0
    @State private var hoveredGap: Int?
    @State private var rowFrames: [UUID: CGRect] = [:]

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
                        GapIndicator(index: index, hoveredGap: hoveredGap)
                        FloatingRowView(
                            item: item,
                            isDragging: draggingItemID == item.id,
                            dragOffset: draggingItemID == item.id ? dragTranslation : 0,
                            onComplete: { store.complete(item.id) },
                            onDragChanged: { translation in
                                handleDragChanged(itemID: item.id, translation: translation)
                            },
                            onDragEnded: handleDragEnded
                        )
                        .background(
                            GeometryReader { proxy in
                                Color.clear.preference(
                                    key: RowFramePreferenceKey.self,
                                    value: [item.id: proxy.frame(in: .named("floatingList"))]
                                )
                            }
                        )
                    }
                    GapIndicator(index: displayedItems.count, hoveredGap: hoveredGap)
                }
                .coordinateSpace(name: "floatingList")
                .onPreferenceChange(RowFramePreferenceKey.self) { rowFrames = $0 }
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

    private func handleDragChanged(itemID: UUID, translation: CGSize) {
        if draggingItemID != itemID { draggingItemID = itemID }
        dragTranslation = translation.height

        guard let startFrame = rowFrames[itemID] else { return }
        let currentY = startFrame.midY + translation.height
        let gap = gapIndex(for: currentY, excluding: itemID)
        if hoveredGap != gap {
            withAnimation(.easeOut(duration: 0.12)) { hoveredGap = gap }
        }
    }

    /// Counts how many of the other rows sit above `y`, giving the gap index `y` currently falls into.
    private func gapIndex(for y: CGFloat, excluding draggedID: UUID) -> Int {
        var gap = 0
        for id in displayedItems.map(\.id) where id != draggedID {
            if let frame = rowFrames[id], y > frame.midY {
                gap += 1
            }
        }
        return gap
    }

    private func handleDragEnded() {
        defer {
            draggingItemID = nil
            dragTranslation = 0
            hoveredGap = nil
        }
        guard let draggedID = draggingItemID, let gapIndex = hoveredGap else { return }
        var order = displayedItems.map(\.id)
        guard let from = order.firstIndex(of: draggedID) else { return }
        order.remove(at: from)
        let insertAt = from < gapIndex ? gapIndex - 1 : gapIndex
        order.insert(draggedID, at: min(insertAt, order.count))
        withAnimation(.easeInOut(duration: 0.2)) {
            store.reorder(ids: order)
        }
        settings.sortRule = .manual
    }
}

private struct RowFramePreferenceKey: PreferenceKey {
    static var defaultValue: [UUID: CGRect] = [:]
    static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
        value.merge(nextValue()) { _, new in new }
    }
}

/// A thin visual indicator sitting between (and around) rows, showing where a drag would insert.
private struct GapIndicator: View {
    let index: Int
    let hoveredGap: Int?

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
    }
}
