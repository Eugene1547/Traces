//
//  ThemeTransition.swift
//  Traces
//

import AppKit

/// Crossfades the whole app between light and dark mode. SwiftUI swaps dynamic system colors
/// discretely, so per-color animation isn't possible; instead each visible window is covered
/// with a snapshot of its current appearance, the theme flips underneath instantly, and the
/// snapshot fades out — reading as one smooth color blend across every surface at once.
@MainActor
enum ThemeTransition {
    static func crossfade(_ change: () -> Void) {
        guard !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion else {
            change()
            return
        }

        var overlays: [NSImageView] = []
        for window in NSApp.windows where window.isVisible {
            guard let contentView = window.contentView,
                  contentView.bounds.width > 0, contentView.bounds.height > 0,
                  let rep = contentView.bitmapImageRepForCachingDisplay(in: contentView.bounds) else { continue }
            contentView.cacheDisplay(in: contentView.bounds, to: rep)

            let image = NSImage(size: contentView.bounds.size)
            image.addRepresentation(rep)

            let overlay = NSImageView(frame: contentView.bounds)
            overlay.image = image
            overlay.imageScaling = .scaleAxesIndependently
            overlay.autoresizingMask = [.width, .height]
            contentView.addSubview(overlay, positioned: .above, relativeTo: nil)
            overlays.append(overlay)
        }

        change()

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.35
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            for overlay in overlays {
                overlay.animator().alphaValue = 0
            }
        }, completionHandler: {
            for overlay in overlays {
                overlay.removeFromSuperview()
            }
        })
    }
}
