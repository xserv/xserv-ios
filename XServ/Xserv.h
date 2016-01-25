//
//  Xserv.h
//  Pods
//
//  Created by Giuseppe Nugara on 26/12/15.
//
//

#import <Foundation/Foundation.h>

@protocol XservDelegate <NSObject>

- (void) didReceiveEvents:(id)message;
- (void) didReceiveOpsResponse:(id)message;

@optional
- (void) didOpenConnection;
//- (void) didCloseConnectionWithReason:(NSString *) reason;
//- (void) didFailWithError:(NSError *)error;

- (void) didErrorConnection:(NSError *)reason;
- (void) didCloseConnection:(NSError *)reason;
@end

@interface Xserv : NSObject

@property BOOL autoConnect;
@property (nonatomic, weak) id <XservDelegate> delegate;

- (instancetype)initWithAppId:(NSString *) appId;
- (BOOL) isConnected;
- (void) connect;
- (void) disconnect;
- (NSString *) bindWithTopic:(NSString *) topic withEvent:(NSString *) event;
- (NSString *) unbindWithTopic:(NSString *) topic withEvent:(NSString *) event;
- (void) trigger:(NSString *) message withTopic:(NSString *) topic withEvent:(NSString *) event;
- (NSString *) historyByIdWithTopic:(NSString *)topic withEvent:(NSString *) event withOffset:(int) offset withLimit:(int) limit;
- (NSString *) historyByTimeStampWithTopic:(NSString *)topic withEvent:(NSString *) event withOffset:(int) offset withLimit:(int) limit;

@end
