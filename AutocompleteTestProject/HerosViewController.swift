//
//  HerosViewController.swift
//  AutocompleteTestProject
//
//  Created by Hugo Bosc-Ducros on 29/12/2016.
//  Copyright © 2016 Hugo Bosc-Ducros. All rights reserved.
//

import UIKit

class HerosViewController: UIViewController, HBAutocompleteDataSource {
    
    
    var heroList:[String] = ["Batman","Catwoman", "Flash", "Spiderman", "Superman", "Zoro" ]
    
    @IBOutlet weak var autocomplete: HBAutocompleteView!

    
//MARK: - ViewController life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.setGraphicalSettings()
        self.setAutocomplete()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
//MARK: - Settings
    
    func setGraphicalSettings() {
        self.title = "Hero"
        self.autocomplete.layer.cornerRadius = 5.0
        self.autocomplete.layer.borderColor = UIColor.lightGray.cgColor
        self.autocomplete.layer.borderWidth = 1
    }
    
    func setAutocomplete() {
        //required
        self.autocomplete.dataSource = self
        //optionnal
        self.autocomplete.maxVisibleRow = 7
        self.autocomplete.minCharactersforDataSource = 1
//        self.autocomplete.historicalImageName = "SearchHistory"
//        self.autocomplete.actionsDelegate = self
//        self.autocomplete.withCustomActions = true
//        self.autocomplete.customActionsDescription = ["Current location"]
//        self.autocomplete.customActionsImageName = ["CurrentLocation"]
    }
    
    
//MARK: - Actions
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.autocomplete.textField.resignFirstResponder()
    }
    
    
//MARK: - HBAutocomplete dataSource
    
    func getSuggestions(input: String, completionHandler: @escaping ([String], NSDictionary?) -> Void) {
        completionHandler(self.heroList, nil)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
