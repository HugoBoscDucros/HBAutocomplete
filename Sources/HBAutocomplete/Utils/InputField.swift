//
//  File.swift
//  HBAutoComplete
//
//  Created by Hugo Bosc-Ducros on 21/06/2019.
//  Copyright © 2019 Hugo Bosc-Ducros. All rights reserved.
//

import Foundation
import UIKit

typealias InputFieldDelegate = UITextFieldDelegate & UISearchBarDelegate

class InputField:NSObject, UISearchBarDelegate {
    
    private unowned var textField: UITextField?
    private unowned var searchBar: UISearchBar?
    private var searchBarIsEditing: Bool = false
    
    weak var delegate:InputFieldDelegate? {
        didSet {
            self.textField?.delegate = self.delegate
            self.searchBar?.delegate = self
        }
    }
    
    init(_ textField:UITextField) {
        self.textField = textField
        self.searchBar = nil
    }
    
    init(_ searchBar:UISearchBar) {
        self.searchBar = searchBar
        self.textField = nil
    }
    
    var view:UIView {
        return textField ?? searchBar!
    }
    
    var isEditing:Bool {
        return textField?.isEditing ?? searchBarIsEditing
    }
    
    var text:String? {
        get {
            return textField?.text ?? searchBar!.text
        }
        set {
            searchBar?.text = newValue
            textField?.text = newValue
        }
    }
    
    var font:UIFont? {
        return (self.textField ??  self.searchBar?.textField)?.font ?? UIFont.systemFont(ofSize: 17)
    }
    
    func resignFirstResponder() {
        self.textField?.resignFirstResponder()
        self.searchBar?.resignFirstResponder()
    }
    
    func becomeFirstResponder() {
        self.textField?.becomeFirstResponder()
        self.searchBar?.becomeFirstResponder()
    }
    
    
    //MARK: - SearchBarDelegate
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        self.searchBarIsEditing = false
        self.delegate?.searchBarTextDidEndEditing?(searchBar)
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.searchBarIsEditing = true
        self.delegate?.searchBarTextDidBeginEditing?(searchBar)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.delegate?.searchBar?(searchBar, textDidChange: searchText)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.delegate?.searchBarSearchButtonClicked?(searchBar)
    }
}

extension UISearchBar {
    var textField:UITextField? {
        return self.find(UITextField.self)
    }
}

public extension UIView {
    
    func find<T>(_ type:T.Type) -> T? {
        for subview in self.subviews {
            if let type = subview as? T {
                return type
            } else if let type = subview.find(T.self) {
                return type
            }
        }
        return nil
    }
}
