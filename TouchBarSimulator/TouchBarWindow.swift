//
//  TouchBarWindow.swift
//  TouchBar Simulator
//
//  Created by 上原葉 on 8/13/23.
//

import AppKit
import Defaults

final class TouchBarWindow: NSPanel, NSWindowDelegate {
    
    private var isClosed = false
    func windowWillClose(_ notification: Notification) {
        isClosed = true
    }
    
    enum Docking: String, Codable {
        case floating
        case dockedToTop
        case dockedToBottom
    }
    private var docking: Docking = Defaults[.windowDocking] {
        didSet {
            switch (oldValue, docking) {
            case (_, .floating):
                detectionTimeout = Date.distantFuture
                addTitle()
                moveWithAnimation(destination: destinationFrame(docking, hiding))
                fadeWithAnimation(destination: 1.0)
            case (.floating, .dockedToTop), (.floating, .dockedToBottom):
                Defaults[.lastFloatingPosition] = frame.origin
                fallthrough
            case (_, _):
                removeTitle()
                moveWithAnimation(destination: destinationFrame(docking, hiding))
                detectionTimeout = Date() + TimeInterval(1.5)
                break
            }
            Defaults[.windowDocking] = docking
        }
    }
    
    private var hiding: Bool = false {
        didSet {
            switch (docking, hiding) {
            case (.floating, _) where hiding == true:
                hiding = false
                break
            case (_, true) where oldValue != hiding:
                moveWithAnimation(destination: destinationFrame(docking, hiding))
                fadeWithAnimation(destination: 0.0)
            case (_, false) where oldValue != hiding:
                moveWithAnimation(destination: destinationFrame(docking, hiding))
                fadeWithAnimation(destination: 1.0)
            case (_, _):
                break
            }
        }
    }
    
    private var windowMoveAnimation = TouchBarAnimation(duration: 0.3, animationCurve: .easeInOut, blockMode: .nonblocking)
    private var windowFadeAnimation = TouchBarAnimation(duration: 0.3, animationCurve: .easeInOut, blockMode: .nonblocking)
    
    override var canBecomeMain: Bool { false }
    override var canBecomeKey: Bool { false }
    
    private func addToolBar() {
        guard let toolbarView = toolbarView else {
            return
        }

        let buttonUp = NSButton()
        if #available(macOS 11, *) {
            buttonUp.image = NSImage(systemSymbolName: "menubar.arrow.up.rectangle", accessibilityDescription: "Dock touch bar simulator to the top of the screen.")
        }
        else {
            buttonUp.image = NSImage(named: "DockTop")
        }
        buttonUp.imageScaling = .scaleProportionallyDown
        buttonUp.isBordered = false
        buttonUp.bezelStyle = .shadowlessSquare
        buttonUp.frame = CGRect(x: toolbarView.frame.width - 57, y: 4, width: 16, height: 11)
        buttonUp.autoresizingMask.insert(NSView.AutoresizingMask.minXMargin)
        buttonUp.action = #selector(TouchBarWindow.dockUpPressed)
        toolbarView.addSubview(buttonUp)
        
