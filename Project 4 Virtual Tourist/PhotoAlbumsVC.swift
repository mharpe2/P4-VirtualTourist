//
//  PhotoAlbumsVC.swift
//  Project 4 Virtual Tourist
//
//  Created by Michael Harper on 11/11/15.
//  Copyright © 2015 hxx. All rights reserved.
//

import UIKit
import MapKit
import BNRCoreDataStack
import CoreData


class PhotoAlbumsVC: UIViewController, MKMapViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate  {
    
    @IBOutlet weak var newCollection: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var layout: UICollectionViewFlowLayout!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var noImagesForThisLocationLabel: UILabel!
    
    var oKButton: UIBarButtonItem!
    var selectedLocation: Location!
    var lastPage = 1
    
    // The selected indexes array keeps all of the indexPaths for cells that are "selected". The array is
    // used inside cellForItemAtIndexPath to lower the alpha of selected cells.  You can see how the array
    // works by searchign through the code for 'selectedIndexes'
    var selectedIndexes = [NSIndexPath]()
    
    
    var sharedContext = {
        // using mainQueueContext to work on UI thread
        return CoreDataStackManager.sharedInstance().coreDataStack!.mainQueueContext
        
    }
    
    // fetchedResultsController
    lazy var fetchedResultsController: FetchedResultsController<Photo> = {
        
        //Create fetch request for photos which match the sent Location.
        
        let fetchRequest = NSFetchRequest(entityName: Photo.entityName)
        fetchRequest.predicate = NSPredicate(format: "location == %@", self.selectedLocation)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        fetchRequest.sortDescriptors = []
        
        //Create fetched results controller with the new fetch request.
        var fetchedResultsController = FetchedResultsController<Photo>(fetchRequest: fetchRequest,
                                                                  managedObjectContext: self.sharedContext(),
                                                                  sectionNameKeyPath: nil,
                                                                  cacheName: nil)
        
        return fetchedResultsController
    }()
    lazy var frcDelegate: PhotosFetchedResultsControllerDelegate = {
        return PhotosFetchedResultsControllerDelegate(collectionView: self.collectionView)
    }()
    
    //MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Delegates
        fetchedResultsController.setDelegate(frcDelegate)
        mapView.delegate = self
        collectionView.delegate = self
        collectionView.dataSource = self
        
        //Mark: UI - Custom Navigation buttons
        oKButton = UIBarButtonItem(title: "Ok", style: .Plain, target: self, action: #selector(PhotoAlbumsVC.oKButtonPressed(_:)))
        
        let leftButtons = [oKButton!]
        self.navigationItem.leftBarButtonItems = leftButtons
        layout.minimumInteritemSpacing = 0.5
        layout.minimumLineSpacing = 0.5
        
         // add the annotation to map
        if selectedLocation != nil {
            
            // center map around selectedLocation
            let span:MKCoordinateSpan = MKCoordinateSpanMake(10, 10)
            let region:MKCoordinateRegion = MKCoordinateRegionMake(selectedLocation.coordinate, span)
            mapView.setRegion(region, animated: true)
            mapView.addAnnotation(selectedLocation)
        }
        
        // Core Data
        fetchResults()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Layout the collection view so that cells take up 1/3 of the width,
        let layout : UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        //layout.sectionInset = UIEdgeInsets(top: 50.0, left: 20.0, bottom: 50.0, right: 20.0)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        let width = floor(self.collectionView.frame.size.width/3)
        layout.itemSize = CGSize(width: width, height: width)
        collectionView.collectionViewLayout = layout
    }
    
    
    //MARK: CollectionView
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return fetchedResultsController.sections?[section].objects.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cellIdentifer = "photoCell"
        
        // dequeued cell
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(cellIdentifer, forIndexPath: indexPath) as! PhotoCell
        
