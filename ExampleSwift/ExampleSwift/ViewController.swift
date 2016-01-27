//
//  ViewController.swift
//  xserv-swift
//
//  Created by Giuseppe Nugara on 12/29/2015.
//  Copyright (c) 2015 Giuseppe Nugara. All rights reserved.
//

import UIKit
import XServ

class ViewController: UIViewController, XservDelegate {

    var xserv : Xserv? ;
    
    @IBOutlet weak var textTopic: UITextField!
    @IBOutlet weak var textEvent: UITextField!
    @IBOutlet weak var textMessage: UITextField!
    @IBOutlet weak var textUser: UITextField!
    @IBOutlet weak var textPassword: UITextField!
    @IBOutlet weak var textLimit: UITextField!
    @IBOutlet weak var textOffset: UITextField!
    
    @IBAction func onTapConnect(sender: AnyObject) {
        
        self.xserv?.connect()
    }
    
    @IBAction func onTapDisconnect(sender: AnyObject) {
        
        self.xserv?.disconnect()
    }
    
    @IBAction func onTapTrigger(sender: AnyObject) {
        
        self.xserv?.trigger(self.textMessage.text , withTopic: self.textTopic.text, withEvent: self.textEvent.text)
    }
    
    @IBAction func onTapBind(sender: AnyObject) {
        
        self.xserv?.bindWithTopic(self.textTopic.text, withEvent: self.textEvent.text, withAuthEndpoint: nil)
    }
    
    @IBAction func onTapPrivateBind(sender: AnyObject) {
        
        let params = ["user" : self.textUser.text!, "pass" : self.textPassword.text!]
        
        self.xserv?.bindWithTopic(self.textTopic.text, withEvent: self.textEvent.text, withAuthEndpoint: params)
        
    }
    
    @IBAction func onTapUnbind(sender: AnyObject) {
    }
    
    @IBAction func onTapPresence(sender: AnyObject) {
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        xserv = Xserv(appId: "9Pf80-3")
        xserv?.delegate = self
        xserv!.connect()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func didReceiveEvents(message: AnyObject!) {
        print(message)
    }
    
    func didReceiveOpsResponse(message: AnyObject!) {
        print(message)
    }
    
    func didOpenConnection() {
        print("connect")
       // xserv!.bindWithTopic("milan", withEvent: "cazzate", withAuthEndpoint: nil)
    }
    
    func didErrorConnection(reason: NSError!) {
        
    }
    
    func didCloseConnection(reason: NSError!) {
        
    }
    
    
    

}

