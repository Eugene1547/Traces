//
//  L.swift
//  Traces
//

import Foundation

/// Minimal in-app zh/en string table (no Xcode String Catalog needed).
enum L: String {
    case newTodoTitle
    case namePlaceholder
    case noDeadline
    case dueTimeLabel
    case addButton
    case todoSection
    case completedSection
    case editTitle
    case deleteButton
    case cancelButton
    case saveButton
    case restoreButton
    case emptyTodo
    case opacityLabel
    case sortRuleLabel
    case pinLabel
    case openMainWindowButton
    case noDeadlineShort

    private static let table: [L: (zh: String, en: String)] = [
        .newTodoTitle: ("新建待办事项", "New To-Do"),
        .namePlaceholder: ("名称", "Name"),
        .noDeadline: ("无时间限制", "No due date"),
        .dueTimeLabel: ("完成时间", "Due time"),
        .addButton: ("添加", "Add"),
        .todoSection: ("待办", "To-Do"),
        .completedSection: ("已完成", "Completed"),
        .editTitle: ("编辑条目", "Edit Item"),
        .deleteButton: ("删除", "Delete"),
        .cancelButton: ("取消", "Cancel"),
        .saveButton: ("保存", "Save"),
        .restoreButton: ("恢复", "Restore"),
        .emptyTodo: ("暂无待办", "No tasks"),
        .opacityLabel: ("透明度", "Opacity"),
        .sortRuleLabel: ("排序规则", "Sort by"),
        .pinLabel: ("置顶", "Pin on top"),
        .openMainWindowButton: ("打开主窗口", "Open Main Window"),
        .noDeadlineShort: ("无期限", "No date"),
    ]

    func text(_ language: AppLanguage) -> String {
        let pair = Self.table[self] ?? (zh: rawValue, en: rawValue)
        return language == .zh ? pair.zh : pair.en
    }
}
