//
//  ViewController.swift
//  xserv-swift
//
//  Created by Giuseppe Nugara on 12/29/2015.
//  Copyright (c) 2015 Giuseppe Nugara. All rights reserved.
//

import UIKit
import XServ

let APP_ID = "9Pf80-3"
let kCellEvents = "CellEvents"
let kCellOperations = "CellOperations";


class ViewController: UIViewController, XservDelegate, UITableViewDelegate, UITableViewDataSource {

    var xserv : Xserv? ;
    var messages : [[String: AnyObject]] = []
    var operations : [[String: AnyObject]] = []
    
    @IBOutlet weak var textTopic: UITextField!
    @IBOutlet weak var textMessage: UITextField!
    @IBOutlet weak var textUser: UITextField!
    @IBOutlet weak var textPassword: UITextField!
    @IBOutlet weak var textLimit: UITextField!
    @IBOutlet weak var textOffset: UITextField!
    
    @IBOutlet weak var tableOperations: UITableView!
    @IBOutlet weak var tableEvents: UITableView!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.messages = []
        self.operations = []
        self.tableEvents.registerClass(UITableViewCell.self, forCellReuseIdentifier: kCellEvents)
        self.tableOperations.registerClass(UITableViewCell.self, forCellReuseIdentifier: kCellOperations)
        xserv = Xserv(appId: APP_ID)
        xserv?.delegate = self
        xserv!.connect()
    }

    func didOpenConnection() {
        print("connect")
    }
    
    func didErrorConnection(reason: NSError!) {
        
    }
    
    func didCloseConnection(reason: NSError!) {
        
    }
    
    func didReceiveMessages(json: [NSObject : AnyObject]!) {
        print(json)
        
        self.messages.insert(json as! [String : AnyObject], atIndex: 0)
        self.tableEvents.reloadData()
    }
    
    func didReceiveOpsResponse(json: [NSObject : AnyObject]!) {
        print(json)
        
        self.operations.insert(json as! [String : AnyObject], atIndex: 0)
        self.tableOperations.reloadData()
    }
    
    @IBAction func onTapConnect(sender: AnyObject) {
        
        self.xserv?.connect()
    }
    
    @IBAction func onTapDisconnect(sender: AnyObject) {
        
        self.xserv?.disconnect()
    }
    
    @IBAction func onTapPublish(sender: AnyObject) {
        
        self.xserv?.publishString(self.textMessage.text, onTopic: self.textTopic.text)
    }
    
    @IBAction func onTapSubscribe(sender: AnyObject) {
        
        self.xserv?.subscribeOnTopic(self.textTopic.text)
    }
    
    @IBAction func onTapPrivateSubscribe(sender: AnyObject) {
        
        let params = ["user" : self.textUser.text!, "pass" : self.textPassword.text!]
        
        self.xserv?.subscribeOnTopic(self.textTopic.text, withAuthEndpoint: params)
    }
    
    @IBAction func onTapUnSubscribe(sender: AnyObject) {
        
        self.xserv?.unsubscribeOnTopic(self.textTopic.text)
    }
    
    @IBAction func onTapPresence(sender: AnyObject) {
        
        self.xserv?.presenceOnTopic(self.textTopic.text)
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 20.0
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        var count = 0
        
        if tableView == self.tableOperations {
            count = self.operations.count
        }
        else if tableView == self.tableEvents {
            count = self.messages.count
        }
        
        return count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell : UITableViewCell?
        
        if tableView == self.tableOperations {
            cell = tableView.dequeueReusableCellWithIdentifier(kCellOperations, forIndexPath: indexPath)
            let mess = self.operations[indexPath.row]
            cell?.textLabel?.text = mess.description
        }
        else if tableView == self.tableEvents {
            cell = tableView.dequeueReusableCellWithIdentifier(kCellEvents, forIndexPath: indexPath)
            let mess = self.messages[indexPath.row]
            cell?.textLabel?.text = mess.description
        }
        
        return cell!
    }
}

