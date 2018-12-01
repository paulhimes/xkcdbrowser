//
//  ComicsTableViewController.swift
//  xkcdbrowser
//
//  Created by Paul Himes on 11/24/18.
//  Copyright © 2018 Tin Whistle. All rights reserved.
//

import UIKit
import CoreData

/**
 A searchable table of xkcd comics.
 */
class ComicsTableViewController: UITableViewController, NSFetchedResultsControllerDelegate, UISearchResultsUpdating {

    /** A main thread context used to populate the table. */
    var managedObjectContext: NSManagedObjectContext? = nil

    private let imageCache = NSCache<NSString, UIImage>()
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    private let searchController = UISearchController(searchResultsController: nil)
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Apply theme and styling.
        styleNavigationBar()
        tableView.sectionIndexColor = .black
        tableView.sectionIndexTrackingBackgroundColor = .xkcdBlueWithAlpha
        
        // Wire up the search controller.
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.tintColor = .white
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
    }

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
            let comic = fetchedResultsController.object(at: indexPath)
                let controller = (segue.destination as! UINavigationController).topViewController as! ComicDetailsViewController
                // Pass the data model to the detail view controller.
                controller.comic = comic
                // More split view controller back button wiring.
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
        let cell = tableView.dequeueReusableCell(withIdentifier: ComicTableViewCell.cellIdentifier, for: indexPath) as! ComicTableViewCell
        let comic = fetchedResultsController.object(at: indexPath)
        configureCell(cell, forIndexPath: indexPath, withComic: comic)
        return cell
    }

    /**
     Apply the given model object to this table cell.
     - Parameters:
        - cell: The cell to populated with data.
        - forIndexPath: The indexpath of the cell at the time it was configured. This is used for asynchronous loading to guard against populating the wrong cell due to cell reuse.
        - withComic: The model object used to configure the cell.
     */
    private func configureCell(_ cell: ComicTableViewCell, forIndexPath indexPath: IndexPath?, withComic comic: ManagedComic) {
        cell.textLabel?.text = "\(comic.safeTitle)"
        cell.detailTextLabel?.text = "No. \(comic.number) • \(dateFormatter.string(from: comic.date))"
        cell.setComicImage(UIImage())
        
        // Attempt to use a cached image first.
        let imageURLString = comic.image.absoluteString
        if let cachedImage = imageCache.object(forKey: imageURLString as NSString) {
            // Using cached image.
            cell.setComicImage(cachedImage)
        } else {
            // Download a fresh copy of the image.
            guard let indexPath = indexPath else { return }
            ComicFetcher.loadImageForURL(comic.image, highResolution: false) { [weak self] (image) in
                guard let cell = self?.tableView.cellForRow(at: indexPath) as? ComicTableViewCell else { return }
                guard let image = image else {
                    cell.imageView?.image = nil
                    return
                }
                // Save the image to the cache.
                self?.imageCache.setObject(image, forKey: imageURLString as NSString)
                cell.setComicImage(image)
            }
        }
    }

    // MARK: - Fetched results controller

    private var fetchedResultsController: NSFetchedResultsController<ManagedComic> {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchRequest: NSFetchRequest<ManagedComic> = ManagedComic.fetchRequest()
        fetchRequest.fetchBatchSize = 20
        
        // Sort comics from newest to oldest.
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "number", ascending: false)]
        
        // Filter the results based on the current search string, if it is not empty.
        if let searchString = searchController.searchBar.text, searchString.count > 0 {
            // Search String 1: Remove all alphanumeric characters and replace with "*" to allow wild card matching.
            let starryString = "*\(searchString.components(separatedBy: CharacterSet.alphanumerics.inverted).joined(separator: "*"))*".normalized
            // Search String 2: Include only decimal digits for searching by comic number.
            let numberString = searchString.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
            // Search normalized versions of these attributes for matches: safeTitle, number, alternateText, transcript, link.
            fetchRequest.predicate = NSPredicate(format: "safeTitleNormalized LIKE %@ || number == %@ || alternateTextNormalized LIKE %@ || transcriptNormalized LIKE %@ || linkNormalized LIKE %@", starryString, numberString, starryString, starryString, starryString)
        }
        
        _fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: "year", cacheName: nil)
        _fetchedResultsController?.delegate = self
        
        do {
            try _fetchedResultsController!.performFetch()
        } catch {
            NSLog("A programming error caused the core data fetch to fail: \(error)")
        }
        
        return _fetchedResultsController!
    }
    private var _fetchedResultsController: NSFetchedResultsController<ManagedComic>? = nil

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
                configureCell(tableView.cellForRow(at: indexPath!) as! ComicTableViewCell, forIndexPath: indexPath, withComic: anObject as! ManagedComic)
            case .move:
                configureCell(tableView.cellForRow(at: indexPath!) as! ComicTableViewCell, forIndexPath: indexPath, withComic: anObject as! ManagedComic)
                tableView.moveRow(at: indexPath!, to: newIndexPath!)
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, sectionIndexTitleForSectionName sectionName: String) -> String? {
        return sectionName.replacingCharacters(in: sectionName.startIndex...sectionName.index(sectionName.startIndex, offsetBy: 1), with: "’")
    }
    
    // MARK: - UISearchResultsUpdating
    
    func updateSearchResults(for searchController: UISearchController) {
        _fetchedResultsController = nil
        tableView.reloadData()
    }
}

