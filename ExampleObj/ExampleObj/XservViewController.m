//
//  XservViewController.m
//  xserv-objective-c
//
//  Created by Giuseppe Nugara on 12/29/2015.
//  Copyright (c) 2015 Giuseppe Nugara. All rights reserved.
//

#import "XservViewController.h"
#import <XServ/Xserv.h>

static NSString *APP_ID = @"9Pf80-3";
static NSString *kCellMessages = @"CellMessages";
static NSString *kCellOperations = @"CellOperations";

@interface XservViewController ()  <XservDelegate, UITextFieldDelegate>

@property (nonatomic, strong) Xserv *xserv;
@property (nonatomic, strong) NSMutableArray *messages;
@property (nonatomic, strong) NSMutableArray *operations;

@end

@implementation XservViewController

#pragma mark -

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.xserv = [[Xserv alloc]initWithAppId:APP_ID];
    self.xserv.delegate = self;
    self.messages = [NSMutableArray new];
    self.operations = [NSMutableArray new];
    [self.tableViewMessages registerClass:[UITableViewCell class] forCellReuseIdentifier:kCellMessages];
    [self.tableViewOperations registerClass:[UITableViewCell class] forCellReuseIdentifier:kCellOperations];
}

#pragma mark - onTap Event

- (IBAction)onTapConnect:(id)sender {
    
    [self.xserv connect];
}

- (IBAction)onTapDisconnect:(id)sender {
    
    [self.xserv disconnect];
}

- (IBAction)onTapBind:(id)sender {
    
    [self.xserv bindOnTopic:self.textTopic.text withEvent:self.textEvent.text withAuthEndpoint:nil];
}

- (IBAction)onTapUnBind:(id)sender {
    
    [self.xserv unbindOnTopic:self.textTopic.text withEvent:self.textEvent.text];
}

- (IBAction)onTapTrigger:(id)sender {
    
    [self.xserv triggerString:self.textMessage.text onTopic:self.textTopic.text withEvent:self.textEvent.text];
}

- (IBAction)onTapHistoryById:(id)sender {
    
    [self.xserv historyByIdOnTopic:self.textTopic.text withEvent:self.textEvent.text withOffset:[self.textOffset.text intValue] withLimit:[self.textLimit.text intValue]];
}

- (IBAction)onTapHistoryByTimeStamo:(id)sender {
    [self.xserv historyByTimeStampOnTopic:self.textTopic.text withEvent:self.textEvent.text withOffset:[self.textOffset.text intValue] withLimit:[self.textLimit.text intValue]];
}

- (IBAction)onTapPrivateBind:(id)sender {
    
    NSDictionary *autorizationParams = @{
                                         @"user" : self.textUser.text,
                                         @"pass" : self.textPassword.text
                                         };
    
    [self.xserv bindOnTopic:self.textTopic.text withEvent:self.textEvent.text withAuthEndpoint:autorizationParams];
}

- (IBAction)onTapPresence:(id)sender {
    
    [self.xserv presenceOnTopic:self.textTopic.text withEvent:self.textEvent.text];
    
}

#pragma mark - Xserv Protocol

- (void) didReceiveEvents:(id)message {
    
    NSLog(@"message: %@", message);
    
    [self.messages insertObject:message atIndex:0];
    [self.tableViewMessages reloadData];
}

- (void) didReceiveOpsResponse:(id)message {
    
    NSLog(@"operation: %@", message);
    
    [self.operations insertObject:message atIndex:0];
    [self.tableViewOperations reloadData];
}

- (void) didOpenConnection {
    
    NSLog(@"%s", __func__);
}

- (void) didCloseConnection:(NSError *)reason {
   
    NSLog(@"Connection closed - %@", reason);
}

- (void) didErrorConnection:(NSError *)reason {
    
    NSLog(@"error: %@", reason);
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = 0;
    
    if([tableView isEqual:self.tableViewMessages])
        count = self.messages.count;
    else if([tableView isEqual:self.tableViewOperations])
        count = self.operations.count;
    
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    if([tableView isEqual:self.tableViewMessages]) {
        
        cell = [tableView dequeueReusableCellWithIdentifier:kCellMessages forIndexPath:indexPath];
        
        NSData * jsonData = [NSJSONSerialization  dataWithJSONObject:self.messages[indexPath.row] options:0 error:nil];
        
        cell.textLabel.font = [UIFont systemFontOfSize:8];
        cell.textLabel.text = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    else if([tableView isEqual:self.tableViewOperations]){
        
        cell = [tableView dequeueReusableCellWithIdentifier:kCellOperations forIndexPath:indexPath];
        NSData * jsonData = [NSJSONSerialization  dataWithJSONObject:self.operations[indexPath.row] options:0 error:nil];
        cell.textLabel.font = [UIFont systemFontOfSize:8];
        cell.textLabel.text = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 15.0;
}

#pragma mark - UITextFiledDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    return YES;
}

@end
