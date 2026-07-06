//
//  FloatingPanelController.swift
//  Traces
//

import AppKit
import SwiftUI
import Combine

/// Borderless windows don't get AppKit's automatic edge resize cursors (those come from the
/// standard title bar frame), so we add them manually along the two resizable side edges.
/// Plain cursor rects (`resetCursorRects`/`addCursorRect`) only refresh for the key window, and
/// this panel is a `.nonactivatingPanel` that never becomes key — so those never fired. Tracking
/// areas with `.activeAlways` update regardless of key/main status, which is what's needed here.
private final class ResizeCursorHostingView<Content: View>: NSHostingView<Content> {
    private let edgeWidth: CGFloat = 6
    private var edgeTrackingAreas: [NSTrackingArea] = []

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in edgeTrackingAreas { removeTrackingArea(area) }
        edgeTrackingAreas.removeAll()

        let options: NSTrackingArea.Options = [.cursorUpdate, .activeAlways]
        let leftEdge = NSTrackingArea(
            rect: NSRect(x: 0, y: 0, width: edgeWidth, height: bounds.height),
            options: options, owner: self
        )
        let rightEdge = NSTrackingArea(
            rect: NSRect(x: bounds.width - edgeWidth, y: 0, width: edgeWidth, height: bounds.height),
            options: options, owner: self
        )
        addTrackingArea(leftEdge)
        addTrackingArea(rightEdge)
        edgeTrackingAreas = [leftEdge, rightEdge]
    }

    override func cursorUpdate(with event: NSEvent) {
        NSCursor.resizeLeftRight.set()
    }
}

final class FloatingPanelController: NSObject, NSWindowDelegate {
    private let panel: NSPanel
    private let settings: AppSettings
    private var cancellables = Set<AnyCancellable>()

    init(store: ChecklistStore, settings: AppSettings, onOpenMainWindow: @escaping () -> Void) {
        self.settings = settings

        let rootView = FloatingChecklistView(onOpenMainWindow: onOpenMainWindow)
            .environmentObject(store)
            .environmentObject(settings)

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: settings.panelWidth, height: 360),
            styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView, .resizable],
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

        let hostingView = ResizeCursorHostingView(rootView: rootView)
        hostingView.sizingOptions = [.intrinsicContentSize]
        panel.contentView = hostingView
        panel.setFrameAutosaveName("FloatingPanel")

        self.panel = panel
        super.init()

        panel.delegate = self

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

    /// Only the width is user-resizable; height keeps tracking content via intrinsicContentSize.
    func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
        let clampedWidth = min(max(frameSize.width, AppSettings.panelWidthRange.lowerBound), AppSettings.panelWidthRange.upperBound)
        settings.panelWidth = clampedWidth
        return NSSize(width: clampedWidth, height: sender.frame.height)
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
