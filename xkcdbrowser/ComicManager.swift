//
//  ComicManager.swift
//  xkcdbrowser
//
//  Created by Paul Himes on 11/24/18.
//  Copyright © 2018 Tin Whistle. All rights reserved.
//

import UIKit
import CoreData

class ComicManager {
    static func loadComicsIntoContext(_ context: NSManagedObjectContext) {
        
//        Batch the saves to core data after the first few dozen to improve scrolling performance while the data is being loaded.
        
        
        context.perform {
            let fetchRequest: NSFetchRequest<ManagedComic> = ManagedComic.fetchRequest()
            fetchRequest.fetchLimit = 1
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "number", ascending: false)]
            let newestComicNumber = (try? context.fetch(fetchRequest))?.first?.number
            
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "number", ascending: true)]
            let oldestComicNumber = (try? context.fetch(fetchRequest))?.first?.number
            
            // If we hava an oldest comic, start fetching all the comics older than it.
            if let oldestComicNumber = oldestComicNumber, oldestComicNumber > 1 {
                NSLog("Loading older comics from \(oldestComicNumber - 1) to 1")
                ComicFetcher.fetchComicsWithNumbers(UInt(oldestComicNumber) - 1, through: 1) { (comic) in
                    createOrUpdateComic(with: comic, in: context)
                }
            }
            
            // Get the current comic.
            ComicFetcher.fetchComicWithNumber(nil) { (currentComic) in
                guard let currentComicNumber = currentComic?.number else { return }
                
                if let newestComicNumber = newestComicNumber, newestComicNumber < currentComicNumber {
                    // If we have a newest comic, fetch all numbers between it and the current comic, including the current comic.
                    NSLog("Loading newer comics from \(newestComicNumber + 1) to \(currentComicNumber)")
                    ComicFetcher.fetchComicsWithNumbers(UInt(newestComicNumber) + 1, through: currentComicNumber) { (comic) in
                        createOrUpdateComic(with: comic, in: context)
                    }
                } else if newestComicNumber == nil {
                    // If we have no comics, fetch all numbers between the current comic and 0, including the current comic.
                    NSLog("Loading all comics from \(currentComicNumber) to 1")
                    ComicFetcher.fetchComicsWithNumbers(currentComicNumber, through: 1) { (comic) in
                        createOrUpdateComic(with: comic, in: context)
                    }
                } else {
                    // Already up-to-date.
                    NSLog("No newer comics available.")
                }
            }
        }
    }
    
    private static var totalCreatedOrUpdatedThisRun = 0
    private static var currentBatch: [Comic] = []
    private static let batchSize = 50
    private static let batchingThreshold = 100
    
    private static func createOrUpdateComic(with comic: Comic?, in context: NSManagedObjectContext) {
        guard let comic = comic else { return }
        currentBatch.append(comic)
        
        totalCreatedOrUpdatedThisRun += 1
        if totalCreatedOrUpdatedThisRun > batchingThreshold, currentBatch.count < batchSize, comic.number > 1 {
            return
        }
        
        context.perform {
            for comic in currentBatch {
                let fetchRequest: NSFetchRequest<ManagedComic> = ManagedComic.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "number = %u", comic.number)
                if let matchingComic = (try? context.fetch(fetchRequest))?.first {
                    matchingComic.updateWithComic(comic)
                } else {
                    ManagedComic.createWithComic(comic, in: context)
                }
            }
            
            if context.saveOrRollback() {
                NSLog("Loaded comic numbers [\((currentBatch.map { "\($0.number)" }).joined(separator: ", "))]")
            }
            
            currentBatch.removeAll()
        }
    }
}

extension ManagedComic {
    func updateWithComic(_ comic: Comic) {
        alternateText = comic.alternateText.count > 0 ? comic.alternateText : nil
        
        var dateComponents = DateComponents()
        dateComponents.year = Int(comic.year)
        dateComponents.month = Int(comic.month)
        dateComponents.day = Int(comic.day)
        date = Calendar.current.date(from: dateComponents) ?? Date.distantPast
        
        image = comic.image
        link = URL(string: comic.link)
        news = comic.news
        safeTitle = comic.safeTitle
        title = comic.title
        transcript = comic.transcript
        year = Int32(comic.year)!
    }
    
    static func createWithComic(_ comic: Comic, in context: NSManagedObjectContext) {
        let managedComic = ManagedComic(context: context)
        managedComic.number = Int32(comic.number)
        managedComic.updateWithComic(comic)
    }
}

extension NSManagedObjectContext {
    public func saveOrRollback() -> Bool {
        do {
            try save()
            return true
        } catch let error as NSError {
            NSLog("Core Data error. Rolling back. \(error)")
            rollback()
            return false
        }
    }
}

