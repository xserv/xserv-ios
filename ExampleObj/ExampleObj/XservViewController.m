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
static NSString *kCellEvents = @"CellEvents";
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
    [self.tableViewMessages registerClass:[UITableViewCell class] forCellReuseIdentifier:kCellEvents];
    [self.tableViewOperations registerClass:[UITableViewCell class] forCellReuseIdentifier:kCellOperations];
}

#pragma mark - onTap Event

- (IBAction)onTapConnect:(id)sender {
    
    [self.xserv connect];
}

- (IBAction)onTapDisconnect:(id)sender {
    
    [self.xserv disconnect];
}

- (IBAction)onTapSubscribe:(id)sender {
    
    [self.xserv subscribeOnTopic:self.textTopic.text];
}

- (IBAction)onTapUnSubscribe:(id)sender {
    
    [self.xserv unsubscribeOnTopic:self.textTopic.text];
}

- (IBAction)onTapPublish:(id)sender {
    if ([self.textMessage.text length] > 0) {
        id data = self.textMessage.text;
        
        NSData *objectData = [data dataUsingEncoding:NSUTF8StringEncoding];
        
        NSError *error;
        id tmp = [NSJSONSerialization JSONObjectWithData:objectData options:0 error:&error];
        
        if(error == nil && tmp != nil) {
            //data = tmp;
        }
        
        [self.xserv publish:data onTopic:self.textTopic.text];
        
        self.textMessage.text = @"";
    }
}

- (IBAction)onTapHistoryByTimeStamo:(id)sender {
    NSDictionary *params = @{
                             @"offset": [NSNumber numberWithInt:[self.textOffset.text intValue]],
                             @"limit": [NSNumber numberWithInt:[self.textLimit.text intValue]],
                             // @"query": @{@"data.n": @{@"$gte": [NSNumber numberWithInt:2]}}
                             };
    
    [self.xserv historyOnTopic:self.textTopic.text withParams:params];
}

- (IBAction)onTapPrivateSubscribe:(id)sender {
    NSDictionary *auth = @{
                           /*@"headers": @{
                                   
                           },*/
                           @"params": @{
                                   @"user" : self.textUser.text,
                                   @"pass" : self.textPassword.text
                           }
    };
    
    [self.xserv subscribeOnTopic:self.textTopic.text withAuth:auth];
}

- (IBAction)onTapPresence:(id)sender {
    
    [self.xserv usersOnTopic:self.textTopic.text];
    
}

#pragma mark - Xserv Protocol

- (void) didReceiveMessages:(NSDictionary *)json {
    
    NSLog(@"message: %@", json);
    
    [self.messages insertObject:json atIndex:0];
    [self.tableViewMessages reloadData];
}

- (void) didReceiveOperations:(NSDictionary *)json {
    
    NSLog(@"operation: %@", json);
    
    [self.operations insertObject:json atIndex:0];
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
        
        cell = [tableView dequeueReusableCellWithIdentifier:kCellEvents forIndexPath:indexPath];
        
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
