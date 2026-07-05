//
//  AppLanguage.swift
//  Traces
//

import Foundation

enum AppLanguage: String, Codable, CaseIterable {
    case zh
    case en

    /// Compact label used for the language toggle button itself.
    var shortLabel: String {
        switch self {
        case .zh: return "中"
        case .en: return "EN"
        }
    }
}
