//
//  AppSettings.swift
//  Traces
//

import Foundation
import Combine

@MainActor
final class AppSettings: ObservableObject {
    static let opacityRange: ClosedRange<Double> = 0.3...1.0
    static let panelWidthRange: ClosedRange<Double> = 220...480

    private enum Keys {
        static let opacity = "settings.opacity"
        static let isPinned = "settings.isPinned"
        static let sortRule = "settings.sortRule"
        static let isDarkMode = "settings.isDarkMode"
        static let language = "settings.language"
        static let panelWidth = "settings.panelWidth"
        static let completionEffect = "settings.completionEffect"
    }

    @Published var opacity: Double {
        didSet {
            let clamped = min(max(opacity, Self.opacityRange.lowerBound), Self.opacityRange.upperBound)
            if clamped != opacity { opacity = clamped; return }
            defaults.set(opacity, forKey: Keys.opacity)
        }
    }

    @Published var panelWidth: Double {
        didSet {
            let clamped = min(max(panelWidth, Self.panelWidthRange.lowerBound), Self.panelWidthRange.upperBound)
            if clamped != panelWidth { panelWidth = clamped; return }
            defaults.set(panelWidth, forKey: Keys.panelWidth)
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

    @Published var completionEffect: CompletionEffect {
        didSet { defaults.set(completionEffect.rawValue, forKey: Keys.completionEffect) }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if defaults.object(forKey: Keys.opacity) != nil {
            opacity = defaults.double(forKey: Keys.opacity)
        } else {
            opacity = 0.85
        }
        if defaults.object(forKey: Keys.panelWidth) != nil {
            panelWidth = defaults.double(forKey: Keys.panelWidth)
        } else {
            panelWidth = 280
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
        if let raw = defaults.string(forKey: Keys.completionEffect), let effect = CompletionEffect(rawValue: raw) {
            completionEffect = effect
        } else {
            completionEffect = .confetti
        }
    }
}
