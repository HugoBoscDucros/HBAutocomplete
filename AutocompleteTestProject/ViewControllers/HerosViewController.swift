//
//  HerosViewController.swift
//  AutocompleteTestProject
//
//  Created by Hugo Bosc-Ducros on 29/12/2016.
//  Copyright © 2016 Hugo Bosc-Ducros. All rights reserved.
//

import UIKit
import HBAutocomplete

class HerosViewController: UIViewController {
    
        
    @IBOutlet weak var autocompleteView: UIView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var addToHistoryView: UIView!
    @IBOutlet weak var addToHistoryTextField: UITextField!
    var autocomplete:HBAutocomplete!
    var dataSource = HeroAutocompleteDataSource()

    
//MARK: - ViewController life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setAutocomplete()
        self.setGraphicalSettings()
    }
    
    
//MARK: - Settings
    
    func setGraphicalSettings() {
        self.title = "Hero"
        self.autocompleteView.textFieldSuperViewStyle()
        self.addToHistoryView.textFieldSuperViewStyle()
    }
    
    func setAutocomplete() {
        //required
        self.autocomplete = HBAutocomplete(textField, templateView: autocompleteView)
        self.autocomplete.dataSource = dataSource
        //optionnal
        self.autocomplete.maxVisibleRow = 7
        self.autocomplete.minCharactersforDataSource = 0
        self.autocomplete.historicalImage = UIImage(named: "SearchHistory")
        self.autocomplete.store = AutocompleteStore(.hero)
    }
    
    
//MARK: - Actions
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.textField.resignFirstResponder()
    }
    
    
    @IBAction func addToHistoryButtonTapped(_ sender: Any) {
        if let text = self.addToHistoryTextField.text, !text.isEmpty {
             self.autocomplete.addToHistory(input: text, inputData: nil)
        }
    }
    
    @IBAction func cleanHistoryButtonDidTapped(_ sender: Any) {
        self.autocomplete.cleanHistory()
    }

}

extension UIView {
    func textFieldSuperViewStyle() {
        self.layer.cornerRadius = 5.0
        self.layer.borderColor = UIColor.lightGray.cgColor
        self.layer.borderWidth = 1
    }
}
