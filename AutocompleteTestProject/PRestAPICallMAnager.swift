//
//  PRestAPICallMAnager.swift
//  AutocompleteTestProject
//
//  Created by Hugo Bosc-Ducros on 27/12/2016.
//  Copyright © 2016 Hugo Bosc-Ducros. All rights reserved.
//

import UIKit
import SystemConfiguration

let HTTP_ERROR_DOMAIN = "HTTP Error"
let API_ERROR_DOMAIN = "API Error"
let TIMEOUT_ERROR_DOMAIN = "TimeOut Error"

let HTTP_ERROR_MESSAGE_BEGININ = "An internal error has occurred\n(code ";
let HTTP_ERROR_MESSAGE_END = ")";
let HTTP_3000_ERROR_END_MESSAGE = "\nPlease try again";
let TIMEOUT_ERROR_MESSAGE = "Connection error, please try again";
let NETWORK_ERROR_MESSAGE = "Please check your internet connection";

let DEFAULT_TIMOUT:TimeInterval = 10


class PRestAPICallMAnager: NSObject {
    
    // MARK: - Any API call
    
    //Rest API Call for Any API (with API's URL in argument)
    class func APICall(
        _ callType:String,
        url:URL,
        postParams:[String: AnyObject]?,
        timeout:TimeInterval,
        accessToken:Bool,
        success: @escaping (_ jsonResponse:NSDictionary) -> Void,
        failure: @escaping (_ error:NSError) -> Void) {
        
        let session = URLSession.shared
        // Create the request
        let request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = callType
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = timeout
        
        if accessToken {
            //check if token is necessary in header
        }
        
        
        //put parameters in the body
        if postParams != nil {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: postParams!, options: JSONSerialization.WritingOptions())
                print(postParams as Any)
            } catch {
                print("bad things happened")
            }
            
        }
        // Make the POST call and handle it in a completion handler
        let task = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
            do {
                
                //let statusCode = (response as? NSHTTPURLResponse)!.statusCode
                if (error == nil) {
                    let jsonDictionary = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
                    var statusCode:Int = 0
                    if let myResponse = response as? HTTPURLResponse {
                        statusCode = myResponse.statusCode
                    }
                    //cast JSON response to NSDictionary for parsing in any kind of object
                    if (statusCode >= 200 && statusCode <= 206) {
                        DispatchQueue.main.async {
                            //print("response : \(jsonDictionary)")
                            success(jsonDictionary)
                        }
                    } else {
                        print("HTTP error")
                        //build and return HTTP error
                        if let HTTPError:NSError = self.buildHTTPError(response!) {
                            DispatchQueue.main.async(execute: {
                                failure(HTTPError)
                            })
                        }
                    }
                } else {
                    print("bad things happened in post, oftenly timout")
                    if let errorNS:NSError = error as NSError? {
                        if (errorNS.code == -1001) {
                            let timeOutError = NSError(domain: TIMEOUT_ERROR_DOMAIN, code: errorNS.code, userInfo: [NSLocalizedDescriptionKey : TIMEOUT_ERROR_MESSAGE])
                            DispatchQueue.main.async {
                                failure(timeOutError)
                            }
                        } else {
                            DispatchQueue.main.async {
                                failure(errorNS)
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            failure(self.buildUnknowError())
                        }
                    }
                }
            } catch {
                print("HTTP error")
                //build and return HTTP error
                if response != nil {
                    let HTTPError:NSError = self.buildHTTPError(response)!
                    DispatchQueue.main.async {
                        failure(HTTPError)
                    }
                } else if let localError:NSError = self.buildErrorWithErrorType((error)) {
                    DispatchQueue.main.async {
                        failure(localError)
                    }
                } else {
                    DispatchQueue.main.async {
                        failure(self.buildUnknowError())
                    }
                }
            }
        })
        task.resume()
    }
    
    //build swift error with HTTP error
    class func buildHTTPError (_ response :URLResponse?) -> NSError? {
        if response != nil {
            let statusCode = (response as? HTTPURLResponse)!.statusCode
            let description = HTTP_ERROR_MESSAGE_BEGININ + "\(statusCode)" + HTTP_ERROR_MESSAGE_END
            return NSError(domain: HTTP_ERROR_DOMAIN, code: statusCode, userInfo: [NSLocalizedDescriptionKey : description])
        }
        return nil
    }
    
    class func buildUnknownHTTPError(_ error:NSError?) -> NSError? {
        if error != nil {
            let statusCode:Int = error!.code
            let description = HTTP_ERROR_MESSAGE_BEGININ + "\(statusCode)" + HTTP_ERROR_MESSAGE_END
            return NSError(domain: HTTP_ERROR_DOMAIN, code: statusCode, userInfo: [NSLocalizedDescriptionKey : description])
        }
        return nil
    }
    
    class func buildErrorWithErrorType(_ error:Error?) -> NSError? {
        if error != nil {
            let statusCode:Int = 3000
            let description = HTTP_ERROR_MESSAGE_BEGININ + "\(statusCode)" + HTTP_ERROR_MESSAGE_END + HTTP_3000_ERROR_END_MESSAGE
            return NSError(domain: HTTP_ERROR_DOMAIN, code: statusCode, userInfo: [NSLocalizedDescriptionKey : description])
        }
        return nil
    }
    
    class func buildUnknowError() -> NSError {
        let statusCode:Int = 3000
        let description = HTTP_ERROR_MESSAGE_BEGININ + "\(statusCode)" + HTTP_ERROR_MESSAGE_END + HTTP_3000_ERROR_END_MESSAGE
        return NSError(domain: HTTP_ERROR_DOMAIN, code: statusCode, userInfo: [NSLocalizedDescriptionKey : description])
    }

}
