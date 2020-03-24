//
//  File.swift
//  Padam
//
//  Created by Hugo Bosc-Ducros on 17/05/2018.
//  Copyright © 2018 OPTIWAYS SAS. All rights reserved.
//
import UIKit

public protocol HBDropDownListDelegate:class {
    func didSelectItem(dropDownList:HBDropDownList, selectedString:String, at index:Int, forView:UIView)
}

public class HBDropDownList:NSObject, UITableViewDataSource, UITableViewDelegate {
    
    weak var ownerView:UIView!
    var data = [String]()
    var tableView:UITableView
    weak var delegate:HBDropDownListDelegate?
    var isVisible = false
    var completionHandler:((String)->())?
    
    private static var percistantInstance:HBDropDownList = {
       return HBDropDownList()
    }()
    
    public convenience init(delegate:HBDropDownListDelegate) {
        self.init()
        self.delegate = delegate
    }
    
    private override init() {
        self.tableView = UITableView()
        super.init()
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    
    //MARK : - show/hide methods
    
    public func show(below:UIView, withData:[String]? = nil) {
        self.ownerView = below
        if let data = withData {
            self.data = data
            self.tableView.reloadData()
        }
        print(below.frame)
        var x = below.frame.origin.x
        var y = below.frame.origin.y + below.frame.size.height
        let width = below.frame.width
        let height = below.frame.height * CGFloat(self.data.count) as CGFloat
        var view = below
        while let superview = view.superview {
            x += superview.frame.origin.x
            y += superview.frame.origin.y
            view = superview
        }
        let viewSubHeight = view.frame.height - y - 16
        let finalHeight = [height, viewSubHeight].min()!
        print(CGRect(x: x, y: y, width: width, height: finalHeight))
        self.tableView.frame = CGRect(x: x, y: y, width: width, height: finalHeight)
        self.tableView.layer.cornerRadius = below.layer.cornerRadius
        self.tableView.backgroundColor = below.backgroundColor
        self.tableView.layer.borderColor = below.layer.borderColor
        self.tableView.layer.borderWidth = below.layer.borderWidth
        view.addSubview(self.tableView)
        self.isVisible = true
        self.ownerView.bringSubviewToFront(tableView)
    }
    
    public func hide() {
        self.tableView.removeFromSuperview()
        self.isVisible = false
    }
    
    public static func show(below:UIView, withData:[String]? = nil, completionHandler:@escaping (String) -> ()) {
        self.percistantInstance.show(below:below, withData:withData)
        self.percistantInstance.completionHandler = completionHandler
    }
    
    public static func hide() {
        self.percistantInstance.hide()
    }
    
    
    //MARK: - UITableViewDataSource
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = self.data[indexPath.row]
        return cell
    }
    
    //MARK: - UITableViewDelegate
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.delegate?.didSelectItem(dropDownList: self, selectedString: self.data[indexPath.row], at: indexPath.row, forView:self.ownerView)
        self.completionHandler?(self.data[indexPath.row])
        self.hide()
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.ownerView.frame.height
    }
}
