//
//  HeroAutocompleteDataSource.swift
//  AutocompleteTestProject
//
//  Created by Hugo Bosc-Ducros on 20/06/2019.
//  Copyright © 2019 Hugo Bosc-Ducros. All rights reserved.
//

import Foundation
import HBAutoComplete

class HeroAutocompleteDataSource:HBAutocompleteDataSource {
    
    var heroList:[String] = ["Batman","Catwoman", "Flash", "Spiderman", "Superman", "Zoro" ]
    
    func getSuggestions(autocomplete: HBAutocomplete, input: String, completionHandler: @escaping ([String], [String : Any]?, [String : UIImage]?) -> Void) {
        completionHandler(self.filteredList(for: input), nil, nil)
    }
    
    private func filteredList(for input:String) -> [String] {
        var list = [String]()
        for hero in heroList {
            if hero.lowercased().contains(input.lowercased()) {
                list.append(hero)
            }
        }
        return list
    }
    
}