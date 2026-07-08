//
//  CalendarRange.swift
//  Traces
//

import Foundation

/// Time span shown by the calendar heatmap; also scopes the completed/pending stat cards.
enum CalendarRange: String, CaseIterable, Identifiable {
    case all
    case sixMonths
    case threeMonths

    var id: String { rawValue }

    func label(_ language: AppLanguage) -> String {
        switch (self, language) {
        case (.all, .zh): return "所有"
        case (.sixMonths, .zh): return "六个月"
        case (.threeMonths, .zh): return "三个月"
        case (.all, .en): return "All"
        case (.sixMonths, .en): return "6 Months"
        case (.threeMonths, .en): return "3 Months"
        }
    }
}
