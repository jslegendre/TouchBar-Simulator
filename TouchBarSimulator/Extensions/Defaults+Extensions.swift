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
extension CGRect: Defaults.Serializable {}

extension Defaults.Keys {
    static let windowDocking = Key<TouchBarWindow.Docking>("windowDocking", default: .floating)
    static let lastFloatingPosition = Key<CGPoint?>("lastFloatingPosition")
}
