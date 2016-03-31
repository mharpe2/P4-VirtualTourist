//
//  FlickrClient.swift
//  Project 4 Virtual Tourist
//
//  Created by Michael Harper on 11/5/15.
//  Copyright © 2015 hxx. All rights reserved.
//

import UIKit
import MapKit
import Foundation
import CoreData

class FlickrClient: NSObject {
    
    typealias CompletionHander = (result: AnyObject!, error: NSError?) -> Void
    var sharedContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    
    
    // Session
    var session: NSURLSession!
    //var foundPhotos: [Photo]   = []
    
    override init() {
        session = NSURLSession.sharedSession()
        super.init()
    }
    
    // download a list of image urls assocatiated with a location
    func getImageUrlsByLocation(location: Location,
                                completionHandler: (result: [[String: AnyObject]]!, error: NSError?, numPages: Int?) -> Void ) {
        
        // Choose a random page everytime
        var randomPage = 1
        if let numPages = location.numberOfPages as? Int {
            if numPages > 1 {
                
                randomPage = Int(arc4random_uniform(UInt32(numPages)))
                print("random page = \(randomPage)")
            }
        }
        
        let methodArguments: [String: AnyObject] = [
            methodParameters.method: const.PHOTO_SEARCH,
            methodParameters.api_key: const.API_KEY,
            methodParameters.extras: const.EXTRAS,
            methodParameters.format: const.DATA_FORMAT,
            methodParameters.noJsonCallback: const.NO_JSON_CALLBACK,
            "lat" : location.latitude,
            "lon" : location.longitude,
            methodParameters.page: randomPage,
            methodParameters.perPage: 21
        ]
        
        self.taskForGETMethod(methodArguments){ JSONResult, error in
            
            guard error == nil else {
                print(error)
                completionHandler(result: nil, error: error, numPages: nil)
                return
            }
            
            let domainText = "getImagesByLocation"
            guard let photosDictionary = JSONResult.valueForKey(jsonResponse.photos) as? NSDictionary else {
                let errorText = "Cant find key 'photo' in photosDictionary"
                print("\(errorText)")
                
                let dataError = NSError(domain: domainText, code: 0, userInfo: [NSLocalizedDescriptionKey : errorText])
                completionHandler(result: nil, error: dataError, numPages: nil)
                return
            }
            
            guard let numPages = photosDictionary[jsonResponse.pages] as? Int else {
                let errorText = "Cant find key number of pages"
                print("\(errorText)")
                let dataError = NSError(domain: domainText, code: 0, userInfo: [NSLocalizedDescriptionKey : errorText])
                completionHandler(result: nil, error: dataError, numPages: nil)
                return
            }
            
            guard let photoArray = photosDictionary.valueForKey(jsonResponse.photo) as? [[String: AnyObject]] else {
                let errorText = "Cant find key 'photo' in photosDictionary"
                print("\(errorText)")
                let dataError = NSError(domain: domainText, code: 0, userInfo: [NSLocalizedDescriptionKey : errorText])
                completionHandler(result: nil, error: dataError, numPages: nil)
                return
            }
            
            print( "NumberOfPages \(numPages)")
            completionHandler(result: photoArray, error: nil, numPages: numPages)
        }
        
    }
    
    //MARK: General networking funcs
    
    func taskForGETMethod(parameters: [String : AnyObject], completionHandler: (result: AnyObject!, error: NSError?) -> Void) -> NSURLSessionDataTask {
        
        
        /* 2/3. Build the URL and configure the request */
        let urlString = const.BASE_URL + escapedParameters(parameters)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        /* 4. Make the request */
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            
            guard let _ = data else {
                print("Error: did not recieve data")
                let dataError =  NSError(domain: "taskForGetMethod", code: 0, userInfo: [NSLocalizedDescriptionKey : "no data recieved"])
                completionHandler(result: nil, error: dataError)
                return
            }
            
            guard downloadError == nil else {
                print("Error: \(downloadError?.localizedDescription)")
                completionHandler(result: nil, error: downloadError)
                return
            }
            
            // Success!
            FlickrClient.parseJSONWithCompletionHandler(data!, completionHandler: completionHandler)
        }
        
