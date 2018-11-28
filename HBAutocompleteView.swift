//
//  HBAutocompleteView.swift
//  AutocompleteTestProject
//
//  Created by Hugo Bosc-Ducros on 27/12/2016.
//  Copyright © 2016 Hugo Bosc-Ducros. All rights reserved.
//

@objc protocol HBAutocompleteDataSource:class {
    func getSuggestions(autocomplete:HBAutocompleteView, input:String, completionHandler:@escaping(_ suggestions:[String], _ data:NSDictionary?, _ suggestionImages:[String:String]?) -> Void)
}

@objc protocol HBAutoCompleteActionsDelegate:class {
    func didSelect(autocomplete:HBAutocompleteView, index:Int, suggestion:String, data:Any?)
    func didSelectCustomAction(autocomplete:HBAutocompleteView, index:Int)
}

protocol HBAutoCompleteTableViewDelegate:class {
    func tableViewDidShow(autocomplete:HBAutocompleteView, tableView:UITableView)
    func tableViewDidHide(autocomplete:HBAutocompleteView, tableView:UITableView)
}

protocol HBAutocompleteTextFieldDelegate:class {
    func autocompleteTextFieldDidBeginEditing(autocomplete:HBAutocompleteView, textField:UITextField)
    func autocompleteTextFieldDidEndEditing(autocomplete:HBAutocompleteView, textField:UITextField)
}

import UIKit

