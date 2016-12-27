//
//  HBAutocompleteView.swift
//  AutocompleteTestProject
//
//  Created by Hugo Bosc-Ducros on 27/12/2016.
//  Copyright © 2016 Hugo Bosc-Ducros. All rights reserved.
//

protocol HBAutoCompleteTableViewDelegate : class {
    func tableViewDidShow(_ tableView:UITableView)
    func tableViewDidHide(_ tableView:UITableView)
}

protocol HBAutocompleteTextFieldDelegate {
    func autocompleteTextFieldDidBeginEditing(_ textField:UITextField)
    func autocompleteTextFieldDidEndEditing(_ autoComplete:UITextField)
}

protocol HBAutocompleteCustomActionsDelegate {
    func didSelectCustomAction(index:Int)
}

protocol HBAutocompleteDataSource {
    func getSuggestions(input:String, completionHandler:@escaping(_ suggestions:[String], _ data:Any?) -> Void)
}

import UIKit

class HBAutocompleteView: UIView, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate {
    
//customable variables
    
    //custom lines actions
    var customActionsDescription:[String] = []
    var cutomActionsImageName:[String] = []
    
    //favorites
    var favoritesDescription:[String] = []
    var favoritesImageName:[String] = []
    
    //historical
    var historicalImageName:String?
    

    //Graphical settings (you can set it in the view controller to change displaying style)
    var maxVisibleRow:Int = 5
    var maxHistoricalRow:Int = 3
    var minCharactersforDataSource:Int = 3
    var cellFont:UIFont!
    //optional features
    var withFavorite:Bool = false
    var withCustomActions:Bool = false
    
//internal variables
    
    //dataSource & actions delegates
    var dataSource:HBAutocompleteDataSource?
    var customActionsDelegate:HBAutocompleteCustomActionsDelegate?
    //delegates for subviews & layers gestion
    var tableViewDelegate:HBAutoCompleteTableViewDelegate?
    var textFieldDelegate:HBAutocompleteTextFieldDelegate?
    
    var suggestions:[String] = []
    var tableView:UITableView!
    
    //keys for DefaultUser
    let AUTOCOMPLETE_SEARCH_HISTORY = "AutocompleteSearchHistory"
    let AUTOCOMPLETE_SEARCH_FREQUENCIES  = "AutocompleteSearchFrequency"
    let AUTOCOMPLETE_LAST_SEARCH = "AutocompleteLastSearch"
    
