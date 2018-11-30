//
//  ComicFetcher.swift
//  xkcdbrowser
//
//  Created by Paul Himes on 11/24/18.
//  Copyright © 2018 Tin Whistle. All rights reserved.
//

import Foundation
import UIKit

private let currentComicURLString = "https://xkcd.com/info.0.json"
private let numberedComicURLString = "https://xkcd.com/%u/info.0.json"

struct ComicFetcher {
    static func fetchComicWithNumber(_ number: UInt?, completion: @escaping (Comic?) -> Void) {
        let urlString: String
        if let number = number {
            urlString = String(format: numberedComicURLString, number)
        } else {
            urlString = currentComicURLString
        }
        
        URLSession.shared.dataTask(with: URL(string: urlString)!) { (data, response, error) in
            var comic: Comic?
            defer {
                completion(comic)
            }
            
            guard let data = data else {
                return
            }
            
            do {
                let decoder = JSONDecoder()
                comic = try decoder.decode(Comic.self, from: data)
            } catch {
                NSLog("Failed to parse json data: \(error)")
            }
        }.resume()
    }
    
    static func fetchComicsWithNumbers(_ first: UInt, through last: UInt, completion: @escaping (Comic?) -> Void) {
        fetchComicWithNumber(first) { (comic) in
            completion(comic)
            
            if first != last {
                let newFirst: UInt
                if first < last {
                    newFirst = first + 1
                } else {
                    newFirst = first - 1
                }
                fetchComicsWithNumbers(newFirst, through: last, completion: completion)
            }
        }
    }
    
    static func loadImageForURL(_ imageURL: URL, completion: @escaping (UIImage?) -> Void) {
        URLSession.shared.dataTask(with: imageURL) { (data, response, error) in
            guard let data = data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                completion(image)
            }
        }.resume()
    }
    
//    static func collectStatsForAllComics() {
//        fetchComicWithNumber(nil) { (currentComic) in
//            guard let currentComic = currentComic else {
//                NSLog("Current comic is missing.")
//                return
//            }
//
//            NSLog("Fetched current comic.")
//
//            fetchComicBeforeNumber(currentComic.number)
//        }
//    }
    
//    private static func fetchComicBeforeNumber(_ number: UInt) {
//        if number > 1 {
//            fetchComicWithNumber(number - 1) { (comic) in
//                guard let _ = comic else {
//                    NSLog("Comic \(number - 1) is missing.")
//                    fetchComicBeforeNumber(number - 1)
//                    return
//                }
//
//                NSLog("Fetched comic \(number - 1).")
//
////                if comic.alternateText.count == 0 {
////                    NSLog("Comic \(number - 1) is missing alt text.")
////                }
//
////                if comic.link.count > 0 {
////                    NSLog("Comic \(number - 1) is has a link: \(comic.link)")
////                }
//
////                if comic.news.count > 0 {
////                    NSLog("Comic \(number - 1) is has news: \(comic.news)")
////                }
//
////                if comic.title != comic.safeTitle {
////                    NSLog("Comic \(number - 1) is has differing titles: title = \(comic.title), safe = \(comic.safeTitle)")
////                }
//
////                if comic.transcript.count > 0 {
////                    NSLog("Comic \(number - 1) is has a transcript: \(comic.transcript)")
////                }
//
//
//                fetchComicBeforeNumber(number - 1)
//            }
//        } else {
//            NSLog("Done.")
//        }
//    }
}

struct Comic: Codable {
    let number: UInt
    let title: String
    let safeTitle: String
    let year: String
    let month: String
    let day: String
    let image: URL
    let alternateText: String
    let link: String
    let news: String
    let transcript: String
    
    enum CodingKeys: String, CodingKey {
        case number = "num"
        case title
        case safeTitle = "safe_title"
        case year
        case month
        case day
        case image = "img"
        case alternateText = "alt"
        case link
        case news
        case transcript
    }
}

// Final Key counts: ["num": 2075, "day": 2075, "year": 2075, "alt": 2072, "link": 54, "img": 2075, "news": 49, "transcript": 1666, "month": 2075, "safe_title": 2075, "title": 2075]
// Links are URLs that appear when you click the image.
// News is HTML snippets that appear at the top of the page
// Title is an HTML snippet. Safe Title is just text. (#259 & #472 have non-plain-text titles)
// Alt text is displayed when you hover over the image. Some don't have alt text. #1525, #1506, & #1193 have no alt text.
// Transcript is a text description of the comic (like a script) that he stopped doing a long time ago. I'm not sure how to parse or present it.
// #404 is missing.
