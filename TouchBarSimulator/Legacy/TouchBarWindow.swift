//
//  TouchBarWindow.swift
//  TouchBar Simulator
//
//  Created by 上原葉 on 8/12/23.
//

import Cocoa
import Combine
import Defaults

enum Constants {
    static let windowAutosaveName = "TouchBarWindow"
}

extension Defaults.Keys {
    static let windowTransparency = Key<Double>("windowTransparency", default: 0.75)
    static let windowDocking = Key<TouchBarWindow.Docking>("windowDocking", default: .floating)
    static let windowPadding = Key<Double>("windowPadding", default: 0.0)
    static let showOnAllDesktops = Key<Bool>("showOnAllDesktops", default: false)
    static let lastFloatingPosition = Key<CGPoint?>("lastFloatingPosition")
    static let dockBehavior = Key<Bool>("dockBehavior", default: false)
    static let lastWindowDockingWithDockBehavior = Key<TouchBarWindow.Docking>("windowDockingWithDockBehavior", default: .dockedToTop)
}

extension TouchBarWindow.Docking: Defaults.Serializable {}
extension CGPoint: Defaults.Serializable {}


final class TouchBarWindow: NSPanel {
    // TODO: Migrate this to not use `Codable`.
    enum Docking: String, Codable {
        case floating
        case dockedToTop
        case dockedToBottom

        func dock(window: TouchBarWindow, padding: Double) {
            switch self {
            case .floating:
                window.addTitlebar()
            case .dockedToTop:
                window.removeTitlebar()
            case .dockedToBottom:
                window.removeTitlebar()
            }

            reposition(window: window, padding: padding)
        }

        func reposition(window: NSWindow, padding: Double) {
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
    }

    override var canBecomeMain: Bool { false }
    override var canBecomeKey: Bool { false }

    var docking: Docking = .floating {
        didSet {
            if oldValue == .floating, docking != .floating {
                Defaults[.lastFloatingPosition] = frame.origin
            }

            if docking == .floating {
                dockBehavior = false
            }

            // Prevent the Touch Bar from momentarily becoming visible.
            if docking == .floating || !dockBehavior {
                stopDockBehaviorTimer()
                docking.dock(window: self, padding: Defaults[.windowPadding])
                setIsVisible(true)
                orderFront(nil)
                return
            }

            // When docking is set to `dockedToTop` or `dockedToBottom` dockBehavior should start.
            if dockBehavior {
                setIsVisible(false)
                docking.dock(window: self, padding: Defaults[.windowPadding])
                startDockBehaviorTimer()
            }
        }
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

    var dockBehaviorTimer = Timer()
    var showTouchBarTimer = Timer()

    func startDockBehaviorTimer() {
        stopDockBehaviorTimer()

        dockBehaviorTimer = Timer.scheduledTimer(
            timeInterval: 0.1,
            target: self,
            selector: #selector(handleDockBehavior),
            userInfo: nil,
            repeats: true
        )
    }

    func stopDockBehaviorTimer() {
        dockBehaviorTimer.invalidate()
        dockBehaviorTimer = Timer()
    }

    var dockBehavior: Bool = Defaults[.dockBehavior] {
        didSet {
            Defaults[.dockBehavior] = dockBehavior
            if docking == .dockedToBottom || docking == .dockedToTop {
                Defaults[.lastWindowDockingWithDockBehavior] = docking
            }

            if dockBehavior {
                if docking == .dockedToBottom || docking == .dockedToTop {
                    docking = Defaults[.lastWindowDockingWithDockBehavior]
                    startDockBehaviorTimer()
                } else if docking == .floating {
                    Defaults[.windowDocking] = Defaults[.lastWindowDockingWithDockBehavior]
                }
            } else {
                stopDockBehaviorTimer()
                setIsVisible(true)
            }
        }
    }

    @objc
    func handleDockBehavior() {
        guard
            let visibleFrame = NSScreen.main?.visibleFrame,
            let screenFrame = NSScreen.main?.frame
        else {
            return
        }

        var detectionRect = CGRect.zero
        if docking == .dockedToBottom {
            if isVisible {
                detectionRect = CGRect(
                    x: 0,
                    y: 0,
                    width: visibleFrame.width,
                    height: frame.height + (screenFrame.height - visibleFrame.height - NSStatusBar.system.thickness + Defaults[.windowPadding])
                )
            } else {
                detectionRect = CGRect(x: 0, y: 0, width: visibleFrame.width, height: 1)
            }
        } else if docking == .dockedToTop {
            if isVisible {
                detectionRect = CGRect(
                    x: 0,
                    // Without `+ 1`, the Touch Bar would glitch (toggling rapidly).
                    y: screenFrame.height - frame.height - NSStatusBar.system.thickness - Defaults[.windowPadding] + 1.0,
                    width: visibleFrame.width,
                    height: frame.height + NSStatusBar.system.thickness + Defaults[.windowPadding]
                )
            } else {
                detectionRect = CGRect(
                    x: 0,
                    y: screenFrame.height,
                    width: visibleFrame.width,
                    height: 1
                )
            }
        }

        let mouseLocation = NSEvent.mouseLocation
        if detectionRect.contains(mouseLocation) {
            dismissAnimationDidRun = false

            guard
                !showTouchBarTimer.isValid,
                !showAnimationDidRun
            else {
                return
            }

            showTouchBarTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
                guard let self = self else {
                    return
                }

                self.performActionWithAnimation(action: .show)
                self.showAnimationDidRun = true
            }
        } else {
            showTouchBarTimer.invalidate()
            showTouchBarTimer = Timer()
            showAnimationDidRun = false

            if isVisible, !dismissAnimationDidRun {
                performActionWithAnimation(action: .dismiss)
                dismissAnimationDidRun = true
            }
        }
    }

