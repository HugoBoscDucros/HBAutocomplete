//
//  HBDAutoComplete.swift
//  HBDAutoComplete
//
//  Created by Hugo Bosc-Ducros on 09/03/2019.
//  Copyright © 2019 HBD. All rights reserved.
//

public protocol HBDAutocompleteDataSource:AnyObject {
    func autocomplete(_ autocomplete:HBDAutoComplete, suggestionsFor input:String, completion:@escaping(_ suggestions:[String], _ dataDictionary:[String:Any]?)->())
    //func autocomplete(_ autocomplete:HBDAutoComplete, dataFor suggestion:String) -> Any?
    func autocomplete(_ autocomplete:HBDAutoComplete, imageFor suggestion:String) -> UIImage?
}

extension HBDAutocompleteDataSource {
//    func autocomplete(_ autocomplete:HBDAutoComplete, dataFor suggestion:String) -> Any? {
//        return nil
//    }
    
    func autocomplete(_ autocomplete:HBDAutoComplete, imageFor suggestion:String) -> UIImage? {
        return nil
    }
}

import Foundation

public class HBDAutoComplete:NSObject,UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    
    //storedData from dataSource
    var suggestions = [String]()
    var datas:[String:Any]?
    //managed UI objects
    var textField:UITextField
    var tableView:UITableView {
        return externalTableView ?? internalTableView
    }
    //delegates
    public weak var dataSource:HBDAutocompleteDataSource?
    public weak var textFieldDelegate:UITextFieldDelegate?
    //private parameters
    private weak var externalTableView:UITableView?
    private var internalTableView:UITableView!
    private var tableViewIsExternal:Bool {
        return self.tableView == self.externalTableView
    }
    //public functional parameters
    public var minimumCaracterToCallDataSource:Int = 3
    public var maximumCaracterToShowCustomActions:Int = 0
    
    
    //MARK: - Init
    
    public init(_ textField:UITextField, tableView:UITableView? = nil) {
        self.textField = textField
        if let delegate = textField.delegate, self.textFieldDelegate == nil {
            self.textFieldDelegate = delegate
        }
        if let tableView = tableView {
            self.externalTableView = tableView
        } else {
            self.internalTableView = UITableView()
            //TODO make internal tableView frame
        }
    }
    
    
    //MARK: - UITableViewDataSource
    
    private func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return suggestions.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let suggestion = suggestions[indexPath.row]
        let cell = UITableViewCell()
        cell.textLabel?.text = suggestion
        cell.imageView?.image = self.dataSource?.autocomplete(self, imageFor: suggestion)
        return cell
    }
    
    
    //MARK : - UITableViewDelegate
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.textField.text = suggestions[indexPath.row]
        self.textField.resignFirstResponder()
    }
    
    
    //MARK: - UITextFieldDelegate
    
    private func textFieldDidBeginEditing(_ textField: UITextField) {
        self.showTableView()
        self.textFieldDelegate?.textFieldDidBeginEditing?(textField)
    }
    
    private func textFieldDidEndEditing(_ textField: UITextField) {
        self.hideTableView()
        self.textFieldDelegate?.textFieldDidBeginEditing?(textField)
    }
    
    private func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        //call AutoCompleteDataSource
        if let text = textField.text, let textRange = Range(range, in: text), let dataSource = self.dataSource{
            let updatedText = text.replacingCharacters(in: textRange, with: string)
            dataSource.autocomplete(self, suggestionsFor: updatedText, completion: { (suggestions, dataDictionary) in
                self.suggestions = suggestions
                self.datas = dataDictionary
                self.tableView.reloadData()
            })
        }
        
        
        return self.textFieldDelegate?.textField?(textField, shouldChangeCharactersIn: range, replacementString: string) ?? true
    }
    
    
    //MARK: - Internal tableView methods
    
    func showTableView() {
        if !self.tableViewIsExternal, self.textField.isEditing {
            //TODO, show tableView
        }
    }
    
    func hideTableView() {
        //TODO hide tableView
    }
    
}
