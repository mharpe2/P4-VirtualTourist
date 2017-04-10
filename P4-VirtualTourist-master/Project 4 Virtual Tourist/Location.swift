////
////  Location.swift
////  Project 4 Virtual Tourist
////
////  Created by Michael Harper on 11/30/15.
////  Copyright © 2015 hxx. All rights reserved.
////
//
//import CoreData
//import MapKit
//
//class Location: NSManagedObject, MKAnnotation{
//    
//    @NSManaged var latitude: Double
//    @NSManaged var longitude: Double
//    //@NSManaged var geohash: String
//    @NSManaged var photos: NSMutableOrderedSet
//    @NSManaged var numberOfPages: NSNumber?
//    
//    
//    struct Keys {
//        static let location = "Location"
//        static let longitude = "longitude"
//        static let latitude = "latitude"
//        static let numPages = "numberOfPages"
//    }
//    
//    // conform to MKAnnotation
//    var coordinate: CLLocationCoordinate2D {
//        set {
//            self.latitude = newValue.latitude
//            self.longitude = newValue.longitude
//        }
//        
//        get {
//            return CLLocationCoordinate2DMake(latitude, longitude)
//        }
//    }
//    
//    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
//        super.init(entity: entity, insertInto: context)
//    }
//    
//    init(coordiante: CLLocationCoordinate2D, context: NSManagedObjectContext) {
//        
//        // Core Data
//        let entity = NSEntityDescription.entity(forEntityName: Keys.location, in: context)!
//        super.init(entity: entity, insertInto: context)
//        
//        longitude = coordiante.longitude
//        latitude = coordiante.latitude
//        //geohash = Geohash.encode(latitude: latitude, longitude: longitude)
//        self.photos = NSMutableOrderedSet()
//    }
//    
//    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
//        
//        let entity = NSEntityDescription.entity(forEntityName: Keys.location, in: context)!
//        super.init(entity: entity, insertInto: context)
//        
//        if let lat = dictionary[Keys.latitude] as! Double? {
//            if let long = dictionary[Keys.longitude] as! Double? {
//                latitude = lat
//                longitude = long
//               // geohash = Geohash.encode(latitude: latitude, longitude: longitude)
//            }
//        }
//        numberOfPages = dictionary[Keys.numPages] as? NSNumber
//        self.photos = NSMutableOrderedSet()
//    }
//    
//    //MARK: override DESCRIPTION
//    override var description: String {
//        return String("Location: \(latitude), \(longitude), \(numberOfPages)")
//    }
//    
//}
//
////MARK: == Operator
//// isEqual
//func ==(lhs: Location, rhs: Location) -> Bool {
//    
//    //return ( (lhs.longitude == rhs.longitude) && (lhs.latitude == rhs.latitude))
//    return ( lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude)
//}
