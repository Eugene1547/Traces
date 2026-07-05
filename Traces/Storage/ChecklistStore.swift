//
//  ChecklistStore.swift
//  Traces
//

import Foundation
import Combine

@MainActor
final class ChecklistStore: ObservableObject {
    @Published private(set) var items: [ChecklistItem] = []

    private let fileURL: URL

    var todoItems: [ChecklistItem] {
        items.filter { !$0.isCompleted }
    }

    var completedItems: [ChecklistItem] {
        items
            .filter { $0.isCompleted }
            .sorted { ($0.completedAt ?? $0.createdAt) > ($1.completedAt ?? $1.createdAt) }
    }

    init(fileURL: URL? = nil) {
        if let fileURL {
            self.fileURL = fileURL
        } else {
            let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            let bundleID = Bundle.main.bundleIdentifier ?? "Traces"
            let dir = support.appendingPathComponent(bundleID, isDirectory: true)
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            self.fileURL = dir.appendingPathComponent("items.json")
        }
        load()
    }

    func addItem(name: String, dueTime: Date?, importance: Importance) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let nextOrder = (todoItems.map(\.sortOrder).max() ?? 0) + 1
        let item = ChecklistItem(name: trimmed, dueTime: dueTime, importance: importance, sortOrder: nextOrder)
        items.append(item)
        save()
    }

    func update(_ item: ChecklistItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index] = item
        save()
    }

    func delete(_ id: UUID) {
        items.removeAll { $0.id == id }
        save()
    }

    func complete(_ id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].isCompleted = true
        items[index].completedAt = Date()
        save()
    }

    func reopen(_ id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        let nextOrder = (todoItems.map(\.sortOrder).max() ?? 0) + 1
        items[index].isCompleted = false
        items[index].completedAt = nil
        items[index].sortOrder = nextOrder
        save()
    }

    /// Reassigns sortOrder for the given ordered list of todo item ids.
    func reorder(ids: [UUID]) {
        for (index, id) in ids.enumerated() {
            guard let itemIndex = items.firstIndex(where: { $0.id == id }) else { continue }
            items[itemIndex].sortOrder = Double(index)
        }
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        items = (try? decoder.decode([ChecklistItem].self, from: data)) ?? []
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(items) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
