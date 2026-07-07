//
//  FloatingChecklistView.swift
//  Traces
//

import SwiftUI

struct FloatingChecklistView: View {
    @EnvironmentObject private var store: ChecklistStore
    @EnvironmentObject private var settings: AppSettings
    @State private var showSettings = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var draggingItemID: UUID?
    @State private var dragTranslation: CGSize = .zero
    @State private var hoveredGap: Int?
    @State private var rowFrames: [UUID: CGRect] = [:]
    @State private var confettiBursts: [ConfettiBurst] = []

    private struct ConfettiBurst: Identifiable {
        let id = UUID()
        let origin: CGPoint
        let seed: UInt64
    }

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
                            onComplete: {
                                withAnimation(.easeOut(duration: 0.25)) {
                                    store.complete(item.id)
                                }
                            },
                            onCompletionBegan: {
                                spawnCompletionEffect(for: item.id)
                            },
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
                        .transition(.opacity)
                    }
                    GapIndicator(index: displayedItems.count, itemCount: displayedItems.count, hoveredGap: hoveredGap)
                }
                .coordinateSpace(name: "floatingList")
                .onPreferenceChange(RowFramePreferenceKey.self) { rowFrames = $0 }
                .overlay {
                    // The dragged row's handle icon, lifted out of the row and following the
                    // cursor (the in-row copy hides itself while dragging).
                    if let id = draggingItemID, let frame = rowFrames[id] {
                        DragHandleGlyph()
                            .position(
                                x: frame.maxX - 10.5 + dragTranslation.width,
                                y: frame.midY + dragTranslation.height
                            )
                            .allowsHitTesting(false)
                    }
                }
                .overlay {
                    ForEach(confettiBursts) { burst in
                        ConfettiBurstView(origin: burst.origin, seed: burst.seed)
                    }
                }
            }
        }
        .padding(.bottom, 8)
        .background(
            Color(nsColor: .windowBackgroundColor).opacity(settings.opacity)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .frame(width: settings.panelWidth)
        // Double-clicking any non-interactive part of the panel (header, gaps, row text)
        // opens the main window; buttons and drag handles swallow their own clicks first.
        .onTapGesture(count: 2, perform: onOpenMainWindow)
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
            .buttonStyle(HoverIconButtonStyle())
            .help(L.openMainWindowButton.text(settings.language))
            Button {
                showSettings.toggle()
            } label: {
                Image(systemName: "gearshape")
            }
            .buttonStyle(HoverIconButtonStyle())
            // Pushes the gear left so its right edge lines up with the rows' time text
            // (rows reserve 4pt trailing padding + 13pt drag handle + 2pt spacing ≈ 19pt,
            // versus the header's own 10pt trailing padding).
            .padding(.trailing, 7)
            .popover(isPresented: $showSettings, arrowEdge: .bottom) {
                PanelSettingsView()
                    .environmentObject(settings)
            }
        }
        .padding(.leading, 14)
        .padding(.trailing, 10)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .gesture(WindowDragGesture())
    }

    /// Launches the configured celebration at the completing row's checkbox. Gated on the
    /// effect setting and Reduce Motion; future effects switch here on `settings.completionEffect`.
    private func spawnCompletionEffect(for itemID: UUID) {
        guard settings.completionEffect == .confetti, !reduceMotion,
              let frame = rowFrames[itemID] else { return }
        // The checkbox glyph sits just inside the row's 14pt leading padding.
        let origin = CGPoint(x: frame.minX + 21, y: frame.midY)
        let burst = ConfettiBurst(origin: origin, seed: .random(in: .min ... .max))
        confettiBursts.append(burst)
        DispatchQueue.main.asyncAfter(deadline: .now() + ConfettiBurstView.duration + 0.1) {
            confettiBursts.removeAll { $0.id == burst.id }
        }
    }

    private func handleDragChanged(itemID: UUID, translation: CGSize) {
        if draggingItemID != itemID { draggingItemID = itemID }
        dragTranslation = translation

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
            dragTranslation = .zero
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
    /// #211F94 — shared accent for the reorder insertion line and the dragged row's highlight.
    static let dragAccent = Color(red: 0x21 / 255.0, green: 0x1F / 255.0, blue: 0x94 / 255.0)
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
    @Environment(\.colorScheme) private var colorScheme
    let index: Int
    let itemCount: Int
    let hoveredGap: Int?

    private var isEdge: Bool { index == 0 || index == itemCount }

    var body: some View {
        ZStack {
            if hoveredGap == index {
                Rectangle()
                    .fill(colorScheme == .dark ? Color(white: 0.26) : Color(white: 0.78))
                    .frame(height: 2)
            } else if !isEdge {
                Divider().opacity(0.15).padding(.leading, 34)
            }
        }
        .frame(height: isEdge ? 4 : 9)
    }
}
