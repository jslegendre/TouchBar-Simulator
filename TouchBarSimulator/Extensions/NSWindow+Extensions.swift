//
//  NSWindow+Extensions.swift
//  TouchBar Simulator
//
//  Created by 上原葉 on 8/13/23.
//

import AppKit

extension NSWindow {
    var toolbarView: NSView? { standardWindowButton(.closeButton)?.superview }
}

extension NSWindow {
    enum MoveXPositioning {
        case left
        case center
        case right
    }

    enum MoveYPositioning {
        case top
        case center
        case bottom
    }

    func moveTo(x xPositioning: MoveXPositioning, y yPositioning: MoveYPositioning) {
        guard let screen = NSScreen.main else {
            return
        }

        let visibleFrame = screen.visibleFrame

        let x: Double
        let y: Double
        switch xPositioning {
        case .left:
            x = visibleFrame.minX
        case .center:
            x = visibleFrame.midX - frame.width / 2
        case .right:
            x = visibleFrame.maxX - frame.width
        }
        switch yPositioning {
        case .top:
            // Defect fix: Keep docked windows below menubar area.
            // Previously, the window would obstruct menubar clicks when the menubar was set to auto-hide.
            // Now, the window stays below that area.
            let menubarThickness = NSStatusBar.system.thickness
            y = min(visibleFrame.maxY - frame.height, screen.frame.maxY - menubarThickness - frame.height)
        case .center:
            y = visibleFrame.midY - frame.height / 2
        case .bottom:
            y = visibleFrame.minY
        }

        setFrameOrigin(CGPoint(x: x, y: y))
    }
}


extension NSWindow.Level {
    private static func level(for cgLevelKey: CGWindowLevelKey) -> Self {
        .init(rawValue: Int(CGWindowLevelForKey(cgLevelKey)))
    }

    public static let desktop = level(for: .desktopWindow)
    public static let desktopIcon = level(for: .desktopIconWindow)
    public static let backstopMenu = level(for: .backstopMenu)
    public static let dragging = level(for: .draggingWindow)
    public static let overlay = level(for: .overlayWindow)
    public static let help = level(for: .helpWindow)
    public static let utility = level(for: .utilityWindow)
    public static let assistiveTechHigh = level(for: .assistiveTechHighWindow)
    public static let cursor = level(for: .cursorWindow)

    public static let minimum = level(for: .minimumWindow)
    public static let maximum = level(for: .maximumWindow)
}
