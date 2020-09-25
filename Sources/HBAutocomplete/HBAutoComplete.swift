//
//  File.swift
//  HBAutoComplete
//
//  Created by Hugo Bosc-Ducros on 11/06/2019.
//  Copyright © 2019 Hugo Bosc-Ducros. All rights reserved.
//

import Foundation
import UIKit

//TEST

public protocol HBAutocompleteDataSource:class {
    func getSuggestions(autocomplete:HBAutocomplete, input:String, completionHandler:@escaping(_ suggestions:[String], _ data:[String:Any]?, _ suggestionImages:[String:UIImage]?) -> Void)
}

public protocol HBAutoCompleteActionsDelegate:class {
    func didSelect(autocomplete:HBAutocomplete, index:Int, suggestion:String, data:Any?)
    func didSelectCustomAction(autocomplete:HBAutocomplete, index:Int)
}

public protocol HBAutoCompleteTableViewDelegate:class {
    func tableViewDidShow(autocomplete:HBAutocomplete, tableView:UITableView)
    func tableViewDidHide(autocomplete:HBAutocomplete, tableView:UITableView)
}

public protocol HBAutocompleteStore {
    func getHistory() -> (suggestions:[String], dataDictionary:[String:Any]?)
    func updateDataHistory(for suggestion:String, newData:Any)
    func addToHistory(input:String, inputData:Any?)
    func cleanHistory()
}

