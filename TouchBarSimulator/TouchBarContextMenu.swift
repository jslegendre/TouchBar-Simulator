//
//  TouchBarContextMenu.swift
//  TouchBarSimulator
//
//  Created by 上原葉 on 9/27/23.
//

import AppKit
import Defaults
import LaunchAtLogin

class TouchBarContextMenu {
    class ContextMenuDelegate:NSObject, NSMenuDelegate {
        func confinementRect(for menu: NSMenu, on screen: NSScreen?) -> NSRect {
            guard let lscreen = screen else { return NSZeroRect }
            return lscreen.visibleFrame
        }
    }
    private static let delegate = ContextMenuDelegate()
    private static let instance = TouchBarContextMenu()
    private let contextMenu: NSMenu
    private let autoLaunchToggle: NSMenuItem
    //private let quitButton: NSMenuItem
    //private let seperator1 = NSMenuItem.separator()
    private init() {
        let menu = NSMenu()
        
        let nEditToggle = NSMenuItem(title: "Launch At Login".localized, action: #selector(toggleAutoLaunch), keyEquivalent: "")
        nEditToggle.tag = 0
        
        //let nQuitButton = NSMenuItem(title: "Quit".localized, action: #selector(NSApplication.terminate(_:)), keyEquivalent: "")
        //nQuitButton.tag = 1
        
        contextMenu = menu
        autoLaunchToggle = nEditToggle
        //quitButton = nQuitButton
    }
    
    private func updateMenu() {
        autoLaunchToggle.state = (LaunchAtLogin.isEnabled) ? .on : .off
    }
    
    public static func setup() {
        instance.autoLaunchToggle.target = instance
        instance.contextMenu.addItem(instance.autoLaunchToggle)
        //instance.contextMenu.addItem(instance.seperator1)
        //instance.contextMenu.addItem(instance.quitButton)
        
        instance.contextMenu.delegate = delegate
        
        instance.updateMenu()
    }
    
    public static func showContextMenu(_ sender: NSButton) {
        instance.updateMenu()
        instance.contextMenu.popUp(positioning: nil, at: .init(x: sender.bounds.minX, y: sender.bounds.minY), in: sender)
    }
    
    @objc func toggleAutoLaunch(_ sender: NSButton) {
        //Defaults[.launchAtLogin] = !Defaults[.launchAtLogin] // Don't need to store autoLaunch option elsewhere
        LaunchAtLogin.isEnabled = !LaunchAtLogin.isEnabled
    }

    
}


