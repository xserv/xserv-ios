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

NSString *const ADDRESS = @"xserv.mobile-italia.com";
NSString *const PORT = @"4332";
NSString *const HISTORY_ID = @"id";
NSString *const HISTORY_TIMESTAMP = @"timestamp";
NSString *const XServErrorDomain = @"XServErrorDomain";
int const DefaultReconnectDelay = 5000;

@interface Xserv () <SRWebSocketDelegate>

@property (nonatomic, strong) SRWebSocket *webSocket;
@property (nonatomic, strong) NSString *appId;

@end

@implementation Xserv

- (instancetype)initWithAppId:(NSString *) app_id
{
    self = [super init];
    if (self) {
        self.appId = app_id;
    }
    return self;
}

#pragma mark - Connection Method

- (void)connect {
    
    if([self isConnected]) return;
    
    self.webSocket.delegate = nil;
    self.webSocket = nil;
    
    NSString *urlString = [NSString stringWithFormat:@"ws://%@:%@/ws/%@", ADDRESS, PORT, self.appId];
    self.webSocket =[[SRWebSocket alloc] initWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]]];
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

- (void) reconnect {
    
    long delay = self.reconnectInterval ? self.reconnectInterval : DefaultReconnectDelay;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (delay/1000) * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self connect];
    });
}

#pragma mark - Operation Method

-(NSString *) bindOnTopic:(NSString *) topic withEvent:(NSString *) event withAuthEndpoint:(NSDictionary *) auth_endpoint {
    
    if(![self isConnected]) return nil;
    
    NSString *UUID = [[NSUUID UUID] UUIDString];
    
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict setObject:UUID forKey:@"uuid"];
    [dict setObject:[NSNumber numberWithInteger:BIND] forKey:@"op"];
    [dict setObject:topic forKey:@"topic"];
    [dict setObject:event forKey:@"event"];
    
    if(auth_endpoint) {
        [dict setObject:auth_endpoint forKey:@"auth_endpoint"];
    }
    
    [self send:dict];
    
    return UUID;
}

- (NSString *) bindOnTopic:(NSString *) topic withEvent:(NSString *) event {
    
    return [self bindOnTopic:topic withEvent:event withAuthEndpoint:nil];
}

- (NSString *) unbindOnTopic:(NSString *) topic withEvent:(NSString *) event {
    
    if(![self isConnected]) return nil;
    
    NSString *UUID = [[NSUUID UUID] UUIDString];
    
    NSDictionary *dict = @{
                           @"uuid" : UUID,
                           @"op" : [NSNumber numberWithInteger:UNBIND],
                           @"topic" : topic,
                           @"event" : event
                           };
    [self send:dict];
    
    return UUID;
}

- (NSString *)  unbindOnTopic:(NSString *) topic {
    
   return [self unbindOnTopic:topic withEvent:@""];
}

- (NSString *) historyByIdOnTopic:(NSString *)topic withEvent:(NSString *) event withOffset:(int) offset withLimit:(int) limit {
    
    if(![self isConnected]) return nil;
    
    NSString *UUID = [[NSUUID UUID] UUIDString];
    
    NSDictionary *dict = @{
                           @"uuid" : UUID,
                           @"op" : [NSNumber numberWithInteger:HISTORY],
                           @"topic" : topic,
                           @"event" : event,
                           @"arg1" : HISTORY_ID,
                           @"arg2" : [NSString stringWithFormat:@"%i",offset],
                           @"arg3" : [NSString stringWithFormat:@"%i",limit]
                           };
    [self send:dict];
    
    return UUID;
}

- (NSString *) historyByIdOnTopic:(NSString *)topic withEvent:(NSString *) event withOffset:(int) offset {
    
    return [self historyByIdOnTopic:topic withEvent:event withOffset:offset withLimit:0];
}

