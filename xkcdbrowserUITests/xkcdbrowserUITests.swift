//
//  xkcdbrowserUITests.swift
//  xkcdbrowserUITests
//
//  Created by Paul Himes on 12/1/18.
//  Copyright © 2018 Tin Whistle. All rights reserved.
//

import XCTest

class xkcdbrowserUITests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    func testSearch() {
        let app = XCUIApplication()
        app.navigationBars["No Comic Selected"].buttons["Comics are this way!"].tap()
        app/*@START_MENU_TOKEN@*/.tables.staticTexts["Tectonics Game"]/*[[".otherElements[\"dismiss popup\"].tables",".cells.staticTexts[\"Tectonics Game\"]",".staticTexts[\"Tectonics Game\"]",".otherElements[\"PopoverDismissRegion\"].tables",".tables"],[[[-1,4,1],[-1,3,1],[-1,0,1]],[[-1,2],[-1,1]]],[0,0]]@END_MENU_TOKEN@*/.tap()
        app/*@START_MENU_TOKEN@*/.otherElements["PopoverDismissRegion"]/*[[".otherElements[\"dismiss popup\"]",".otherElements[\"PopoverDismissRegion\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        app.children(matching: .window).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .scrollView).element.tap()
        
    }

}
