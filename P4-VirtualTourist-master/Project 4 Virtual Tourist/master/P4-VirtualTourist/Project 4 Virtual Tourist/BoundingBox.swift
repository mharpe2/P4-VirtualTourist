//
//  BoundingBox.swift
//  Project 4 Virtual Tourist
//
//  Created by Michael Harper on 12/1/15.
//  Copyright © 2015 hxx. All rights reserved.
//

import Foundation

// Bounding Box

//struct BoundingBox {
//    var lowerLeftLongitude: Double
//    var lowerLeftLatitude: Double
//    var upperRightLongitude: Double
//    var upperRightLatitude: Double
//
//    // create bounding box
//    // lat -90 to 90
//    // long -180 to 180
//    init(longitude: Double, latitude: Double, span: Double) {
//        self.lowerLeftLatitude = max(latitude - span, -90)
//        self.lowerLeftLongitude = max(longitude - span, -180)
//        self.upperRightLongitude = min(longitude + span, 180)
//        self.upperRightLatitude = min(latitude + span, 90)
//
//    }
//
//    func toString() -> String {
//        return ("\(lowerLeftLongitude),\(lowerLeftLatitude),\(upperRightLongitude),\(upperRightLatitude)")
//    }
//}



class BoundingBox
{
    let WGS84_a = Double(6378137.0)
    let WGS84_b = Double(6356752.3)
    
    // 'halfSideInKm' is the half length of the bounding box you want in kilometers.
    func GetBoundingBox(point: Location, halfSideInKm: Double) -> String
    {
        
        // Bounding box surrounding the point at given coordinates,
        // assuming local approximation of Earth surface as a sphere
        // of radius given by WGS84
        let lat = Deg2rad(point.latitude);
        let lon = Deg2rad(point.longitude);
        let halfSide = 1000 * halfSideInKm;
        
        // Radius of Earth at given latitude
        let radius = WGS84EarthRadius(lat);
        // Radius of the parallel at given latitude
        let pradius = radius * cos(lat);
        
        let latMin = lat - halfSide / radius;
        let latMax = lat + halfSide / radius;
        let lonMin = lon - halfSide / pradius;
        let lonMax = lon + halfSide / pradius;
        
        let minPoint = Location(Latitude: Rad2deg(latMin), Longitude: Rad2deg(lonMin) )
        let maxPoint = Location(Latitude: Rad2deg(latMax), Longitude: Rad2deg(lonMax) )
        
        return "\(minPoint.latitude), \(minPoint.longitude), \(maxPoint.latitude), \(maxPoint.longitude)"
        
        
    }
    
    
    // degrees to radians
    func Deg2rad(degrees: Double) -> Double
    {
        return M_PI * degrees / 180.0;
    }
    
    // radians to degrees
    func Rad2deg(radians: Double) -> Double
    {
        return 180.0 * radians / M_PI;
    }
    
    // Earth radius at a given latitude, according to the WGS-84 ellipsoid [m]
    func WGS84EarthRadius(lat: Double) -> Double
    {
        // http://en.wikipedia.org/wiki/Earth_radius
        let An = WGS84_a * WGS84_a * cos(lat);
        let Bn = WGS84_b * WGS84_b * sin(lat);
        let Ad = WGS84_a * cos(lat);
        let Bd = WGS84_b * sin(lat);
        return sqrt((An*An + Bn*Bn) / (Ad*Ad + Bd*Bd));
    }
    
}

//extension BoundingBox {
//    static let WGS84_a = Double(6378137.0)
//    static let WGS84_b = Double(6356752.3)
//}



