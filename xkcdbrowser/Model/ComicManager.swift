//
//  ComicManager.swift
//  xkcdbrowser
//
//  Created by Paul Himes on 11/24/18.
//  Copyright © 2018 Tin Whistle. All rights reserved.
//

import UIKit
import CoreData

/**
 Manages the core data database.
 Uses the ComicFetcher to download comics then converts them to `ManagedComic` instances and saves them locally.
 */
class ComicManager {
    
    // Batch saving to improve performance.
    private static let batchSize = 200
    private static let batchingThreshold = 50
    
    /**
     Downloads any missing comics newer or older and saves them to the core data database.
     - Parameter context: The context used to save the comics to the database. **Preferably a background context.**
     */
    static func loadComicsIntoContext(_ context: NSManagedObjectContext) {
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
                    let forceSave = comic?.number == 1 ? true : false
                    addComicToBatch(comic, context: context, forceSave: forceSave)
                }
            }
            
            // Get the current comic.
            ComicFetcher.fetchComicWithNumber(nil) { (currentComic) in
                guard let currentComicNumber = currentComic?.number else { return }
                
                if let newestComicNumber = newestComicNumber, newestComicNumber < currentComicNumber {
                    // If we have a newest comic, fetch all numbers between it and the current comic, including the current comic.
                    NSLog("Loading newer comics from \(newestComicNumber + 1) to \(currentComicNumber)")
                    ComicFetcher.fetchComicsWithNumbers(UInt(newestComicNumber) + 1, through: currentComicNumber) { (comic) in
                        let forceSave = comic?.number == currentComicNumber ? true : false
                        addComicToBatch(comic, context: context, forceSave: forceSave)
                    }
                } else if newestComicNumber == nil {
                    // If we have no comics, fetch all numbers between the current comic and 0, including the current comic.
                    NSLog("Loading all comics from \(currentComicNumber) to 1")
                    ComicFetcher.fetchComicsWithNumbers(currentComicNumber, through: 1) { (comic) in
                        let forceSave = comic?.number == 1 ? true : false
                        addComicToBatch(comic, context: context, forceSave: forceSave)
                    }
                } else {
                    // Already up-to-date.
                    NSLog("No newer comics available.")
                }
            }
        }
    }
    
    /**
     Adds a downloaded comic to a batch waiting to be saved to the local database.
     - Parameters:
        - comic: The comic to save.
        - context: The context to save into.
        - forceSave: Flag to save all pending comics immediately.
     */
    private static func addComicToBatch(_ comic: Comic?, context: NSManagedObjectContext, forceSave: Bool) {
        // Function-scoped struct to prevent others from accessing these properties.
        struct BatchQueue {
            // Batch Queue and queue-managed properties.
            static let queue = DispatchQueue(label: "comicBatchQueue", qos: .background)
            static var totalCreatedOrUpdatedThisRun = 0
            static var currentBatch: [Comic] = []
        }
        
        BatchQueue.queue.async {
            if let comic = comic {
                BatchQueue.currentBatch.append(comic)
                BatchQueue.totalCreatedOrUpdatedThisRun += 1
                
                if forceSave {
                    NSLog("Forced save after downloading comic: \(comic.number)")
                }
            }
            
            if BatchQueue.totalCreatedOrUpdatedThisRun > batchingThreshold, BatchQueue.currentBatch.count < batchSize, !forceSave {
                return
            }
            
            let batchToSave = BatchQueue.currentBatch
            BatchQueue.currentBatch.removeAll()
            
            context.perform {
                for comic in batchToSave {
                    // Create or update comic in database.
                    let fetchRequest: NSFetchRequest<ManagedComic> = ManagedComic.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "number = %u", comic.number)
                    if let matchingComic = (try? context.fetch(fetchRequest))?.first {
                        matchingComic.updateWithComic(comic)
                    } else {
                        ManagedComic.createWithComic(comic, in: context)
                    }
                }
                
                let _ = context.saveOrRollback()
            }
        }
    }
}

// Enables creating or updateing core data managed comics from ComicFetcher downloaded comics.
fileprivate extension ManagedComic {
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

fileprivate extension NSManagedObjectContext {
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

