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

class InputField:NSObject {
    
    private unowned var textField: UITextField?
    private unowned var searchBar: UISearchBar?
    
    weak var delegate:InputFieldDelegate? {
        didSet {
            self.textField?.delegate = self.delegate
            self.searchBar?.delegate = self.delegate
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
    
    var view:UIView? {
        return textField ?? searchBar
    }
    
    var isEditing:Bool? {
        return textField?.isEditing ?? searchBar?.textField?.isEditing
    }
    
    var text:String? {
        get {
            return textField?.text ?? searchBar?.text
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
