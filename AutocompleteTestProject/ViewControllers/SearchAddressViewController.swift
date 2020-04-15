//
//  SearchAddressViewController.swift
//  AutocompleteTestProject
//
//  Created by Hugo Bosc-Ducros on 21/06/2019.
//  Copyright © 2019 Hugo Bosc-Ducros. All rights reserved.
//

import UIKit
import HBAutocomplete
import MapKit

class SearchAddressViewController: UITableViewController, HBAutoCompleteActionsDelegate {
    
    
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
        self.autocomplete.store = AutocompleteStore(.place)
        self.autocomplete.historicalImage = UIImage(named: "SearchHistory")
        searchController.searchBar.placeholder = "Search an address"
        definesPresentationContext = false
        searchController.searchBar.showsCancelButton = false
        searchController.obscuresBackgroundDuringPresentation = false
        self.tableView.tableFooterView = UIView()
        self.autocomplete.actionsDelegate = self
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.searchController.searchBar.resignFirstResponder()
    }
    
    
    //MARK: - Autocomplete Action delegate
    
    func didSelect(autocomplete: HBAutocomplete, index: Int, suggestion: String, data: Any?) {
        if self.autocomplete.selectedData is MKMapItem {
            self.performSegue(withIdentifier: "MapSegue", sender: self)
            self.autocomplete.addToHistory()
        }
    }
    
    func didSelectCustomAction(autocomplete: HBAutocomplete, index: Int) {
        //Do something
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "MapSegue", let item = self.autocomplete.selectedData as? MKMapItem, let mapVC = segue.destination as? MapViewController {
            mapVC.mapItem = item
        }
    }
    

}
