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
    var oKButton: UIBarButtonItem!
    var selectedLocation: Location!
    var temporaryContext: NSManagedObjectContext!
    
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
        //fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
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
        
        // Set the temporary context
        temporaryContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.MainQueueConcurrencyType)
        temporaryContext.persistentStoreCoordinator = sharedContext()!.persistentStoreCoordinator

        
        //Delegates
        mapView.delegate = self
        collectionView.delegate = self
        collectionView.dataSource = self
        
        //Mark: UI - Custom Navigation buttons
        oKButton = UIBarButtonItem(title: "Ok", style: .Plain, target: self, action: "oKButtonPressed:")
        
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
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("Error performing fetch")
        }
        if fetchedResultsController.fetchedObjects?.count == 0{
            newCollection.enabled = false
        }
        
//        if selectedLocation.photos.count == 0 {
//            // download photos
//            print("Downloading photos")
//           fetchPhotosForLocation(selectedLocation)
//            // Update the table on the main thread
            dispatch_async(dispatch_get_main_queue()) {
            self.collectionView.reloadData()
            }
        
        }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Lay out the collection view so that cells take up 1/3 of the width,
        // with no space in between.
        let layout : UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        let width = floor(self.collectionView.frame.size.width/3)
        layout.itemSize = CGSize(width: width, height: width)
        collectionView.collectionViewLayout = layout
    }

    
    //MARK: CollectionView
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 1
       
    }

    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        
        print("number Of Cells: \(sectionInfo.numberOfObjects)")
        return sectionInfo.numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cellIdentifer = "photoCell"
        
        // dequeued cell
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(cellIdentifer, forIndexPath: indexPath) as! PhotoCell
        
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        if photo.getImage() != nil {
            
            //cell.activityIndicatorView.stopAnimating()
            cell.imageView.alpha = 0.0
            cell.imageView.image = photo.getImage()
            
            UIView.animateWithDuration(0.2,
                animations: { cell.imageView.alpha = 1.0 })
        }

    
        // confiure cell
        configureCell(cell, atIndexPath: indexPath)
        
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
        configureCell(cell, atIndexPath: indexPath)
        
    }

    //MARK: Collection View Helpers
    
    //func configureCell(cell: PhotoCell, photo: Photo) {
        func configureCell(cell: PhotoCell, atIndexPath indexPath: NSIndexPath) {
//            
//            let photo = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
//            
//            cell.imageView.image = photo.getImage()
//            // If the cell is "selected" it's color panel is grayed out
//            // we use the Swift `find` function to see if the indexPath is in the array
//            
//            if let index = selectedIndexes.indexOf(indexPath) {
//                cell.alpha = 0.05
//            } else {
//                cell.alpha = 1.0
//            }
            //Grey cell out            
            if let _ = selectedIndexes.indexOf(indexPath) {
                UIView.animateWithDuration(0.1,
                    animations: {
                        cell.imageView.alpha = 0.5
                })
            } else {
                
                // Do not grew
                UIView.animateWithDuration(0.1,
                    animations: {
                        cell.imageView.alpha = 1.0
                })
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
    
    // The second method may be called multiple times, once for each Color object that is added, deleted, or changed.
    // We store the incex paths into the three arrays.
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {

        
        switch type{
            
        case .Insert:
            print("Insert an item")
            insertedIndexPaths.append(newIndexPath!)
            break
        case .Delete:
            print("Delete an item")
            deletedIndexPaths.append(indexPath!)
            break
        case .Update:
            print("Update an item.")
            // We don't expect Color instances to change after they are created. But Core Data would
            // notify us of changes if any occured. This can be useful if you want to respond to changes
            // that come about after data is downloaded. For example, when an images is downloaded from
            // Flickr in the Virtual Tourist app
            updatedIndexPaths.append(indexPath!)
            break
        case .Move:
            print("Move an item. We don't expect to see this in this app.")
            break
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
    
    // delegate method is implemented to respond to taps. It opens the system browser
    // to the URL specified in the annotationViews subtitle property.
    func mapView(mapView: MKMapView, annotationView: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
    }
    
    func loadNewPhotos() {
    
        newCollection.enabled = false
        print("Load new photos for \(selectedLocation)")
        
        FlickrClient.sharedInstance().fetchPhotosForLocation(selectedLocation!)
        //delete existing pictures
        for picture in fetchedResultsController.fetchedObjects as! [Photo] {
            sharedContext()?.deleteObject(picture)
        }
        CoreDataStackManager.sharedInstance().saveContext()
        newCollection.enabled = true
    }
    
    @IBAction func oKButtonPressed(sender: AnyObject) {
        
        navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func newCollectionButtonTapped(sender: AnyObject) {
        print("New Collection Button Pressed")
        loadNewPhotos()
    }
//    func downloadImage(photo: Photo) {
//        FlickrClient.sharedInstance().taskForGETImage(photo.url!, completionHandler: {
//            success, imageData, error in
//            if success != true {
//                print("error extracting " + photo.url!)
//            } else {
//                photo.saveImage(UIImage(data: imageData!)) //= UIImage(data: imageData!)
//                self.collectionView.reloadData()
//            }
//        })
//    }
}

