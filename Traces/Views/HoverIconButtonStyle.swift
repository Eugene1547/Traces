//
//  HoverIconButtonStyle.swift
//  Traces
//

import SwiftUI

/// Shared hover/press feedback for the panel's small icon buttons: on hover the glyph darkens
/// and a soft circular backdrop fades in (150ms), on press the whole control dips to 0.9 (100ms).
/// Honors the system Reduce Motion setting by swapping animations for instant state changes.
struct HoverIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        HoverIconButton(configuration: configuration)
    }

    private struct HoverIconButton: View {
        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        @State private var isHovered = false
        let configuration: Configuration

        var body: some View {
            configuration.label
                .foregroundStyle(isHovered ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary))
                .frame(width: 22, height: 22)
                .background(
                    Circle()
                        .fill(Color.primary.opacity(isHovered ? 0.08 : 0))
                )
                .contentShape(Circle())
                .scaleEffect(configuration.isPressed ? 0.9 : 1)
                .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: isHovered)
                .animation(reduceMotion ? nil : .easeOut(duration: 0.1), value: configuration.isPressed)
                .onHover { isHovered = $0 }
        }
    }
}