        /* 7. Start the request */
        task.resume()
        return task
    }
    
    
    func taskForGETImage(filePath: String, completionHandler: (success: Bool, imageData: NSData?, error: NSError?) ->  Void) -> NSURLSessionTask {
        
        // Set the parameters
        // 2/3. Build the URL and configure the request */
        let request =  NSMutableURLRequest(URL: NSURL(string: filePath)!)
        
        // 4. Make the request */
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            
            // 5/6. Parse the data and use the data (happens in completion handler)
            guard  downloadError == nil else {
                let newError = FlickrClient.errorForData(data, response: response, error: downloadError!)
                
                // print( response?.description)
                completionHandler(success: false, imageData: nil, error: newError)
                return
            }
            
            // Success!
            completionHandler(success: true, imageData: data, error: nil)
        }
        
        //  Start the request
        task.resume()
        return task
    }
    
    // MARK: - Helpers
    
    class func errorForData(data: NSData?, response: NSURLResponse?, error: NSError) -> NSError {
        
        if data == nil {
            return error
        }
        
        let  parsedResult: NSDictionary
        do {
            parsedResult = ((try? NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments)) as? [String : AnyObject])!
            
            if let status = parsedResult[jsonResponse.status] as? String {
                let msg = parsedResult[jsonResponse.msg] as? String
                if status == jsonRepsonseVals.failure {
                    let reasonForFailure: [NSObject: AnyObject] = [NSLocalizedDescriptionKey: msg!]
                    print("Error converting to json")
                    return NSError(domain: "errorForData", code: 0, userInfo: reasonForFailure  )
                    
                }
            }
        }catch error as NSError {
            print("Error converting to json")
            return error
            
        } catch {
            print("Error converting to json")
            return NSError(domain: "errorForData", code: 0, userInfo: [NSLocalizedDescriptionKey : "Error converting to json"])
        }
        
        guard let _ = parsedResult["msg"] as? String else {
            return NSError(domain: "errorForData", code: 0, userInfo: [NSLocalizedDescriptionKey : "Error: msg not found in parsed resut"])
        }
        return error
    }
    
    // Helper: Given raw JSON, return a usable Foundation object
    
    class func parseJSONWithCompletionHandler(data: NSData, completionHandler: (result: AnyObject!, error: NSError?) -> Void) {
        
        var parsedResult: AnyObject? = nil
        
        do {
            parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments)
            
        } catch let error as NSError {
            completionHandler(result: nil, error: error)
            return
            
        } catch {
            completionHandler( result: nil, error: NSError(domain: "parseJSONWithCompletionHandler", code: 0,
                userInfo: [NSLocalizedDescriptionKey : "Error: msg not found in parsed resut"])
            )
            return
        }
        
        completionHandler(result: parsedResult, error: nil)
        
    }
    
    /* Helper: Substitute the key for the value that is contained within the method name */
    class func subtituteKeyInMethod(method: String, key: String, value: String) -> String? {
        if method.rangeOfString("{\(key)}") != nil {
            return method.stringByReplacingOccurrencesOfString("{\(key)}", withString: value)
        } else {
            return nil
        }
    }
    
    /* Helper function: Given a dictionary of parameters, convert to a string for a url */
    func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        for (key, value) in parameters {
            
            /* Make sure that it is a string value */
            let stringValue = "\(value)"
            
            /* Escape it */
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            /* Append it */
            urlVars += [key + "=" + "\(escapedValue!)"]
        }
        
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }
    
    /* helper function: get last path component of URL */
    //
    func getLastPathComponent(fullPath: String) -> String {
        return ( fullPath as NSString).lastPathComponent
    }
    
    // MARK: - Shared Image Cache
    
    struct Caches {
        static let imageCache = ImageCache()
    }
    
    // MARK: - Shared Instance
    
    class func sharedInstance() -> FlickrClient {
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        return Singleton.sharedInstance
    }
    
    func fetchPhotosForLocation(location: Location, completionHandler: ((Void) -> (Void)) ) {
        print("fetchPhotosForLocation \(location)")
        
        FlickrClient.sharedInstance().getImageUrlsByLocation(location) {
            result, error, numPages in
            if result == nil {
                print("fetchPhotosForLocations returned nil")
                return
            }
            
            
            _ = result.map() { ( dictionary: [String : AnyObject]) -> Photo in
                // 1 - dictionary[Photo.Keys.location] = location // add location data to dict
                let photo = Photo(dictionary: dictionary, context: self.sharedContext())
                photo.location = location
                location.photos.addObject(photo)
                
                print("Location \(photo.location)")
                //CoreDataStackManager.sharedInstance().saveContext()
                
                FlickrClient.sharedInstance().taskForGETImage(photo.url!, completionHandler: {
                    success, imageData, error in
                    if success != true {
                        print("error extracting " + photo.url!)
                    } else {
                        dispatch_async(dispatch_get_main_queue()) {
                            photo.saveImage(UIImage(data: imageData!))
                            print("saved \(photo.location)" )
                            CoreDataStackManager.sharedInstance().saveContext()
                        } //end dispatch
                    }
                }) // end taskForGetImage
                return photo
            } // end result.map()
            
        }
    }
    
    func downloadImage(photo: Photo) {
        FlickrClient.sharedInstance().taskForGETImage(photo.url!, completionHandler: {
            success, imageData, error in
            if success != true {
                print("error extracting " + photo.url!)
            } else {
                photo.saveImage(UIImage(data: imageData!))
                print("saved \(photo.location)" )
                CoreDataStackManager.sharedInstance().saveContext()
            }
        }) // end taskForGetImage
    }
}