- (NSString *) historyByTimeStampOnTopic:(NSString *)topic withEvent:(NSString *) event withOffset:(int) offset withLimit:(int) limit {
    
    if(![self isConnected]) return nil;
    
    NSString *UUID = [[NSUUID UUID] UUIDString];
    
    NSDictionary *dict = @{
                           @"uuid" : UUID,
                           @"op" : [NSNumber numberWithInteger:HISTORY],
                           @"topic" : topic,
                           @"event" : event,
                           @"arg1" : HISTORY_TIMESTAMP,
                           @"arg2" : [NSString stringWithFormat:@"%i",offset],
                           @"arg3" : [NSString stringWithFormat:@"%i",limit]
                           };
    [self send:dict];
    
    return UUID;
}

- (NSString *) historyByTimeStampOnTopic:(NSString *)topic withEvent:(NSString *) event withOffset:(int) offset {
    
    return [self historyByTimeStampOnTopic:topic withEvent:event withOffset:offset withLimit:0];
}

- (NSString *) triggerString:(NSString *) message onTopic:(NSString *) topic withEvent:(NSString *) event {
    
    if(![self isConnected]) return nil;
    
    NSString *UUID = [[NSUUID UUID] UUIDString];
    
    NSDictionary *dict = @{
                           @"uuid" : UUID,
                           @"op" : [NSNumber numberWithInteger:TRIGGER],
                           @"topic" : topic,
                           @"event" : event,
                           @"arg1" : message
                           };
    [self send:dict];
    
    return UUID;
}

- (NSString *) triggerJSON:(NSDictionary *) message onTopic:(NSString *) topic withEvent:(NSString *) event {
    
   return  [self triggerString:[self jsonStringWithDict:message] onTopic:topic withEvent:event];
}

- (NSString *) presenceOnTopic:(NSString *) topic withEvent:(NSString *) event {
    
    if(![self isConnected]) return nil;
    
    NSString *UUID = [[NSUUID UUID] UUIDString];
    
    NSDictionary *dict = @{
                           @"uuid" : UUID,
                           @"op" : [NSNumber numberWithInteger:PRESENCE],
                           @"topic" : topic,
                           @"event" : event
                           };
    [self send:dict];
    
    return UUID;
}

#pragma mark - SRWebSocketDelegate

- (void)webSocketDidOpen:(SRWebSocket *)newWebSocket {
    
    [self sendStats];
    
    if ([self.delegate respondsToSelector:@selector(didOpenConnection)]) {
        [self.delegate didOpenConnection];
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    
    if ([self.delegate respondsToSelector:@selector(didErrorConnection:)]) {
        [self.delegate didErrorConnection:error];
    }
    
    [self reconnect];
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    
    NSMutableDictionary* details = [NSMutableDictionary dictionary];
    [details setValue:reason forKey:NSLocalizedDescriptionKey];
    NSError *error = [NSError errorWithDomain:XServErrorDomain code:code userInfo:details];
    
    if ([self.delegate respondsToSelector:@selector(didCloseConnection:)]) {
        [self.delegate didCloseConnection:error];
    }
    
    [self reconnect];
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
   
    if([message isKindOfClass:[NSString class]]) {
        NSString *string = (NSString *) message;
        NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
        NSError *jsonParsingError = nil;
        NSDictionary *obj = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonParsingError];
        
        [self manageMessage:obj];
    }
}

#pragma mark -

