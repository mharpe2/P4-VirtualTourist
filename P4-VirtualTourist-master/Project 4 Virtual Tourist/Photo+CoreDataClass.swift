//
//  Photo+CoreDataClass.swift
//  Project 4 Virtual Tourist
//
//  Created by Michael Harper on 3/28/17.
//  Copyright © 2017 hxx. All rights reserved.
//

import Foundation
import CoreData
import UIKit


public class Photo: NSManagedObject {

    
    struct Keys {
        static let url = "url_m"
        static let title = "title"
        static let photo = "Photo"
        //static let location = "Location"
        static let fileName = "fileName"
    }
    
    
    //    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
    //        super.init(entity: entity, insertInto: context)
    //    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        //Core Data
        let entity =  NSEntityDescription.entity(forEntityName: Keys.photo, in: context)!
        super.init(entity: entity,insertInto: context)
        
        
        // Dictionary
        url = (dictionary[Keys.url] as? String)!
        //location = Location(dictionary: dictionary, context: context)
        fileName = getLastPathComponent(url!) //generate filename
        title = (dictionary[Keys.title] as? String )
    }
    
    
    func getImage() -> UIImage? {
        return FlickrClient.Caches.imageCache.imageWithIdentifier(fileName)
    }
    
    func saveImage(_ image: UIImage?) {
        if fileName != nil {
            _ = FlickrClient.Caches.imageCache.storeImage(image, withIdentifier: fileName!)
        }
    }
    
    override public func prepareForDeletion() {
        _ = FlickrClient.Caches.imageCache.storeImage(nil, withIdentifier: fileName!)
    }
    
    func deleteImage() -> Bool {
        if FlickrClient.Caches.imageCache.storeImage(nil, withIdentifier: fileName!) == false {
            //image was deleted
            return true
        }
        //image was not deleted
        return false
    }
    
    func getLastPathComponent(_ fullPath: String) -> String {
        return ( fullPath as NSString).lastPathComponent
    }

}
