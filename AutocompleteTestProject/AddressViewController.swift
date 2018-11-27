//
//  ViewController.swift
//  AutocompleteTestProject
//
//  Created by Hugo Bosc-Ducros on 27/12/2016.
//  Copyright © 2016 Hugo Bosc-Ducros. All rights reserved.
//

import UIKit
import CoreLocation

let GOOGLE_PLACE_API_KEY = ""
let GOOGLE_PLACE_DEFAULT_LOCATION = "48.8567,2.3508"

class AddressViewController: UIViewController, HBAutocompleteDataSource, HBAutoCompleteActionsDelegate {
    
    @IBOutlet weak var autocomplete: HBAutocompleteView!
    
    @IBOutlet weak var addToHistoryButton: UIButton!

//MARK: - viewController life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        //self.autocomplete.removeHistory()
        self.setGraphicalSettings()
        self.setAutocomplete()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


//MARK: - Settings
    
    func setGraphicalSettings() {
        self.title = "Search an adress"
        self.addToHistoryButton.layer.cornerRadius = 5.0
        self.autocomplete.layer.cornerRadius = 5.0
        self.autocomplete.layer.borderColor = UIColor.lightGray.cgColor
        self.autocomplete.layer.borderWidth = 1
    }
    
    func setAutocomplete() {
        //required
        self.autocomplete.dataSource = self
        //optionnal
        self.autocomplete.maxVisibleRow = 7
        self.autocomplete.minCharactersforDataSource = 2
        self.autocomplete.historicalImageName = "SearchHistory"
        self.autocomplete.actionsDelegate = self
        self.autocomplete.withCustomActions = true
        self.autocomplete.customActionsDescription = ["Current location"]
        self.autocomplete.customActionsImageName = ["CurrentLocation"]
    }
    
    
//MARK: - Actions
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.autocomplete.textField.resignFirstResponder()
    }
    
    @IBAction func addToHistoryButtonTapped(_ sender: Any) {
        if self.autocomplete.textField.text != nil && self.autocomplete.textField.text != "" {
            //self.autocomplete.addToSearchHistory(self.autocomplete.textField.text!)
            self.autocomplete.addToHistory(self.autocomplete.textField.text!)//, inputData: self.autocomplete.selectedData)
        }
    }

    
//MARK: - HBAutocomplete dataSource (required)
    
    func getSuggestions(autocomplete: HBAutocompleteView, input: String, completionHandler: @escaping ([String], NSDictionary?) -> Void) {
        GoogleAPI.AutocompleteSuggestionsFromDefaultLocation(input) { (suggestions, places) in
            completionHandler(suggestions, places)
        }
    }
    
    
//MARK: - HBAutocomplete actions delegate
    
    func didSelectCustomAction(autocomplete: HBAutocompleteView, index: Int) {
        if index == 0 {
            self.autocomplete.textField.text = "success"
        }
    }
    
    func didSelect(autocomplete: HBAutocompleteView, suggestion: String, data: Any?) {
        if let place = data as? Place {
            print(place.placeId)
        }
    }
    
}