        //let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        guard let sections = fetchedResultsController.sections else {
            assertionFailure("Sections missing")
            return cell
        }
        let section = sections[indexPath.section]
        let photo = section.objects[indexPath.row]
        
        // if photo already downloaded, display it
        if photo.getImage() != nil {
            
            dispatch_async(dispatch_get_main_queue()) {
                cell.activityIndicator.stopAnimating()
                cell.imageView.alpha = 0.0
                cell.imageView.image = photo.getImage()
                UIView.animateWithDuration(0.5, animations: { cell.imageView.alpha = 1.0 })
            }
            
        } else {
            // try to download image
            cell.activityIndicator.startAnimating()
            downloadImageForPhoto(photo, cell: cell)
            cell.activityIndicator.stopAnimating()
        }
        
        dispatch_async(dispatch_get_main_queue()) {
            self.configureCell(cell, atIndexPath: indexPath)
        }
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCell
        
        // Whenever a cell is tapped we will toggle its presence in the selectedIndexes array
        if let index = selectedIndexes.indexOf(indexPath) {
            selectedIndexes.removeAtIndex(index)
        } else {
            selectedIndexes.append(indexPath)
        }
        
        // Then reconfigure the cell
        dispatch_async(dispatch_get_main_queue()) {
            self.configureCell(cell, atIndexPath: indexPath)
        }
        
        
        // toggle collection view text
        if selectedIndexes.count > 0 {
            newCollection.setTitle("Tap to delete selected images", forState: .Normal)
        }
        else {
            newCollection.setTitle("New Collection", forState: .Normal)
        }
        
    }
    
    //MARK: Collection View Helpers
    
    func configureCell(cell: PhotoCell, atIndexPath indexPath: NSIndexPath) {
        
        //let photo = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Photo

        guard let sections = fetchedResultsController.sections else {
            assertionFailure("Sections missing")
            return
        }
        let section = sections[indexPath.section]
        let photo = section.objects[indexPath.row]
        
        if let image = photo.getImage() {
            cell.imageView.image = image
            cell.activityIndicator.stopAnimating()
        } else {
            cell.imageView.image = UIImage(named: "madmen")
            cell.activityIndicator.startAnimating()
        }
        
        //Grey cell out
        if let _ = selectedIndexes.indexOf(indexPath) {
            UIView.animateWithDuration(0.25, animations: { cell.imageView.alpha = 0.25 })
        } else {
            // otherwise do not grey
            UIView.animateWithDuration(0.25, animations: { cell.imageView.alpha = 1.0})
        }
    }
    
    
    //MARK: Mapview
    
    // create a view with a "right callout accessory view".
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "Location"
        var LocationView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if LocationView == nil {
            LocationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            LocationView!.canShowCallout = false
            LocationView!.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
            LocationView?.animatesDrop = true
        }
        else {
            LocationView!.annotation = annotation
        }
        
        return LocationView
    }
    
    //MARK: Utility Functions
    
    // fetch coredata results
    func fetchResults() {
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            print("Error performing fetch")
            displayError(self, errorString: error.localizedDescription)
        }
        if fetchedResultsController.fetchedObjects?.count == 0{
            newCollection.enabled = false
            noImagesForThisLocationLabel.hidden = false
        } else {
            newCollection.enabled = true
            noImagesForThisLocationLabel.hidden = true
        }
        
    }
    
    func loadNewPhotos() {
        
        newCollection.enabled = false
        print("load new photos for location \(selectedLocation!)")
        
//         // delete all photos
//        for photo in fetchedResultsController.fetchedObjects as! [Photo] {
//            //photo.deleteImage()
//            sharedContext()!.deleteObject(photo)
//        }
        
        
        guard let photos = fetchedResultsController.fetchedObjects else {
            assertionFailure("objects missing")
            return
        }
        for photo in photos {
            sharedContext().deleteObject(photo)
        }
        
        // remove all photos from location
        selectedLocation.photos = NSMutableOrderedSet()
        
        FlickrClient.sharedInstance().fetchPhotosForLocation(selectedLocation) {
            // Code
            print("Finished fetchPhotosForLocation")
        }
        
        collectionView.reloadData()
        fetchResults()
        newCollection.enabled = true
        
        }
    
    func downloadImageForPhoto(photo: Photo, cell: PhotoCell) {
        FlickrClient.sharedInstance().taskForGETImage(photo.url!, completionHandler: {
            
            success, imageData, error in
            
            if success != true {
                displayError(self, errorString: "error extracting " + photo.url!)
                print("error extracting " + photo.url!)
            }
            else {
                photo.saveImage(UIImage(data: imageData!))
                print("saved \(photo.location)" )
                
                dispatch_async(dispatch_get_main_queue()) {
                    if let image = photo.getImage() {
                        cell.imageView.image = image
                        cell.activityIndicator.stopAnimating()
                    } else {
                        cell.imageView.image = UIImage(named: "madmen")
                        cell.activityIndicator.startAnimating()
                    }
                } // end dispatch
            } // end else
        }) // end taskForGetImage
    }

    //MARK: Actions 
    
    @IBAction func oKButtonPressed(sender: AnyObject) {
        
        navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func newCollectionButtonTapped(sender: AnyObject) {
        print("New Collection Button Pressed")
        
        // if nothing is selected, load a new set
        if selectedIndexes.count == 0
        {
            loadNewPhotos()
        }
        else { // remove selceted photos from set
            for item in selectedIndexes {
                // delete the item from fetched results
               
                //let photo = fetchedResultsController.objectAtIndexPath(item) as! Photo
                
                // remove photo from dir
                //photo.deleteImage()
                
                // remove from core data
                sharedContext().deleteObject(fetchedResultsController[item])
                
            }
            // reset selected index
            selectedIndexes = []
            //CoreDataStackManager.sharedInstance().saveContext()
            do {
                try sharedContext().save()
            } catch _ {
                print("could not save after deletion")
            }
            
            // newCollection button should always be "New Collection" after photos
            // are removed
            newCollection.setTitle("New Collection", forState: .Normal)
            newCollection.enabled = true
        }
        
        dispatch_async(dispatch_get_main_queue()) {
            self.collectionView.reloadData()
        }
    }
}



