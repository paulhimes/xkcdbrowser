//
//  ComicFetcher.swift
//  xkcdbrowser
//
//  Created by Paul Himes on 11/24/18.
//  Copyright © 2018 Tin Whistle. All rights reserved.
//

import Foundation
import UIKit

// API endpoints.
private let currentComicURLString = "https://xkcd.com/info.0.json"
private let numberedComicURLString = "https://xkcd.com/%u/info.0.json"

/**
 A collection of functions to download and parse comics and images.
 This encapsulates the JSON API.
 */
struct ComicFetcher {
    /**
     Download a specific single comic
     - Parameters:
        - number: The number of the comic to download or nil to download the latest comic.
        - completion: A callback with the downloaded comic or nil if no comic was found.
        - comic: The downloaded comic or nil if no comic was found.
     */
    static func fetchComicWithNumber(_ number: UInt?, completion: @escaping (_ comic: Comic?) -> Void) {
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
    
    /**
     Download a series of comics.
     - Parameters:
        - first: The number of the first comic in the series.
        - last: The number of the last comic in the series.
        - completion: A callback called once for each number.
        - comic: The downloaded comic or nil if no comic was found.
     */
    static func fetchComicsWithNumbers(_ first: UInt, through last: UInt, completion: @escaping (_ comic: Comic?) -> Void) {
        fetchComicWithNumber(first) { (comic) in
            completion(comic)
            
            if first != last {
                let newFirst: UInt
                if first < last {
                    newFirst = first + 1
                } else {
                    newFirst = first - 1
                }
                // Call recursively with the remaining range of numbers.
                fetchComicsWithNumbers(newFirst, through: last, completion: completion)
            }
        }
    }
    
    /**
     Downloads the comic image from a URL.
     - Parameters:
        - imageURL: The URL provided by the API for a comic image.
        - highResolution: Flag to turn on high resolution image downloading. If the high resolution image can't be found, it will fall back to the normal resolution image.
        - completion: A callback with the downloaded image or nil if the image was not found.
        - image: The comic image or nil
     */
    static func loadImageForURL(_ imageURL: URL, highResolution: Bool, completion: @escaping (_ image: UIImage?) -> Void) {
        var modifiedURL = imageURL
        if highResolution && !imageURL.absoluteString.contains("_2x.png") {
            modifiedURL = URL(string: imageURL.absoluteString.replacingOccurrences(of: ".png", with: "_2x.png"))!
        }
        
        URLSession.shared.dataTask(with: modifiedURL) { (data, response, error) in
            guard let data = data, let image = UIImage(data: data) else {
                if highResolution {
                    // The high resolution image download failed, fall back to normal resolution.
                    loadImageForURL(imageURL, highResolution: false, completion: completion)
                } else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                }
                return
            }
            DispatchQueue.main.async {
                completion(image)
            }
        }.resume()
    }
}

/**
 The ComicFetcher representation of a comic.
 */
struct Comic: Codable {
    // #404 is missing.
    let number: UInt
    // HTML snippet
    let title: String
    // Plain text (#259 & #472 have non-plain-text titles.)
    let safeTitle: String
    let year: String
    let month: String
    let day: String
    let image: URL
    // Displayed when you hover over the image on the webpage.
    let alternateText: String
    // URLs that appear when you click the image.
    let link: String
    // HTML snippet that appears at the top of the webpage.
    let news: String
    // A text description of the image.
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