class HBAutocompleteView: UIView, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    
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
    var cellHeight:CGFloat!
    //optional features
    var withFavorite:Bool = false
    //var withCustomActions:Bool = false
    var tableViewIsReproducingViewStyle = true
    var customActionsAreAllaysVisible = false
    
    //internal variables
    
    //dataSource & actions delegates
    @IBOutlet weak var dataSource:HBAutocompleteDataSource?
    @IBOutlet weak var actionsDelegate:HBAutoCompleteActionsDelegate?
    //delegates for subviews & layers gestion
    weak var tableViewDelegate:HBAutoCompleteTableViewDelegate?
    weak var textFieldDelegate:HBAutocompleteTextFieldDelegate?
    
    var dataDictionary = NSMutableDictionary()
    var selectedData:Any?
    var suggestions:[String] = []
    var suggestionImagesNames:[String:String]?
    var tableView:UITableView!
    
    //keys for plist files & UserDefault
    var historyStoreDomain = "default"
    private var AUTOCOMPLETE_HISTORY_FREQUENCY:String!
    private var AUTOCOMPLETE_HISTORY_DATA:String!
    private var AUTOCOMPLETE_LAST_SEARCH:String!
    
    @IBOutlet weak var textField:UITextField?
    @IBOutlet weak var searchBar:UISearchBar?
    @IBOutlet weak var externalTableView:UITableView?
    private var tableViewIsExternal = false
    
    private var activeFieldsHeight:CGFloat {
        if let textField = self.textField {
            return textField.frame.height
        } else if let searchBar = self.searchBar {
            return searchBar.frame.height
        }
        return 30
    }
    
    // MARK: - Instanciate method
    
    
    override func draw(_ rect: CGRect) {
        if let externalTable = self.externalTableView {
            self.tableViewIsExternal = true
            self.tableView = externalTable
        } else {
            self.tableViewIsExternal = false
            self.tableView = UITableView()
        }
        self.tableView.allowsSelection = true
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.textField?.delegate = self
        self.searchBar?.delegate = self
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
    
    
    //MARK: - Utils
    
    func update(suggestion:String, data:Any?) {
        if let textField = self.textField {
            textField.text = suggestion
        } else if let searchBar = self.searchBar {
            searchBar.text  = suggestion
        }
        self.selectedData = data
    }
    
    private func getActiveText() -> String {
        if let textField = self.textField {
            return textField.text ?? ""
        } else if let searchBar = self.searchBar {
            return searchBar.text ?? ""
        }
        return ""
    }
    
    func resignActiveResponder() {
        self.textField?.resignFirstResponder()
        self.searchBar?.resignFirstResponder()
    }
    
    private func getSuggestionImageNames() -> [String:String] {
        var imageNames = [String:String]()
        for suggestion in suggestions {
            if self.customActionsDescription.count > 0 && self.customActionsImageName.count > 0, self.customActionsDescription.contains(suggestion) {
                if self.customActionsImageName.count == self.customActionsDescription.count, let index = self.customActionsDescription.index(of: suggestion) {
                    imageNames[suggestion] = self.customActionsImageName[index]
                } else if self.customActionsImageName.count > 0 {
                    imageNames[suggestion] = self.customActionsImageName.first!
                }
            }
            if self.withFavorite && self.favoritesImageName.count > 0, self.favoritesDescription.contains(suggestion) {
                if self.favoritesImageName.count == self.favoritesDescription.count, let index = self.favoritesDescription.index(of: suggestion) {
                    imageNames[suggestion] = self.favoritesImageName[index]
                } else if self.favoritesImageName.count > 0 {
                    imageNames[suggestion] = self.favoritesImageName.first!
                }
            }
            if let historicalImage = self.historicalImageName,(suggestion as NSString).length > 2, (suggestion as NSString).substring(to: 2) == "H:" {
                imageNames[suggestion] = historicalImage
            }
        }
        if let suggestionImageNameDictionary = self.suggestionImagesNames {
            suggestionImageNameDictionary.forEach({ (key, value) in
                imageNames[key] = value
            })
        }
        return imageNames
    }
    
    
    // MARK: - Show/Hide tableView suggestions
    
    // MARK: - Show/Hide tableView suggestions
    
    func showSuggestions() {
        //In case of dataSource or delegate concurancy
        self.tableView.dataSource = self
        self.tableView.delegate = self
        //
        self.tableView.reloadData()
        if !tableViewIsExternal && (self.textField?.isEditing ?? false || self.searchBar?.isFirstResponder ?? false) {
            var x = self.frame.origin.x
            var y = self.frame.origin.y + self.frame.size.height
            let width = self.frame.width
            var height = self.frame.height * CGFloat(self.suggestions.count) as CGFloat
            if (self.suggestions.count > self.maxVisibleRow) {
                height = self.frame.height * CGFloat(self.maxVisibleRow) as CGFloat
            }
            if var view = self.superview {
                while let superview =  view.superview {
                    x += view.frame.origin.x
                    y += view.frame.origin.y
                    view = superview
                }
                x += view.frame.origin.x
                y += view.frame.origin.y
                self.tableView.frame = CGRect(x: x, y: y, width: width, height: height)
                view.addSubview(self.tableView)
                //self.tableView.delegate = self
                self.tableViewDelegate?.tableViewDidShow(autocomplete:self, tableView:self.tableView)
            }
        }
    }
    
    func hideSuggestions() {
        if !tableViewIsExternal {
            self.tableView.removeFromSuperview()
            self.tableViewDelegate?.tableViewDidHide(autocomplete:self, tableView:self.tableView)
        }
    }
    
    
    // MARK: - tableView delagate & datasource
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        if let cellFont = self.cellFont {
            cell.textLabel?.font = cellFont
        } else if let font = self.textField?.font {
            cell.textLabel?.font = font//self.textField.font
        }
        if let lineString = self.suggestions[safe:indexPath.row] {
            cell.textLabel!.text = lineString
            let imageNames = self.getSuggestionImageNames()
            if let imageName = imageNames[lineString] {
                cell.imageView?.image = UIImage(named:imageName)
            }
            if (lineString as NSString).length > 2,(lineString as NSString).substring(to: 2) == "H:" {
                cell.textLabel!.text = (lineString as NSString).substring(from: 2)
                if let historicalImageName = self.historicalImageName {
                    cell.imageView?.image = UIImage(named: historicalImageName)
                }
            }
            cell.backgroundColor = UIColor.clear
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let lineString = self.suggestions[safe:indexPath.row] {
            if self.customActionsDescription.contains(lineString) {
                self.resignActiveResponder()//textField.resignFirstResponder()
                tableView.deselectRow(at: indexPath, animated: true)
                self.actionsDelegate?.didSelectCustomAction(autocomplete:self, index: self.customActionsDescription.index(of: lineString)!)
            } else {
                if let text = tableView.cellForRow(at: indexPath)?.textLabel?.text {
                    self.update(suggestion: text, data: nil)
                }
                //self.textField.text = tableView.cellForRow(at: indexPath)?.textLabel!.text
                //print("textfield text : \(self.textField.text)" ?? "textField's text is nill")
                if let data = self.dataDictionary.object(forKey: self.getActiveText()) {
                    if data is Data {
                        if #available(iOS 9.0, *) {
                            do {
                                self.selectedData = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData((data as! NSData) as Data)
                            } catch {
                                self.selectedData = data
                            }
                        } else {
                            self.selectedData = NSKeyedUnarchiver.unarchiveObject(with: data as! Data)
                        }
                    } else {
                        self.selectedData = data
                    }
                } else {
                    self.selectedData = nil
                }
                self.actionsDelegate?.didSelect(autocomplete:self, index:indexPath.row, suggestion: self.getActiveText(), data: self.selectedData)
                //you can add to search history here if needed :
                //self.addToSearchHistory()
            }
        }
        //self.textField.resignFirstResponder()
        self.resignActiveResponder()
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return suggestions.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if self.cellHeight != nil {
            return self.cellHeight!
        } else if tableViewIsReproducingViewStyle {
            return self.bounds.size.height
        } else {
            return activeFieldsHeight
        }
    }
    
    
    // MARK: - textField delegate
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let str = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        print(str)
        self.loadSuggestions(str)
        //self.textFieldDelegate?.autocompleteTextFieldWillChange(autoComplete: self, textField: textField)
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
        print("blabla")
        //self.hideSuggestions()
        self.loadSuggestions("")
        return true
    }
    
    
    //MARK: - UISearchBarDelegate
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.loadSuggestions(searchText)
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        //self.textFieldDelegate?.autocompleteTextFieldDidBeginEditing(autocomplete:self, textField:textField)
        self.loadSuggestions(searchBar.text!)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        //self.textFieldDelegate?.autocompleteTextFieldDidEndEditing(autocomplete:self, textField:textField)
        self.hideSuggestions()
    }
    
    
    // MARK: - Historical methods
    
    //MARK: methods to implement in your project
    func addToHistory(input:String? = nil, inputData:Any? = nil) {
        self.setHistoryStoreFilesName()
        let newInput = input ?? self.textField?.text ?? searchBar!.text!
        let newInputData = inputData ?? self.selectedData
        let directories = NSSearchPathForDirectoriesInDomains(.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let formatedInput = "H:" + newInput
        if let documents = directories.first {
            if let urlDocuments = NSURL(string: documents) {
                //store suggestion
                if let frequencyURL = urlDocuments.appendingPathComponent(AUTOCOMPLETE_HISTORY_FREQUENCY) {
                    var frequency = NSMutableDictionary()
                    if let loadedfrequency = NSMutableDictionary(contentsOfFile: frequencyURL.path) {
                        frequency = loadedfrequency
                    }
                    if let inputFrequency = frequency[newInput] as? NSNumber {
                        frequency[formatedInput] = (inputFrequency as! Int + 1) as NSNumber
                        
                    } else {
                        frequency[formatedInput] = 1 as NSNumber
                    }
                    self.writeData(data: frequency, dataURL: frequencyURL)
                }
                //storeData
                if let dataURL = urlDocuments.appendingPathComponent(AUTOCOMPLETE_HISTORY_DATA) {
                    var data = NSMutableDictionary()
                    if let loadedData = NSMutableDictionary(contentsOfFile: dataURL.path) {
                        data = loadedData
                        //print(data)
                    }
                    if let newData = newInputData {
                        data[newInput] = NSKeyedArchiver.archivedData(withRootObject: newData)
                    }
                    self.writeData(data: data, dataURL: dataURL)
                }
                UserDefaults.standard.set(("H:" + newInput), forKey: AUTOCOMPLETE_LAST_SEARCH)
            }
        }
    }
    
    func updateDataHistory(for suggestion:String, newData:Any) {
        let directories = NSSearchPathForDirectoriesInDomains(.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        if let documents = directories.first {
            if let urlDocuments = NSURL(string: documents) {
                let dataURL = urlDocuments.appendingPathComponent(AUTOCOMPLETE_HISTORY_DATA)
                let loadedData = NSMutableDictionary(contentsOfFile: dataURL!.path)
                if let data = loadedData {
                    if (data.object(forKey: suggestion) != nil) {
                        data.setValue(NSKeyedArchiver.archivedData(withRootObject:newData), forKey: suggestion)
                        self.writeData(data: data, dataURL: dataURL!)
                        return
                    } else {
                        print("newData")
                        data.setValue(NSKeyedArchiver.archivedData(withRootObject:newData), forKey: suggestion)
                        self.writeData(data: data, dataURL: dataURL!)
                        return
                    }
                }
            }
        }
        print("failed update data")
    }
    
    func removeHistory() {
        self.setHistoryStoreFilesName()
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
        let success = data.write(toFile: dataURL.path, atomically: true)
        print(success ? "data stored with sucess":"error storing data")
    }
    
    //new methodes
    func getHistory() -> (frequency:NSDictionary?, data:NSDictionary?) {
        self.setHistoryStoreFilesName()
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
    
    func getSortedHistory() -> (suggestions:[String], dataDictionary:NSDictionary?) {
        var suggestions:[String] = []
        var datas:NSDictionary? = NSMutableDictionary()
        let (frequency, data) = self.getHistory()
        //test
        //print("frequency dictionnaty\(String(describing: frequency?.count)) & data dictionary \(String(describing: data?.count))")
        //end test
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
                    } else {
                        print("No data found stored for: \(normalLastInput)")
                    }
                }
                
            }
            for value in suggestionsArray {
                if let stringValue = value as? String {
                    if !suggestions.contains(stringValue) {
                        suggestions.append(stringValue)
                        if (stringValue as NSString).length > 3 {
                            let normalStringValue = (stringValue as NSString).substring(from: 2)
                            if let valueData = data?.object(forKey: normalStringValue) {
                                datas!.setValue(valueData, forKey: normalStringValue)
                            } else {
                                print("No data found stored for: \(normalStringValue)")
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
                if self.favoritesData != nil, let favoriteData = favoritesData!.object(forKey: favorite) {
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
        if !self.customActionsAreAllaysVisible {
            self.suggestions = []
        } else {
            self.suggestions = self.customActionsDescription
        }
        
        self.dataDictionary = NSMutableDictionary()
        let (history, historyDatas) = self.getSortedHistory()
        if self.withFavorite {
            for favorite in self.favoritesDescription {
                if (favorite as NSString).length > (input as NSString).length {
                    let scaleFavorite = (favorite as NSString).substring(to: (input as NSString).length)
                    if (input.lowercased() == scaleFavorite.lowercased()) {
                        self.suggestions.append(favorite)
                        if self.favoritesData != nil, let favoriteData = favoritesData!.object(forKey: favorite) {
                            self.dataDictionary.setValue(favoriteData, forKey: favorite)
                        } else if historyDatas != nil, let favoriteData = historyDatas!.object(forKey: favorite) {
                            self.dataDictionary.setValue(favoriteData, forKey: favorite)
                        }
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
                        if historyDatas != nil, let data = historyDatas!.object(forKey: normalDescription) {
                            self.dataDictionary.setValue(data, forKey: normalDescription)
                        }
                    }
                }
            }
        }
    }
    
    private func addDataSourceSuggestions(suggestions:[String], data:NSDictionary?) {
        for suggestion in suggestions {
            if !self.suggestions.contains(suggestion) {
                if !self.suggestions.contains(("H:" + suggestion)) {
                    self.suggestions.append(suggestion as String)
                    if let dictionary = data , let value = dictionary.object(forKey: suggestion){
                        self.dataDictionary.setValue(value, forKey: suggestion)
                    }
                }
            }
        }
    }
    
    func loadSuggestions(_ input:String) {
        if (input as NSString).length >= self.minCharactersforDataSource, let dataSource = self.dataSource {
            dataSource.getSuggestions(autocomplete:self, input: input, completionHandler: { (suggestions, data, suggestionImages) in
                if self.textField?.isEditing ?? false || self.searchBar?.isFirstResponder ?? false {
                    self.suggestionImagesNames = suggestionImages
                    self.loadStoredResults(input: input)
                    self.addDataSourceSuggestions(suggestions: suggestions, data: data)
                    self.showSuggestions()
                }
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

extension Collection {
    
    /// Returns the element at the specified index iff it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Iterator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