    var showAnimationDidRun = false
    var dismissAnimationDidRun = false

    func performActionWithAnimation(action: TouchBarAction) {
        guard
            docking == .dockedToTop ||
            docking == .dockedToBottom
        else {
            return
        }

        var endY: Double!

        if action == .show {
            docking.reposition(window: self, padding: -frame.height)
            setIsVisible(true)

            if docking == .dockedToTop {
                endY = frame.minY - frame.height - Defaults[.windowPadding]
            } else if docking == .dockedToBottom {
                endY = frame.minY + frame.height + Defaults[.windowPadding]
            }
        } else if action == .dismiss {
            if docking == .dockedToTop {
                endY = frame.minY + frame.height + NSStatusBar.system.thickness + Defaults[.windowPadding]
            } else if docking == .dockedToBottom {
                endY = 0 - frame.height
            }
        }

        var endFrame = frame
        endFrame.origin.y = endY

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = TimeInterval(0.3)
            animator().setFrame(endFrame, display: false, animate: true)
        }, completionHandler: { [self] in
            if action == .show {
                docking.reposition(window: self, padding: Defaults[.windowPadding])
            } else if action == .dismiss {
                setIsVisible(false)
                docking.reposition(window: self, padding: 0)
            }
        })
    }

    enum TouchBarAction {
        case show
        case dismiss
    }

    func addTitlebar() {
        styleMask.insert(.titled)
        title = "Touch Bar Simulator"
/*
        guard let toolbarView = toolbarView else {
            return
        }

        toolbarView.addSubviews(
            makeScreenshotButton(toolbarView),
            makeTransparencySlider(toolbarView)
        )
 */
    }

    func removeTitlebar() {
        styleMask.remove(.titled)
    }
