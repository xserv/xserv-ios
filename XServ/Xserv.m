//
//  Xserv.m
//  Pods
//
//  Created by Giuseppe Nugara on 26/12/15.
//
//

#import "Xserv.h"
#import "SRWebSocket.h"

NSString *const ADDRESS = @"mobile-italia.com";
NSString *const PORT = @"4332";
NSString *const HISTORY_ID = @"id";
NSString *const HISTORY_TIMESTAMP = @"timestamp";
NSString *const XServErrorDomain = @"XServErrorDomain";

typedef enum XServOperationCode : NSInteger {
    TRIGGER = 200,
    BIND = 201,
    UNBIND = 202,
    HISTORY = 203,
    PRESENCE = 204,
    PRESENCE_IN = BIND + 200,
    PRESENCE_OUT = UNBIND + 200
} XServOperationCode;

@interface Xserv () <SRWebSocketDelegate>

@property (nonatomic, strong) SRWebSocket *webSocket;
@property (nonatomic, strong) NSString *appId;
@property (nonatomic, strong) NSMutableArray *operations;
@property (nonatomic, strong) NSMutableArray *offlineOperations;
@property (nonatomic, strong) NSDictionary *userData;

@end

@implementation Xserv

#pragma mark 

- (instancetype)initWithAppId:(NSString *) appId
{
    self = [super init];
    if (self) {
        self.appId = appId;
        self.operations = [NSMutableArray new];
        self.offlineOperations = [NSMutableArray new];
    }
    return self;
}

#pragma mark - Connection Method

- (void)connect
{
    self.webSocket.delegate = nil;
    self.webSocket = nil;
    
    NSString *urlString = [NSString stringWithFormat:@"ws://%@:%@/ws/%@", ADDRESS, PORT, self.appId];
    self.webSocket =[[SRWebSocket alloc] initWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]]];
    
    self.webSocket.delegate = self;
    
    [self.webSocket open];
}

- (void) disconnect
{
    [self.webSocket close];
    self.webSocket.delegate = nil;
    self.webSocket = nil;
    
    if ([self.delegate respondsToSelector:@selector(didCloseConnection:)]) {
        [self.delegate didCloseConnection:nil];
    }
}

- (BOOL) isConnected {
    
    return self.webSocket.readyState == SR_OPEN;
}

#pragma mark - Operation Method

-(NSString *) bindWithTopic:(NSString *) topic withEvent:(NSString *) event withAuthentication:(NSDictionary *) params
{
    NSString *UUID = [[NSUUID UUID] UUIDString];
    
    NSMutableDictionary *dict = [NSMutableDictionary new];
    
    [dict setObject:UUID forKey:@"uuid"];
    [dict setObject:[NSNumber numberWithInteger:BIND] forKey:@"op"];
    [dict setObject:topic forKey:@"topic"];
    [dict setObject:event forKey:@"event"];
    
    if(params) {
        [dict setObject:params forKey:@"auth_endpoint"];
    }
    
    if(![self isConnected])
    {
        for(NSDictionary *op in self.offlineOperations)
        {
            if([op[@"topic"] isEqualToString:topic] && [op[@"event"] isEqualToString:event]) {
                
                return nil;
            }
        }
        [self.offlineOperations addObject:dict];
        
        return nil;
    }
    
    [self send:dict];
    
    return UUID;
}

- (NSString *)  unbindWithTopic:(NSString *) topic withEvent:(NSString *) event {
    
    NSString *UUID = [[NSUUID UUID] UUIDString];
    
    NSDictionary *dict = @{
                           @"uuid" : UUID,
                           @"op" : [NSNumber numberWithInteger:UNBIND],
                           @"topic" : topic,
                           @"event" : event
                           };
    
    if(![self isConnected])
    {
        for(NSDictionary *op in self.offlineOperations)
        {
            if([op[@"topic"] isEqualToString:topic] && [op[@"event"] isEqualToString:event]) {
                
                [self.offlineOperations removeObject:op];
                return nil;
            }
        }
        for(NSDictionary *op in self.operations)
        {
            if([op[@"topic"] isEqualToString:topic] && [op[@"event"] isEqualToString:event]) {
                
                [self.operations removeObject:op];
                return nil;
            }
        }
        
        return nil;
    }
    
    [self send:dict];
    
    return UUID;
}