class PhotosFetchedResultsControllerDelegate: FetchedResultsControllerDelegate {
    
    private weak var collectionView: UICollectionView?
    
    // Keep the changes. We will keep track of insertions, deletions, and updates.
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!

    
    init(collectionView: UICollectionView) {
        self.collectionView = collectionView
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()

    }
    
    func fetchedResultsControllerDidPerformFetch(controller: FetchedResultsController<Photo>) {
        collectionView?.reloadData()
    }
    
    func fetchedResultsControllerWillChangeContent(controller: FetchedResultsController<Photo>) {
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()

    }
    
    func fetchedResultsControllerDidChangeContent(controller: FetchedResultsController<Photo>) {
        print("in controllerDidChangeContent. changes.count: \(insertedIndexPaths.count + deletedIndexPaths.count)")
        
        collectionView!.performBatchUpdates({() -> Void in
            
            for indexPath in self.insertedIndexPaths {
                self.collectionView!.insertItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.collectionView!.deleteItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.collectionView!.reloadItemsAtIndexPaths([indexPath])
            }
            
            }, completion: nil)

    }
    
    func fetchedResultsController(controller: FetchedResultsController<Photo>,
                                  didChangeObject change: FetchedResultsObjectChange<Photo>) {
           switch change {
        case let .Insert(_, indexPath):
             insertedIndexPaths.append(indexPath)
            
        case let .Delete(_, indexPath):
            deletedIndexPaths.append(indexPath)
        case let .Move(_, fromIndexPath, toIndexPath): break
           
            
        case let .Update(_, indexPath):
            updatedIndexPaths.append(indexPath)
        }
    }
    
    func fetchedResultsController(controller: FetchedResultsController<Photo>,
                                  didChangeSection change: FetchedResultsSectionChange<Photo>) {
//        switch change {
//        case let .Insert(_, index):
//            collectionView?.insertSections(NSIndexSet(index: index), withRowAnimation: .Automatic)
//            
//        case let .Delete(_, index):
//            collectionView?.deleteSections(NSIndexSet(index: index), withRowAnimation: .Automatic)
        }
}


//extension PhotoAlbumsVC: NSFetchedResultsControllerDelegate {
//    
//    func controllerWillChangeContent(controller: NSFetchedResultsController) {
//        
//        // We are about to handle some new changes. Start out with empty arrays for each change type
//        
//        insertedIndexPaths = [NSIndexPath]()
//        deletedIndexPaths = [NSIndexPath]()
//        updatedIndexPaths = [NSIndexPath]()
//        
//    }
//    
//    
//    func controller(controller: FetchedResultsController<Photo>, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
//        
//        switch type{
//            
//        case .Insert:
//            //print("Insert an item")
//            insertedIndexPaths.append(newIndexPath!)
//        case .Delete:
//            //print("Delete an item")
//            deletedIndexPaths.append(indexPath!)
//        case .Update:
//            //print("Update an item.")
//            updatedIndexPaths.append(indexPath!)
//        default:
//            break
//            
//        }
//    }
//    
//    // This method is invoked after all of the changed in the current batch have been collected
//    // into the three index path arrays (insert, delete, and upate). We now need to loop through the
//    // arrays and perform the changes.
//    //
//    // The most interesting thing about the method is the collection view's "performBatchUpdates" method.
//    // Notice that all of the changes are performed inside a closure that is handed to the collection view.
//    func controllerDidChangeContent(controller: FetchedResultsController<Photo>) {
//        
//        print("in controllerDidChangeContent. changes.count: \(insertedIndexPaths.count + deletedIndexPaths.count)")
//        
//        collectionView.performBatchUpdates({() -> Void in
//            
//            for indexPath in self.insertedIndexPaths {
//                self.collectionView.insertItemsAtIndexPaths([indexPath])
//            }
//            
//            for indexPath in self.deletedIndexPaths {
//                self.collectionView.deleteItemsAtIndexPaths([indexPath])
//            }
//            
//            for indexPath in self.updatedIndexPaths {
//                self.collectionView.reloadItemsAtIndexPaths([indexPath])
//            }
//            
//            }, completion: nil)
//    }
//
//}
