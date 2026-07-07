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
                        GapIndicator(index: index, itemCount: displayedItems.count, hoveredGap: hoveredGap)
                        FloatingRowView(
                            item: item,
                            isDragging: draggingItemID == item.id,
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
                    GapIndicator(index: displayedItems.count, itemCount: displayedItems.count, hoveredGap: hoveredGap)
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

        guard let startFrame = rowFrames[itemID],
              let from = displayedItems.firstIndex(where: { $0.id == itemID }) else { return }
        let currentY = startFrame.midY + translation.height

        // Count how many of the *other* rows sit above the cursor...
        var gap = 0
        for item in displayedItems where item.id != itemID {
            if let frame = rowFrames[item.id], currentY > frame.midY {
                gap += 1
            }
        }
        // ...then convert that position-among-others into an index in the on-screen gap
        // list, which still contains the dragged row. Below the dragged row the two
        // indexings differ by one; without this shift the bottommost gap is unreachable
        // when dragging downward.
        let visualGap = gap <= from ? gap : gap + 1

        if hoveredGap != visualGap {
            hoveredGap = visualGap
        }
    }

    private func handleDragEnded() {
        defer {
            draggingItemID = nil
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

extension Color {
    /// #0400FF — shared accent for the reorder insertion line and the dragged row's highlight.
    static let dragAccent = Color(red: 0x04 / 255.0, green: 0x00 / 255.0, blue: 0xFF / 255.0)
}

private struct RowFramePreferenceKey: PreferenceKey {
    static var defaultValue: [UUID: CGRect] = [:]
    static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
        value.merge(nextValue()) { _, new in new }
    }
}

/// A thin visual indicator sitting between (and around) rows, showing where a drag would insert.
/// The edge gaps (above the first row, below the last) never show an idle divider and stay
/// compact, so the list doesn't gain extra top/bottom padding from them.
private struct GapIndicator: View {
    let index: Int
    let itemCount: Int
    let hoveredGap: Int?

    private var isEdge: Bool { index == 0 || index == itemCount }

    var body: some View {
        ZStack {
            if hoveredGap == index {
                Rectangle()
                    .fill(Color.dragAccent)
                    .frame(height: 2)
                    .padding(.horizontal, 32)
            } else if !isEdge {
                Divider().opacity(0.15).padding(.leading, 34)
            }
        }
        .frame(height: isEdge ? 4 : 9)
    }
}
