//
//  heroAutocompleteStore.swift
//  AutocompleteTestProject
//
//  Created by Hugo Bosc-Ducros on 20/06/2019.
//  Copyright © 2019 Hugo Bosc-Ducros. All rights reserved.
//

import Foundation
import HBAutocomplete
import MapKit

class AutocompleteStore:HBAutocompleteStore {
    
    enum DataType:String {
        case hero = "Hero"
        case address = "Address"
        case place = "Place"
    }
    
    private let dataType:DataType
    
    init(_ dataType:DataType) {
        self.dataType = dataType
    }
    
    var userDefault = UserDefaults.standard
    var storageKey:String {
        return self.dataType.rawValue + "HistoryList"
    }
    
    var dataStorageKey:String {
        return self.dataType.rawValue + "DataDictionary"
    }
    
    var data:[String:MKMapItem]? {
        switch self.dataType {
        case .place:
            guard let data = userDefault.data(forKey: dataStorageKey),
                let datas = NSKeyedUnarchiver.unarchiveObject(with: data) as? [String:MKMapItem]
                else {return [String:MKMapItem]()}
            return datas
        default:
            return nil
        }
    }
    
    func getHistory() -> (suggestions: [String], dataDictionary: [String : Any]?) {
        let suggestions = (self.userDefault.object(forKey: self.storageKey) as? [String]) ?? [String]()
        switch self.dataType {
        case .hero, .address:
            return (suggestions, nil)
        case .place:
//            var dataDictionary:[String:MKMapItem]?
//            if let datas = self.data {
//                dataDictionary = datas
//            }
            return (suggestions,self.data)
        }
        
        
    }
    
    func updateDataHistory(for suggestion: String, newData: Any) {
        if var datas = self.data, let inputData = newData as? MKMapItem, datas.keys.contains(suggestion) {
            datas[suggestion] = inputData
            let updatesDatas = NSKeyedArchiver.archivedData(withRootObject: datas)
            userDefault.set(updatesDatas, forKey: dataStorageKey)
        }
        
    }
    
    func addToHistory(input: String, inputData: Any?) {
        var (list,_) = self.getHistory()
        if !list.contains(input) {
            list.append(input)
            self.userDefault.set(list, forKey: self.storageKey)
        }
        if let newData = inputData as? MKMapItem, var datas = self.data {
            datas[input] = newData
            let updatesDatas = NSKeyedArchiver.archivedData(withRootObject: datas)
            userDefault.set(updatesDatas, forKey: dataStorageKey)
        }
    }
    
    func cleanHistory() {
        self.userDefault.removeObject(forKey: self.storageKey)
    }
    
    
}
