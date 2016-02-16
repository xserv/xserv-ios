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
    RC_ALREADY_SUBSCRIBED = -2,
    RC_UNAUTHORIZED = -3,
    RC_NO_TOPIC = -4,
    RC_NO_DATA = -5,
    RC_NOT_PRIVATE = -6,
    RC_LIMIT_MESSAGES = -7
} XservResultCode;

typedef enum XServOperationCode : NSInteger {
    OP_PUBLISH = 200,
    OP_SUBSCRIBE = 201,
    OP_UNSUBSCRIBE = 202,
    OP_HISTORY = 203,
    OP_PRESENCE = 204,
    OP_JOIN = OP_SUBSCRIBE + 200,
    OP_LEAVE = OP_UNSUBSCRIBE + 200
} XServOperationCode;


@protocol XservDelegate <NSObject>

- (void) didReceiveMessages:(NSDictionary *) json;
- (void) didReceiveOpsResponse:(NSDictionary *) json;

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
- (NSString *) subscribeOnTopic:(NSString *) topic withAuthEndpoint:(NSDictionary *) auth_endpoint;
- (NSString *) subscribeOnTopic:(NSString *) topic;
- (NSString *) unsubscribeOnTopic:(NSString *) topic;
- (NSString *) publishString:(NSString *) data onTopic:(NSString *) topic;
- (NSString *) publishJSON:(NSDictionary *) data onTopic:(NSString *) topic;
- (NSString *) historyByIdOnTopic:(NSString *) topic withOffset:(int) offset withLimit:(int) limit;
- (NSString *) historyByIdOnTopic:(NSString *) topic withOffset:(int) offset;
- (NSString *) historyByTimeStampOnTopic:(NSString *) topic withOffset:(int) offset withLimit:(int) limit;
- (NSString *) historyByTimeStampOnTopic:(NSString *) topic withOffset:(int) offset;
- (NSString *) presenceOnTopic:(NSString *) topic;

+ (BOOL) isPrivateTopic:(NSString *) topic;

@end
