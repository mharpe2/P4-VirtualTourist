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
    var lastPage = 1
    
    // The selected indexes array keeps all of the indexPaths for cells that are "selected". The array is
    // used inside cellForItemAtIndexPath to lower the alpha of selected cells.  You can see how the array
    // works by searchign through the code for 'selectedIndexes'
    var selectedIndexes = [IndexPath]()
    
    // Keep the changes. We will keep track of insertions, deletions, and updates.
    var insertedIndexPaths: [IndexPath]!
    var deletedIndexPaths: [IndexPath]!
    var updatedIndexPaths: [IndexPath]!
    
    let ad = UIApplication.shared.delegate as! AppDelegate
    var sharedContext: NSManagedObjectContext!
    
    //    var sharedContext = {
    //        return CoreDataStackManager.sharedInstance().persistentContainer.viewContext
    //    }
    
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    //    lazy var fetchedResultsController: NSFetchedResultsController<Photo> = {() -> NSFetchedResultsController<Photo>
    //        let fetchRequest: NSFetchRequest = Photo.fetchRequest()
    //        fetchRequest.predicate = NSPredicate(format: "location == %@", self.selectedLocation)
    //        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
    //        fetchRequest.sortDescriptors = []
    //
    //        //Create fetched results controller with the new fetch request.
    //        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
    //                                                                  managedObjectContext: self.sharedContext()!,
    //                                                                  sectionNameKeyPath: nil,
    //                                                                  cacheName: nil)
    //        fetchedResultsController.delegate = self
    //        return fetchedResultsController
    //    }
    
    //    // fetchedResultsController
    //    lazy var fetchedResultsController: NSFetchedResultsController<Photo> = { () in
    //
    //        //Create fetch request for photos which match the sent Location.
    //
    //        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
    //        fetchRequest.predicate = NSPredicate(format: "location == %@", self.selectedLocation)
    //        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
    //        fetchRequest.sortDescriptors = []
    //
    //        //Create fetched results controller with the new fetch request.
    //        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
    //                                                                  managedObjectContext: self.sharedContext()!,
    //                                                                  sectionNameKeyPath: nil,
    //                                                                  cacheName: nil)
    //        fetchedResultsController.delegate = self
    //        return fetchedResultsController
    //    }()
    
    //MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sharedContext = ad.coreData.persistentContainer.viewContext
        
        //Delegates
        mapView.delegate = self
        collectionView.delegate = self
        collectionView.dataSource = self
        
        //Mark: UI - Custom Navigation buttons
        oKButton = UIBarButtonItem(title: "Ok", style: .plain, target: self, action: #selector(PhotoAlbumsVC.oKButtonPressed(_:)))
        
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
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        guard let sectionInfo = self.fetchedResultsController.sections?[section] else {
            return 1
        }
        
        return sectionInfo.numberOfObjects
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cellIdentifer = "photoCell"
        
        // dequeued cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifer, for: indexPath) as! PhotoCell
        
        let photo = fetchedResultsController.object(at: indexPath)
        
        // if photo already downloaded, display it
        if photo.getImage() != nil {
            
            DispatchQueue.main.async {
                cell.activityIndicator.stopAnimating()
                cell.imageView.alpha = 0.0
                cell.imageView.image = photo.getImage()
                UIView.animate(withDuration: 0.5, animations: { cell.imageView.alpha = 1.0 })
            }
            
        } else {
            // try to download image
            cell.activityIndicator.startAnimating()
            downloadImageForPhoto(photo, cell: cell)
            cell.activityIndicator.stopAnimating()
        }
        
        DispatchQueue.main.async {
            self.configureCell(cell, atIndexPath: indexPath)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let cell = collectionView.cellForItem(at: indexPath) as! PhotoCell
        
        // Whenever a cell is tapped we will toggle its presence in the selectedIndexes array
        if let index = selectedIndexes.index(of: indexPath) {
            selectedIndexes.remove(at: index)
        } else {
            selectedIndexes.append(indexPath)
        }
        
        // Then reconfigure the cell
        DispatchQueue.main.async {
            self.configureCell(cell, atIndexPath: indexPath)
        }
        
        
        // toggle collection view text
        if selectedIndexes.count > 0 {
            newCollection.setTitle("Tap to delete selected images", for: UIControlState())
        }
        else {
            newCollection.setTitle("New Collection", for: UIControlState())
        }
        
    }
    
    //MARK: Collection View Helpers
    
    func configureCell(_ cell: PhotoCell, atIndexPath indexPath: IndexPath) {
        
        let photo = self.fetchedResultsController.object(at: indexPath)
        if let image = photo.getImage() {
            cell.imageView.image = image
            cell.activityIndicator.stopAnimating()
        } else {
            cell.imageView.image = UIImage(named: "madmen")
            cell.activityIndicator.startAnimating()
        }
        
        //Grey cell out
        if let _ = selectedIndexes.index(of: indexPath) {
            UIView.animate(withDuration: 0.25, animations: { cell.imageView.alpha = 0.25 })
        } else {
            // otherwise do not grey
            UIView.animate(withDuration: 0.25, animations: { cell.imageView.alpha = 1.0})
        }
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        // We are about to handle some new changes. Start out with empty arrays for each change type
        
        insertedIndexPaths = [IndexPath]()
        deletedIndexPaths = [IndexPath]()
        updatedIndexPaths = [IndexPath]()
        
    }
    
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type{
            
        case .insert:
            //print("Insert an item")
            insertedIndexPaths.append(newIndexPath!)
        case .delete:
            //print("Delete an item")
            deletedIndexPaths.append(indexPath!)
        case .update:
            //print("Update an item.")
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
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        print("in controllerDidChangeContent. changes.count: \(insertedIndexPaths.count + deletedIndexPaths.count)")
        
        collectionView.performBatchUpdates({() -> Void in
            
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItems(at: [indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItems(at: [indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItems(at: [indexPath])
            }
            
        }, completion: nil)
    }
    
    //MARK: Mapview
    
    // create a view with a "right callout accessory view".
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "Location"
        var LocationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if LocationView == nil {
            LocationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            LocationView!.canShowCallout = false
            LocationView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
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
        
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "location == %@", self.selectedLocation)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        fetchRequest.sortDescriptors = []
        
        //Create fetched results controller with the new fetch request.
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                  managedObjectContext: self.sharedContext,
                                                                  sectionNameKeyPath: nil,
                                                                  cacheName: nil)
        fetchedResultsController.delegate = self
        self.fetchedResultsController = fetchedResultsController
        
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            print("Error performing fetch")
            displayError(self, errorString: error.localizedDescription)
        }
        if fetchedResultsController.fetchedObjects?.count == 0{
            newCollection.isEnabled = false
            noImagesForThisLocationLabel.isHidden = false
        } else {
            newCollection.isEnabled = true
            noImagesForThisLocationLabel.isHidden = true
        }
        
    }
    
    func loadNewPhotos() {
        
        newCollection.isEnabled = false
        print("load new photos for location \(selectedLocation!)")
        
        // delete all photos
        for photo in fetchedResultsController.fetchedObjects!  {
            //photo.deleteImage()
            sharedContext.delete(photo)
        }
        
        // remove all photos from location
        selectedLocation.photos = NSMutableOrderedSet()
        
        FlickrClient.sharedInstance().fetchPhotosForLocation(selectedLocation)        
        collectionView.reloadData()
        fetchResults()
        newCollection.isEnabled = true
        
    }
    
    func downloadImageForPhoto(_ photo: Photo, cell: PhotoCell) {
        FlickrClient.sharedInstance().taskForGETImage(photo.url!, completionHandler: {
            
            success, imageData, error in
            
            if success != true {
                displayError(self, errorString: "error extracting " + photo.url!)
                print("error extracting " + photo.url!)
                return
            }
            guard let image = imageData else {
                return
            }
            
            photo.saveImage(image)
            print("saved \(photo.location)" )
            
            performUIUpdatesOnMain {
                
                if let image = photo.getImage() {
                    cell.imageView.image = image
                    cell.activityIndicator.stopAnimating()
                } else {
                    cell.imageView.image = UIImage(named: "madmen")
                    cell.activityIndicator.startAnimating()
                }
            } // perform updates on main       
        }) // end taskForGetImage
}

//MARK: Actions

@IBAction func oKButtonPressed(_ sender: AnyObject) {
    
    _ = navigationController?.popViewController(animated: true)
}

@IBAction func newCollectionButtonTapped(_ sender: AnyObject) {
    print("New Collection Button Pressed")
    
    // if nothing is selected, load a new set
    if selectedIndexes.count == 0
    {
        loadNewPhotos()
    }
    else { // remove selceted photos from set
        for item in selectedIndexes {
            // delete the item from fetched results
            
            //let photo = fetchedResultsController.object(at: item)
            
            // remove photo from dir
            //photo.deleteImage()
            
            // remove from core data
            sharedContext.delete(fetchedResultsController.object(at: item) )
            
        }
        // reset selected index
        selectedIndexes = []
        do {
            try self.sharedContext.save()
        } catch _ {
            fatalError()
        }
        
        // newCollection button should always be "New Collection" after photos
        // are removed
        newCollection.setTitle("New Collection", for: UIControlState())
        newCollection.isEnabled = true
    }
    
    DispatchQueue.main.async {
        self.collectionView.reloadData()
    }
}
}

