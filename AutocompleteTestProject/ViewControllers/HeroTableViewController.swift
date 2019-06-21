//
//  HeroTableViewController.swift
//  AutocompleteTestProject
//
//  Created by Hugo Bosc-Ducros on 20/06/2019.
//  Copyright © 2019 Hugo Bosc-Ducros. All rights reserved.
//

import UIKit
import HBAutoComplete

class HeroTableViewController: UIViewController {

    @IBOutlet weak var autocompleteView: UIView!
    @IBOutlet weak var autocompleteTextField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    
    var autocomplete:HBAutocomplete!
    var dataSource = HeroAutocompleteDataSource()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setAutocomplete()
        self.autocompleteView.textFieldSuperViewStyle()
        self.tableView.tableFooterView = UIView()
    }
    
    
    private func setAutocomplete() {
        self.autocomplete = HBAutocomplete(self.autocompleteTextField, tableView: self.tableView)
        self.autocomplete.dataSource = dataSource
        self.autocomplete.store = AutocompleteStore(.hero)
        self.autocomplete.minCharactersforDataSource = 1
        self.autocomplete.cellHeight = 40
        self.autocomplete.historicalImage = UIImage(named: "SearchHistory")
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