    @IBOutlet var textField:UITextField!
    
    
    // MARK: - Instanciate method
    
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        self.textField.clearButtonMode = UITextFieldViewMode.always
        self.textField.autocorrectionType = UITextAutocorrectionType.no
        self.tableView = UITableView()
        self.tableView.allowsSelection = true
        self.tableView.delegate = self
        self.tableView.layer.cornerRadius = self.layer.cornerRadius
        self.tableView.layer.borderWidth = self.layer.borderWidth
        self.tableView.layer.borderColor = self.layer.borderColor
        self.tableView.dataSource = self
        self.textField.delegate = self
        
    }
    
    
    // MARK: - Show/Hide tableView suggestions
    
    func showSuggestions() {
        self.tableView.reloadData()
        var x = self.frame.origin.x
        var y = self.frame.origin.y + self.frame.size.height
        let width = self.frame.width
        var height = self.frame.height * CGFloat(self.suggestions.count) as CGFloat
        if (self.suggestions.count > self.maxVisibleRow) {
            height = self.frame.height * CGFloat(self.maxVisibleRow) as CGFloat
        }
        var view = self.superview!
        while view.superview != nil {
            x += view.frame.origin.x
            y += view.frame.origin.y
            view = view.superview!
        }
        x += view.frame.origin.x
        y += view.frame.origin.y
        self.tableView.frame = CGRect(x: x, y: y, width: width, height: height)
        view.addSubview(self.tableView)
        self.tableView.delegate = self
        self.tableViewDelegate?.tableViewDidShow(self.tableView)
    }
    
    func hideSuggestions() {
        self.tableView.removeFromSuperview()
        self.tableViewDelegate?.tableViewDidHide(self.tableView)
    }
    
    
    // MARK: - tableView delagate & datasource
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        if self.cellFont != nil {
            cell.textLabel?.font = self.cellFont
        } else {
            cell.textLabel?.font = self.textField.font
        }
        
        let lineString = self.suggestions[indexPath.row]
        cell.textLabel!.text = lineString
        //print("index : \(indexPath.row)")
        if indexPath.row < self.customActionsDescription.count && self.customActionsDescription.contains(lineString) {
            if self.cutomActionsImageName.count == self.customActionsDescription.count {
                let imageName = self.cutomActionsImageName[self.customActionsDescription.index(of: lineString)!]
                cell.imageView?.image = UIImage(named: imageName)
            } else if self.cutomActionsImageName.count > 0 {
                cell.imageView?.image = UIImage(named: self.cutomActionsImageName.first!)
            }
        } else if indexPath.row >= self.customActionsDescription.count && indexPath.row < (self.customActionsDescription.count + self.favoritesDescription.count) && self.favoritesDescription.contains(lineString) {
            if self.favoritesDescription.count == self.favoritesImageName.count {
                let imageName = self.favoritesImageName[self.favoritesDescription.index(of: lineString)!]
                cell.imageView?.image = UIImage(named: imageName)
            } else if self.favoritesImageName.count > 0 {
                let imageName = self.favoritesImageName.first!
                cell.imageView?.image = UIImage(named: imageName)
            }
        } else if (lineString as NSString).substring(to: 2) == "H:" {
            cell.textLabel!.text = (lineString as NSString).substring(from: 2)
            if self.historicalImageName != nil {
                cell.imageView?.image = UIImage(named: historicalImageName!)
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.textField.resignFirstResponder()
        if self.customActionsDescription.contains(self.suggestions[indexPath.row]) {
            self.customActionsDelegate?.didSelectCustomAction(index: self.customActionsDescription.index(of: self.suggestions[indexPath.row])!)
            self.hideSuggestions()
            tableView.deselectRow(at: indexPath, animated: true)
            
        } else {
            textField.text = tableView.cellForRow(at: indexPath)?.textLabel!.text
            //you can add to search historical here if needed :
            //self.addToSearchHistory(textField.text!)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return suggestions.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.bounds.size.height
    }
    
    
    // MARK: - textField delegate
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let str = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        self.loadSuggestions(str)
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if self.textFieldDelegate != nil {
            self.textFieldDelegate?.autocompleteTextFieldDidBeginEditing(textField)
        }
        self.loadSuggestions(textField.text!)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if self.textFieldDelegate != nil {
            self.textFieldDelegate?.autocompleteTextFieldDidEndEditing(textField)
        }
        self.hideSuggestions()
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        self.hideSuggestions()
        return true
    }
    
    
    // MARK: - Historical methods
    
    //MARK: add and remove historical address
    func addToSearchHistory(_ newAddresse:String) {
        var searchHistory:[String] = []
        var searchFrequencies:[Int] = []
        //var searchObjet:[String:Any] = [:]
        let userDef = UserDefaults.standard
        if (userDef.object(forKey: AUTOCOMPLETE_SEARCH_HISTORY) != nil) {
            searchHistory = userDef.object(forKey: AUTOCOMPLETE_SEARCH_HISTORY) as! [String]
            searchFrequencies = userDef.object(forKey: AUTOCOMPLETE_SEARCH_FREQUENCIES) as! [Int]
        }
        let nexHistoricalAddress = "H:\(newAddresse)"
        if !searchHistory.contains(nexHistoricalAddress) {
            searchHistory.append(nexHistoricalAddress)
            searchFrequencies.append(1)
            userDef.set(searchHistory, forKey: AUTOCOMPLETE_SEARCH_HISTORY)
            userDef.set(searchFrequencies, forKey: AUTOCOMPLETE_SEARCH_FREQUENCIES)
        } else {
            let index = searchHistory.index(of: nexHistoricalAddress)
            var n = searchFrequencies[index!]
            n += 1
            searchFrequencies[index!] = n
            userDef.set(searchFrequencies, forKey: AUTOCOMPLETE_SEARCH_FREQUENCIES)
            userDef.synchronize()
        }
        userDef.set(nexHistoricalAddress, forKey: AUTOCOMPLETE_LAST_SEARCH)
        userDef.synchronize()
    }
    
    func removeSearchHistory() {
        UserDefaults.standard.removeObject(forKey: AUTOCOMPLETE_SEARCH_HISTORY)
        UserDefaults.standard.removeObject(forKey: AUTOCOMPLETE_LAST_SEARCH)
        UserDefaults.standard.removeObject(forKey: AUTOCOMPLETE_SEARCH_FREQUENCIES)
    }
    
    
    //MARK: internal methodes
    private func getSearchHistory() -> [String] {
        var searchHistory:[String] = []
        if (UserDefaults.standard.object(forKey: AUTOCOMPLETE_SEARCH_HISTORY) != nil) {
            searchHistory = UserDefaults.standard.object(forKey: AUTOCOMPLETE_SEARCH_HISTORY) as! [String]
        }
        return searchHistory
    }
    
    private func getSearchFrequencies() -> [Int] {
        var searchFrequencies:[Int] = []
        if (UserDefaults.standard.object(forKey: AUTOCOMPLETE_SEARCH_FREQUENCIES) != nil) {
            searchFrequencies = UserDefaults.standard.object(forKey: AUTOCOMPLETE_SEARCH_FREQUENCIES) as! [Int]
        }
        return searchFrequencies
    }
    
    private func getSortedSearchHistory() -> [String] {
        var suggestions:[String] = []
        let mostFrequentSuggestions = self.findMoreSearchedResults()
        if let lastSearch = UserDefaults.standard.object(forKey: AUTOCOMPLETE_LAST_SEARCH) as? String {
            suggestions.append(lastSearch)
            for value in mostFrequentSuggestions {
                if value != lastSearch {
                    suggestions.append(value)
                }
            }
        }
        return suggestions
    }
    
    private func findInSearchHistory(_ input:String) -> [String] {
        var suggestions:[String] = []
        let mostFrequentSuggestions = self.findMoreSearchedResultsForAnInput(input)
        if let lastSearch = UserDefaults.standard.object(forKey: AUTOCOMPLETE_LAST_SEARCH) as? String {
            if self.lastSearchIsMatchingWithInput(input) {
                suggestions.append(lastSearch)
                for value in mostFrequentSuggestions {
                    if value != lastSearch {
                        suggestions.append(value)
                    }
                }
            } else {
                suggestions.append(contentsOf: mostFrequentSuggestions)
            }
        }
        return suggestions
    }
    
    private func findNResultInSearchHistory(_ input:String, nResult:Int) -> [String] {
        var suggestions:[String] = []
        let mostFrequentSuggestions = self.findNMoreSearchedResultsForAnInput(input, nResults: nResult)
        if let lastSearch = UserDefaults.standard.object(forKey: AUTOCOMPLETE_LAST_SEARCH) as? String {
            if self.lastSearchIsMatchingWithInput(input) {
                suggestions.append(lastSearch)
                for value in mostFrequentSuggestions {
                    if value != lastSearch {
                        suggestions.append(value)
                    }
                }
            } else {
                suggestions.append(contentsOf: mostFrequentSuggestions)
            }
        }
        return suggestions
    }
    
    private func findNMoreSearchedResultsForAnInput(_ input:String, nResults:Int) -> [String] {
        var suggestions:[String] = []
        let searchHistory = self.getSearchHistory()
        if searchHistory.count > 0 {
            let searchFrequencies = self.getSearchFrequencies()
            var matchingSearchHistory:[(address:String,frequency:Int)] = []
            for address in searchHistory {
                if (address as NSString).length - 2 > (input as NSString).length {
                    let scaleAddress  = ((address as NSString).substring(from: 2) as NSString).substring(to: (input as NSString).length)
                    if (input.lowercased() == scaleAddress.lowercased()) {
                        matchingSearchHistory.append((address:address,frequency:searchFrequencies[searchHistory.index(of: address)!]))
                    }
                }
                
            }
            let Count = min(matchingSearchHistory.count, nResults)
            matchingSearchHistory.sort(by: { $0.frequency > $1.frequency})
            let history = matchingSearchHistory[0..<Count]
            suggestions.append(contentsOf: history.map {$0.address})
        }
        return suggestions
    }
    
    func findMoreSearchedResultsForAnInput(_ input:String) -> [String] {
        var suggestions:[String] = []
        let searchHistory = self.getSearchHistory()
        if searchHistory.count > 0 {
            let searchFrequencies = self.getSearchFrequencies()
            var matchingSearchHistory:[(address:String,frequency:Int)] = []
            for address in searchHistory {
                if (address as NSString).length - 2 > (input as NSString).length {
                    let scaleAddress = ((address as NSString).substring(from: 2) as NSString).substring(to: (input as NSString).length)
                    if (input.lowercased() == scaleAddress.lowercased()) {
                        matchingSearchHistory.append((address:address,frequency:searchFrequencies[searchHistory.index(of: address)!]))
                    }
                }
                
            }
            matchingSearchHistory.sort(by: { $0.frequency > $1.frequency})
            suggestions.append(contentsOf: matchingSearchHistory.map {$0.address})
        }
        return suggestions
        
    }
    
    func findMoreSearchedResults() -> [String] {
        var suggestions:[String] = []
        let searchHistory = self.getSearchHistory()
        if searchHistory.count > 0 {
            let searchFrequencies = self.getSearchFrequencies()
            var matchingSearchHistory:[(address:String,frequency:Int)] = []
            for address in searchHistory {
                matchingSearchHistory.append((address:address,frequency:searchFrequencies[searchHistory.index(of: address)!]))
            }
            matchingSearchHistory.sort(by: { $0.frequency > $1.frequency})
            suggestions.append(contentsOf: matchingSearchHistory.map {$0.address})
        }
        return suggestions
    }
    
    func lastSearchIsMatchingWithInput(_ input:String) -> Bool {
        let lastSearch = UserDefaults.standard.object(forKey: AUTOCOMPLETE_LAST_SEARCH) as? String
        
        if (lastSearch! as NSString).length - 2 > (input as NSString).length {
            let scaleAddress = ((lastSearch! as NSString).substring(from: 2) as NSString).substring(to: (input as NSString).length)
            if (input.lowercased() == scaleAddress.lowercased()) {
                return true
            }
        }
        
        return false
    }
    
    //MARK: Advance methods
    func setDefaultSuggestions() {
        self.suggestions = self.customActionsDescription
        self.suggestions.append(contentsOf: self.getFavorite())
        let sortedSerchHistory = self.getSortedSearchHistory()
        for value2:String in sortedSerchHistory {
            if (value2 as NSString).length > 3 {
                if !self.suggestions.contains((value2 as NSString).substring(from: 2)) {
                    self.suggestions.append(value2 as String)
                }
            }
        }
    }
    
    func setMatchingSuggestionsWithoutDataSource(_ input:String) {
        self.suggestions = self.favoriteWitchMatchingWithInput(input)
        let searchhistory = self.findInSearchHistory(input)
        for value:String in searchhistory {
            if (value as NSString).length > 3 {
                if !self.suggestions.contains((value as NSString).substring(from: 2)) {
                    self.suggestions.append(value as String)
                }
            }
        }
    }
    
    func setMatchingSuggestionsWithDataSource(_ input:String, dataSourceSuggestions:[String]) {
        self.suggestions = self.favoriteWitchMatchingWithInput(input)
        let searchhistory = self.findNResultInSearchHistory(input,nResult: self.maxHistoricalRow)
        for value1:String in searchhistory {
            if (value1 as NSString).length > 3 {
                if !self.suggestions.contains((value1 as NSString).substring(from: 2)) {
                    self.suggestions.append(value1 as String)
                }
            }
        }
        for value2:String in dataSourceSuggestions {
            if (value2 as NSString).length > 3 {
                if !self.suggestions.contains(value2) && !self.suggestions.contains("H:\(value2)") {
                    self.suggestions.append(value2)
                }
            }
        }
    }
    
    func loadSuggestions(_ input:String) {
        if (input as NSString).length >= self.minCharactersforDataSource && self.dataSource != nil {
            self.dataSource!.getSuggestions(input: input, completionHandler: { (suggestions, data) in
                self.setMatchingSuggestionsWithDataSource(input, dataSourceSuggestions: suggestions)
                self.showSuggestions()
            })
        } else if (input as NSString).length > 0 {
            self.setMatchingSuggestionsWithoutDataSource(input)
            self.showSuggestions()
        } else {
            self.setDefaultSuggestions()
            self.showSuggestions()
        }
    }
    
    func makeAddressStringFromDictionary(addresDictionary:[AnyHashable:Any]) -> String {
        var address = ""
        for (_,value) in addresDictionary {
            print(value)
            address += " \(value),"
        }
        return address
    }
    
    
    // Mark: - Favorite methodes
    
    func setFavorites(description:[String], imagesName:[String]?) {
        self.favoritesDescription = description
        if imagesName != nil {
            self.favoritesImageName = imagesName!
        }
    }
    
    func getFavorite() -> [String] {
        var suggestions:[String] = []
        if self.withFavorite {
            suggestions.append(contentsOf: self.favoritesDescription)
        }
        return suggestions
    }
    
    func favoriteWitchMatchingWithInput(_ input:String) -> [String] {
        var response:[String] = []
        
        for favorite in self.favoritesDescription {
            if ((favorite as NSString).length) >= (input as NSString).length {
                let scalleAddress = (favorite as NSString).substring(to: (input as NSString).length)
                if input.lowercased() == scalleAddress.lowercased() {
                    response.append(favorite)
                }
            }
        }
        return response
    }

}
