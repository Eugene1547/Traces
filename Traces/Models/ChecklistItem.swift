//
//  ChecklistItem.swift
//  Traces
//

import SwiftUI

enum Importance: String, Codable, CaseIterable, Identifiable {
    case high
    case medium
    case low

    var id: String { rawValue }

    func label(_ language: AppLanguage) -> String {
        switch (self, language) {
        case (.high, .zh): return "高"
        case (.medium, .zh): return "中"
        case (.low, .zh): return "低"
        case (.high, .en): return "High"
        case (.medium, .en): return "Medium"
        case (.low, .en): return "Low"
        }
    }

    var color: Color {
        switch self {
        case .high: return .red
        case .medium: return .orange
        case .low: return .green
        }
    }

    /// Higher value sorts first for importanceDesc.
    var sortWeight: Int {
        switch self {
        case .high: return 0
        case .medium: return 1
        case .low: return 2
        }
    }
}

struct ChecklistItem: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var dueTime: Date?
    var importance: Importance
    var isCompleted: Bool
    var sortOrder: Double
    let createdAt: Date
    var completedAt: Date?

    init(
        id: UUID = UUID(),
        name: String,
        dueTime: Date?,
        importance: Importance,
        isCompleted: Bool = false,
        sortOrder: Double,
        createdAt: Date = Date(),
        completedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.dueTime = dueTime
        self.importance = importance
        self.isCompleted = isCompleted
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.completedAt = completedAt
    }
}
