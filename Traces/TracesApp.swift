//
//  TracesApp.swift
//  Traces
//

import SwiftUI

@main
struct TracesApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
