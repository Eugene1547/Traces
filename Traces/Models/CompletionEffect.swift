//
//  CompletionEffect.swift
//  Traces
//

import Foundation

/// The celebration effect played when a todo is completed. Designed as an enum + setting so a
/// picker in the main window can switch effects later; adding a new effect means adding a case
/// here and a matching one-shot view (see ConfettiBurstView).
enum CompletionEffect: String, Codable, CaseIterable, Identifiable {
    case none
    case confetti

    var id: String { rawValue }

    func label(_ language: AppLanguage) -> String {
        switch (self, language) {
        case (.none, .zh): return "无"
        case (.confetti, .zh): return "彩带"
        case (.none, .en): return "None"
        case (.confetti, .en): return "Confetti"
        }
    }
}
