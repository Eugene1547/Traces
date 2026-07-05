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

    var label: String {
        switch self {
        case .manual: return "手动"
        case .nameAsc: return "名称"
        case .importanceDesc: return "重要性"
        case .timeAsc: return "时间 ↑"
        case .timeDesc: return "时间 ↓"
        }
    }
}
