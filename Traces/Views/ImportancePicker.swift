//
//  ImportancePicker.swift
//  Traces
//

import SwiftUI

struct ImportancePicker: View {
    @EnvironmentObject private var settings: AppSettings
    @Binding var selection: Importance
    @Binding var customColor: RGBAColor?

    @State private var showColorPopover = false

    private static let rainbow = AngularGradient(
        gradient: Gradient(colors: [.red, .yellow, .green, .cyan, .blue, .purple, .red]),
        center: .center
    )

    private var customColorBinding: Binding<RGBAColor> {
        Binding(
            get: { customColor ?? RGBAColor(red: 0.6, green: 0.6, blue: 0.6) },
            set: { customColor = $0 }
        )
    }

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Importance.allCases.filter { $0 != .custom }) { importance in
                option(for: importance) {
                    Circle()
                        .fill(importance.color)
                        .frame(width: 8, height: 8)
                } action: {
                    selection = importance
                }
            }

            option(for: .custom) {
                Circle()
                    .fill(customColor.map { AnyShapeStyle($0.color) } ?? AnyShapeStyle(Self.rainbow))
                    .frame(width: 8, height: 8)
            } action: {
                selection = .custom
                showColorPopover = true
            }
            .popover(isPresented: $showColorPopover, arrowEdge: .bottom) {
                CustomColorPopover(color: customColorBinding)
            }
        }
    }

    private func option(
        for importance: Importance,
        @ViewBuilder swatch: () -> some View,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                swatch()
                Text(importance.label(settings.language))
                    .font(.caption)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(selection == importance ? Color.secondary.opacity(0.15) : Color.clear)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct CustomColorPopover: View {
    @Binding var color: RGBAColor

    var body: some View {
        VStack(spacing: 14) {
            Circle()
                .fill(color.color)
                .frame(width: 36, height: 36)

            VStack(spacing: 8) {
                slider("R", $color.red, .red)
                slider("G", $color.green, .green)
                slider("B", $color.blue, .blue)
            }
        }
        .padding(14)
        .frame(width: 200)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func slider(_ label: String, _ value: Binding<Double>, _ tint: Color) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .frame(width: 12)
            Slider(value: value, in: 0...1)
                .tint(tint)
        }
    }
}
