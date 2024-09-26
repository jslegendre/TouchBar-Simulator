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
        TouchBarContextMenu.setup()
        TouchBarWindow.setUp()
        TouchBarWindow.showOnAllDesktops = true
        NSLog("App launched.")
        
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return TouchBarWindow.isClosed 
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        TouchBarWindow.dockSetting = .floating
        NSLog("App Reopened.")
        return true
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        NSLog("App shutting down.")
        //TouchBarContextMenu.finishUp()
        TouchBarWindow.finishUp()
    }
   
}
