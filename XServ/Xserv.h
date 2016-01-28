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

typedef enum XServOperationCode : NSInteger {
    TRIGGER = 200,
    BIND = 201,
    UNBIND = 202,
    HISTORY = 203,
    PRESENCE = 204,
    PRESENCE_IN = BIND + 200,
    PRESENCE_OUT = UNBIND + 200
} XServOperationCode;


@protocol XservDelegate <NSObject>

- (void) didReceiveEvents:(id)message;
- (void) didReceiveOpsResponse:(id)message;

@optional
- (void) didOpenConnection;
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
- (NSString *) bindOnTopic:(NSString *) topic withEvent:(NSString *) event withAuthEndpoint:(NSDictionary *) params;
- (NSString *) bindOnTopic:(NSString *) topic withEvent:(NSString *) event;
- (NSString *) unbindOnTopic:(NSString *) topic withEvent:(NSString *) event;
- (NSString *) unbindOnTopic:(NSString *) topic;
- (NSString *) triggerString:(NSString *) message onTopic:(NSString *) topic withEvent:(NSString *) event;
- (NSString *) triggerJSON:(NSDictionary *) message onTopic:(NSString *) topic withEvent:(NSString *) event;
- (NSString *) historyByIdOnTopic:(NSString *)topic withEvent:(NSString *) event withOffset:(int) offset withLimit:(int) limit;
- (NSString *) historyByIdOnTopic:(NSString *)topic withEvent:(NSString *) event withOffset:(int) offset;
- (NSString *) historyByTimeStampOnTopic:(NSString *)topic withEvent:(NSString *) event withOffset:(int) offset withLimit:(int) limit;
- (NSString *) historyByTimeStampOnTopic:(NSString *)topic withEvent:(NSString *) event withOffset:(int) offset;
- (NSString *) presenceOnTopic:(NSString *) topic withEvent:(NSString *) event;

@end
