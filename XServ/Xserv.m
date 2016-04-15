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

NSString *const VERSION = @"1";

NSString *const HOST = @"mobile-italia.com";
NSString *const PORT = @"4332";
NSString *const TLS_PORT = @"8332";
NSString *const XServErrorDomain = @"XServErrorDomain";
const int DefaultReconnectDelay = 5000;

@interface Xserv () <SRWebSocketDelegate>

@property (nonatomic, strong) SRWebSocket *webSocket;
@property (nonatomic, strong) NSString *appId;
@property (nonatomic) BOOL secure;

@end

@implementation Xserv

- (instancetype) initWithAppId:(NSString *) app_id
{
    
    self = [super init];
    if (self) {
        self.appId = app_id;
        self.reconnectInterval = DefaultReconnectDelay;
        // TLS
        self.secure = YES;
    }
    return self;
}

#pragma mark - Connection Method

- (void) connect {
    
    if([self isConnected]) return;
    
    self.webSocket.delegate = nil;
    self.webSocket = nil;
    
    NSString *urlString = [NSString stringWithFormat:@"ws%@://%@:%@/ws/%@?version=%@", self.secure ? @"s" : @"", HOST, self.secure ? TLS_PORT : PORT, self.appId, VERSION];
    
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

- (void) disableTLS {
    self.secure = NO;
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
    
    if (self.reconnectInterval > 0) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (self.reconnectInterval/1000) * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self connect];
        });
    }
}

#pragma mark - Operation Method

-(NSString *) subscribeOnTopic:(NSString *) topic withAuth:(NSDictionary *) auth {
    
    if(![self isConnected]) return nil;
    
    NSString *UUID = [[NSUUID UUID] UUIDString];
    
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict setObject:UUID forKey:@"uuid"];
    [dict setObject:[NSNumber numberWithInteger:OP_SUBSCRIBE] forKey:@"op"];
    [dict setObject:topic forKey:@"topic"];
    
    if(auth) {
        [dict setObject:auth forKey:@"auth"];
    }
    
    [self send:dict];
    
    return UUID;
}

