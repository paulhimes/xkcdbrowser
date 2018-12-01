//
//  ComicFetcherTests.swift
//  xkcdbrowserTests
//
//  Created by Paul Himes on 11/30/18.
//  Copyright © 2018 Tin Whistle. All rights reserved.
//

import XCTest
@testable import xkcdbrowser

class ComicFetcherTests: XCTestCase {

    func testFetchComicWithNumber() {
        let fetchCurrentComicExpectation = XCTestExpectation(description: "fetched current comic")
        ComicFetcher.fetchComicWithNumber(nil) { (comic) in
            XCTAssertNotNil(comic, "Failed to fetch current comic.")
            fetchCurrentComicExpectation.fulfill()
        }
        
        let fetchMissingComicExpectation = XCTestExpectation(description: "fetched missing comic")
        ComicFetcher.fetchComicWithNumber(404) { (comic) in
            XCTAssertNil(comic, "Failed to fail to fetch comic 404.")
            fetchMissingComicExpectation.fulfill()
        }
        
        let fetchTestComicExpectation = XCTestExpectation(description: "fetched test comic")
        ComicFetcher.fetchComicWithNumber(2050) { (comic) in
            XCTAssertNotNil(comic, "Failed to fetch comic 2050.")
            guard let comic = comic else { return }
            
            XCTAssertEqual(comic.safeTitle, "6/6 Time", "Comic 2050's title was wrong.")
            XCTAssertEqual(comic.alternateText, "You know how Einstein figured out that the speed of light was constant, and everything else had to change for consistency? My theory is like his, except not smart or good.", "Comic 2050's alternate text was wrong.")
            XCTAssertEqual(comic.image.absoluteString, "https://imgs.xkcd.com/comics/6_6_time.png", "Comic 2050's image URL was wrong.")
            XCTAssertEqual(comic.link, "https://xkcd.com/1061/", "Comic 2050's link was wrong.")
            XCTAssertEqual(comic.number, 2050, "Comic 2050's number was wrong.")
            XCTAssertEqual(comic.year, "2018", "Comic 2050's year was wrong.")
            XCTAssertEqual(comic.month, "9", "Comic 2050's month was wrong.")
            XCTAssertEqual(comic.day, "24", "Comic 2050's day was wrong.")

            fetchTestComicExpectation.fulfill()
        }
        
        wait(for: [fetchCurrentComicExpectation, fetchMissingComicExpectation, fetchTestComicExpectation], timeout: 2)
    }
    
    func testFetchComicsWithNumbers() {
        let fetchLastFiveComicsExpectation = XCTestExpectation(description: "fetched last five comics")
        fetchLastFiveComicsExpectation.expectedFulfillmentCount = 5
        ComicFetcher.fetchComicWithNumber(nil) { (comic) in
            XCTAssertNotNil(comic, "Failed to fetch current comic.")
            guard let comic = comic else { return }
            ComicFetcher.fetchComicsWithNumbers(comic.number, through: comic.number - 4, completion: { (comic) in
                XCTAssertNotNil(comic, "Failed to fetch one of the last five comics.")
                fetchLastFiveComicsExpectation.fulfill()
            })
        }

        let fetchFirstFiveComicsExpectation = XCTestExpectation(description: "fetched first five comics")
        fetchFirstFiveComicsExpectation.expectedFulfillmentCount = 5
        ComicFetcher.fetchComicsWithNumbers(1, through: 5) { (comic) in
            XCTAssertNotNil(comic, "Failed to fetch one of the first five comics.")
            fetchFirstFiveComicsExpectation.fulfill()
        }
        
        let fetchFirstComicExpectation = XCTestExpectation(description: "fetched first comic")
        fetchFirstComicExpectation.expectedFulfillmentCount = 1
        ComicFetcher.fetchComicsWithNumbers(1, through: 1) { (comic) in
            XCTAssertNotNil(comic, "Failed to fetch first comic.")
            fetchFirstComicExpectation.fulfill()
        }
        
        wait(for: [fetchLastFiveComicsExpectation, fetchFirstFiveComicsExpectation, fetchFirstComicExpectation], timeout: 11)
    }
    
    func testLoadImage() {
        let loadRegularImageExpectation = XCTestExpectation(description: "fetched regular image")
        ComicFetcher.loadImageForURL(URL(string: "https://imgs.xkcd.com/comics/hazard_symbol.png")!, highResolution: false) { (image) in
            XCTAssertNotNil(image)
            XCTAssertEqual(image!.size, CGSize(width: 404, height: 445), "Regular image had the wrong size.")
            loadRegularImageExpectation.fulfill()
        }

        let loadHighResolutionImageExpectation = XCTestExpectation(description: "fetched high resolution image")
        ComicFetcher.loadImageForURL(URL(string: "https://imgs.xkcd.com/comics/hazard_symbol.png")!, highResolution: true) { (image) in
            XCTAssertNotNil(image)
            XCTAssertEqual(image!.size, CGSize(width: 808, height: 890), "High resolution image had the wrong size.")
            loadHighResolutionImageExpectation.fulfill()
        }
        
        let loadMissingImageExpectation = XCTestExpectation(description: "fetched missing image")
        ComicFetcher.loadImageForURL(URL(string: "https://imgs.xkcd.com/comics/404.png")!, highResolution: false) { (image) in
            XCTAssertNil(image)
            loadMissingImageExpectation.fulfill()
        }
        
        wait(for: [loadRegularImageExpectation, loadHighResolutionImageExpectation, loadMissingImageExpectation], timeout: 4)
    }
}
