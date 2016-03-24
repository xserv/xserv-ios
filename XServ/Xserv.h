//
//  Xserv.h
//  Pods
//
//  Created by Giuseppe Nugara on 26/12/15.
//
//

#import <Foundation/Foundation.h>

extern NSString *const VERSION;

typedef enum XservResultCode : NSInteger {
    RC_OK = 1,
    RC_GENERIC_ERROR = 0,
    RC_ARGS_ERROR = -1,
    RC_ALREADY_SUBSCRIBED = -2,
    RC_UNAUTHORIZED = -3,
    RC_NO_TOPIC = -4,
    RC_NO_DATA = -5,
    RC_NOT_PRIVATE = -6,
    RC_LIMIT_MESSAGES = -7,
    RC_DATA_ERROR = -8
} XservResultCode;

typedef enum XServOperationCode : NSInteger {
    OP_HANDSHAKE = 100,
    OP_PUBLISH = 200,
    OP_SUBSCRIBE = 201,
    OP_UNSUBSCRIBE = 202,
    OP_HISTORY = 203,
    OP_USERS = 204,
    OP_TOPICS = 205,
    OP_JOIN = 401,
    OP_LEAVE = 402
} XServOperationCode;

@protocol XservDelegate <NSObject>

- (void) didReceiveMessages:(NSDictionary *) json;
- (void) didReceiveOperations:(NSDictionary *) json;

@optional
- (void) didOpenConnection;
- (void) didErrorConnection:(NSError *) reason;
- (void) didCloseConnection:(NSError *) reason;

@end

@interface Xserv : NSObject

@property (nonatomic, weak) id <XservDelegate> delegate;
@property long reconnectInterval;
@property (nonatomic, strong, readonly) NSDictionary *userData;

- (instancetype) initWithAppId:(NSString *) app_id;
- (void) connect;
- (void) disconnect;
- (BOOL) isConnected;
- (NSString *) socketId;
- (void) disableTLS;
- (NSString *) subscribeOnTopic:(NSString *) topic withAuthEndpoint:(NSDictionary *) auth_endpoint;
- (NSString *) subscribeOnTopic:(NSString *) topic;
- (NSString *) unsubscribeOnTopic:(NSString *) topic;
- (NSString *) publish:(id) data onTopic:(NSString *) topic;
- (NSString *) historyOnTopic:(NSString *) topic withOffset:(int) offset withLimit:(int) limit;
- (NSString *) usersOnTopic:(NSString *) topic;
- (NSString *) topics;

+ (BOOL) isPrivateTopic:(NSString *) topic;

@end
