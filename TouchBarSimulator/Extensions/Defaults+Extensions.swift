//
//  DefaultsManager.swift
//  TouchBar Simulator
//
//  Created by 上原葉 on 8/13/23.
//

import Foundation
import CoreGraphics
import Defaults

extension TouchBarWindow.Docking: Defaults.Serializable {}
extension CGPoint: Defaults.Serializable {}

extension Defaults.Keys {
    static let windowTransparency = Key<Double>("windowTransparency", default: 0.75)
    static let windowDocking = Key<TouchBarWindow.Docking>("windowDocking", default: .floating)
    static let windowPadding = Key<Double>("windowPadding", default: 0.0)
    static let showOnAllDesktops = Key<Bool>("showOnAllDesktops", default: false)
    static let lastFloatingPosition = Key<CGPoint?>("lastFloatingPosition")
    static let dockBehavior = Key<Bool>("dockBehavior", default: false)
    static let lastWindowDockingWithDockBehavior = Key<TouchBarWindow.Docking>("windowDockingWithDockBehavior", default: .dockedToTop)
}
