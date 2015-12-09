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
    var foundPhotos: [SimplePhoto]   = []
    
    // MARK: - Shared Instance
    class func sharedInstance() -> FlickrClient {
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        return Singleton.sharedInstance
    }

    override init() {
        super.init()
        session = NSURLSession.sharedSession()
    }
    
    
    func getImagesByLocation(lat: Double, long: Double, completionHandler: (success: Bool, error: NSError?) -> Void)
    {
        
        let bbox = BoundingBox()
        let bboxStr = bbox.GetBoundingBox(Location(Latitude: lat, Longitude: long), halfSideInKm: 20.0)
        print(bboxStr)
        let methodArguments: [String: AnyObject] = [
            methodParameters.method: const.PHOTO_SEARCH,
            methodParameters.api_key: const.API_KEY,
            methodParameters.extras: const.EXTRAS,
            methodParameters.format: const.DATA_FORMAT,
            methodParameters.noJsonCallback: const.NO_JSON_CALLBACK,
            //methodParameters.bbox: bboxStr,
            "lat" : lat,
            "lon" : long,
            methodParameters.page: 1,
            methodParameters.perPage: 21
        ]
        //TODO:
        print("methodargs \(methodArguments.count)")
        
        self.taskForGETMethod(methodArguments){ JSONResult, error in
            
            guard error == nil else {
                print(error)
                completionHandler(success: false, error: error)
                return
            }
            
            
            let domainText = "getImagesByLocation"
            guard let photosDictionary = JSONResult.valueForKey(jsonResponse.photos) as? NSDictionary else {
                let errorText = "Cant find key 'photo' in photosDictionary"
                print("\(errorText)")
                
                if let dict = JSONResult as? NSDictionary {
                    for x in dict {
                        print(x)
                    }
                }
                
                let dataError = NSError(domain: domainText, code: 0, userInfo: [NSLocalizedDescriptionKey : errorText])
                //FlickrClient.errorForData(data: nil, response: jsonResponse, error: dataError)
                
                completionHandler(success: false, error: dataError)
                return
            }
            
            guard let photoArray = photosDictionary.valueForKey(jsonResponse.photo) as? [[String: AnyObject]] else {
                let errorText = "Cant find key 'photo' in photosDictionary"
                print("\(errorText)")
                let dataError = NSError(domain: domainText, code: 0, userInfo: [NSLocalizedDescriptionKey : errorText])
                completionHandler(success: false, error: dataError)
                return
            }
            
            guard let numPages = photosDictionary[jsonResponse.pages] as? Int else {
                let errorText = "Cant find key number of pages"
                print("\(errorText)")
                let dataError = NSError(domain: domainText, code: 0, userInfo: [NSLocalizedDescriptionKey : errorText])
                completionHandler(success: false, error: dataError)
                return
            }
            
            for photo in photoArray {
                
                let photoUrl = photo[jsonResponse.imageType] as! String
                self.taskForGETImage(photoUrl, completionHandler: {
                    success, imageData, error in
                    
                    if success != true {
                        print("error extracting " + photoUrl )
                    } else {
                        
                        var thisPhoto = SimplePhoto(titleOfPhoto: "", image: UIImage(data: imageData!)!, location: Location(Latitude: lat, Longitude: long))
                        self.foundPhotos.append(thisPhoto)
                        print("found Photos \(self.foundPhotos.count)" )
                    }
                }) // endTaskGetImage
            } // end for
        } // endTaskForGetMethod
        completionHandler(success: true, error: nil)
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
    
    
    func taskForGETImage(filePath: String, completionHandler: (success: Bool, imageData: NSData?, error: NSError?) ->  Void) -> NSURLSessionTask {
        
        /* 1. Set the parameters */
        // There are none...
        
        /* 2/3. Build the URL and configure the request */
        let request =  NSMutableURLRequest(URL: NSURL(string: filePath)!)
        
        /* 4. Make the request */
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            
            /* 5/6. Parse the data and use the data (happens in completion handler) */
            guard  downloadError == nil else {
                let newError = FlickrClient.errorForData(data, response: response, error: downloadError!)
                
               // print( response?.description)
                completionHandler(success: false, imageData: nil, error: newError)
                return
            }
            
            // Success!
            completionHandler(success: true, imageData: data, error: nil)
        }
        
        /* 7. Start the request */
        task.resume()
        return task
    }
    
    //----------------------------------------------------------------------------------------------------
    // MARK: - Helpers
    
    /* Helper: Given a response with error, see if a status_message is returned, otherwise return the previous error */
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
    
}


