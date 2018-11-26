//
//  ManagedComic+CoreDataProperties.swift
//  
//
//  Created by Paul Himes on 11/25/18.
//

import Foundation
import CoreData


extension ManagedComic {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ManagedComic> {
        return NSFetchRequest<ManagedComic>(entityName: "ManagedComic")
    }

    @NSManaged public var alternateText: String?
    @NSManaged public var date: Date
    @NSManaged public var image: URL
    @NSManaged public var link: URL?
    @NSManaged public var news: String?
    @NSManaged public var number: Int32
    @NSManaged public var safeTitle: String
    @NSManaged public var title: String
    @NSManaged public var transcript: String?
    @NSManaged public var year: Int32

}
