//
//  String+Helpers.swift
//  xkcdbrowser
//
//  Created by Paul Himes on 11/30/18.
//  Copyright © 2018 Tin Whistle. All rights reserved.
//

import Foundation

extension String {
    var normalized: String {
        return folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
    }
}
