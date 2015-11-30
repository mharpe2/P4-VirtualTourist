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

class FlickrClient: NSObject {
    
    // Session
    var session: NSURLSession!
    
    override init() {
        super.init()
        session = NSURLSession.sharedSession()
    }
    
    
    func getImagesByLocation(lat: Double, long: Double, completionHandler: (success: Bool, error: NSError?) -> Void)
    {
        
    }
    
    // gets a random image of people sleeping in the library
    // TODO: Delete this code
    func getImage(completionHandler: (result: AnyObject!, error: NSError?) -> Void  )  {
        
        let methodArguments = [
            methodParameters.method: const.GETPHOTOS,
            methodParameters.api_key: const.API_KEY,
            methodParameters.galleryId: "5704-72157622566655097",
            methodParameters.extras: const.EXTRAS,
            methodParameters.format: const.DATA_FORMAT,
            methodParameters.noJsonCallback: const.NO_JSON_CALLBACK
        ]
        
       self.taskForGETMethod(methodArguments){ JSONResult, error in
            
            /*guard  let _error = error where error != nil else {
            print(error)
            completionHandler(result: nil, error: error)
            return
            }
            */
            
            guard let photosDictionary = JSONResult.valueForKey("photos") as? NSDictionary else {
                let errorText = "Cant find key 'photo' in photosDictionary"
                print("\(errorText)")
                
                let dataError = NSError(domain: "getImage", code: 0, userInfo: [NSLocalizedDescriptionKey : errorText])
                completionHandler(result: nil, error: dataError)
                return
            }
            
            guard let photoArray = photosDictionary.valueForKey("photo") as? [[String: AnyObject]] else {
                let errorText = "Cant find key 'photo' in photosDictionary"
                print("\(errorText)")
                let dataError = NSError(domain: "getImage", code: 0, userInfo: [NSLocalizedDescriptionKey : errorText])
                completionHandler(result: nil, error: dataError)
                return
            }
            
            /* 6 - Grab a single, random image */
            let randomPhotoIndex = Int(arc4random_uniform(UInt32(photoArray.count)))
            let photoDictionary = photoArray[randomPhotoIndex] as [String: AnyObject]
            
            /* 7 - Get the image url and title */
            let photoTitle = photoDictionary["title"] as? String
            let imageUrlString = photoDictionary["url_m"] as? String
            let imageURL = NSURL(string: imageUrlString!)
            
            /* 8 - If an image exists at the url, set the image and title */
            guard let imageData = NSData(contentsOfURL: imageURL!)  else {
                let errorText = "Image does not exist at \(imageURL)"
                print("\(errorText)")
                let dataError = NSError(domain: "getImage", code: 0, userInfo: [NSLocalizedDescriptionKey : errorText])
                completionHandler(result: nil, error: dataError)
                return
            }
            
            let photo = SimplePhoto(titleOfPhoto: photoTitle!, image: UIImage(data: imageData)!)
            completionHandler(result: photo, error: nil)
            return
        }
    }
    
    //MARK: General networking funcs
    
    func taskForGETMethod(parameters: [String : AnyObject], completionHandler: (result: AnyObject!, error: NSError?) -> Void) -> NSURLSessionDataTask {
        
        /* 1. Set the parameters */
        //var mutableParameters = parameters
        //mutableParameters[ParameterKeys.ApiKey] = FlickrC
        
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
    
    
    func taskForGETImage(filePath: String, completionHandler: (imageData: NSData?, error: NSError?) ->  Void) -> NSURLSessionTask {
        
        /* 1. Set the parameters */
        // There are none...
        
        /* 2/3. Build the URL and configure the request */
        let request =  NSMutableURLRequest(URL: NSURL(fileURLWithPath: filePath) )
        
        /* 4. Make the request */
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            
            /* 5/6. Parse the data and use the data (happens in completion handler) */
            guard  downloadError == nil else {
                let newError = FlickrClient.errorForData(data, response: response, error: downloadError!)
                completionHandler(imageData: nil, error: newError)
                return
            }
            
            // Success!
            completionHandler(imageData: data, error: nil)
        }
        
        /* 7. Start the request */
        task.resume()
        return task
    }
    
    //----------------------------------------------------------------------------------------------------
    // MARK: - Helpers
    
    /* Helper: Given a response with error, see if a status_message is returned, otherwise return the previous error */
    class func errorForData(data: NSData?, response: NSURLResponse?, error: NSError) -> NSError {
        
        let  parsedResult: NSDictionary
        
        do {
            parsedResult = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments) as! [String : AnyObject]
            
        } catch error as NSError {
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
    
    /* Helper: Given raw JSON, return a usable Foundation object */
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
    
    // MARK: - Shared Instance
    class func sharedInstance() -> FlickrClient {
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        return Singleton.sharedInstance
    }
}


// Bounding Box

struct BoundingBox {
    var lowerLeftLongitude: Double
    var lowerLeftLatitude: Double
    var upperRightLongitude: Double
    var upperRightLatitude: Double
    
    // create bounding box
    init(longitude: Double, latitude: Double, span: Double) {
        self.lowerLeftLatitude = max(latitude - span, -90)
        self.lowerLeftLongitude = max(longitude - span, -180)
        self.upperRightLongitude = min(longitude + span, 180)
        self.upperRightLatitude = min(latitude + span, 90)
        
    }
    
    func toString() -> String {
        return ("\(lowerLeftLongitude), \(lowerLeftLatitude), \(upperRightLongitude), \(upperRightLatitude)")
    }
}

