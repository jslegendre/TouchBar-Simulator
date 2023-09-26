//
//  String+Extensions.swift
//  TouchBarSimulator
//
//  Created by 上原葉 on 9/27/23.
//

import Foundation

extension String {
    
    // localize
    var localized: String {
        return NSLocalizedString(self, comment: self)
    }
}
