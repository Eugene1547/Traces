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
                    ForEach(displayedItems) { item in
                        FloatingRowView(item: item) {
                            store.complete(item.id)
                        }
                        .onDrag {
                            NSItemProvider(object: item.id.uuidString as NSString)
                        }
                        .onDrop(
                            of: [.text],
                            delegate: ReorderDropDelegate(targetID: item.id, onReorder: handleReorder)
                        )
                        if item.id != displayedItems.last?.id {
                            Divider().opacity(0.15).padding(.leading, 34)
                        }
                    }
                }
            }
        }
        .padding(.bottom, 8)
        .background(
            Color(nsColor: .windowBackgroundColor).opacity(settings.opacity)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .frame(minWidth: 260, maxWidth: 320)
        .preferredColorScheme(settings.isDarkMode ? .dark : .light)
    }

    private var header: some View {
        HStack {
            Text("Traces")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Button {
                showSettings.toggle()
            } label: {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showSettings, arrowEdge: .bottom) {
                PanelSettingsView(onOpenMainWindow: onOpenMainWindow)
                    .environmentObject(settings)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .gesture(WindowDragGesture())
    }

    private func handleReorder(draggedID: UUID, targetID: UUID) {
        guard draggedID != targetID else { return }
        var order = displayedItems.map(\.id)
        guard let from = order.firstIndex(of: draggedID), let to = order.firstIndex(of: targetID) else { return }
        order.remove(at: from)
        order.insert(draggedID, at: to)
        store.reorder(ids: order)
        settings.sortRule = .manual
    }
}

private struct ReorderDropDelegate: DropDelegate {
    let targetID: UUID
    let onReorder: (_ draggedID: UUID, _ targetID: UUID) -> Void

    func performDrop(info: DropInfo) -> Bool {
        guard let provider = info.itemProviders(for: [.text]).first else { return false }
        provider.loadObject(ofClass: NSString.self) { object, _ in
            guard let idString = object as? String, let draggedID = UUID(uuidString: idString) else { return }
            DispatchQueue.main.async {
                onReorder(draggedID, targetID)
            }
        }
        return true
    }
}
