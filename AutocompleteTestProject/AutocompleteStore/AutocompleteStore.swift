//
//  heroAutocompleteStore.swift
//  AutocompleteTestProject
//
//  Created by Hugo Bosc-Ducros on 20/06/2019.
//  Copyright © 2019 Hugo Bosc-Ducros. All rights reserved.
//

import Foundation
import HBAutoComplete

class AutocompleteStore:HBAutocompleteStore {
    
    enum DataType:String {
        case hero = "Hero"
        case address = "Address"
    }
    
    private let dataType:DataType
    
    init(_ dataType:DataType) {
        self.dataType = dataType
    }
    
    var userDefault = UserDefaults.standard
    var storageKey:String {
        return self.dataType.rawValue + "HistoryList"
    }
    
    func getHistory() -> (suggestions: [String], dataDictionary: [String : Any]?) {
        let suggestions = (self.userDefault.object(forKey: self.storageKey) as? [String]) ?? [String]()
        return (suggestions, nil)
    }
    
    func updateDataHistory(for suggestion: String, newData: Any) {
        //
    }
    
    func addToHistory(input: String, inputData: Any?) {
        var (list,_) = self.getHistory()
        list.append(input)
        self.userDefault.set(list, forKey: self.storageKey)
    }
    
    func cleanHistory() {
        self.userDefault.removeObject(forKey: self.storageKey)
    }
    
    
}
