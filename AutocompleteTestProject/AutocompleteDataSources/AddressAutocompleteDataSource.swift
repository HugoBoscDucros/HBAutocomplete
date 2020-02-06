//
//  PlaceAutocompleteDataSource.swift
//  AutocompleteTestProject
//
//  Created by Hugo Bosc-Ducros on 20/06/2019.
//  Copyright © 2019 Hugo Bosc-Ducros. All rights reserved.
//

import Foundation
import HBAutocomplete
import MapKit

class AddressAutocompleteDataSource:NSObject,HBAutocompleteDataSource, MKLocalSearchCompleterDelegate {
    
    let requestCompleter = MKLocalSearchCompleter()
    
    override init() {
        super.init()
        self.requestCompleter.delegate = self
    }
    
    var completion:(([String])-> ())?
    
    
    func getSuggestions(autocomplete: HBAutocomplete, input: String, completionHandler: @escaping ([String], [String : Any]?, [String : UIImage]?) -> Void) {
        self.serachRequest(input) { addresses in
            completionHandler(addresses,nil,nil)
        }
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let addressList = completer.results.map({$0.title})
        self.completion?(addressList)
        self.completion = nil
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        self.completion?([String]())
        self.completion = nil
    }
    
    private func serachRequest(_ input:String, completion: @escaping ([String])-> ()) {
        self.completion = completion
        requestCompleter.queryFragment = input
    }
    
    
}
