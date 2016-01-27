//
//  Xserv.h
//  Pods
//
//  Created by Giuseppe Nugara on 26/12/15.
//
//

#import <Foundation/Foundation.h>

typedef enum XservResultCode : NSInteger {
    RC_OK = 1,
    RC_GENERIC_ERROR = 0,
    RC_ARGS_ERROR = -1,
    RC_ALREADY_BINDED = -2,
    RC_UNAUTHORIZED = -3,
    RC_NO_EVENT = -4,
    RC_NO_DATA = -5,
    RC_NOT_PRIVATE = -6,
} XservResultCode;

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
- (void) connect;
- (void) disconnect;
- (BOOL) isConnected;
-(NSString *) bindWithTopic:(NSString *) topic withEvent:(NSString *) event withAuthentication:(NSDictionary *) params;
- (NSString *) unbindWithTopic:(NSString *) topic withEvent:(NSString *) event;
- (NSString *) trigger:(NSString *) message withTopic:(NSString *) topic withEvent:(NSString *) event;
- (NSString *) historyByIdWithTopic:(NSString *)topic withEvent:(NSString *) event withOffset:(int) offset withLimit:(int) limit;
- (NSString *) historyByTimeStampWithTopic:(NSString *)topic withEvent:(NSString *) event withOffset:(int) offset withLimit:(int) limit;

@end
