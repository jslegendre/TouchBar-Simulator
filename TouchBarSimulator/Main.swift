//
//  main.swift
//  TouchBar Simulator
//
//  Created by 上原葉 on 8/13/23.
//

import AppKit

@main struct MyApp {
    
    static func main () -> Void {
        // Check for duplicated instances (in case of "open -n" command or other circumstances).
        let otherRunningInstances = NSWorkspace.shared.runningApplications.filter {
            $0.bundleIdentifier == Globals.mainAppId && $0 != NSRunningApplication.current
        }
        let isAppAlreadyRunning = !otherRunningInstances.isEmpty
        
        if (isAppAlreadyRunning) {
            NSLog("Program already running: \(otherRunningInstances.map{$0.processIdentifier}).")
        }
        else {
            
            // Load main entry for NSApp
            NSLog("App started.")
            let delegate = AppDelegate()
            NSApplication.shared.delegate = delegate
            NSApplication.shared.setActivationPolicy(.accessory)
            /*
            let infoDict = Bundle.main.infoDictionary
            NSLog("\(infoDict!)")
             */
            let ret_val = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
            NSLog("App exited with exit code: \(ret_val).")
        }
        return
    }
}
