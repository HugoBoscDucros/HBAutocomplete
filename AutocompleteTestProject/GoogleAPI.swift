//
//  GoogleAPI.swift
//  AutocompleteTestProject
//
//  Created by Hugo Bosc-Ducros on 27/12/2016.
//  Copyright © 2016 Hugo Bosc-Ducros. All rights reserved.
//

import UIKit
import CoreLocation

let GOOGLE_API_ROOT_PATH = "https://maps.googleapis.com/maps/api/"
let GOOGLE_PLACE_API_AUTOCOMPLETE_PATH = "place/autocomplete/"
let GOOGLE_MAP_API_DIRECTION = "directions/json"
let GOOGLE_GEOCODE_API = "geocode/json"
let GOOGLE_PLACE_DETAILS = "place/details/json"

let FAILED_GET_USER_LOCATION = "Failed getting user location"

//put your google place API key here
//let GOOGLE_PLACE_API_KEY = ""

//put a default location for autocomplete searching if needed (google place API take your IP address in reference in priority)
//let GOOGLE_PLACE_DEFAULT_LOCATION = "48.8567,2.3508" //here is the center of Paris

//Set your language
let APP_LANGUAGE = "en"

class Place: NSObject, NSCoding {
    
    var addressDescription: String = ""
    var location:String = ""
    var placeId:String = ""
    
    convenience required init?(coder aDecoder: NSCoder) {
        let addressDescription = aDecoder.decodeObject(forKey: "addressDescription") as! String
        let location = aDecoder.decodeObject(forKey: "location") as! String
        let placeId = aDecoder.decodeObject(forKey: "placeId") as! String
        self.init(description: addressDescription, placeId: placeId, location: location)
    }
    
    init(description:String, placeId:String, location:String = "") {
        super.init()
        self.addressDescription = description
        self.placeId = placeId
        self.location = location
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(addressDescription, forKey: "addressDescription")
        aCoder.encode(location, forKey: "location")
        aCoder.encode(placeId, forKey: "placeId")
    }
    
    
}

class GoogleAPI: NSObject {
    
    // MARK: - Place/AutoComplete, ask for adresses autocomplete.
    
    class func AutocompleteSuggestionsFromDefaultLocation(
        _ input:String,
        completionHandler:@escaping (_ suggestions:[String], _ data:NSDictionary) -> Void) {
        
        //make URL path
        let url = GoogleAPI.makeAutocompleteURLForAPICall(input, language: nil, location: nil, radius:nil)
        var suggestions:[String] = []
        let places = NSMutableDictionary()
        
        //make API call
        PRestAPICallMAnager.APICall("GET", url: url, postParams: nil, timeout: DEFAULT_TIMOUT, accessToken: false, success: { (jsonResponse) -> Void in
            print(jsonResponse)
            if let suggestionsArray = jsonResponse["predictions"] as? NSArray {
                for value in suggestionsArray {
                    if let valueDictionary = value as? NSDictionary {
                        if let description = valueDictionary["description"] as? String, let placeId = valueDictionary["place_id"] as? String {
                            suggestions.append(description)
                            let place = Place(description: description, placeId: placeId)
                            //places[description] = place
                            places.setValue(place, forKey: description)
                        }
                    }
                }
                DispatchQueue.main.async {
                    completionHandler(suggestions,places)
                }
            }
        }) { (error) -> Void in
            print(error.localizedDescription)
        }
    }
    
