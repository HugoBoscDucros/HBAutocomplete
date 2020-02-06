//
//  ViewController.swift
//  AutocompleteTestProject
//
//  Created by Hugo Bosc-Ducros on 27/12/2016.
//  Copyright © 2016 Hugo Bosc-Ducros. All rights reserved.
//

import UIKit
import CoreLocation
import HBAutocomplete
import MapKit

let GOOGLE_PLACE_API_KEY = ""
let GOOGLE_PLACE_DEFAULT_LOCATION = "48.8567,2.3508"

class AddressViewController: UIViewController, /*HBAutocompleteDataSource,*/ HBAutoCompleteActionsDelegate {
    
    @IBOutlet weak var autocompleteView: UIView!
    @IBOutlet weak var textField: UITextField!

    @IBOutlet weak var addToHistoryButton: UIButton!
    
    var autocomplete:HBAutocomplete!
    var dataSource = AddressAutocompleteDataSource()

//MARK: - viewController life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setAutocomplete()
        self.setGraphicalSettings()
    }


//MARK: - Settings
    
    func setGraphicalSettings() {
        self.title = "Adress"
        self.addToHistoryButton.layer.cornerRadius = 5.0
        self.autocompleteView.layer.cornerRadius = 5.0
        self.autocompleteView.layer.borderColor = UIColor.lightGray.cgColor
        self.autocompleteView.layer.borderWidth = 1
    }
    
    func setAutocomplete() {
        //required
        self.autocomplete = HBAutocomplete(textField, templateView: autocompleteView)
        self.autocomplete.dataSource = dataSource
        self.autocomplete.store = AutocompleteStore(.address)
        //optionnal
        self.autocomplete.maxVisibleRow = 7
        self.autocomplete.minCharactersforDataSource = 2
        self.autocomplete.historicalImage = UIImage(named:"SearchHistory")!
        self.autocomplete.actionsDelegate = self
        self.autocomplete.setCustomeActions(descriptions: ["Current location"], images: [UIImage(named: "CurrentLocation")!])
        //self.autocomplete.customActionsDescription = ["Current location"]
        //self.autocomplete.customActionsImageName = ["CurrentLocation"]
    }
    
    
//MARK: - Actions
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.textField.resignFirstResponder()
    }
    
    @IBAction func addToHistoryButtonTapped(_ sender: Any) {
        if let text = self.textField.text, text != "" {
            self.autocomplete.addToHistory()
        }
    }

    
//MARK: - HBAutocomplete dataSource (required)
    
//    func getSuggestions(autocomplete: HBAutocomplete, input: String, completionHandler: @escaping ([String], [String : Any]?, [String : UIImage]?) -> Void) {
//        GoogleAPI.AutocompleteSuggestionsFromDefaultLocation(input) { (suggestions, places) in
//            completionHandler(suggestions, places, nil)
//        }
//    }
    
    
//MARK: - HBAutocomplete actions delegate
    
    func didSelect(autocomplete: HBAutocomplete, index: Int, suggestion: String, data: Any?) {
//        if let place = data as? Place {
//            print(place.placeId)
//        }
    }
    
    func didSelectCustomAction(autocomplete: HBAutocomplete, index: Int) {
        if index == 0 {
            self.textField.text = "success"
        }
    }
    
}
