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
    enum ScreenXPositioning {
        case retained
        case leftOut
        case left
        case center
        case right
        case rightOut
    }

    enum ScreenYPositioning {
        case retained
        case topOut
        case top
        case center
        case bottom
        case bottomOut
    }

    func alignedOrigin(_ xPositioning: ScreenXPositioning, _ yPositioning: ScreenYPositioning) -> CGPoint {
        guard let screen = NSScreen.main else {
            return frame.origin
        }

        let visibleFrame = screen.visibleFrame

        let x: Double
        let y: Double
        switch xPositioning {
        case .leftOut:
            x = screen.frame.minX - frame.width - 1
        case .left:
            x = visibleFrame.minX
        case .center:
            x = visibleFrame.midX - frame.width / 2
        case .right:
            x = visibleFrame.maxX - frame.width
        case .rightOut:
            x = screen.frame.maxX + 1
        case .retained:
            x = frame.origin.x
        }
        switch yPositioning {
        case .topOut:
            y = screen.frame.maxY + 1
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
        case .bottomOut:
            y = screen.frame.minY - frame.height - 1
        case .retained:
            y = frame.origin.y
        }

        return CGPoint(x: x, y: y)
        //return CGRect(x: x, y: y, width: frame.width, height: frame.height)
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
