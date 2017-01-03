//
//  HBAutocompleteView.swift
//  AutocompleteTestProject
//
//  Created by Hugo Bosc-Ducros on 27/12/2016.
//  Copyright © 2016 Hugo Bosc-Ducros. All rights reserved.
//

protocol HBAutocompleteDataSource {
    func getSuggestions(autocomplete:HBAutocompleteView, input:String, completionHandler:@escaping(_ suggestions:[String], _ data:NSDictionary?) -> Void)
}

protocol HBAutoCompleteActionsDelegate {
    func didSelect(autocomplete:HBAutocompleteView, suggestion:String, data:Any?)
    func didSelectCustomAction(autocomplete:HBAutocompleteView, index:Int)
}

protocol HBAutoCompleteTableViewDelegate {
    func tableViewDidShow(autocomplete:HBAutocompleteView, tableView:UITableView)
    func tableViewDidHide(autocomplete:HBAutocompleteView, tableView:UITableView)
}

protocol HBAutocompleteTextFieldDelegate {
    func autocompleteTextFieldDidBeginEditing(autocomplete:HBAutocompleteView, textField:UITextField)
    func autocompleteTextFieldDidEndEditing(autocomplete:HBAutocompleteView, textField:UITextField)
}

import UIKit

class HBAutocompleteView: UIView, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate {
    
//customable variables
    
    //custom lines actions
    var customActionsDescription:[String] = []
    var customActionsImageName:[String] = []
    
    //favorites
    var favoritesDescription:[String] = []
    var favoritesData:NSDictionary?
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
    var tableViewIsReproducingViewStyle = true
    var customActionsAreAllaysVisible = false
    
//internal variables
    
    //dataSource & actions delegates
    var dataSource:HBAutocompleteDataSource?
    var actionsDelegate:HBAutoCompleteActionsDelegate?
    //delegates for subviews & layers gestion
    var tableViewDelegate:HBAutoCompleteTableViewDelegate?
    var textFieldDelegate:HBAutocompleteTextFieldDelegate?
    
    //var suggestionsDictionnary = NSDictionary()
    var dataDictionary = NSMutableDictionary()
    var selectedData:Any?
    var suggestions:[String] = []
    var tableView:UITableView!
    
    //keys for plist files & UserDefault
    var historyStoreDomain = "default"
    private var AUTOCOMPLETE_HISTORY_FREQUENCY:String!
    private var AUTOCOMPLETE_HISTORY_DATA:String!
    private var AUTOCOMPLETE_LAST_SEARCH:String!
    
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
        self.tableView.dataSource = self
        self.textField.delegate = self
        if self.tableViewIsReproducingViewStyle {
            self.tableView.layer.cornerRadius = self.layer.cornerRadius
            self.tableView.layer.borderWidth = self.layer.borderWidth
            self.tableView.layer.borderColor = self.layer.borderColor
            self.tableView.backgroundColor = self.backgroundColor
        }
        self.setHistoryStoreFilesName()
    }
    
    
