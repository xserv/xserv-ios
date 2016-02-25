//
//  Xserv.m
//  Pods
//
//  Created by Giuseppe Nugara on 26/12/15.
//
//

#import "Xserv.h"
#import "SRWebSocket.h"
#import <UIKit/UIKit.h>
#import "UIDevice-Hardware.h"

NSString *const VERSION = @"1.0.0";

NSString *const ADDRESS = @"xserv.mobile-italia.com";
NSString *const PORT = @"4332";
NSString *const HISTORY_ID = @"id";
NSString *const HISTORY_TIMESTAMP = @"timestamp";
NSString *const XServErrorDomain = @"XServErrorDomain";
const int DefaultReconnectDelay = 5000;

@interface Xserv () <SRWebSocketDelegate>

@property (nonatomic, strong) SRWebSocket *webSocket;
@property (nonatomic, strong) NSString *appId;

@end

@implementation Xserv

- (instancetype) initWithAppId:(NSString *) app_id
{
    
    self = [super init];
    if (self) {
        self.appId = app_id;
    }
    return self;
}

#pragma mark - Connection Method

- (void) connect {
    
    if([self isConnected]) return;
    
    self.webSocket.delegate = nil;
    self.webSocket = nil;
    
    NSString *urlString = [NSString stringWithFormat:@"ws://%@:%@/ws/%@?version=%@", ADDRESS, PORT, self.appId, VERSION];
    
    self.webSocket = [[SRWebSocket alloc] initWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]]];
    self.webSocket.delegate = self;
    
    [self.webSocket open];
}

- (void) disconnect {
    
    if(![self isConnected]) return;
    
    self.webSocket.delegate = nil;
    [self.webSocket close];
    self.webSocket = nil;
    
    if ([self.delegate respondsToSelector:@selector(didCloseConnection:)]) {
        [self.delegate didCloseConnection:nil];
    }
}

- (BOOL) isConnected {
    
    return self.webSocket && self.webSocket.readyState == SR_OPEN;
}

- (NSString *) socketId {
    
    if (self.userData) {
        NSString *socket_id = self.userData[@"socket_id"];
        if (socket_id) {
            return socket_id;
        }
    }
    return @"";
}

- (void) reconnect {
    
    long delay = self.reconnectInterval ? self.reconnectInterval : DefaultReconnectDelay;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (delay/1000) * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self connect];
    });
}

#pragma mark - Operation Method

-(NSString *) subscribeOnTopic:(NSString *) topic withAuthEndpoint:(NSDictionary *) auth_endpoint {
    
    if(![self isConnected]) return nil;
    
    NSString *UUID = [[NSUUID UUID] UUIDString];
    
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict setObject:UUID forKey:@"uuid"];
    [dict setObject:[NSNumber numberWithInteger:OP_SUBSCRIBE] forKey:@"op"];
    [dict setObject:topic forKey:@"topic"];
    
    if(auth_endpoint) {
        [dict setObject:auth_endpoint forKey:@"auth_endpoint"];
    }
    
    [self send:dict];
    
    return UUID;
}

- (NSString *) subscribeOnTopic:(NSString *) topic {
    
    return [self subscribeOnTopic:topic withAuthEndpoint:nil];
}

- (NSString *) unsubscribeOnTopic:(NSString *) topic {
    
    if(![self isConnected]) return nil;
    
    NSString *UUID = [[NSUUID UUID] UUIDString];
    
    NSDictionary *dict = @{
                           @"uuid" : UUID,
                           @"op" : [NSNumber numberWithInteger:OP_UNSUBSCRIBE],
                           @"topic" : topic
                           };
    [self send:dict];
    
    return UUID;
}

