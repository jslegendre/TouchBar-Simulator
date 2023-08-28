//
//  TouchBarWindow.swift
//  TouchBar Simulator
//
//  Created by 上原葉 on 8/13/23.
//

import AppKit
import Defaults

final class TouchBarWindow: NSPanel {
    enum Docking: String, Codable {
        case floating
        case dockedToTop
        case dockedToBottom
    }
    private var docking: Docking = .floating {
        didSet {
            switch (oldValue, docking) {
            case (_, .floating):
                detectionTimeout = Date.distantFuture
                hiding = false
                addTitle()
                moveWithAnimation(destination: destinationFrame(docking, hiding))
                fadeWithAnimation(destination: 1.0)
            case (_, .dockedToTop), (_, .dockedToBottom):
                removeTitle()
                moveWithAnimation(destination: destinationFrame(docking, hiding))
                detectionTimeout = Date() + TimeInterval(1.5)
            }
        }
    }
    
    private var hiding: Bool = false {
        didSet {
            switch (docking, hiding) {
            case (.floating, _):
                break
            case (_, true):
                moveWithAnimation(destination: destinationFrame(docking, hiding))
                fadeWithAnimation(destination: 0.0)
            case (_, false):
                moveWithAnimation(destination: destinationFrame(docking, hiding))
                fadeWithAnimation(destination: 1.0)
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
            buttonUp.image = NSImage(systemSymbolName: "menubar.arrow.up.rectangle", accessibilityDescription: "Dock Top.")
        }
        else {
            buttonUp.image = NSImage(named: "DockTop")
        }
        buttonUp.imageScaling = .scaleProportionallyDown
        buttonUp.isBordered = false
        buttonUp.bezelStyle = .shadowlessSquare
        buttonUp.frame = CGRect(x: toolbarView.frame.width - 38, y: 4, width: 16, height: 11)
        buttonUp.action = #selector(TouchBarWindow.dockUpPressed)
        toolbarView.addSubview(buttonUp)
        
        let buttonDown = NSButton()
        if #available(macOS 11, *) {
            buttonDown.image = NSImage(systemSymbolName: "dock.arrow.down.rectangle", accessibilityDescription: "Dock down.")
        }
        else {
            buttonDown.image = NSImage(named: "DockDown")
        }
        buttonDown.imageScaling = .scaleProportionallyDown
        buttonDown.isBordered = false
        buttonDown.bezelStyle = .shadowlessSquare
        buttonDown.frame = CGRect(x: toolbarView.frame.width - 19, y: 4, width: 16, height: 11)
        buttonDown.action = #selector(TouchBarWindow.dockDownPressed)
        toolbarView.addSubview(buttonDown)
    }
    
    @objc func dockDownPressed(_: NSButton) {
        docking = .dockedToBottom
    }
    
    @objc func dockUpPressed(_: NSButton) {
        docking = .dockedToTop
    }
    
    private func addTitle() {
        if !styleMask.contains(.titled) {
            styleMask.insert(.titled)
            addToolBar()
        }
    }
    private func removeTitle() {
        if styleMask.contains(.titled) {
            styleMask.remove(.titled)
        }
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
        switch docking {
        case .floating:
            break
        case .dockedToTop, .dockedToBottom:
            if isMouseDetected {
                detectionTimeout = Date() + TimeInterval(1.5)
                hiding = false
            }
            else if Date() >= detectionTimeout {
                hiding = true
            }
        }
    }
    