//MARK: - Settings
    
    private func setHistoryStoreFilesName() {
        self.AUTOCOMPLETE_HISTORY_FREQUENCY = historyStoreDomain + "AutocompleteHistoryFrequency.plist"
        self.AUTOCOMPLETE_HISTORY_DATA = historyStoreDomain + "AutocompleteHistoryData.plist"
        self.AUTOCOMPLETE_LAST_SEARCH = historyStoreDomain + "AutocompleteLastSearch"
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
        self.tableViewDelegate?.tableViewDidShow(autocomplete:self, tableView:self.tableView)
    }
    
    func hideSuggestions() {
        self.tableView.removeFromSuperview()
        self.tableViewDelegate?.tableViewDidHide(autocomplete:self, tableView:self.tableView)
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
        if indexPath.row < self.customActionsDescription.count && self.customActionsDescription.contains(lineString) {
            if self.customActionsImageName.count == self.customActionsDescription.count {
                let imageName = self.customActionsImageName[self.customActionsDescription.index(of: lineString)!]
                cell.imageView?.image = UIImage(named: imageName)
            } else if self.customActionsImageName.count > 0 {
                cell.imageView?.image = UIImage(named: self.customActionsImageName.first!)
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
            self.actionsDelegate?.didSelectCustomAction(autocomplete:self, index: self.customActionsDescription.index(of: self.suggestions[indexPath.row])!)
            self.hideSuggestions()
            tableView.deselectRow(at: indexPath, animated: true)
            
        } else {
            self.textField.text = tableView.cellForRow(at: indexPath)?.textLabel!.text
            if let data = self.dataDictionary.object(forKey: self.textField.text!) {
                if data is Data {
                    self.selectedData = NSKeyedUnarchiver.unarchiveObject(with: data as! Data)
                } else {
                    self.selectedData = data
                }
            } else {
                self.selectedData = nil
            }
            self.actionsDelegate?.didSelect(autocomplete:self, suggestion: self.textField.text!, data: self.selectedData)
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
            self.textFieldDelegate?.autocompleteTextFieldDidBeginEditing(autocomplete:self, textField:textField)
        }
        self.loadSuggestions(textField.text!)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if self.textFieldDelegate != nil {
            self.textFieldDelegate?.autocompleteTextFieldDidEndEditing(autocomplete:self, textField:textField)
        }
        self.hideSuggestions()
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        self.hideSuggestions()
        return true
    }
    
    
// MARK: - Historical methods
    
    //MARK: methods to implement in your project
    func addToHistory(_ input:String, inputData:Any? = nil) {
        let directories = NSSearchPathForDirectoriesInDomains(.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let formatedInput = "H:" + input
        if let documents = directories.first {
            if let urlDocuments = NSURL(string: documents) {
                let frequencyURL = urlDocuments.appendingPathComponent(AUTOCOMPLETE_HISTORY_FREQUENCY)
                let dataURL = urlDocuments.appendingPathComponent(AUTOCOMPLETE_HISTORY_DATA)
                let loadedfrequency = NSMutableDictionary(contentsOfFile: frequencyURL!.path)
                let loadedData = NSMutableDictionary(contentsOfFile: dataURL!.path)
                if let frequency = loadedfrequency {
                    if let data = loadedData {
                        if inputData != nil {
                            data[input] = NSKeyedArchiver.archivedData(withRootObject: inputData!)
                            self.writeData(data: data, dataURL: dataURL!)
                        } else if self.selectedData != nil {
                            data[input] = NSKeyedArchiver.archivedData(withRootObject: self.selectedData!)
                            self.writeData(data: data, dataURL: dataURL!)
                        }
                        
                    } else if inputData != nil {
                        let data = NSDictionary(object: NSKeyedArchiver.archivedData(withRootObject: inputData!), forKey: input as NSCopying)
                        self.writeData(data: data, dataURL: dataURL!)
                    } else if self.selectedData != nil {
                        let data = NSDictionary(object: NSKeyedArchiver.archivedData(withRootObject: self.selectedData!), forKey: input as NSCopying)
                        self.writeData(data: data, dataURL: dataURL!)
                    }
                    if let inputFrequency = frequency[input] as? NSNumber {
                        frequency[formatedInput] = (inputFrequency as Int + 1) as NSNumber
                        
                    } else {
                        frequency[formatedInput] = 1 as NSNumber
                    }
                    self.writeData(data: frequency, dataURL: frequencyURL!)
//                    if frequency.write(toFile: frequencyURL!.path, atomically: true) {
//                        print("frequency stored with sucess")
//                    } else {
//                        print("error storing frequency")
//                    }
                } else {
                    let frequency = NSDictionary(object: 1 as NSNumber, forKey: formatedInput as NSCopying)
                    self.writeData(data: frequency, dataURL: frequencyURL!)
                    if inputData != nil {
                        let data = NSDictionary(object: NSKeyedArchiver.archivedData(withRootObject: inputData!), forKey: input as NSCopying)
                        self.writeData(data: data, dataURL: dataURL!)
                    }
                }
                UserDefaults.standard.set(("H:" + input), forKey: AUTOCOMPLETE_LAST_SEARCH)
            }
        }
    }
    
    func removeHistory() {
        let fileManager = FileManager.default
        let directories = NSSearchPathForDirectoriesInDomains(.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        if let documents = directories.first {
            if let urlDocuments = NSURL(string: documents) {
                let frequencyURL = urlDocuments.appendingPathComponent(AUTOCOMPLETE_HISTORY_FREQUENCY)
                let dataURL = urlDocuments.appendingPathComponent(AUTOCOMPLETE_HISTORY_DATA)
                do {
                    try fileManager.removeItem(atPath: (frequencyURL?.path)!)
                    try fileManager.removeItem(atPath: (dataURL?.path)!)
                } catch {
                    print("Could not clear temp folder: \(error)")
                }
            }
        }
        UserDefaults.standard.removeObject(forKey: AUTOCOMPLETE_LAST_SEARCH)
    }
    
    
//MARK: internal methodes for historical
    
    private func writeData(data:NSDictionary, dataURL:URL) {
        if data.write(toFile: dataURL.path, atomically: true) {
            print("data stored with sucess")
        } else {
            print("error storing data")
        }
    }
    
//    private func writeFrequency(frequency:NSDictionary, frequencyURL:URL) {
//        if frequency.write(toFile: frequencyURL.path, atomically: true) {
//            print("frequency stored with sucess")
//        } else {
//            print("error storing frequency")
//        }
//    }
    
    //new methodes
    private func getHistory() -> (frequency:NSDictionary?, data:NSDictionary?) {
        let directories = NSSearchPathForDirectoriesInDomains(.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        if let documents = directories.first {
            if let urlDocuments = NSURL(string: documents) {
                let frequencyURL = urlDocuments.appendingPathComponent(AUTOCOMPLETE_HISTORY_FREQUENCY)
                let dataURL = urlDocuments.appendingPathComponent(AUTOCOMPLETE_HISTORY_DATA)
                let loadedfrequency = NSDictionary(contentsOfFile: frequencyURL!.path)
                let loadedData = NSDictionary(contentsOfFile: dataURL!.path)
                if let frequency = loadedfrequency {
                    if let data = loadedData {
                        return (frequency, data)
                    } else {
                        return (frequency, nil)
                    }
                }
            }
            
        }
        return (nil, nil)
    }
    
    private func getSortedHistory() -> (suggestions:[String], dataDictionary:NSDictionary?) {
        var suggestions:[String] = []
        var datas:NSDictionary? = NSMutableDictionary()
        let (frequency, data) = self.getHistory()
        if frequency != nil {
            let suggestionsArray = frequency!.keysSortedByValue(comparator: { (value1, value2) -> ComparisonResult in
                return (value1 as! NSNumber).compare(value2 as! NSNumber)
            })
            if let lastInput = UserDefaults.standard.object(forKey: AUTOCOMPLETE_LAST_SEARCH) as? String {
                suggestions.append(lastInput)
                if (lastInput as NSString).length > 3 {
                    let normalLastInput = (lastInput as NSString).substring(from: 2)
                    if data != nil, let lastData = data!.object(forKey: normalLastInput) {
                        datas!.setValue(lastData, forKey: normalLastInput)
                    }
                }
                
            }
            for value in suggestionsArray {
                if let stringValue = value as? String {
                    if !suggestions.contains(stringValue) {
                        suggestions.append(stringValue)
                        if (stringValue as NSString).length > 3 {
                            let normalStringValue = (stringValue as NSString).substring(from: 2)
                            if data != nil, let valueData = data?.object(forKey: normalStringValue) {
                                datas!.setValue(valueData, forKey: normalStringValue)
                            }
                        }
                    }
                }
            }
        }
        if datas!.count == 0 {
            datas = nil
        }
        return (suggestions,datas)
    }
    
    private func loadStoredSuggestions() {
        self.suggestions = self.customActionsDescription
        self.dataDictionary = NSMutableDictionary()
        let (history, historyDatas) = self.getSortedHistory()
        if self.withFavorite {
            for favorite in self.favoritesDescription {
                self.suggestions.append(favorite)
                if self.favoritesData != nil, let favoriteData = historyDatas!.object(forKey: favorite) {
                    self.dataDictionary.setValue(favoriteData, forKey: favorite)
                } else if historyDatas != nil, let favoriteData = historyDatas!.object(forKey: favorite) {
                    self.dataDictionary.setValue(favoriteData, forKey: favorite)
                }
            }
        }
        for description in history {
            if (description as NSString).length > 3 {
                let normalDescription = (description as NSString).substring(from: 2)
                if !self.suggestions.contains(normalDescription){
                    self.suggestions.append(description)
                    if historyDatas != nil, let data = historyDatas!.object(forKey: normalDescription) {
                        self.dataDictionary.setValue(data, forKey: normalDescription)
                    }
                }
            }
        }
    }
    
    private func loadStoredResults(input:String) {
        if self.customActionsAreAllaysVisible {
            self.suggestions = []
        } else {
            self.suggestions = self.customActionsDescription
        }
        
        self.dataDictionary = NSMutableDictionary()
        let (history, historyDatas) = self.getSortedHistory()
        if self.withFavorite {
            for favorite in self.favoritesDescription {
                let scaleFavorite = (favorite as NSString).substring(to: (input as NSString).length)
                if (input.lowercased() == scaleFavorite.lowercased()) {
                    self.suggestions.append(favorite)
                    if self.favoritesData != nil, let favoriteData = historyDatas!.object(forKey: favorite) {
                        self.dataDictionary.setValue(favoriteData, forKey: favorite)
                    } else if historyDatas != nil, let favoriteData = historyDatas!.object(forKey: favorite) {
                        self.dataDictionary.setValue(favoriteData, forKey: favorite)
                    }
                }
            }
        }
        for description in history {
            if (description as NSString).length - 2 > (input as NSString).length {
                let normalDescription = (description as NSString).substring(from: 2)
                if !self.suggestions.contains(normalDescription) {
                    let scaleDescription = (normalDescription as NSString).substring(to: (input as NSString).length)
                    if (input.lowercased() == scaleDescription.lowercased()) {
                        self.suggestions.append(description)
                        if historyDatas != nil, let data = historyDatas!.object(forKey: scaleDescription) {
                            self.dataDictionary.setValue(data, forKey: scaleDescription)
                        }
                    }
                }
            }
        }
    }
    
    private func addDataSourceSuggestions(suggestions:[String], data:NSDictionary?) {
        for value in suggestions {
            if !self.suggestions.contains(value) {
                if !self.suggestions.contains(("H:" + value)) {
                    self.suggestions.append(value as String)
                    if data != nil {
                        self.dataDictionary.setValue(data?.value(forKey: value), forKey: value)
                    }
                }
            }
        }
    }
    
    func loadSuggestions(_ input:String) {
        if (input as NSString).length >= self.minCharactersforDataSource && self.dataSource != nil {
            self.dataSource!.getSuggestions(autocomplete:self, input: input, completionHandler: { (suggestions, data) in
                self.loadStoredResults(input: input)
                self.addDataSourceSuggestions(suggestions: suggestions, data: data)
                self.showSuggestions()
            })
        } else if (input as NSString).length > 0 {
            self.loadStoredResults(input: input)
            self.showSuggestions()
        } else {
            self.loadStoredSuggestions()
            self.showSuggestions()
        }
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

}
