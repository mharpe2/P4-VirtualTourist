//
//  Location.swift
//  Project 4 Virtual Tourist
//
//  Created by Michael Harper on 11/30/15.
//  Copyright © 2015 hxx. All rights reserved.
//

import CoreData
import MapKit



class Location: NSManagedObject, MKAnnotation {
    
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var photos: NSSet
    
    
    struct Keys {
        //static let latitude = "latitude"
        //static let longitude = "longitude"
        static let location = "Location"
    }
    
    var coordinate: CLLocationCoordinate2D {
        set {
            self.latitude = newValue.latitude
            self.longitude = newValue.longitude
        }
        
        get {
            return CLLocationCoordinate2DMake(latitude, longitude)
        }
    }
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(coordiante: CLLocationCoordinate2D, context: NSManagedObjectContext) {
        
        // Core Data
        let entity = NSEntityDescription.entityForName(Keys.location, inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        longitude = coordiante.longitude
        latitude = coordiante.latitude
        photos = NSSet()
        //print("\(photos.count)" )
        
    }
    
    
}