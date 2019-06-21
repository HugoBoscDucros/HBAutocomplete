//
//  SearchAddressViewController.swift
//  AutocompleteTestProject
//
//  Created by Hugo Bosc-Ducros on 21/06/2019.
//  Copyright © 2019 Hugo Bosc-Ducros. All rights reserved.
//

import UIKit
import HBAutoComplete

class SearchAddressViewController: UITableViewController {
    
    var searchController = UISearchController(searchResultsController: nil)
    var autocomplete: HBAutocomplete!
    var autocompleteDataSource = PlaceAutocompleteDataSource()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.loadSettings()
    }
    

    private func loadSettings() {
        if #available(iOS 11.0, *) {
            self.navigationItem.largeTitleDisplayMode = .automatic
            self.navigationItem.searchController = searchController
            self.navigationItem.hidesSearchBarWhenScrolling = false
            self.navigationItem.searchController?.hidesNavigationBarDuringPresentation = false
        } else {
            // Fallback on earlier versions
        }
        
        self.autocomplete = HBAutocomplete(self.searchController.searchBar, tableView: self.tableView)
        self.autocomplete.dataSource = self.autocompleteDataSource
        self.autocomplete.store = AutocompleteStore(.address)
        self.autocomplete.historicalImage = UIImage(named: "SearchHistory")
        searchController.searchBar.placeholder = "Search an address"
        definesPresentationContext = false
        searchController.searchBar.showsCancelButton = false
        searchController.obscuresBackgroundDuringPresentation = false
        self.tableView.tableFooterView = UIView()
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.searchController.searchBar.resignFirstResponder()
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