/*
    func makeScreenshotButton(_ toolbarView: NSView) -> NSButton {
        let button = NSButton()
        button.image = NSImage(systemSymbolName: "camera.fill", accessibilityDescription: "Capture screenshot of the Touch Bar")
        button.imageScaling = .scaleProportionallyDown
        button.isBordered = false
        button.bezelStyle = .shadowlessSquare
        button.frame = CGRect(x: toolbarView.frame.width - 19, y: 4, width: 16, height: 11)
        button.action = #selector(AppDelegate.captureScreenshot)
        return button
    }

    private var transparencySlider: ToolbarSlider?

    func makeTransparencySlider(_ parentView: NSView) -> ToolbarSlider {
        let slider = ToolbarSlider().alwaysRedisplayOnValueChanged().bindDoubleValue(to: .windowTransparency)
        slider.frame = CGRect(x: parentView.frame.width - 160, y: 1, width: 140, height: 11)
        slider.minValue = 0.5
        return slider
    }
*/
    private var cancellable: AnyCancellable?

    func setUp() {
        let view = contentView!
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.black.cgColor
        
        let remoteView = NSRemoteView(frame: CGRectMake(0, 0, 1004, 30))
        remoteView.setSynchronizesImplicitAnimations(false)
        remoteView.serviceName = "moe.ueharayou.TouchBarSimulatorService"
        remoteView.serviceSubclassName = "TouchBarSimulatorService"
        remoteView.advance(toRunPhaseIfNeeded: {(error) in
            DispatchQueue.main.async {
                remoteView.translatesAutoresizingMaskIntoConstraints = false
                remoteView.setShouldMaskToBounds(false)
                remoteView.layer?.allowsEdgeAntialiasing = true
                
                view.addSubview(remoteView)
                
                let constraintsArray = [NSLayoutConstraint.constraints(withVisualFormat: "H:|-5-[remoteView]-5-|", metrics: nil, views: ["remoteView": remoteView]),
                                        NSLayoutConstraint.constraints(withVisualFormat: "V:|-5-[remoteView]-5-|", metrics: nil, views: ["remoteView": remoteView])]
                    .reduce([], +)
                view.addConstraints(constraintsArray)
                NSLayoutConstraint.activate(constraintsArray)
                view.layoutSubtreeIfNeeded()
            }
            return
        })
        
        //NSRemoteView *remoteView = [[NSRemoteView alloc] initWithFrame: CGRectMake(0, 0, 1004, 30)];
        //[remoteView setSynchronizesImplicitAnimations:NO];
        //[remoteView setServiceName:@"moe.ueharayou.TouchBarSimulatorService"];
        //[remoteView setServiceSubclassName:@"TouchBarSimulatorService"];
        /*
        [remoteView advanceToRunPhaseIfNeeded:^(NSError *err){
            dispatch_async(dispatch_get_main_queue(), ^(){
                NSView *contentView = self.window.contentView;
                [contentView addSubview:remoteView];

                [remoteView setTranslatesAutoresizingMaskIntoConstraints:NO];
                [remoteView setShouldMaskToBounds:NO];
                [[remoteView layer] setAllowsEdgeAntialiasing:YES];

                NSDictionary *dict = NSDictionaryOfVariableBindings(remoteView);
                NSArray *constraintsArray = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-5-[remoteView]-5-|"
                                                                                    options:0
                                                                                    metrics:nil
                                                                                      views:dict];

                constraintsArray = [constraintsArray arrayByAddingObjectsFromArray:
                                    [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-5-[remoteView]-5-|"
                                                                           options:0
                                                                           metrics:nil
                                                                             views:dict]];
                [contentView addConstraints:constraintsArray];
                [NSLayoutConstraint activateConstraints:constraintsArray];

                [contentView layoutSubtreeIfNeeded];
                
            });
        }];
        */
        
/*
        let touchBarView = TouchBarView()
        setContentSize(touchBarView.bounds.adding(padding: 5).size)
        touchBarView.frame = touchBarView.frame.centered(in: view.bounds)
        view.addSubview(touchBarView)
*/
        Defaults.tiedToLifetime(of: self) {
            Defaults.observe(.windowTransparency) { [weak self] change in
                self?.alphaValue = change.newValue
            }
            Defaults.observe(.windowDocking) { [weak self] change in
                self?.docking = change.newValue
            }
            Defaults.observe(.windowPadding) { [weak self] change in
                guard let self = self else {
                    return
                }

                self.docking.reposition(window: self, padding: change.newValue)
            }
            // TODO: We could maybe simplify this by creating another `Default` extension to bind a default to a KeyPath:
            // `defaults.bind(.showOnAllDesktops, to: \.showOnAllDesktops)`
            Defaults.observe(.showOnAllDesktops) { [weak self] change in
                self?.showOnAllDesktops = change.newValue
            }
            Defaults.observe(.dockBehavior) { [weak self] change in
                self?.dockBehavior = change.newValue
            }
        }

        center()
        setFrameOrigin(CGPoint(x: frame.origin.x, y: 100))

        setFrameUsingName(Constants.windowAutosaveName)
        setFrameAutosaveName(Constants.windowAutosaveName)

        // Prevent the Touch Bar from momentarily becoming visible.
        if !dockBehavior {
            orderFront(nil)
        }

        cancellable = NSScreen.publisher.sink { [weak self] in
            guard let self = self else {
                return
            }

            self.docking.reposition(window: self, padding: Defaults[.windowPadding])
        }
    }

    convenience init() {
        self.init(
            contentRect: .zero,
            styleMask: [
                .titled,
                .closable,
                .nonactivatingPanel,
                .hudWindow,
                .utilityWindow
            ],
            backing: .buffered,
            defer: false
        )

        self.level = .assistiveTechHigh
        _setPreventsActivation(true)
        self.isRestorable = true
        self.hidesOnDeactivate = false
        self.worksWhenModal = true
        self.acceptsMouseMovedEvents = true
        self.isMovableByWindowBackground = false
    }
}

