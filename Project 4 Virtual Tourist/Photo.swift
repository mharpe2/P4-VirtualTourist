//
//  Photo.swift
//  SleepingInTheLibrary
//
//  Created by Michael Harper on 11/25/15.
//  Copyright © 2015 Udacity. All rights reserved.
//

import UIKit
import CoreData

class Photo: NSManagedObject {
    
    @NSManaged var location: Location?
    @NSManaged var url: String?
    @NSManaged var fileName: String?
    @NSManaged var title: String?
    
    struct Keys {
        static let url = "url_m"
        static let title = "title"
        static let photo = "Photo"
        static let location = "Location"
        static let fileName = "fileName"
    }

    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        //Core Data
        let entity =  NSEntityDescription.entityForName(Keys.photo, inManagedObjectContext: context)!
        super.init(entity: entity,insertIntoManagedObjectContext: context)
        
        
        // Dictionary
        url = (dictionary[Keys.url] as? String)!
        location = Location(dictionary: dictionary, context: context)
        fileName = getLastPathComponent(url!) //generate filename
        title = (dictionary[Keys.title] as? String )
         }
    
    
    func getImage() -> UIImage? {
        return FlickrClient.Caches.imageCache.imageWithIdentifier(fileName)
    }
    
    func saveImage(image: UIImage?) {
        FlickrClient.Caches.imageCache.storeImage(image, withIdentifier: fileName!)
    }
     
    func getLastPathComponent(fullPath: String) -> String {
        return ( fullPath as NSString).lastPathComponent
    }
}

