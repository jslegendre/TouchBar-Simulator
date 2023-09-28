//
//  TouchBarView.swift
//  TouchBarSimulator
//
//  Created by 上原葉 on 9/26/23.
//

import Foundation

class TouchBarViewFactory {
    
    class TouchBarView: NSView {
        public var dockSideButtonDelegate: ((_: NSButton) -> Void)?
        
        @objc public func sideButtonPressed(_ button: NSButton) {
            dockSideButtonDelegate?(button)
        }
    }
    
    private static let contentView: NSView = {
        let contentView = NSView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        let blurView = NSVisualEffectView()
        blurView.autoresizingMask = [.height, .width]
        blurView.translatesAutoresizingMaskIntoConstraints = true
        blurView.blendingMode = .behindWindow
        blurView.material = .fullScreenUI
        blurView.state = .active
        contentView.addSubview(blurView)
        
        let remoteView = NSRemoteView(frame: CGRectMake(0, 0, 1004, 30)) // 1004, 30
        remoteView.setSynchronizesImplicitAnimations(false)
        remoteView.serviceName = Globals.serviceBundleId
        remoteView.serviceSubclassName = Globals.serviceSubClassName
        remoteView.translatesAutoresizingMaskIntoConstraints = false
        remoteView.setShouldMaskToBounds(false)
        remoteView.layer?.allowsEdgeAntialiasing = true
        
        remoteView.advance(toRunPhaseIfNeeded: {(error) in
            contentView.addSubview(remoteView)
            
            let constraintsArray =
            [[NSLayoutConstraint(item: remoteView, attribute: .width, relatedBy: .equal, toItem: remoteView, attribute: .height, multiplier: 1004.0/30.0, constant: 0.0)],
             NSLayoutConstraint.constraints(withVisualFormat: "H:|-5-[remoteView]-5-|", metrics: nil, views: ["remoteView": remoteView]),
             NSLayoutConstraint.constraints(withVisualFormat: "V:|-5-[remoteView]-5-|", metrics: nil, views: ["remoteView": remoteView])]
                .reduce([], +)
            
            contentView.addConstraints(constraintsArray)
            NSLayoutConstraint.activate(constraintsArray)
            contentView.layoutSubtreeIfNeeded()
            
            return
        })
        
        return contentView
    }()
    
    private static let trimView: NSView = {
        let trimView = NSView()
        trimView.wantsLayer = true
        trimView.layerUsesCoreImageFilters = true
        //trimView.layer?.backgroundColor = NSColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0).cgColor
        trimView.layer?.cornerRadius = 10
        
        return trimView
    }()
    
    private static let sideBarViewTuple: (NSView, (TouchBarView) -> Void) = {
        let sideBarView = NSView()
        sideBarView.translatesAutoresizingMaskIntoConstraints = false
        
        let blurView = NSVisualEffectView()
        blurView.autoresizingMask = [.height, .width]
        blurView.translatesAutoresizingMaskIntoConstraints = true
        blurView.blendingMode = .behindWindow
        blurView.material = .headerView
        blurView.state = .active
        sideBarView.addSubview(blurView)
        
        let escapeImage = {
            if #available(macOS 11, *) {
                return NSImage(systemSymbolName: "escape", accessibilityDescription: "Undock touch bar simulator.".localized) // Alternative: "rhombus.fill" "chevron.compact.left"
            }
            else {
                let image = NSImage(named: "Escape")
                image?.accessibilityDescription = "Undock touch bar simulator.".localized
                return image
            }
        }()
        
