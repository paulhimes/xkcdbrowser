//
//  ComicManagerTests.swift
//  xkcdbrowserTests
//
//  Created by Paul Himes on 12/1/18.
//  Copyright © 2018 Tin Whistle. All rights reserved.
//

import XCTest
import CoreData
@testable import xkcdbrowser

class ComicManagerTests: XCTestCase {

    override func tearDown() {
        let fetchRequest: NSFetchRequest<ManagedComic> = ManagedComic.fetchRequest()
        let objs = try! persistentContainer.viewContext.fetch(fetchRequest)
        for case let obj as NSManagedObject in objs {
            persistentContainer.viewContext.delete(obj)
        }
        try! persistentContainer.viewContext.save()
        super.tearDown()
    }
    
    func testLoadComicsIntoContext() {
        ComicManager.loadComicsIntoContext(persistentContainer.newBackgroundContext())
    
        let loadComicsExpectation = XCTestExpectation(description: "loaded comics")
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            let fetchRequest: NSFetchRequest<ManagedComic> = ManagedComic.fetchRequest()
            let objs = (try! self?.persistentContainer.viewContext.fetch(fetchRequest)) ?? []
            XCTAssertNotNil(objs.first, "Failed to load any comics into the database")
            loadComicsExpectation.fulfill()
        }

        wait(for: [loadComicsExpectation], timeout: 10)
        
    }

    lazy var managedObjectModel: NSManagedObjectModel = {
        let managedObjectModel = NSManagedObjectModel.mergedModel(from: [Bundle(for: type(of: self))] )!
        return managedObjectModel
    }()
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "xkcdbrowser", managedObjectModel: managedObjectModel)
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                NSLog("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
}
