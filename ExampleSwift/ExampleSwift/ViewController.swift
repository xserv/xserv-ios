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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        xserv = Xserv(appId: "qLxFC-1")
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
    
    func didReceiveOps(message: AnyObject!) {
        print(message)
    }
    
    func didOpenConnection() {
        xserv!.bindWithTopic("milan", withEvent: "cazzate")
    }
    
    func didCloseConnectionWithReason(reason: String!) {
        
    }
    
    func didFailWithError(error: NSError!) {
        
    }

}

