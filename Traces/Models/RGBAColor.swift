//
//  RGBAColor.swift
//  Traces
//

import SwiftUI
import AppKit

/// A Codable RGB color, used to persist a user-picked custom importance color.
struct RGBAColor: Codable, Equatable {
    var red: Double
    var green: Double
    var blue: Double

    var color: Color {
        Color(red: red, green: green, blue: blue)
    }

    init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    init(color: Color) {
        let rgb = NSColor(color).usingColorSpace(.deviceRGB) ?? NSColor(color)
        red = Double(rgb.redComponent)
        green = Double(rgb.greenComponent)
        blue = Double(rgb.blueComponent)
    }
}