    class func makeAutocompleteURLForAPICall(
        _ input:String,
        language:String?,
        location:String?,
        radius:String?) -> URL {
        
        let myLocation:String
        let myLanguage:String
        let myRadius:String
        
        if location == nil {
            myLocation = GOOGLE_PLACE_DEFAULT_LOCATION
        } else {
            myLocation = location!
        }
        if language == nil {
            myLanguage = APP_LANGUAGE
        } else {
            myLanguage = language!
        }
        if radius == nil {
            myRadius = "75000"
        } else {
            myRadius = radius!
        }
        let stringURL = "\(GOOGLE_API_ROOT_PATH)\(GOOGLE_PLACE_API_AUTOCOMPLETE_PATH)json?input=\(input)&location=\(myLocation)&radius=\(myRadius)&language=\(myLanguage)&key=\(GOOGLE_PLACE_API_KEY)"
        let UTF8URL = stringURL.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
        let url = URL(string:UTF8URL!)
        print("url : \(url!)")
        return url!
    }
    
    // MARK: - Map, ask for routes.
    
    class func requestForRoute(
        _ location1_Latitude:Double,
        location1_Longitude:Double,
        location2_latitude:Double,
        location2_Longitude:Double,
        success:@escaping (_ routePath:String) -> Void,
        failure:@escaping (_ error:NSError) -> Void) {
        
        
        PRestAPICallMAnager.APICall("GET", url:GoogleAPI.makeDirectionURLForAPICall(location1_Latitude, location1_Longitude: location1_Longitude, location2_latitude: location2_latitude, location2_Longitude: location2_Longitude) , postParams: nil, timeout: DEFAULT_TIMOUT, accessToken: false, success: { (jsonResponse) -> Void in
            let routes = jsonResponse["routes"] as! NSArray
            if let route = (routes.lastObject as? NSDictionary) {
                let routePathJSON = (route["overview_polyline"] as! NSDictionary)["points"] as! String
                success(routePathJSON)
            }
        }) { (error) -> Void in
            failure(error)
        }
        
    }
    
    class func makeDirectionURLForAPICall(
        _ location1_Latitude:Double,
        location1_Longitude:Double,
        location2_latitude:Double,
        location2_Longitude:Double) -> URL {
        let stringURL = "\(GOOGLE_API_ROOT_PATH)\(GOOGLE_MAP_API_DIRECTION)?origin=\(location1_Latitude),\(location1_Longitude)&destination=\(location2_latitude),\(location2_Longitude)&mode=walking&units=metric&sensor=true&key=\(GOOGLE_PLACE_API_KEY)"
        //
        print("url : \(stringURL)")
        return URL(string: stringURL)!
    }
    
    
    
    // MARK: - Geocoding (reverse), ask for address with geolocation.
    
    class func requestForReverseGeocoding(
        _ latitude:Double,
        longitude:Double,
        success:@escaping (_ address:String) -> Void,
        failure:@escaping (_ errorMessage:String) -> Void) {
        
        PRestAPICallMAnager.APICall("GET", url: GoogleAPI.makeReverseGeocodingUrlForAPICall(latitude, longitude: longitude), postParams: nil, timeout: DEFAULT_TIMOUT, accessToken: false, success: { (jsonResponse) -> Void in
            if jsonResponse["status"] as! String == "OK" {
                let resultArray = jsonResponse["results"] as! NSArray
                let firstResultContent = resultArray.firstObject as! NSDictionary
                let address = firstResultContent["formatted_address"] as! String
                success(address)
            } else {
                failure(FAILED_GET_USER_LOCATION)
            }
        }) { (error) -> Void in
            failure(FAILED_GET_USER_LOCATION)
        }
    }
    
//    class func requestForGeocoding(address:String,
//                                   success:@escaping (_ latitude:String, _ longitude:String) -> Void,
//                                   failure:@escaping (_ errorMessage:String) -> Void) {
//        
//    }
    
    class func makeReverseGeocodingUrlForAPICall(_ latitude:Double,longitude:Double) -> URL {
        let stringURL = "\(GOOGLE_API_ROOT_PATH)\(GOOGLE_GEOCODE_API)?latlng=\(latitude),\(longitude)&language=\(APP_LANGUAGE)&key=\(GOOGLE_PLACE_API_KEY)"
        return URL(string: stringURL)!
    }

}