    private func destinationOrigin(_ forDocking: Docking, _ forHiding: Bool) -> CGPoint {
        switch(forDocking, forHiding) {
        case (.floating, _):
            return Defaults[.lastFloatingPosition] ?? alignedOrigin(.center, .center)
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
        //TouchBarWindowAnimation.moveWithAnimation(endFrame)
        windowMoveAnimation.animate = {(startFrame, endFrame) in { [unowned self] (currentValue: Float) in
            if currentValue == 1.0 {
                self.setFrame(endFrame, display: true)
            }
            else {
                // Calc frame
                // Step 0: Get parameter `t`
                let t = CGFloat(currentValue)
                
                // Step 1: Scaling transform
                let dWidth = endFrame.size.width / startFrame.size.width - 1
                let dHeight = endFrame.size.width / startFrame.size.width - 1
                
                let scalingTransform = CGAffineTransform.identity
                    .scaledBy(x: dWidth * t + 1, y: dHeight * t + 1)
                
                let scaledFrame = startFrame.applying(scalingTransform)
                
                // Step 2: Translating transform
                let dx = endFrame.midX - scaledFrame.midX
                let dy = endFrame.midY - scaledFrame.midY
                
                let translatingTransform = CGAffineTransform.identity
                    .translatedBy(x: dx * t, y: dy * t)
                
                let translatedScaledFrame = scaledFrame.applying(translatingTransform)
                
                // Step 3: Apply transform
                self.setFrame(translatedScaledFrame, display: true)
                /*
                NSLog("-> \(translatedScaledFrame)")
                if currentValue == 1.0 && endFrame != translatedScaledFrame {
                    self.setFrame(endFrame, display: true)
                    NSLog("-X> \(endFrame)")
                }
                else if currentValue == 1.0 && endFrame == translatedScaledFrame {
                    NSLog("OK")
                }
                 */
            }
        }}(frame, endFrame)
       
        windowMoveAnimation.start()
    }
    private func fadeWithAnimation(destination endValue: CGFloat) {
        //TouchBarWindowAnimation.moveWithAnimation(endFrame)
        windowFadeAnimation.animate = {(startValue, endValue) in { [unowned self] (currentValue: Float) in
            if currentValue == 1.0 {
                self.alphaValue = endValue
            }
            else {
                // Calc frame
                // Step 0: Get parameter `t`
                let t = CGFloat(currentValue)
                
                // Step 1: Scaling transform
                let dAlphaValue = endValue - startValue
                
                let scaledValue = startValue + dAlphaValue * t
                
                // Step 2: Apply transform
                self.alphaValue = scaledValue
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
                .utilityWindow
            ],
            backing: .buffered,
            defer: false
        )
        title = "Touch Bar"
        level = .assistiveTechHigh
        //TODO: if implementing _setPreventsActivation(true)
        isRestorable = true
        hidesOnDeactivate = false
        worksWhenModal = true
        acceptsMouseMovedEvents = true
        isMovableByWindowBackground = false
        contentAspectRatio = NSMakeSize(1014, 40)
        contentView = TouchBarView.buildView()
    }
    
    private static let instance = TouchBarWindow()
    
    public static func setUp() {
        // setup frame
        let frameDiscriptor = UserDefaults.standard.object(forKey: "savedWindowFrame")
        if let discriptor = frameDiscriptor {
            instance.setFrame(from: discriptor as! NSWindow.PersistableFrameDescriptor)
        }
        
        instance.addToolBar()

        // setup observerTimer
        RunLoop.main.add(Timer(timeInterval: 0.3, repeats: true) { timer in
            instance.handleAutoHide()
        }, forMode: .default)
        instance.orderFrontRegardless()
    }
    
    public static func finishUp() {
        UserDefaults.standard.setValue(instance.frameDescriptor, forKey: "savedWindowFrame")
        UserDefaults.standard.synchronize()
        let remoteViewController = instance.contentViewController as? NSRemoteViewController
        remoteViewController?.disconnect()
    }
    
    public static var showOnAllDesktops = false {
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

class TouchBarToolBarView: NSView {
    
}

class TouchBarView: NSView {
    
    override func draw(_ dirtyRect: NSRect) {
        //NSBezierPath(roundedRect: dirtyRect, xRadius: 0.7, yRadius: 0.7).addClip()
        //dirtyRect.fill(using: .clear);
        super.draw(dirtyRect)
    }
    
    static func buildView() -> TouchBarView {
        let contentView = TouchBarView()
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor.clear.cgColor
        
        let remoteView = NSRemoteView(frame: CGRectMake(0, 0, 1004, 30)) // 1004, 30
        remoteView.setSynchronizesImplicitAnimations(false)
        remoteView.serviceName = "moe.ueharayou.TouchBarSimulatorService"
        remoteView.serviceSubclassName = "TouchBarSimulatorService"
        remoteView.advance(toRunPhaseIfNeeded: {(error) in
            //DispatchQueue.main.async {
                remoteView.translatesAutoresizingMaskIntoConstraints = false
                remoteView.setShouldMaskToBounds(false)
                remoteView.layer?.allowsEdgeAntialiasing = true
                
                contentView.addSubview(remoteView)
                
                let constraintsArray = [NSLayoutConstraint.constraints(withVisualFormat: "H:|-5-[remoteView]-5-|", metrics: nil, views: ["remoteView": remoteView]),
                                        NSLayoutConstraint.constraints(withVisualFormat: "V:|-5-[remoteView]-5-|", metrics: nil, views: ["remoteView": remoteView])]
                    .reduce([], +)
                contentView.addConstraints(constraintsArray)
                NSLayoutConstraint.activate(constraintsArray)
                contentView.layoutSubtreeIfNeeded()
            //}
            
            return
        })
        
        return contentView
    }
}

/*
 func reposition(window: NSWindow, padding: Double) { // padding: decided by animation
 switch self {
 case .floating:
 if let prevPosition = Defaults[.lastFloatingPosition] {
 window.setFrameOrigin(prevPosition)
 }
 case .dockedToTop:
 window.moveTo(x: .center, y: .top)
 window.setFrameOrigin(CGPoint(x: window.frame.origin.x, y: window.frame.origin.y - padding))
 case .dockedToBottom:
 window.moveTo(x: .center, y: .bottom)
 window.setFrameOrigin(CGPoint(x: window.frame.origin.x, y: window.frame.origin.y + padding))
 }
 }
 */

/*
final class TouchBarWindowAnimation: NSAnimation { // Outruled: NSAnimationDelegate
    override var currentProgress: NSAnimation.Progress {
        didSet {
            super.currentProgress = currentProgress
            
            if isAnimating {
                // shortcutting currentProgress == 1: end of animation
                if currentProgress == 1.0 {
                    TouchBarWindow.instance.setFrame(endFrame, display: true)
                }
                else {
                    // Calc frame
                    // Step 0: Get parameter `t`
                    let t = CGFloat(currentValue)
                    
                    // Step 1: Scaling transform
                    let dWidth = endFrame.size.width / startFrame.size.width - 1
                    let dHeight = endFrame.size.width / startFrame.size.width - 1

                    let scalingTransform = CGAffineTransform.identity
                        .scaledBy(x: dWidth * t + 1, y: dHeight * t + 1)
                        
                    let scaledFrame = startFrame.applying(scalingTransform)
                    
                    // Step 2: Translating transform
                    let dx = endFrame.midX - scaledFrame.midX
                    let dy = endFrame.midY - scaledFrame.midY
                    
                    let translatingTransform = CGAffineTransform.identity
                        .translatedBy(x: dx * t, y: dy * t)
                    
                    let translatedScaledFrame = scaledFrame.applying(translatingTransform)
                    
                    // Step 3: Apply transform
                    TouchBarWindow.instance.setFrame(translatedScaledFrame, display: true)
                }
            }
        }
    }

    private var startFrame = CGRect.zero
    
    public var endFrame = CGRect.zero {
        didSet {
            // immediately stop (cancel) current animation & reset
            if isAnimating {
                stop()
                currentProgress = 0.0
            }
            startFrame = TouchBarWindow.instance.frame
            start()
        }
    }
    
    private override init(duration: TimeInterval, animationCurve: NSAnimation.Curve) {
        super.init(duration: duration, animationCurve: animationCurve)
    }
    
    internal required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private static let instance = TouchBarWindowAnimation(duration: 0.5, animationCurve: .easeInOut)
    
    public static var duration: TimeInterval {
        get {
            return instance.duration
        }
        set {
            instance.duration = newValue
        }
    }
    
    public static var animationCurve: NSAnimation.Curve {
        get {
            return instance.animationCurve
        }
        set {
            instance.animationCurve = newValue
        }
    }
    
    public static func moveWithAnimation(_ dest: CGRect) {
        instance.endFrame = dest
    }
}
*/

/*
 // test
 RunLoop.main.add(Timer(timeInterval: 1.0, repeats: true) { timer in
     let rand = CGFloat(Float.random(in: 0.0...1.0))
     //let rand2 = CGFloat(Float.random(in: 0.8...1.25))
     let rand2 = 1.0
     let visibleFrame = NSScreen.main?.visibleFrame ?? CGRect.zero
     let newOrigin = CGPoint(x: visibleFrame.width * rand, y: visibleFrame.height * rand)
     let newFrame = CGRect(origin: newOrigin, size: instance.frame.size.applying(CGAffineTransform(scaleX: rand2, y: rand2)))
     instance.moveWithAnimation(destination: newFrame)
 }, forMode: .default)
 RunLoop.main.add(Timer(timeInterval: 1.0, repeats: true) { timer in
     let rand = CGFloat(Float.random(in: 0.0...1.0))
     instance.fadeWithAnimation(destination: rand)
 }, forMode: .default)
 Timer(timeInterval: 1, repeats: true) { [unowned self] timer in
     let rand = CGFloat(Int.random(in: 0...3))
     switch rand {
     case 0...1:
         //self.addTitle()
         self.docking = .floating
     case 2:
         //self.removeTitle()
         self.docking = .dockedToTop
     case 3:
         //self.removeTitlebar()
         self.docking = .dockedToBottom
     default:
         break
     }
 }.fire()
 */
