//
//  TouchBarAnimation.swift
//  TouchBarSimulator
//
//  Created by 上原葉 on 8/28/23.
//

import AppKit

class TouchBarAnimation: NSAnimation {
    override var currentProgress: NSAnimation.Progress {
        didSet {
            super.currentProgress = currentProgress
            if isAnimating {
                animate(currentValue)
            }
        }
    }
    public var animate: (Float) -> Void  = {_ in return} {
        didSet {
            // immediately stop (cancel) current animation & reset
            if isAnimating {
                stop()
                NSLog("animation Interrupted: \(currentProgress)")
                currentProgress = 0.0
            }
            //start()
        }
    }
    
    public convenience init(duration: TimeInterval, animationCurve: NSAnimation.Curve, blockMode: NSAnimation.BlockingMode) {
        self.init(duration: duration, animationCurve: animationCurve)
        self.animationBlockingMode = blockMode
    }
}
