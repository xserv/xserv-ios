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
@property (weak, nonatomic) IBOutlet UITextField *textMessage;
@property (weak, nonatomic) IBOutlet UITextField *textUser;
@property (weak, nonatomic) IBOutlet UITextField *textPassword;
@property (weak, nonatomic) IBOutlet UITableView *tableViewMessages;
@property (weak, nonatomic) IBOutlet UITextField *textLimit;
@property (weak, nonatomic) IBOutlet UITextField *textOffset;
@property (weak, nonatomic) IBOutlet UITableView *tableViewOperations;

- (IBAction)onTapConnect:(id)sender;
- (IBAction)onTapDisconnect:(id)sender;
- (IBAction)onTapSubscribe:(id)sender;
- (IBAction)onTapUnSubscribe:(id)sender;
- (IBAction)onTapPublish:(id)sender;
- (IBAction)onTapHistoryById:(id)sender;
- (IBAction)onTapHistoryByTimeStamo:(id)sender;
- (IBAction)onTapPrivateSubscribe:(id)sender;
- (IBAction)onTapPresence:(id)sender;


@end
