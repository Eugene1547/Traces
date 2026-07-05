//
//  FloatingPanelController.swift
//  Traces
//

import AppKit
import SwiftUI
import Combine

final class FloatingPanelController {
    private let panel: NSPanel
    private var cancellables = Set<AnyCancellable>()

    init(store: ChecklistStore, settings: AppSettings, onOpenMainWindow: @escaping () -> Void) {
        let rootView = FloatingChecklistView(onOpenMainWindow: onOpenMainWindow)
            .environmentObject(store)
            .environmentObject(settings)

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 260, height: 360),
            styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isReleasedWhenClosed = false

        let hostingView = NSHostingView(rootView: rootView)
        hostingView.sizingOptions = [.intrinsicContentSize]
        panel.contentView = hostingView
        panel.setFrameAutosaveName("FloatingPanel")

        self.panel = panel

        settings.$isPinned
            .sink { [weak panel] isPinned in
                panel?.level = isPinned ? .floating : .normal
            }
            .store(in: &cancellables)

        if panel.setFrameUsingName("FloatingPanel") == false {
            positionAtTopCenter()
        }
    }

    func showPanel() {
        panel.orderFrontRegardless()
    }

    private func positionAtTopCenter() {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let size = panel.frame.size
        let origin = NSPoint(
            x: screenFrame.midX - size.width / 2,
            y: screenFrame.maxY - size.height - 12
        )
        panel.setFrameOrigin(origin)
    }
}
