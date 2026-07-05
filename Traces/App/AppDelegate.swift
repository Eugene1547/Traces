//
//  AppDelegate.swift
//  Traces
//

import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    let store = ChecklistStore()
    let settings = AppSettings()

    private var mainWindow: NSWindow!
    private var panelController: FloatingPanelController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)

        setUpMainWindow()
        setUpPanel()

        mainWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        return false
    }

    func showMainWindow() {
        mainWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func setUpMainWindow() {
        let rootView = MainWindowView()
            .environmentObject(store)
            .environmentObject(settings)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 620),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Traces"
        window.center()
        window.contentView = NSHostingView(rootView: rootView)
        window.delegate = self
        window.isReleasedWhenClosed = false
        mainWindow = window
    }

    private func setUpPanel() {
        panelController = FloatingPanelController(
            store: store,
            settings: settings,
            onOpenMainWindow: { [weak self] in self?.showMainWindow() }
        )
        panelController.showPanel()
    }
}
