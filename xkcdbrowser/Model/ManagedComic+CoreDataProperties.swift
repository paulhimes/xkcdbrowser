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
    @NSManaged public var alternateTextNormalized: String?
    @NSManaged public var date: Date
    @NSManaged public var image: URL
    @NSManaged public var link: URL?
    @NSManaged public var linkNormalized: String?
    @NSManaged public var news: String?
    @NSManaged public var number: Int32
    @NSManaged public var safeTitle: String
    @NSManaged public var safeTitleNormalized: String
    @NSManaged public var title: String
    @NSManaged public var transcript: String?
    @NSManaged public var transcriptNormalized: String?
    @NSManaged public var year: Int32

    public override func willSave() {
        if alternateTextNormalized != alternateText?.normalized {
            alternateTextNormalized = alternateText?.normalized
        }
        
        if linkNormalized != link?.absoluteString.normalized {
            linkNormalized = link?.absoluteString.normalized
        }
        
        if safeTitleNormalized != safeTitle.normalized {
            safeTitleNormalized = safeTitle.normalized
        }
        
        if transcriptNormalized != transcript?.normalized {
            transcriptNormalized = transcript?.normalized
        }
    }
    
}
