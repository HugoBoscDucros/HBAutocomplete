//
//  AddressAutocompleteDataSource.swift
//  AutocompleteTestProject
//
//  Created by Hugo Bosc-Ducros on 24/06/2019.
//  Copyright © 2019 Hugo Bosc-Ducros. All rights reserved.
//

import Foundation
import HBAutocomplete
import MapKit

class PlaceAutocompleteDataSource: HBAutocompleteDataSource {
    

    func getSuggestions(autocomplete: HBAutocomplete, input: String, completionHandler: @escaping ([String], [String : Any]?, [String : UIImage]?) -> Void) {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = input
        let search = MKLocalSearch(request: searchRequest)
        search.start { response, error in
            guard let response = response else {
                print("Error: \(error?.localizedDescription ?? "Unknown error").")
                completionHandler([String](),nil,nil)
                return
            }
            var suggestions = [String]()
            var mapItemDictionary = [String:MKMapItem]()
            for item in response.mapItems {
                if let name = item.name {
                    mapItemDictionary[name] = item
                    suggestions.append(name)
                }
            }
            completionHandler(suggestions,mapItemDictionary,nil)
        }
    }
    
}
