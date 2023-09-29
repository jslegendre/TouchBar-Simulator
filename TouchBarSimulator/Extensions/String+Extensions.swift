//
//  String+Extensions.swift
//  TouchBarSimulator
//
//  Created by 上原葉 on 9/27/23.
//

import Foundation
//import StringsLiteralMacro

extension String {
    
    // localize
    var localized: String {
        //return String(localized: self)
        return NSLocalizedString(self, comment: self)
    }
}

/*
@freestanding(expression)
public macro localize(_ value: String) -> String = #externalMacro(module: "StringsLiteralMacroMacros", type: "LocalizeMacro")
*/