- (NSString *) historyByIdOnTopic:(NSString *) topic withOffset:(int) offset withLimit:(int) limit {
    
    if(![self isConnected]) return nil;
    
    NSString *UUID = [[NSUUID UUID] UUIDString];
    
    NSDictionary *dict = @{
                           @"uuid" : UUID,
                           @"op" : [NSNumber numberWithInteger:OP_HISTORY],
                           @"topic" : topic,
                           @"arg1" : HISTORY_ID,
                           @"arg2" : [NSString stringWithFormat:@"%i", offset],
                           @"arg3" : [NSString stringWithFormat:@"%i", limit]
                           };
    [self send:dict];
    
    return UUID;
}

- (NSString *) historyByIdOnTopic:(NSString *) topic withOffset:(int) offset {
    
    return [self historyByIdOnTopic:topic withOffset:offset withLimit:0];
}

- (NSString *) historyByTimeStampOnTopic:(NSString *) topic withOffset:(int) offset withLimit:(int) limit {
    
    if(![self isConnected]) return nil;
    
    NSString *UUID = [[NSUUID UUID] UUIDString];
    
    NSDictionary *dict = @{
                           @"uuid" : UUID,
                           @"op" : [NSNumber numberWithInteger:OP_HISTORY],
                           @"topic" : topic,
                           @"arg1" : HISTORY_TIMESTAMP,
                           @"arg2" : [NSString stringWithFormat:@"%i", offset],
                           @"arg3" : [NSString stringWithFormat:@"%i", limit]
                           };
    [self send:dict];
    
    return UUID;
}

- (NSString *) historyByTimeStampOnTopic:(NSString *) topic withOffset:(int) offset {
    
    return [self historyByTimeStampOnTopic:topic withOffset:offset withLimit:0];
}

- (NSString *) publishString:(NSString *) data onTopic:(NSString *) topic {
    
    if(![self isConnected]) return nil;
    
    NSString *UUID = [[NSUUID UUID] UUIDString];
    
    NSDictionary *dict = @{
                           @"uuid" : UUID,
                           @"op" : [NSNumber numberWithInteger:OP_PUBLISH],
                           @"topic" : topic,
                           @"arg1" : data
                           };
    [self send:dict];
    
    return UUID;
}

- (NSString *) publishJSON:(NSDictionary *) data onTopic:(NSString *) topic  {
    
    return  [self publishString:[self jsonStringWithDict:data] onTopic:topic];
}

- (NSString *) presenceOnTopic:(NSString *) topic {
    
    if(![self isConnected]) return nil;
    
    NSString *UUID = [[NSUUID UUID] UUIDString];
    
    NSDictionary *dict = @{
                           @"uuid" : UUID,
                           @"op" : [NSNumber numberWithInteger:OP_PRESENCE],
                           @"topic" : topic
                           };
    [self send:dict];
    
    return UUID;
}

#pragma mark - SRWebSocketDelegate

- (void) webSocketDidOpen:(SRWebSocket *) newWebSocket {
    
    [self handshake]; // connect open on finish handshake
}

- (void) webSocket:(SRWebSocket *) webSocket didFailWithError:(NSError *) error {
    
    if ([self.delegate respondsToSelector:@selector(didErrorConnection:)]) {
        [self.delegate didErrorConnection:error];
    }
    
    [self reconnect];
}

- (void) webSocket:(SRWebSocket *) webSocket didCloseWithCode:(NSInteger) code reason:(NSString *) reason wasClean:(BOOL) wasClean {
    
    if ([self.delegate respondsToSelector:@selector(didCloseConnection:)]) {
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:reason forKey:NSLocalizedDescriptionKey];
        NSError *error = [NSError errorWithDomain:XServErrorDomain code:code userInfo:details];
        
        [self.delegate didCloseConnection:error];
    }
    
    [self reconnect];
}

- (void) webSocket:(SRWebSocket *) webSocket didReceiveMessage:(id) message {
    
    if([message isKindOfClass:[NSString class]]) {
        NSString *string = (NSString *) message;
        NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
        
        NSError *error = nil;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        
        if(error == nil && json != nil) {
            [self manageMessage:json];
        }
    }
}

#pragma mark -