- (NSString *) historyByIdWithTopic:(NSString *)topic withEvent:(NSString *) event withOffset:(int) offset withLimit:(int) limit
{
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

- (NSString *) historyByTimeStampWithTopic:(NSString *)topic withEvent:(NSString *) event withOffset:(int) offset withLimit:(int) limit
{
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

- (NSString *) trigger:(NSString *) message withTopic:(NSString *) topic withEvent:(NSString *) event
{
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

- (NSString *) presenceWithTopic:(NSString *) topic withEvent:(NSString *) event {
    
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
    
    [self sendOperations];
    
    if ([self.delegate respondsToSelector:@selector(didOpenConnection)]) {
        [self.delegate didOpenConnection];
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    
    if ([self.delegate respondsToSelector:@selector(didErrorConnection:)]) {
        [self.delegate didErrorConnection:error];
    }
    
    [self connect];
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    
    NSMutableDictionary* details = [NSMutableDictionary dictionary];
    [details setValue:reason forKey:NSLocalizedDescriptionKey];
    NSError *error = [NSError errorWithDomain:XServErrorDomain code:code userInfo:details];
    
    if ([self.delegate respondsToSelector:@selector(didCloseConnection:)]) {
        [self.delegate didCloseConnection:error];
    }
    
    [self connect];
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    
    [self decriptMessage:message];
}

#pragma mark -

-(void) decriptMessage:(id) message
{
    if([message isKindOfClass:[NSString class]]) {
        
        NSString *string = (NSString *) message;
        
        NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
        NSError *jsonParsingError = nil;
        NSDictionary *obj = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonParsingError];
        
        if(obj[@"op"]) {
            [self addOperation:obj];
        }
        else if ([self.delegate respondsToSelector:@selector(didReceiveEvents:)]) {
                [self.delegate didReceiveEvents:obj];
        }
    }
}

- (void) addOperation:(NSDictionary *) json
{
    NSMutableDictionary *operation = [NSMutableDictionary dictionaryWithDictionary:json];
    
    if([operation[@"rc"] intValue] == 1) {
        
        if(operation[@"data"]) {
            
            NSData *nsdataFromBase64String = [[NSData alloc] initWithBase64EncodedString:operation[@"data"] options:0];

            NSDictionary *data = [NSJSONSerialization JSONObjectWithData:nsdataFromBase64String options:0 error:nil];
            [operation setObject:data forKey:@"data"];
        }
        
        if([operation[@"op"] intValue] == UNBIND) {
            NSString *topic = operation[@"topic"];
            NSString *event = operation[@"event"];
            
            for(NSDictionary *op in self.operations)
            {
                if([op[@"topic"] isEqualToString:topic] && [op[@"event"] isEqualToString:event]) {
                    [self.operations removeObject:op];
                    continue;
                }
            }
        }
        else if([operation[@"op"] intValue] == BIND) {
            
            if([self isPrivateTopic:operation[@"topic"]]) {
                self.userData = operation[@"data"];
            }
            
            [self.operations addObject:[operation copy]];
        }
        
       
    }
    
    //delete operation from offline opearation checking UUID
    for(NSDictionary *offOp in self.offlineOperations)
    {
        if([offOp[@"uuid"] isEqualToString:operation[@"uuid"]]) {
            [self.offlineOperations removeObject:offOp];
            continue;
        }
    }
    
    if ([self.delegate respondsToSelector:@selector(didReceiveOpsResponse:)]) {
        [self.delegate didReceiveOpsResponse:[operation copy]];
    }
    
    NSLog(@"count operations: %@", self.operations);
    NSLog(@"count offline operations: %@", self.offlineOperations);
}

- (void) send :(NSDictionary *) dictionary {
    
    if([dictionary[@"op"] intValue] == BIND && dictionary[@"auth_endpoint"] && [self isPrivateTopic:dictionary[@"topic"]])
    {
        NSDictionary *params = @{
                                 @"topic": dictionary[@"topic"],
                                 @"user": dictionary[@"auth_endpoint"][@"user"],
                                 @"pass": dictionary[@"auth_endpoint"][@"pass"]
                                 };
     
        NSLog(@"params: %@", params);
        
     //   endpoint
        
        NSString *urlString = [NSString stringWithFormat:@"http://%@:%@/app/%@/auth_user", ADDRESS, PORT, self.appId];
        
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
                    
                    NSLog(@"Json: %@", json);
                    
                    NSMutableDictionary *newJson = [NSMutableDictionary dictionaryWithDictionary:dictionary];
                    [newJson removeObjectForKey:@"auth_endpoint"];
                    
                    if(json) {
                        [newJson setObject:params[@"user"] forKey:@"arg1"];
                        [newJson setObject:json[@"data"] forKey:@"arg2"];
                        [newJson setObject:json[@"sign"] forKey:@"arg3"];
                    }
                    
                    [self send:newJson];
                    
                }] resume];
    }
    else
    {
        NSString *s = [self bv_jsonStringWithPrettyPrint:NO withDict:dictionary];
        [self.webSocket send:s];
    }
}

- (void) sendOperations
{
    for(NSDictionary *op in self.offlineOperations) {
        [self send:op];
    }
    
    for(NSDictionary *op in self.operations) {
        [self send:op];
    }
}

- (BOOL) isPrivateTopic:(NSString *) topic {
    
    if(topic.length >0 &&  [[topic substringToIndex:1] isEqualToString:@"@"])
        return YES;
    
    return NO;
}

-(NSString*) bv_jsonStringWithPrettyPrint:(BOOL) prettyPrint withDict:(NSDictionary *)dict{
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict
                                                       options:(NSJSONWritingOptions)    (prettyPrint ? NSJSONWritingPrettyPrinted : 0)
                                                         error:&error];
    
    if (! jsonData) {
        NSLog(@"bv_jsonStringWithPrettyPrint: error: %@", error.localizedDescription);
        return @"{}";
    } else {
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
}

@end
