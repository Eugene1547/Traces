//
//  SortRule.swift
//  Traces
//

import Foundation

enum SortRule: String, Codable, CaseIterable, Identifiable {
    case manual
    case nameAsc
    case importanceDesc
    case timeAsc
    case timeDesc

    var id: String { rawValue }

    func label(_ language: AppLanguage) -> String {
        switch (self, language) {
        case (.manual, .zh): return "手动"
        case (.nameAsc, .zh): return "名称"
        case (.importanceDesc, .zh): return "重要性"
        case (.timeAsc, .zh): return "时间 ↑"
        case (.timeDesc, .zh): return "时间 ↓"
        case (.manual, .en): return "Manual"
        case (.nameAsc, .en): return "Name"
        case (.importanceDesc, .en): return "Importance"
        case (.timeAsc, .en): return "Time ↑"
        case (.timeDesc, .en): return "Time ↓"
        }
    }
}