- (void) manageMessage:(NSDictionary *) json {
    
    NSMutableDictionary *operation = [NSMutableDictionary dictionaryWithDictionary:json];
    
    if(operation[@"op"]) {
        
        [operation setObject:[self getOperationNameByCode:[operation[@"op"] intValue] ] forKey:@"name"];

        if(operation[@"data"] && ![operation[@"data"] isEqualToString:@""]) {
            
            NSData *nsdataFromBase64String = [[NSData alloc] initWithBase64EncodedString:operation[@"data"] options:0];
            NSDictionary *data = [NSJSONSerialization JSONObjectWithData:nsdataFromBase64String options:0 error:nil];
            [operation setObject:data forKey:@"data"];
        }
        
        if([operation[@"op"] intValue] == BIND  && [Xserv isPrivateTopic:operation[@"topic"]] && [operation[@"rc"] intValue] == 1) {
            _userData = operation[@"data"];
        }
        
        if ([self.delegate respondsToSelector:@selector(didReceiveOpsResponse:)]) {
            [self.delegate didReceiveOpsResponse:[operation copy]];
        }
    }
    else if(operation[@"message"]) {
        
        NSError *error;
        id json = [NSJSONSerialization JSONObjectWithData:[operation[@"message"] dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
        
        if(error != nil && json != nil) {
            [operation setObject:json forKey:@"message"];
        }
        
        if ([self.delegate respondsToSelector:@selector(didReceiveEvents:)]) {
            [self.delegate didReceiveEvents:[operation copy]];
        }
    }
}

- (void) send :(NSDictionary *) dictionary {
    
    if([dictionary[@"op"] intValue] == BIND && dictionary[@"auth_endpoint"] && [Xserv isPrivateTopic:dictionary[@"topic"]])
    {
        NSDictionary *params = @{
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
                 
                    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                    NSMutableDictionary *newJson = [NSMutableDictionary dictionaryWithDictionary:dictionary];
                    [newJson removeObjectForKey:@"auth_endpoint"];
                    
                    if(json) {
                        [newJson setObject:params[@"user"] forKey:@"arg1"];
                        [newJson setObject:json[@"data"] forKey:@"arg2"];
                        [newJson setObject:json[@"sign"] forKey:@"arg3"];
                    }
                    
                    NSString *s = [self jsonStringWithDict:newJson];
                    [self.webSocket send:s];
                    
                }] resume];
    }
    else
    {
        NSString *s = [self jsonStringWithDict:dictionary];
        [self.webSocket send:s];
    }
}

+ (BOOL) isPrivateTopic:(NSString *) topic {
    
    if(topic.length >0 &&  [[topic substringToIndex:1] isEqualToString:@"@"])
        return YES;
    
    return NO;
}

-(NSString*) jsonStringWithDict:(NSDictionary *)dict {
   
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict
                                                       options:0
                                                         error:&error];
    if (! jsonData) {
        NSLog(@"Error jsonString : error: %@", error.localizedDescription);
        return @"{}";
    } else {
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
}

- (NSString *) getOperationNameByCode:(int) code {
    
    NSString *stringCode = @"";
    
    switch (code) {
        case BIND:
            stringCode = @"bind";
            break;
        case UNBIND:
            stringCode = @"unbind";
            break;
        case HISTORY:
            stringCode = @"history";
            break;
        case PRESENCE:
            stringCode = @"presence";
            break;
        case PRESENCE_IN:
            stringCode = @"presence_in";
            break;
        case PRESENCE_OUT:
            stringCode = @"presence_out";
            break;
        case TRIGGER:
            stringCode = @"trigger";
            break;
        default:
            break;
    }
    
    return stringCode;
};

- (void) sendStats {
    
    NSUUID *oNSUUID = [[UIDevice currentDevice] identifierForVendor];
    NSString *deviceId = [oNSUUID UUIDString];
    NSString *model =  [[UIDevice currentDevice] platform];
    NSString *systemVersion =  [[UIDevice currentDevice] systemVersion];
    long timezoneOffset = [[NSTimeZone localTimeZone] secondsFromGMT] / 3600;
    NSTimeZone* systemTimeZone = [NSTimeZone systemTimeZone];
    BOOL dstIsOn = [systemTimeZone isDaylightSavingTime];
    int dst = dstIsOn ? 1 : 0;
    
    NSDictionary *stats = @{
                            @"uuid" : deviceId,
                            @"model" : model,
                            @"os" : [NSString stringWithFormat:@"iOS %@", systemVersion],
                            @"tz_offset" : [NSNumber numberWithLong:timezoneOffset],  
                            @"tz_dst" : [NSNumber numberWithInt:dst]
                           };
    [self send:stats];
}

@end