        let buttonDown = NSButton()
        if #available(macOS 11, *) {
            buttonDown.image = NSImage(systemSymbolName: "dock.arrow.down.rectangle", accessibilityDescription: "Dock touch bar simulator to the bottom of the screen.")
        }
        else {
            buttonDown.image = NSImage(named: "DockDown")
        }
        buttonDown.imageScaling = .scaleProportionallyDown
        buttonDown.isBordered = false
        buttonDown.bezelStyle = .shadowlessSquare
        buttonDown.frame = CGRect(x: toolbarView.frame.width - 38, y: 4, width: 16, height: 11)
        buttonDown.autoresizingMask.insert(NSView.AutoresizingMask.minXMargin)
        buttonDown.action = #selector(TouchBarWindow.dockDownPressed)
        toolbarView.addSubview(buttonDown)
        
        let buttonSettings = NSButton()
        if #available(macOS 11, *) {
            buttonSettings.image = NSImage(systemSymbolName: "gear", accessibilityDescription: "Touch bar simulator Settings.")
        }
        else {
            buttonSettings.image = NSImage(named: "Settings")
        }
        buttonSettings.imageScaling = .scaleProportionallyDown
        buttonSettings.isBordered = false
        buttonSettings.bezelStyle = .shadowlessSquare
        buttonSettings.frame = CGRect(x: toolbarView.frame.width - 19, y: 4, width: 16, height: 11)
        buttonSettings.autoresizingMask.insert(NSView.AutoresizingMask.minXMargin)
        buttonSettings.action = #selector(TouchBarWindow.settingsPressed)
        toolbarView.addSubview(buttonSettings)
        
        let constraintsArray = [
            NSLayoutConstraint.constraints(withVisualFormat: "H:[buttonUp]-3-[buttonDown]-3-[buttonSettings]", metrics: nil, views: ["buttonUp": buttonUp, "buttonDown": buttonDown, "buttonSettings": buttonSettings]),
            ]
            .reduce([], +)
        toolbarView.addConstraints(constraintsArray)
        NSLayoutConstraint.activate(constraintsArray)
        //toolbarView.layoutSubtreeIfNeeded()
        //toolbarView.updateLayer()
        toolbarView.updateConstraints()
        toolbarView.updateConstraintsForSubtreeIfNeeded()
        //NSLog("\(toolbarView.subviews.map({($0, $0.frame, $0.constraints)}))")
    }
    private func addViewSideBar() {
        contentView = TouchBarViewFactory.generate(standalone: true) {
            [weak self] button in
            self?.dockReleasePressed(button)
            return
        }
    }
    
    private func removeViewSideBar() {
        contentView = TouchBarViewFactory.generate(standalone: false)
    }
    
    @objc func dockDownPressed(_: NSButton) {
        docking = .dockedToBottom
    }
    
    @objc func dockUpPressed(_: NSButton) {
        docking = .dockedToTop
    }
    
    @objc func dockReleasePressed(_ sender: NSButton) {
        if let event = NSApp.currentEvent {
            
            let isOptionKeyPressed = event.modifierFlags.contains(NSEvent.ModifierFlags.option)
            let isComandKeyPressed = event.modifierFlags.contains(NSEvent.ModifierFlags.command)
            
            switch (isComandKeyPressed, isOptionKeyPressed) {
            case (true, _):
                TouchBarContextMenu.showContextMenu(sender)
            case (false, true):
                close()
            case (false, false):
                docking = .floating
            }
        }
    }
    
    @objc func settingsPressed(_ sender: NSButton) {
        TouchBarContextMenu.showContextMenu(sender)
    }
    
    private func addTitle() {
        if !styleMask.contains(.titled) {
            styleMask.insert(.titled)
            addToolBar()
            removeViewSideBar()
        }
    }
    private func removeTitle() {
        if styleMask.contains(.titled) {
            styleMask.remove(.titled)
        }
        addViewSideBar()
    }
    
    private var detectionTimeout = Date() + TimeInterval(1.5)
    private var detectionRect: CGRect {
        let windowFrame = frame
        guard
            let visibleFrame = NSScreen.main?.visibleFrame,
            let screenFrame = NSScreen.main?.frame
        else {
            return CGRect.zero
        }
        
        switch (docking, hiding) {
        case (.floating, _):
            return CGRect.infinite//windowFrame
        case (.dockedToBottom, false):
            return CGRect(
                x: windowFrame.minX, //0,
                y: 0,
                width: windowFrame.width,//visibleFrame.width,
                height: frame.height + (screenFrame.height - visibleFrame.height - NSStatusBar.system.thickness)
            )
        case (.dockedToBottom, true):
            return CGRect(x: windowFrame.minX,
                          y: 0,
                          width: windowFrame.width,
                          height: 1)
        case (.dockedToTop, false):
            return CGRect(
                x: windowFrame.minX,
                // Without `+ 1`, the Touch Bar would glitch (toggling rapidly).
                y: screenFrame.height - frame.height - NSStatusBar.system.thickness + 1,
                width: windowFrame.width,
                height: frame.height + NSStatusBar.system.thickness
            )
        case (.dockedToTop, true):
            return CGRect(
                x: windowFrame.minX,
                y: screenFrame.height,
                width: windowFrame.width,
                height: 1
            )
        }
    }
    private var isMouseDetected: Bool {
        return detectionRect.contains(NSEvent.mouseLocation)
    }
    private func handleAutoHide() {
        switch (docking, hiding) {
        case (.floating, _):
            break
        case (.dockedToTop, _), (.dockedToBottom, _):
            if isMouseDetected {
                hiding = false
                detectionTimeout = Date() + TimeInterval(1.5)
            }
            else if Date() >= detectionTimeout {
                hiding = true
            }
        }
    }
    
    private func destinationOrigin(_ forDocking: Docking, _ forHiding: Bool) -> CGPoint {
        switch(forDocking, forHiding) {
        case (.floating, _):
            if let screen = NSScreen.main, let savedValue = Defaults[.lastFloatingPosition], screen.visibleFrame.contains(savedValue) {
                return savedValue
            }
            else {
                return alignedOrigin(.center, .center)
            }
            //return alignedOrigin(.center, .center)
        case (.dockedToTop, false):
            return alignedOrigin(.center, .top)
        case (.dockedToBottom, false):
            return alignedOrigin(.center, .bottom)
        case (.dockedToTop, true):
            return alignedOrigin(.center, .topOut)
        case (.dockedToBottom, true):
            return alignedOrigin(.center, .bottomOut)
        }
    }
    private func destinationFrame(_ forDocking: Docking, _ forHiding: Bool) -> CGRect {
        return CGRect(origin: destinationOrigin(forDocking, forHiding), size: CGSize(width: frame.width, height: frame.height))
    }
    
    private func moveWithAnimation(destination endFrame: CGRect) {
        windowMoveAnimation.animation = {(startFrame, endFrame) in
            let dWidth = endFrame.size.width / startFrame.size.width - 1
            let dHeight = endFrame.size.width / startFrame.size.width - 1
            let centerX = startFrame.midX
            let centerY = startFrame.midY
            let dX = endFrame.midX - startFrame.midX
            let dY = endFrame.midY - startFrame.midY
            
            let scaleTranslateTransform = {(t: CGFloat) in
                return CGAffineTransform.identity
                // Step 1: Scaling transform with mid point as origin
                    .translatedBy(x: -centerX, y: -centerY)
                    .scaledBy(x: dWidth * t + 1, y: dHeight * t + 1)
                    .translatedBy(x: centerX, y: centerY)
                // Step 2: Translating transform
                    .translatedBy(x: dX * t, y: dY * t)
            }
            
            return { [unowned self] (currentValue: Float) in
                if currentValue == 1.0 {
                    self.setFrame(endFrame, display: true)
                }
                else {
                    let t = CGFloat(currentValue)
                    
                    let currentTransform = scaleTranslateTransform(t)
                    let currentFrame = startFrame.applying(currentTransform)
                    self.setFrame(currentFrame, display: true)
                    
                    /*
                    NSLog("\(currentValue) -> \(currentFrame)")
                    if currentValue == 1.0 && endFrame != currentFrame {
                        self.setFrame(endFrame, display: true)
                        NSLog("-X> \(endFrame)")
                    }
                    else if currentValue == 1.0 && endFrame == currentFrame {
                        NSLog("OK")
                    }
                    */
                }
            }}(frame, endFrame)
        windowMoveAnimation.start()
    }
    private func fadeWithAnimation(destination endValue: CGFloat) {
        windowFadeAnimation.animation = {(startValue, endValue) in
            let dAlphaValue = endValue - startValue
            let scaledValue = {(t: CGFloat) in return startValue + dAlphaValue * t}
            return { [unowned self] (currentValue: Float) in
                if currentValue == 1.0 {
                    self.alphaValue = endValue
                }
                else {
                    let t = CGFloat(currentValue)
                    self.alphaValue = scaledValue(t)
                    /*
                     NSLog("-> \(scaledValue)")
                     if currentValue == 1.0 && endValue != scaledValue {
                     self.alphaValue = endValue
                     NSLog("-X> \(endValue)")
                     }
                     else if currentValue == 1.0 && endValue == scaledValue {
                     NSLog("OK")
                     }
                     */
                }
            }}(alphaValue, endValue)
        
        windowFadeAnimation.start()
    }
    
    private init() {
        super.init(
            contentRect: .zero,
            styleMask: [
                .titled,
                .closable,
                .nonactivatingPanel,
                .hudWindow,
                .resizable,
                .utilityWindow,
            ],
            backing: .buffered,
            defer: false
        )
        delegate = self
        isReleasedWhenClosed = false
        title = "Touch Bar"
        level = .assistiveTechHigh
        backgroundColor = .clear
        isOpaque = false
        //TODO: if implementing _setPreventsActivation(true)
        isRestorable = true
        hidesOnDeactivate = false
        worksWhenModal = true
        acceptsMouseMovedEvents = true
        isMovableByWindowBackground = false
        //contentAspectRatio = NSMakeSize(1014, 40)
        contentView = TouchBarViewFactory.generate()//TouchBarView.buildView(standalone: true)
        addToolBar()
    }
    
    private static let instance = TouchBarWindow()
    
    public static var isClosed: Bool {
        return instance.isClosed
    }
    
    public static func setUp() {
        // setup frame
        let frameDiscriptor = UserDefaults.standard.object(forKey: "savedWindowFrame")
        let previousDocking = Defaults[.windowDocking]
        if let discriptor = frameDiscriptor {
            instance.setFrame(from: discriptor as! NSWindow.PersistableFrameDescriptor)
        }
        
        if previousDocking == .dockedToTop || previousDocking == .dockedToBottom {
            instance.setFrame(instance.destinationFrame(previousDocking, false), display: true)
        }

        instance.docking = previousDocking
        
        // setup observerTimer
        RunLoop.main.add(Timer(timeInterval: 0.3, repeats: true) { timer in
            instance.handleAutoHide()
        }, forMode: .default)
        instance.orderFrontRegardless()
    }
    
    public static func finishUp() {
        if instance.docking == .floating {
            Defaults[.lastFloatingPosition] = instance.frame.origin
            UserDefaults.standard.setValue(instance.frameDescriptor, forKey: "savedWindowFrame")
            UserDefaults.standard.synchronize()
        }
        
        let remoteViewController = instance.contentViewController as? NSRemoteViewController
        remoteViewController?.disconnect()
    }
    
    public static var showOnAllDesktops = true {
        didSet {
            if showOnAllDesktops {
                instance.collectionBehavior = .canJoinAllSpaces
            } else {
                instance.collectionBehavior = .moveToActiveSpace
            }
        }
    }
    
    public static var dockSetting: Docking = .floating {
        didSet {
            instance.docking = dockSetting
        }
    }
    
}