- (void) manageMessage:(NSDictionary *) json {
    
    NSMutableDictionary *operation = [NSMutableDictionary dictionaryWithDictionary:json];
    
    if(!operation[@"op"]) {
        
        NSError *error;
        id json = [NSJSONSerialization JSONObjectWithData:[operation[@"data"] dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
        
        if(error == nil && json != nil) {
            [operation setObject:json forKey:@"data"];
        }
        
        if ([self.delegate respondsToSelector:@selector(didReceiveMessages:)]) {
            [self.delegate didReceiveMessages:[operation copy]];
        }
    }
    else {
        
        [operation setObject:[self getOperationNameByCode:[operation[@"op"] intValue]] forKey:@"name"];
        
        if([operation[@"op"] intValue] == OP_HANDSHAKE) {
            
            if([operation[@"rc"] intValue] == RC_OK) {
                
                if(operation[@"data"] && ![operation[@"data"] isEqualToString:@""]) {
                    NSData *nsdataFromBase64String = [[NSData alloc] initWithBase64EncodedString:operation[@"data"] options:0];
                    
                    NSError *error;
                    id data = [NSJSONSerialization JSONObjectWithData:nsdataFromBase64String options:0 error:&error];
                    
                    if(error == nil && data != nil) {
                        _userData = data;
                    }
                }
                
                if(self.userData) {
                    if ([self.delegate respondsToSelector:@selector(didOpenConnection)]) {
                        [self.delegate didOpenConnection];
                    }
                }
                else {
                    if ([self.delegate respondsToSelector:@selector(didErrorConnection:)]) {
                        NSMutableDictionary* details = [NSMutableDictionary dictionary];
                        [details setValue:operation[@"descr"] forKey:NSLocalizedDescriptionKey];
                        NSError *error = [NSError errorWithDomain:XServErrorDomain code:[operation[@"rc"] intValue] userInfo:details];
                        
                        [self.delegate didErrorConnection:error];
                    }
                }
            }
            else {
                
                if ([self.delegate respondsToSelector:@selector(didErrorConnection:)]) {
                    NSMutableDictionary* details = [NSMutableDictionary dictionary];
                    [details setValue:operation[@"descr"] forKey:NSLocalizedDescriptionKey];
                    NSError *error = [NSError errorWithDomain:XServErrorDomain code:[operation[@"rc"] intValue] userInfo:details];
                    
                    [self.delegate didErrorConnection:error];
                }
            }
        }
        else {
            
            if(operation[@"data"] && ![operation[@"data"] isEqualToString:@""]) {
                NSData *nsdataFromBase64String = [[NSData alloc] initWithBase64EncodedString:operation[@"data"] options:0];
                
                NSError *error;
                id data = [NSJSONSerialization JSONObjectWithData:nsdataFromBase64String options:0 error:&error];
                
                if(error == nil && data != nil) {
                    [operation setObject:data forKey:@"data"];
                    
                    if([operation[@"op"] intValue] == OP_SUBSCRIBE  && [Xserv isPrivateTopic:operation[@"topic"]] && [operation[@"rc"] intValue] == RC_OK) {
                        _userData = data;
                    }
                }
            }
            
            if ([self.delegate respondsToSelector:@selector(didReceiveOpsResponse:)]) {
                [self.delegate didReceiveOpsResponse:[operation copy]];
            }
        }
    }
}

- (void) send:(NSDictionary *) dictionary {
    
    if(![self isConnected]) return;
    
    if([dictionary[@"op"] intValue] == OP_SUBSCRIBE && dictionary[@"auth_endpoint"] && [Xserv isPrivateTopic:dictionary[@"topic"]])
    {
        NSDictionary *params = @{
                                 @"socket_id": [self socketId],
                                 @"topic": dictionary[@"topic"],
                                 @"user": dictionary[@"auth_endpoint"][@"user"],
                                 @"pass": dictionary[@"auth_endpoint"][@"pass"]
                                 };
        NSString *urlString;
        
        if(dictionary[@"auth_endpoint"][@"endpoint"]) {
            urlString = dictionary[@"auth_endpoint"][@"endpoint"];
        }
        else {
            urlString = [NSString stringWithFormat:@"http://%@:%@/app/%@/auth_user", ADDRESS, PORT, self.appId];
        }
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
        [request addValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
        [request setHTTPMethod:@"POST"];
        NSData *postData = [NSJSONSerialization dataWithJSONObject:params options:0 error:nil];
        [request setHTTPBody:postData];
        
        NSURLSession *session = [NSURLSession sharedSession];
        [[session dataTaskWithRequest:request
                    completionHandler:^(NSData *data,
                                        NSURLResponse *response,
                                        NSError *error) {
                        
                        NSError *error2 = nil;
                        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error2];
                        
                        if(error2 == nil && json != nil) {
                            
                            NSMutableDictionary *newJson = [NSMutableDictionary dictionaryWithDictionary:dictionary];
                            [newJson removeObjectForKey:@"auth_endpoint"];
                            
                            if(json) {
                                [newJson setObject:params[@"user"] forKey:@"arg1"];
                                [newJson setObject:json[@"data"] forKey:@"arg2"];
                                [newJson setObject:json[@"sign"] forKey:@"arg3"];
                            }
                            
                            NSString *s = [self jsonStringWithDict:newJson];
                            [self.webSocket send:s];
                            
                        } else {
                            
                            NSString *s = [self jsonStringWithDict:dictionary];
                            [self.webSocket send:s];
                        }
                        
                    }] resume];
    }
    else {
        NSString *s = [self jsonStringWithDict:dictionary];
        [self.webSocket send:s];
    }
}

+ (BOOL) isPrivateTopic:(NSString *) topic {
    
    if(topic.length > 0 &&  [[topic substringToIndex:1] isEqualToString:@"@"])
        return YES;
    
    return NO;
}

- (NSString*) jsonStringWithDict:(NSDictionary *) dict {
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
    if (error != nil || !jsonData) {
        // NSLog(@"Error jsonString : error: %@", error.localizedDescription);
        
        return @"{}";
    } else {
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
}

- (NSString *) getOperationNameByCode:(int) code {
    
    NSString *stringCode = @"";
    
    switch (code) {
        case OP_SUBSCRIBE:
            stringCode = @"subscribe";
            break;
        case OP_UNSUBSCRIBE:
            stringCode = @"unsubscribe";
            break;
        case OP_HISTORY:
            stringCode = @"history";
            break;
        case OP_PRESENCE:
            stringCode = @"presence";
            break;
        case OP_JOIN:
            stringCode = @"join";
            break;
        case OP_LEAVE:
            stringCode = @"leave";
            break;
        case OP_PUBLISH:
            stringCode = @"publish";
            break;
        case OP_HANDSHAKE:
            stringCode = @"handshake";
            break;
        default:
            break;
    }
    
    return stringCode;
}

- (void) handshake {
    
    NSUUID *oNSUUID = [[UIDevice currentDevice] identifierForVendor];
    NSString *deviceId = [oNSUUID UUIDString];
    NSString *model =  [[UIDevice currentDevice] platform];
    NSString *systemVersion =  [[UIDevice currentDevice] systemVersion];
    long timezoneOffset = [[NSTimeZone localTimeZone] secondsFromGMT] / 3600;
    NSTimeZone* systemTimeZone = [NSTimeZone systemTimeZone];
    BOOL dstIsOn = [systemTimeZone isDaylightSavingTime];
    int dst = dstIsOn ? 1 : 0;
    NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];
    
    NSDictionary *stats = @{
                            @"uuid" : deviceId,
                            @"model" : model,
                            @"os" : [NSString stringWithFormat:@"iOS %@", systemVersion],
                            @"tz_offset" : [NSNumber numberWithLong:timezoneOffset],
                            @"tz_dst" : [NSNumber numberWithInt:dst],
                            @"lang" : language
                            };
    [self send:stats];
}

@end
