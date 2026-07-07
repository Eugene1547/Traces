//
//  ChecklistItem.swift
//  Traces
//

import SwiftUI

enum Importance: String, Codable, CaseIterable, Identifiable {
    case high
    case medium
    case low
    case custom

    var id: String { rawValue }

    func label(_ language: AppLanguage) -> String {
        switch (self, language) {
        case (.high, .zh): return "高"
        case (.medium, .zh): return "中"
        case (.low, .zh): return "低"
        case (.custom, .zh): return "自定义"
        case (.high, .en): return "High"
        case (.medium, .en): return "Medium"
        case (.low, .en): return "Low"
        case (.custom, .en): return "Custom"
        }
    }

    /// Fallback color when `.custom` has no picked color yet (see `ChecklistItem.displayColor`).
    var color: Color {
        switch self {
        case .high: return .red
        case .medium: return .orange
        case .low: return .green
        case .custom: return .gray
        }
    }

    /// Higher value sorts first for importanceDesc.
    var sortWeight: Int {
        switch self {
        case .high: return 0
        case .medium: return 1
        case .low: return 2
        case .custom: return 3
        }
    }
}

struct ChecklistItem: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var dueTime: Date?
    var importance: Importance
    /// Only meaningful when `importance == .custom`.
    var customColor: RGBAColor?
    var isCompleted: Bool
    var sortOrder: Double
    let createdAt: Date
    var completedAt: Date?

    init(
        id: UUID = UUID(),
        name: String,
        dueTime: Date?,
        importance: Importance,
        customColor: RGBAColor? = nil,
        isCompleted: Bool = false,
        sortOrder: Double,
        createdAt: Date = Date(),
        completedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.dueTime = dueTime
        self.importance = importance
        self.customColor = customColor
        self.isCompleted = isCompleted
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.completedAt = completedAt
    }

    /// The color to actually render: the picked custom color when importance is `.custom`,
    /// otherwise the preset's fixed color.
    var displayColor: Color {
        if importance == .custom, let customColor {
            return customColor.color
        }
        return importance.color
    }

    /// True when the item has a due time in the past and isn't completed.
    func isOverdue(at date: Date = Date()) -> Bool {
        guard !isCompleted, let dueTime else { return false }
        return dueTime < date
    }
}