public class HBAutocomplete:NSObject, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    
    //customable variables
    
    //custom lines actions
    private var customActionsDescription:[String] = []
    private var customActionsImages:[UIImage] = []
    
    //favorites
    public private(set) var favoritesDescription:[String] = []
    public private(set) var favoritesData:[String:Any]?
    private var favoritesImages:[UIImage] = []
    
    //historical
    public var historicalImage:UIImage?
    public var historicalImageTint: UIColor?
    
    
    //Graphical settings (you can set it in the view controller to change displaying style)
    public var maxVisibleRow:Int = 5
    public var maxHistoricalRow:Int = 3
    public var minCharactersforDataSource:Int = 1
    public var cellFont:UIFont?
    public var cellHeight:CGFloat?
    public var cellBackgroundColor:UIColor?
    public var suggestionTextColor:UIColor?
    //optional features
    public var withFavorite:Bool = false
    //var withCustomActions:Bool = false
    public var tableViewIsReproducingViewStyle = true
    public var customActionsAreAllaysVisible = false
    
    //internal variables
    
    //dataSource & actions delegates
    public weak var dataSource:HBAutocompleteDataSource?
    public weak var actionsDelegate:HBAutoCompleteActionsDelegate?
    //delegates for subviews & layers gestion
    public weak var tableViewDelegate:HBAutoCompleteTableViewDelegate?
    public weak var textFieldDelegate:UITextFieldDelegate?
    public weak var searchBarDelegate:UISearchBarDelegate?
    
    
    //historyStoreDelegate
    public var store:HBAutocompleteStore? {
        didSet {
            self.loadSuggestions()
        }
    }
    
    var dataDictionary = [String:Any]()
    public var selectedData:Any?
    var suggestions:[String] = [] {
        didSet {
            self.tableView.reloadData()
            let _ = self.updateTableViewFrameIfNeeded()
        }
    }
    var suggestionImages:[String:UIImage]?
    
    weak var templateView:UIView?
    
    private var tableView:UITableView {
        print("tableView is \(externalTableView != nil ? "external":"internal")")
        return externalTableView ?? internalTableView
    }
    private lazy var internalTableView = UITableView()
    private var internalTableViewIsSet = false
    private var textField:InputField
    private weak var externalTableView:UITableView?
    private var tableViewIsExternal:Bool {
        return self.tableView == externalTableView
    }
    
    
    // MARK: - Instanciate method
    
    
    public init(_ textField:UITextField, templateView:UIView? = nil) {
        self.textField = InputField(textField)
        self.templateView = templateView
        super.init()
        self.setTableViewAndField()
    }
    
    public init(_ textField:UITextField, tableView:UITableView? = nil) {
        self.textField = InputField(textField)
        self.externalTableView = tableView
        super.init()
        self.setTableViewAndField()
    }
    
    public init(_ searchBar:UISearchBar,tableView:UITableView) {
        self.textField = InputField(searchBar)
        self.externalTableView = tableView
        super.init()
        self.setTableViewAndField()
    }
    
    
    private func setTableViewAndField() {
        self.textField.delegate = self
        self.tableView.allowsSelection = true
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.loadSuggestions()
    }
    
    private func setInternalTableViewStyle() {
        let templateView = self.templateView ?? textField.view
        self.internalTableView.layer.cornerRadius = templateView.layer.cornerRadius
        self.internalTableView.layer.borderWidth = templateView.layer.borderWidth
        self.internalTableView.layer.borderColor = templateView.layer.borderColor
        self.internalTableView.backgroundColor = templateView.backgroundColor
    }
    
    
    //MARK: - Utils
    
    public func update(suggestion:String, data:Any?) {
        self.textField.text! = suggestion
        self.selectedData = data
    }
    
    private func getSuggestionImages() -> [String:UIImage] {
        var images = self.suggestionImages ?? [String:UIImage]()
        for suggestion in suggestions {
            if let index = favoritesDescription.firstIndex(of: suggestion), let image = self.favoritesImages[safe:index] ?? self.favoritesImages.first {
                images[suggestion] = image
            } else if let index = self.customActionsDescription.firstIndex(of: suggestion), let image = self.customActionsImages[safe:index] ?? self.customActionsImages.first {
                images[suggestion] = image
            } else if self.store?.getHistory().suggestions.contains(suggestion) ?? false, let image = self.historicalImage {
                images[suggestion] = image
            }
        }
        return images
    }
    
    public func becomeFirstResponder() {
        self.textField.becomeFirstResponder()
    }
    
    
    // MARK: - Show/Hide tableView suggestions
    
    private func updateTableViewFrameIfNeeded() -> UIView? {
        let templateView = self.templateView ?? textField.view
        if !self.tableViewIsExternal, let (hyperView, origin) = self.getHyperViewAndOrigin(from: templateView) {
            var tableViewSize = templateView.frame.size
            tableViewSize.height *= CGFloat(min(self.suggestions.count, self.maxVisibleRow))
            var tableViewOrigin = origin
            tableViewOrigin.y += templateView.frame.height
            self.tableView.frame = CGRect(origin: tableViewOrigin, size: tableViewSize)
            return hyperView
        }
        return nil
    }
    
    private func showTableViewIfNeeded() {
        if let hyperView = updateTableViewFrameIfNeeded() {
            if !internalTableViewIsSet {
                self.setInternalTableViewStyle()
                self.internalTableViewIsSet = true
            }
            hyperView.addSubview(self.tableView)
            self.tableViewDelegate?.tableViewDidShow(autocomplete: self, tableView: tableView)
        }
    }
    
    private func hideTableViewIfNeeded() {
        if !self.tableViewIsExternal {
            self.tableView.removeFromSuperview()
            self.tableViewDelegate?.tableViewDidHide(autocomplete:self, tableView:self.tableView)
        }
    }
    
    private func getHyperViewAndOrigin(from view:UIView) -> (UIView, CGPoint)? {
        var origin = view.frame.origin
        var parentView = view
        while let newParent = parentView.superview {
            origin.x += newParent.frame.origin.x
            origin.y += newParent.frame.origin.y
            parentView = newParent
        }
        return (parentView, origin)
    }
    
    
    // MARK: - tableView delagate & datasource
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.font = (self.cellFont == nil) ? self.textField.font:self.cellFont!
        cell.textLabel?.textColor = self.suggestionTextColor ?? .black
        if let color = self.cellBackgroundColor {
            cell.backgroundColor = color
        }
        //print("cell as textLabel : \((cell.textLabel != nil) ? "yes":"no")")
        if let lineString = self.suggestions[safe:indexPath.row] {
            cell.textLabel!.text = lineString
            let images = self.getSuggestionImages()
            if let image = images[lineString] {
                cell.imageView?.image = image
                cell.imageView?.tintColor = self.historicalImageTint
            }
        }
        
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let lineString = self.suggestions[safe:indexPath.row] {
            if self.customActionsDescription.contains(lineString) {
                self.textField.resignFirstResponder()
                tableView.deselectRow(at: indexPath, animated: true)
                self.actionsDelegate?.didSelectCustomAction(autocomplete:self, index: self.customActionsDescription.firstIndex(of: lineString)!)
            } else {
                self.textField.text = tableView.cellForRow(at: indexPath)?.textLabel!.text
                if let data = self.dataDictionary[self.textField.text!] {
                    self.selectedData = data
                } else {
                    self.selectedData = nil
                }
                self.actionsDelegate?.didSelect(autocomplete:self, index:indexPath.row, suggestion: self.textField.text!, data: self.selectedData)
            }
        }
        self.textField.resignFirstResponder()
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return suggestions.count
    }
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let height = self.cellHeight {
            return height
        } else if let templateView = self.templateView {
            return templateView.bounds.size.height
        }
        return self.textField.view.layer.bounds.height
    }
    
    
    // MARK: - textField delegate
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let str = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        self.loadSuggestions(str)
        return true
    }
    
    @available(iOS 10.0, *)
    public func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        self.textFieldDelegate?.textFieldDidEndEditing?(textField, reason: reason)
        self.hideTableViewIfNeeded()
    }
    
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        self.textFieldDelegate?.textFieldDidBeginEditing?(textField)
        self.showTableViewIfNeeded()
        
    }
    
    public func textFieldDidEndEditing(_ textField: UITextField) {
        self.textFieldDelegate?.textFieldDidEndEditing?(textField)
        self.hideTableViewIfNeeded()
    }
    
    public func textFieldShouldClear(_ textField: UITextField) -> Bool {
        self.loadSuggestions("")
        return  self.textFieldDelegate?.textFieldShouldClear?(textField) ?? true
    }
    
    
    //MARK: - searchBar delegate
    
    public func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.searchBarDelegate?.searchBarTextDidBeginEditing?(searchBar)
        self.showTableViewIfNeeded()
    }
    
    public func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        self.searchBarDelegate?.searchBarTextDidEndEditing?(searchBar)
        self.hideTableViewIfNeeded()
    }
    
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchBarDelegate?.searchBar?(searchBar, textDidChange: searchText)
        self.loadSuggestions(searchText)
    }
    
    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.searchBarDelegate?.searchBarSearchButtonClicked?(searchBar)
    }
    
    
    // MARK: - Historical methods
    
    //MARK: methods to implement in your project
    public func addToHistory(input:String? = nil, inputData:Any? = nil) {
        let newInput = input ?? self.textField.text!
        let newData = inputData ?? self.selectedData
        self.store?.addToHistory(input: newInput, inputData: newData)
    }
    
    public func updateDataHistory(for suggestion:String, newData:Any) {
        self.store?.updateDataHistory(for: suggestion, newData: newData)
    }
    
    public func cleanHistory() {
        self.store?.cleanHistory()
    }
    
    
    //MARK: internal methodes for historical
    
    private func loadStoredResults(input:String) -> ([String], [String:Any]) {
        var suggestion = [String]()
        var datas = [String:Any]()
        if self.customActionsAreAllaysVisible || input.count == 0 {
            suggestion = self.customActionsDescription
        }
        let (history, historyDatas) = self.store?.getHistory() ?? ([String](), nil)
        suggestion.appendFiltered(self.favoritesDescription, matching: input)
        suggestion.appendFiltered(history, matching: input)
        datas.mergeFilterd(self.favoritesData ?? [String:Any](), matching: input)
        datas.mergeFilterd(historyDatas ?? [String:Any](), matching: input)
        return (suggestion,datas)
    }

    
    
    
    private func update(_ suggestions:[String], data:[String:Any]) {
        self.dataDictionary = data
        self.suggestions = suggestions
    }
    
    private func loadSuggestions(_ newInput:String? = nil) {
        let input = newInput ?? self.textField.text ?? ""
        if input.count >= self.minCharactersforDataSource, let dataSource = self.dataSource {
            dataSource.getSuggestions(autocomplete:self, input: input, completionHandler: { (suggestions, data, suggestionImages) in
                self.suggestionImages = suggestionImages
                var (newSuggestion,storedDatas) = self.loadStoredResults(input: input)
                for suggestion in suggestions {
                    if !newSuggestion.map({$0.lowercased()}).contains(suggestion.lowercased()) {
                        newSuggestion.append(suggestion)
                    }
                }
                let newDatas = storedDatas.merging(data ?? [String:Any]()){ (_,new) in new}
                self.update(newSuggestion, data: newDatas)
            })
        } else  {
            let (suggestions, datas) = self.loadStoredResults(input: input)
            self.update(suggestions, data: datas)
        }
    }
    
    
    // Mark: - Favorite methodes
    
    public func setFavorites(description:[String], images:[UIImage]? = nil) {
        self.favoritesDescription = description
        if let images = images {
            self.favoritesImages = images
        }
        self.loadSuggestions()
    }
    
    public func setFavorites(data:[String:Any], images:[UIImage]? = nil) {
        self.favoritesDescription = data.compactMap({$0.key})
        self.favoritesData = data
        if let images = images {
            self.favoritesImages = images
        }
        self.loadSuggestions()
    }
    
    public func setCustomeActions(descriptions:[String], images:[UIImage]? = nil) {
        self.customActionsDescription = descriptions
        if let images = images {
            self.customActionsImages = images
        }
        self.loadSuggestions()
    }
    
    private func getFavorite() -> [String] {
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

extension Array where Element == String {
    mutating func appendFiltered(_ contentsOf: [String],matching input:String?) {
        var filteredContent = contentsOf
        if let input = input, !input.isEmpty {
            filteredContent = filteredContent.filter({$0.lowercased().contains(input.lowercased())})
        }
        filteredContent = filteredContent.filter({!self.map{ value in value.lowercased()}.contains($0.lowercased())})
        self.append(contentsOf:filteredContent)
    }
}

extension Dictionary where Key == String,Value == Any {
    mutating func mergeFilterd(_ contentsOf:[String:Any], matching input:String?) {
        var filteredContent = contentsOf
        if let input = input, !input.isEmpty {
            filteredContent = filteredContent.filter({$0.key.lowercased().contains(input.lowercased())})
        }
        filteredContent = filteredContent.filter({!self.map{value in value.key.lowercased()}.contains($0.key.lowercased())})
        self.merge(filteredContent) { (_, new) in new}
    }
}
