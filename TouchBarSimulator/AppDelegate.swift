//
//  AppDelegate.swift
//  TouchBar Simulator
//
//  Created by 上原葉 on 8/13/23.
//

import Foundation
import AppKit


class AppDelegate: NSObject, NSApplicationDelegate{
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        TouchBarWindow.setUp()
        //ContextMenuManager.setup()
        //HotKeyManager.setup()
        NSLog("App launched.")
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        TouchBarWindow.dockSetting = .floating
        NSLog("App Reopened.")
        return true
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        NSLog("App shutting down.")
        //HotKeyManager.finishUp()
        //ContextMenuManager.finishUp()
        TouchBarWindow.finishUp()
    }
   
}

/*
final class AppDelegate: NSObject, NSApplicationDelegate {
    private(set) lazy var window = with(TouchBarWindow()) {
        $0.alphaValue = Defaults[.windowTransparency]
        $0.setUp()
    }

    private(set) lazy var statusItem = with(NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)) {
        $0.menu = with(NSMenu()) {
            $0.delegate = self
        }
        $0.button!.image = NSImage(named: "MenuBarIcon")
        $0.button!.toolTip = "Right-click or option-click for menu"
        $0.button!.preventsHighlight = true
    }

    private lazy var updateController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)

    func applicationWillFinishLaunching(_ notification: Notification) {
        UserDefaults.standard.register(defaults: [
            "NSApplicationCrashOnExceptions": true
        ])
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        checkAccessibilityPermission()
        _ = updateController
        _ = window
        _ = statusItem

        KeyboardShortcuts.onKeyUp(for: .toggleTouchBar) { [self] in
            toggleView()
        }
    }

    func checkAccessibilityPermission() {
        // We intentionally don't use the system prompt as our dialog explains it better.
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: false] as CFDictionary
        if AXIsProcessTrustedWithOptions(options) {
            return
        }

        "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility".openUrl()

        let alert = NSAlert()
        alert.messageText = "Touch Bar Simulator needs accessibility access."
        alert.informativeText = "In the System Preferences window that just opened, find “Touch Bar Simulator” in the list and check its checkbox. Then click the “Continue” button here."
        alert.addButton(withTitle: "Continue")
        alert.addButton(withTitle: "Quit")

        guard alert.runModal() == .alertFirstButtonReturn else {
            SSApp.quit()
            return
        }

        SSApp.relaunch()
    }

    @objc
    func captureScreenshot() {
        let KEY_6: CGKeyCode = 0x58
        pressKey(keyCode: KEY_6, flags: [.maskShift, .maskCommand])
    }

    func toggleView() {
        window.setIsVisible(!window.isVisible)
    }
}
*/
