//
//  MasterViewController.swift
//  xkcdbrowser
//
//  Created by Paul Himes on 11/24/18.
//  Copyright © 2018 Tin Whistle. All rights reserved.
//

import UIKit
import CoreData

class MasterViewController: UITableViewController, NSFetchedResultsControllerDelegate {

    var managedObjectContext: NSManagedObjectContext? = nil

    private let imageCache = NSCache<NSString, UIImage>()
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        styleNavigationBar()
        tableView.sectionIndexColor = .black
        tableView.sectionIndexTrackingBackgroundColor = .xkcdBlueWithAlpha
    }
    
    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
            let comic = fetchedResultsController.object(at: indexPath)
                let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
                controller.comic = comic
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.name
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return fetchedResultsController.sectionIndexTitles
    }
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return fetchedResultsController.section(forSectionIndexTitle: title, at: index)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let comic = fetchedResultsController.object(at: indexPath)
        configureCell(cell, forIndexPath: indexPath, withComic: comic)
        return cell
    }

    func configureCell(_ cell: UITableViewCell, forIndexPath indexPath: IndexPath?, withComic comic: ManagedComic) {
        cell.textLabel?.text = "\(comic.safeTitle)"
        cell.detailTextLabel?.text = "No. \(comic.number) • \(dateFormatter.string(from: comic.date))"
        cell.imageView?.image = MasterViewController.thumbnailFromImage(UIImage())
        cell.imageView?.layer.shadowColor = UIColor.black.cgColor
        cell.imageView?.layer.shadowRadius = 2
        cell.imageView?.clipsToBounds = false
        cell.imageView?.layer.shadowOpacity = 0.1
        cell.imageView?.layer.shadowOffset = CGSize(width: 2, height: 2)

        let imageURLString = comic.image.absoluteString
        if let cachedImage = imageCache.object(forKey: imageURLString as NSString) {
            cell.imageView?.image = MasterViewController.thumbnailFromImage(cachedImage)
        } else {
            guard let indexPath = indexPath else { return }
            ComicFetcher.loadImageForURL(comic.image, highResolution: false) { [weak self] (image) in
                guard let cell = self?.tableView.cellForRow(at: indexPath) else { return }
                guard let image = image else {
                    cell.imageView?.image = nil
                    return
                }
                self?.imageCache.setObject(image, forKey: imageURLString as NSString)
                cell.imageView?.image = MasterViewController.thumbnailFromImage(image)
            }
        }
    }
    
    private static func thumbnailFromImage(_ image: UIImage) -> UIImage {
        let baseThumbnailSize: Double = 60
        let maximumRotationDegree: Double = 10
        let radians = maximumRotationDegree * .pi / 180
        let thumbnailSizeAfterRotation = (sin(radians) + cos(radians)) * baseThumbnailSize
        
        let thumbnailSize = CGSize(width: thumbnailSizeAfterRotation, height: thumbnailSizeAfterRotation)
        UIGraphicsBeginImageContextWithOptions(thumbnailSize, false, 0)
        
        let context = UIGraphicsGetCurrentContext()
        
        context?.saveGState()
        
        context?.translateBy(x: thumbnailSize.width / 2, y: thumbnailSize.height / 2)
        
        var randomDegree = 0
        for _ in 0..<10 {
            randomDegree = Int(arc4random_uniform(UInt32(2 * maximumRotationDegree))) - Int(maximumRotationDegree)
            if randomDegree != 0 {
                break
            }
        }
        
        context?.rotate(by: CGFloat(randomDegree) * .pi / 180)

        context?.translateBy(x: -thumbnailSize.width / 2, y: -thumbnailSize.height / 2)
        
        // Scale input image to fit base thumbnail size.
        let scaledImageSize: CGSize
        if image.size.width / image.size.height * CGFloat(baseThumbnailSize) > CGFloat(baseThumbnailSize) {
            // Scale the width to fit.
            scaledImageSize = CGSize(width: CGFloat(baseThumbnailSize),
                                     height: image.size.height / image.size.width * CGFloat(baseThumbnailSize))
        } else {
            // Scale the height to fit.
            scaledImageSize = CGSize(width: image.size.width / image.size.height * CGFloat(baseThumbnailSize),
                                     height: CGFloat(baseThumbnailSize))
        }
        
        let scaledImageRect = CGRect(x: (thumbnailSize.width - scaledImageSize.width) / 2,
                                     y: (thumbnailSize.height - scaledImageSize.height) / 2,
                                     width: scaledImageSize.width,
                                     height: scaledImageSize.height)
        
        image.draw(in: scaledImageRect)
        
        context?.restoreGState()
        
        let thumbnailImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return thumbnailImage
    }

    // MARK: - Fetched results controller

    var fetchedResultsController: NSFetchedResultsController<ManagedComic> {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchRequest: NSFetchRequest<ManagedComic> = ManagedComic.fetchRequest()
        
        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = 20
        
        // Edit the sort key as appropriate.
        let sortDescriptor = NSSortDescriptor(key: "number", ascending: false)
        
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: "year", cacheName: nil)
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
        do {
            try _fetchedResultsController!.performFetch()
        } catch {
             // Replace this implementation with code to handle the error appropriately.
             // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
             let nserror = error as NSError
             fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
        
        return _fetchedResultsController!
    }
    var _fetchedResultsController: NSFetchedResultsController<ManagedComic>? = nil

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
            case .insert:
                tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
            case .delete:
                tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
            default:
                return
        }
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
            case .insert:
                tableView.insertRows(at: [newIndexPath!], with: .fade)
            case .delete:
                tableView.deleteRows(at: [indexPath!], with: .fade)
            case .update:
                configureCell(tableView.cellForRow(at: indexPath!)!, forIndexPath: indexPath, withComic: anObject as! ManagedComic)
            case .move:
                configureCell(tableView.cellForRow(at: indexPath!)!, forIndexPath: indexPath, withComic: anObject as! ManagedComic)
                tableView.moveRow(at: indexPath!, to: newIndexPath!)
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, sectionIndexTitleForSectionName sectionName: String) -> String? {
        return sectionName.replacingCharacters(in: sectionName.startIndex...sectionName.index(sectionName.startIndex, offsetBy: 1), with: "’")
    }
}

