//
//  AppSettings.swift
//  Traces
//

import Foundation
import Combine

@MainActor
final class AppSettings: ObservableObject {
    static let opacityRange: ClosedRange<Double> = 0.3...1.0

    private enum Keys {
        static let opacity = "settings.opacity"
        static let isPinned = "settings.isPinned"
        static let sortRule = "settings.sortRule"
        static let isDarkMode = "settings.isDarkMode"
        static let language = "settings.language"
    }

    @Published var opacity: Double {
        didSet {
            let clamped = min(max(opacity, Self.opacityRange.lowerBound), Self.opacityRange.upperBound)
            if clamped != opacity { opacity = clamped; return }
            defaults.set(opacity, forKey: Keys.opacity)
        }
    }

    @Published var isPinned: Bool {
        didSet { defaults.set(isPinned, forKey: Keys.isPinned) }
    }

    @Published var isDarkMode: Bool {
        didSet { defaults.set(isDarkMode, forKey: Keys.isDarkMode) }
    }

    @Published var sortRule: SortRule {
        didSet { defaults.set(sortRule.rawValue, forKey: Keys.sortRule) }
    }

    @Published var language: AppLanguage {
        didSet { defaults.set(language.rawValue, forKey: Keys.language) }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if defaults.object(forKey: Keys.opacity) != nil {
            opacity = defaults.double(forKey: Keys.opacity)
        } else {
            opacity = 0.85
        }
        if defaults.object(forKey: Keys.isPinned) != nil {
            isPinned = defaults.bool(forKey: Keys.isPinned)
        } else {
            isPinned = true
        }
        if let raw = defaults.string(forKey: Keys.sortRule), let rule = SortRule(rawValue: raw) {
            sortRule = rule
        } else {
            sortRule = .importanceDesc
        }
        isDarkMode = defaults.bool(forKey: Keys.isDarkMode)
        if let raw = defaults.string(forKey: Keys.language), let lang = AppLanguage(rawValue: raw) {
            language = lang
        } else {
            language = .zh
        }
    }
}
