//
//  TouchBarWindow.swift
//  TouchBar Simulator
//
//  Created by 上原葉 on 8/13/23.
//

import AppKit

class TouchBarWindow: NSPanel {
    enum Docking: String, Codable {
        case floating
        case dockedToTop
        case dockedToBottom
    }
    
    override var canBecomeMain: Bool { false }
    override var canBecomeKey: Bool { false }

    private func addTitlebar() {
        styleMask.insert(.titled)
        title = "Touch Bar"
    }
    
    private func removeTitlebar() {
        styleMask.remove(.titled)
    }
    
    var showOnAllDesktops = false {
        didSet {
            if showOnAllDesktops {
                collectionBehavior = .canJoinAllSpaces
            } else {
                collectionBehavior = .moveToActiveSpace
            }
        }
    }
    
    var docking: Docking = .dockedToBottom {
        didSet {
            switch (oldValue, docking) {
            case (_, _) where oldValue == docking:
                break;
            case (.floating, .dockedToTop):
                break;
            case (.floating, .dockedToBottom):
                break;
            case (.dockedToTop, _):
                break;
            case (.dockedToBottom, _):
                break;
            case (_, .floating):
                break;
            }
        }
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
        level = .assistiveTechHigh
        //TODO: if implementing _setPreventsActivation(true)
        isRestorable = true
        hidesOnDeactivate = false
        worksWhenModal = true
        acceptsMouseMovedEvents = true
        isMovableByWindowBackground = false
        contentAspectRatio = NSMakeSize(1014, 40)
        contentView = TouchBarView()
    }
    
    private var animationTimer = Timer()
    
    private static let instance = TouchBarWindow()
    public static func setUp() {
        let frameDiscriptor = UserDefaults.standard.object(forKey: "savedWindowFrame")
        if let discriptor = frameDiscriptor {
            instance.setFrame(from: discriptor as! NSWindow.PersistableFrameDescriptor)
        }
        
        let contentView = instance.contentView!
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor.clear.cgColor
        
        let remoteView = NSRemoteView(frame: CGRectMake(0, 0, 1004, 30))
        remoteView.setSynchronizesImplicitAnimations(false)
        remoteView.serviceName = "moe.ueharayou.TouchBarSimulatorService"
        remoteView.serviceSubclassName = "TouchBarSimulatorService"
        remoteView.advance(toRunPhaseIfNeeded: {(error) in
            DispatchQueue.main.async {
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
            }
            return
        })
        
        instance.orderFrontRegardless()
    }
    
    public static func finishUp() {
        UserDefaults.standard.setValue(instance.frameDescriptor, forKey: "savedWindowFrame")
        UserDefaults.standard.synchronize()
        let remoteViewController = instance.contentViewController as? NSRemoteViewController
        remoteViewController?.disconnect()
    }
    
}

class TouchBarView: NSView {
    override func draw(_ dirtyRect: NSRect) {
        //NSBezierPath(roundedRect: dirtyRect, xRadius: 0.7, yRadius: 0.7).addClip()
        //dirtyRect.fill(using: .clear);
        super.draw(dirtyRect)
    }
    static func buildView() -> TouchBarView {
        let contentView = TouchBarView()
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
