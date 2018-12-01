//
//  StringHelperTests.swift
//  StringHelperTests
//
//  Created by Paul Himes on 11/24/18.
//  Copyright © 2018 Tin Whistle. All rights reserved.
//

import XCTest
@testable import xkcdbrowser

class StringHelperTests: XCTestCase {
    func testNormalization() {
        let emptyString = ""
        let nilString: String? = nil
        let normalString = "I'll put this on my resumé."
        let emojiString = "🤓"
        
        XCTAssertEqual(emptyString.normalized, "", "Empty string failed normalization.")
        XCTAssertEqual(nilString?.normalized, nil, "Nil string failed normalization.")
        XCTAssertEqual(normalString.normalized, "i'll put this on my resume.", "Normal string failed normalization.")
        XCTAssertEqual(emojiString.normalized, "🤓", "Emoji string failed normalization.")
    }
}
