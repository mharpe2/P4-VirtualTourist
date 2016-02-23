//
//  Location.swift
//  Project 4 Virtual Tourist
//
//  Created by Michael Harper on 11/30/15.
//  Copyright © 2015 hxx. All rights reserved.
//

import CoreData
import MapKit

class Location: NSManagedObject, MKAnnotation{
    
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var photos: [Photo]
    
    
    struct Keys {
        static let location = "Location"
    }
    
    // conform to MKAnnotation
    var coordinate: CLLocationCoordinate2D {
        set {
            self.latitude = newValue.latitude
            self.longitude = newValue.longitude
        }
        
        get {
            return CLLocationCoordinate2DMake(latitude, longitude)
        }
    }
    
    override var hashValue: Int {
        get {
            return latitude.hashValue ^ longitude.hashValue
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
    }
    
}

//MARK: == Operator
// isEqual
//func ==(lhs: Location, rhs: Location) -> Bool {
//    
//    return ( (lhs.longitude == rhs.longitude) && (lhs.latitude == rhs.latitude))
//}