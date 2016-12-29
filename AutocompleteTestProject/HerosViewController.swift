//
//  HerosViewController.swift
//  AutocompleteTestProject
//
//  Created by Hugo Bosc-Ducros on 29/12/2016.
//  Copyright © 2016 Hugo Bosc-Ducros. All rights reserved.
//

import UIKit

class HerosViewController: UIViewController {
    
    
    var heroList:[String] = ["Batman", "Superman", ]
    
    @IBOutlet weak var autocomplete: HBAutocompleteView!

    
//MARK: - ViewController life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.setGraphicalSettings()
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
    
    
//MARK: - Actions
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.autocomplete.textField.resignFirstResponder()
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