- (NSString *) subscribeOnTopic:(NSString *) topic {
    
    return [self subscribeOnTopic:topic withAuth:nil];
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

- (NSString *) historyOnTopic:(NSString *) topic withParams:(NSDictionary *) params {
    
    if(![self isConnected]) return nil;
    
    NSString *UUID = [[NSUUID UUID] UUIDString];
    
    NSNumber *offset = (params && params[@"offset"]) ? params[@"offset"] : [NSNumber numberWithInt:0];
    NSNumber *limit =  (params && params[@"limit"]) ? params[@"limit"] : [NSNumber numberWithInt:0];
    NSDictionary *query =  (params && params[@"query"]) ? params[@"query"] : nil;
    
    NSDictionary *dict = @{
                           @"uuid" : UUID,
                           @"op" : [NSNumber numberWithInteger:OP_HISTORY],
                           @"topic" : topic,
                           @"arg1" : [offset stringValue],
                           @"arg2" : [limit stringValue],
                           @"arg3" : query ? query : @""
                           };
    [self send:dict];
    
    return UUID;
}

- (NSString *) publish:(id) data onTopic:(NSString *) topic {
    
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

- (NSString *) update:(id) data withObjectId:(NSString *) object_id onTopic:(NSString *) topic {
    
    if(![self isConnected]) return nil;
    
    NSString *UUID = [[NSUUID UUID] UUIDString];
    
    NSDictionary *dict = @{
                           @"uuid" : UUID,
                           @"op" : [NSNumber numberWithInteger:OP_UPDATE],
                           @"topic" : topic,
                           @"arg1" : data,
                           @"arg2" : object_id
                           };
    [self send:dict];
    
    return UUID;
}

- (NSString *) usersOnTopic:(NSString *) topic {
    
    if(![self isConnected]) return nil;
    
    NSString *UUID = [[NSUUID UUID] UUIDString];
    
    NSDictionary *dict = @{
                           @"uuid" : UUID,
                           @"op" : [NSNumber numberWithInteger:OP_USERS],
                           @"topic" : topic
                           };
    [self send:dict];
    
    return UUID;
}

- (NSString *) topics {
    
    if(![self isConnected]) return nil;
    
    NSString *UUID = [[NSUUID UUID] UUIDString];
    
    NSDictionary *dict = @{
                           @"uuid" : UUID,
                           @"op" : [NSNumber numberWithInteger:OP_TOPICS]
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
        // messages
        
        if ([self.delegate respondsToSelector:@selector(didReceiveMessages:)]) {
            [self.delegate didReceiveMessages:[operation copy]];
        }
    }
    else {
        // operations
        
        NSData *nsdataFromBase64String = [[NSData alloc] initWithBase64EncodedString:operation[@"data"] options:0];
        [operation setObject:[[NSString alloc] initWithData:nsdataFromBase64String encoding:NSUTF8StringEncoding] forKey:@"data"];
        
        NSError *error;
        id data = [NSJSONSerialization JSONObjectWithData:nsdataFromBase64String options:0 error:&error];
        
        if(error == nil && data != nil) {
            [operation setObject:data forKey:@"data"];
        }
        
        [operation setObject:[self getOperationNameByCode:[operation[@"op"] intValue]] forKey:@"name"];
        
        if([operation[@"op"] intValue] == OP_HANDSHAKE) {
            // handshake
            
            if([operation[@"rc"] intValue] == RC_OK) {
                // se prima non ha dato errore il decode/serialization
                if(error == nil && data != nil) {
                    _userData = data;
                    
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
            // classic operations
            
            if([operation[@"op"] intValue] == OP_SUBSCRIBE  && [Xserv isPrivateTopic:operation[@"topic"]] && [operation[@"rc"] intValue] == RC_OK) {
                if(error == nil && data != nil) {
                    _userData = data;
                }
            }
            
            if ([self.delegate respondsToSelector:@selector(didReceiveOperations:)]) {
                [self.delegate didReceiveOperations:[operation copy]];
            }
        }
    }
}

- (NSString*) urlEncodedDictionary:(NSDictionary *) params {
    NSMutableArray *parts = [NSMutableArray array];
    for (NSString *key in params) {
        // string format to transform int or other object in string
        NSString *value = [NSString stringWithFormat:@"%@", [params objectForKey:key]];
        NSString *part = [NSString stringWithFormat: @"%@=%@",
                          [key stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]],
                          [value stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]]];
        [parts addObject: part];
    }
    return [parts componentsJoinedByString: @"&"];
}

- (void) send:(NSDictionary *) dictionary {
    
    if(![self isConnected]) return;
    
    if([dictionary[@"op"] intValue] == OP_SUBSCRIBE && dictionary[@"auth"] && [Xserv isPrivateTopic:dictionary[@"topic"]])
    {
        NSString *urlString;
        if(dictionary[@"auth"][@"endpoint"]) {
            urlString = dictionary[@"auth"][@"endpoint"];
        }
        else {
            urlString = [NSString stringWithFormat:@"http%@://%@:%@/1/user", self.secure ? @"s" : @"", HOST, self.secure ? TLS_PORT : PORT];
        }
        
        NSString *user = @"";
        NSString *pass = @"";
        
        // params
        if (dictionary[@"auth"][@"params"]) {
            NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:dictionary[@"auth"][@"params"]];
            
            if (params[@"user"]) {
                user = params[@"user"];
                [params removeObjectForKey:@"user"];
            }
            if (params[@"pass"]) {
                pass = params[@"pass"];
                [params removeObjectForKey:@"pass"];
            }
            
            [params setValue:[self socketId] forKey:@"socket_id"];
            [params setValue:dictionary[@"topic"] forKey:@"topic"];
            
            urlString = [NSString stringWithFormat:@"%@?%@", urlString, [self urlEncodedDictionary:params]];
        }
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
        [request setHTTPMethod:@"GET"];
        
        // headers
        if(dictionary[@"auth"][@"headers"]) {
            for (NSString* key in dictionary[@"auth"][@"headers"]) {
                NSString *value = [dictionary[@"auth"][@"headers"] objectForKey:key];
                [request setValue:value forHTTPHeaderField:key];
            }
        }
        [request addValue:self.appId forHTTPHeaderField:@"X-Xserv-AppId"];
        
        if ([user length] > 0 && [pass length] > 0) {
            NSData *authData = [[NSString stringWithFormat:@"%@:%@", user, pass] dataUsingEncoding:NSUTF8StringEncoding];
            NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64Encoding]];
            [request setValue:authValue forHTTPHeaderField:@"Authorization"];
        }
        
        NSURLSession *session = [NSURLSession sharedSession];
        [[session dataTaskWithRequest:request
                    completionHandler:^(NSData *data,
                                        NSURLResponse *response,
                                        NSError *error) {
                        
                        NSError *error2 = nil;
                        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error2];
                        
                        if(error2 == nil && json != nil) {
                            
                            NSMutableDictionary *newJson = [NSMutableDictionary dictionaryWithDictionary:dictionary];
                            [newJson removeObjectForKey:@"auth"];
                            
                            if(json) {
                                [newJson setObject:user forKey:@"arg1"];
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
        case OP_USERS:
            stringCode = @"users";
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
        case OP_TOPICS:
            stringCode = @"topics";
            break;
        case OP_UPDATE:
            stringCode = @"update";
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
