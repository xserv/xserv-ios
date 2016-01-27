//
//  XservViewController.h
//  xserv-objective-c
//
//  Created by Giuseppe Nugara on 12/29/2015.
//  Copyright (c) 2015 Giuseppe Nugara. All rights reserved.
//

@import UIKit;

@interface XservViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextField *textTopic;
@property (weak, nonatomic) IBOutlet UITextField *textEvent;
@property (weak, nonatomic) IBOutlet UITextField *textMessage;
@property (weak, nonatomic) IBOutlet UITextField *textUser;
@property (weak, nonatomic) IBOutlet UITextField *textPassword;
@property (weak, nonatomic) IBOutlet UITableView *tableViewMessages;
@property (weak, nonatomic) IBOutlet UITextField *textLimit;
@property (weak, nonatomic) IBOutlet UITextField *textOffset;
@property (weak, nonatomic) IBOutlet UITableView *tableViewOperations;

- (IBAction)onTapConnect:(id)sender;
- (IBAction)onTapDisconnect:(id)sender;
- (IBAction)onTapBind:(id)sender;
- (IBAction)onTapUnBind:(id)sender;
- (IBAction)onTapTrigger:(id)sender;
- (IBAction)onTapHistoryById:(id)sender;
- (IBAction)onTapHistoryByTimeStamo:(id)sender;
- (IBAction)onTapPrivateBind:(id)sender;
- (IBAction)onTapPresence:(id)sender;


@end
