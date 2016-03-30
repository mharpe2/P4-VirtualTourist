//
//  PhotoAlbumsVC.swift
//  Project 4 Virtual Tourist
//
//  Created by Michael Harper on 11/11/15.
//  Copyright © 2015 hxx. All rights reserved.
//

import UIKit
import MapKit
import CoreData


class PhotoAlbumsVC: UIViewController, MKMapViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var newCollection: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var layout: UICollectionViewFlowLayout!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var noImagesForThisLocationLabel: UILabel!
    
    
    var oKButton: UIBarButtonItem!
    var selectedLocation: Location!
    
    // The selected indexes array keeps all of the indexPaths for cells that are "selected". The array is
    // used inside cellForItemAtIndexPath to lower the alpha of selected cells.  You can see how the array
    // works by searchign through the code for 'selectedIndexes'
    var selectedIndexes = [NSIndexPath]()
    
    // Keep the changes. We will keep track of insertions, deletions, and updates.
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    
    var sharedContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    // fetchedResultsController
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        //Create fetch request for photos which match the sent Location.
        
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.predicate = NSPredicate(format: "location == %@", self.selectedLocation)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        fetchRequest.sortDescriptors = []
        
        //Create fetched results controller with the new fetch request.
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                  managedObjectContext: self.sharedContext()!,
                                                                  sectionNameKeyPath: nil,
                                                                  cacheName: nil)
        fetchedResultsController.delegate = self
        return fetchedResultsController
    }()
    
    //MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Delegates
        mapView.delegate = self
        collectionView.delegate = self
        collectionView.dataSource = self
        
        //Mark: UI - Custom Navigation buttons
        oKButton = UIBarButtonItem(title: "Ok", style: .Plain, target: self, action: #selector(PhotoAlbumsVC.oKButtonPressed(_:)))
        
        let leftButtons = [oKButton!]
        self.navigationItem.leftBarButtonItems = leftButtons
        layout.minimumInteritemSpacing = 0.5
        layout.minimumLineSpacing = 0.5
        
        // center map around selectedLocation
        if selectedLocation != nil {
            
            // add the annotation to map
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
    
    //MARK: CollectionView - numberOfItemsInSection
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        guard let sectionInfo = self.fetchedResultsController.sections?[section] else {
            return 1
        }
        
        return sectionInfo.numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cellIdentifer = "photoCell"
        
        // dequeued cell
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(cellIdentifer, forIndexPath: indexPath) as! PhotoCell
        
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
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
            downloadImageForPhoto(photo, photoCell: cell)
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
        
        let photo = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        cell.imageView.image = photo.getImage()
        
        //Grey cell out
        if let _ = selectedIndexes.indexOf(indexPath) {
            UIView.animateWithDuration(0.25, animations: { cell.imageView.alpha = 0.25 })
        } else {
            // otherwise do not grey
            UIView.animateWithDuration(0.25, animations: { cell.imageView.alpha = 1.0})
        }
    }
    
    // three fresh arrays to record the index paths that will be changed.
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        
        // We are about to handle some new changes. Start out with empty arrays for each change type
        
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
        
        print("in controllerWillChangeContent")
    }
    
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type{
            
        case .Insert:
            print("Insert an item")
            insertedIndexPaths.append(newIndexPath!)
        case .Delete:
            print("Delete an item")
            deletedIndexPaths.append(indexPath!)
        case .Update:
            print("Update an item.")
            updatedIndexPaths.append(indexPath!)
        default:
            break
            
        }
    }
    
    // This method is invoked after all of the changed in the current batch have been collected
    // into the three index path arrays (insert, delete, and upate). We now need to loop through the
    // arrays and perform the changes.
    //
    // The most interesting thing about the method is the collection view's "performBatchUpdates" method.
    // Notice that all of the changes are performed inside a closure that is handed to the collection view.
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        print("in controllerDidChangeContent. changes.count: \(insertedIndexPaths.count + deletedIndexPaths.count)")
        
        collectionView.performBatchUpdates({() -> Void in
            
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItemsAtIndexPaths([indexPath])
            }
            
            }, completion: nil)
    }
    
    
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
        
        // delete all photos
        for photo in fetchedResultsController.fetchedObjects as! [Photo] {
            
            photo.deleteImage()
            sharedContext()!.deleteObject(photo)
        }
        
        // remove all photos from location
        selectedLocation.photos = NSMutableOrderedSet()
        
        //Download and display photos one by one
        FlickrClient.sharedInstance().getImageUrlsByLocation(selectedLocation) {
            result, error, numPages in
            if result == nil {
                displayError(self, errorString: "Loading new photos failed")
                print("Loading new photos failed")
                return
            }
            
            let photo = result.map() { (var dictionary: [String : AnyObject]) -> Photo in
                // 1 - dictionary[Photo.Keys.location] = location // add location data to dict
                let photo = Photo(dictionary: dictionary, context: self.sharedContext()!)
                photo.location = self.selectedLocation
                self.selectedLocation.photos.addObject(photo)
                
                print("Location \(photo.location)")
                CoreDataStackManager.sharedInstance().saveContext()
                                return photo
            } // end result.map()
            
            dispatch_async(dispatch_get_main_queue()) {
                self.fetchResults()
                self.collectionView.reloadData()
            }

        }
    }
    
    func downloadImageForPhoto(photo: Photo, photoCell: PhotoCell) {
        FlickrClient.sharedInstance().taskForGETImage(photo.url!, completionHandler: {
            
            success, imageData, error in
            
            if success != true {
                displayError(self, errorString: "error extracting " + photo.url!)
                print("error extracting " + photo.url!)
            }
            else {
                photo.saveImage(UIImage(data: imageData!))
                print("saved \(photo.location)" )
                //CoreDataStackManager.sharedInstance().saveContext()
                
                dispatch_async(dispatch_get_main_queue()) {
                    photoCell.imageView.image = photo.getImage()
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
                sharedContext()?.deleteObject(fetchedResultsController.objectAtIndexPath(item) as! Photo)
            }
            // reset selected index
            selectedIndexes = []
            CoreDataStackManager.sharedInstance().saveContext()
            
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