        let closeImage = {
            if #available(macOS 11, *) {
                return NSImage(systemSymbolName: "xmark.square.fill", accessibilityDescription: "Close touch bar simulator.".localized) // Alternative: "rhombus.fill" "chevron.compact.left"
            }
            else {
                let image = NSImage(named: "Xmark")
                image?.accessibilityDescription = "Close touch bar simulator.".localized
                return image
            }
        }()
        
        let settingsImage = {
            if #available(macOS 11, *) {
                return NSImage(systemSymbolName: "gear", accessibilityDescription: "Touch bar simulator settings.".localized) // Alternative: "rhombus.fill" "chevron.compact.left"
            }
            else {
                let image = NSImage(named: "Settings")
                image?.accessibilityDescription = "Touch bar simulator settings.".localized
                return image
            }
        }()
        
        let sideButton = NSButton()
        sideButton.image = escapeImage
        sideButton.imageScaling = .scaleProportionallyDown
        sideButton.isBordered = false
        sideButton.bezelStyle = .shadowlessSquare
        sideButton.frame = CGRect(x: 0, y: 0, width: 16, height: 11)
        sideButton.autoresizingMask = [.minXMargin, .minYMargin, .maxYMargin]
        sideButton.translatesAutoresizingMaskIntoConstraints = false
        sideButton.action = #selector(TouchBarView.sideButtonPressed)
        sideBarView.addSubview(sideButton)
        
        let keyListenHandler: (NSEvent) -> Void = {
            event in
            let isOptionKeyPressed = event.modifierFlags.contains(NSEvent.ModifierFlags.option)
            let isCommandKeyPressed = event.modifierFlags.contains(NSEvent.ModifierFlags.command)
            
            switch (isCommandKeyPressed, isOptionKeyPressed) {
            case (true, _):
                sideButton.image = settingsImage
            case (false, true):
                sideButton.image = closeImage
            case (false, false):
                sideButton.image = escapeImage
            }
            return
        }
        
        NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) {event in keyListenHandler(event)}
        NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) {event in keyListenHandler(event); return event}
        
        let targetRegistration = {(target: TouchBarView) -> Void in sideButton.target = target} // target is a weak reference
        
        let constraintsArray =
        [NSLayoutConstraint.constraints(withVisualFormat: "H:[buttonRelease(16)]", metrics: nil, views: ["buttonRelease": sideButton]),
         NSLayoutConstraint.constraints(withVisualFormat: "H:|-3-[buttonRelease]-3-|", metrics: nil, views: ["buttonRelease": sideButton]),
         NSLayoutConstraint.constraints(withVisualFormat: "V:|-5-[buttonRelease]-5-|", metrics: nil, views: ["buttonRelease": sideButton])]
            .reduce([], +)
        
        sideBarView.addConstraints(constraintsArray)
        NSLayoutConstraint.activate(constraintsArray)
        sideBarView.layoutSubtreeIfNeeded()
        
        return (sideBarView, targetRegistration)
    }()
    
    public static func generate(standalone: Bool = false, dockReleaseDelegate delegateFunc: @escaping (_: NSButton) -> Void = {(_) in return}) -> TouchBarView {
        
        let touchBarView = TouchBarView()
        touchBarView.autoresizingMask = [.height, .width]
        touchBarView.wantsLayer = true
        touchBarView.layerUsesCoreImageFilters = true
        touchBarView.dockSideButtonDelegate = delegateFunc
        //touchBarView.layer?.backgroundColor = NSColor(red: 1.0, green: 0.1, blue: 0.1, alpha: 1.0).cgColor
        
        if standalone {
            let (sideBarView, updateTarget) = sideBarViewTuple
            // update target for sidebar
            updateTarget(touchBarView)
            
            touchBarView.addSubview(sideBarView)
            touchBarView.addSubview(contentView)
            let constraintsArray =
            [NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[sideBarView]-0-[contentView]-0-|", metrics: nil, views: ["sideBarView": sideBarView, "contentView": contentView]),
             NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[sideBarView]-0-|", metrics: nil, views: ["sideBarView": sideBarView]),
             NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[contentView]-0-|", metrics: nil, views: ["contentView": contentView])]
                .reduce([], +)
            
            touchBarView.addConstraints(constraintsArray)
            NSLayoutConstraint.activate(constraintsArray)
            touchBarView.layoutSubtreeIfNeeded()
            
            touchBarView.layer?.cornerRadius = 10
        }
        else {
            touchBarView.addSubview(contentView)
            let constraintsArray =
            [NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[contentView]-0-|", metrics: nil, views: ["contentView": contentView]),
             NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[contentView]-0-|", metrics: nil, views: ["contentView": contentView])]
                .reduce([], +)
            
            touchBarView.addConstraints(constraintsArray)
            NSLayoutConstraint.activate(constraintsArray)
            touchBarView.layoutSubtreeIfNeeded()
        }
        
        return touchBarView
    }
    
}
