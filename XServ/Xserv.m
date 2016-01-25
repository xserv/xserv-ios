//
//  Xserv.m
//  Pods
//
//  Created by Giuseppe Nugara on 26/12/15.
//
//

#import "Xserv.h"
#import "SRWebSocket.h"

static NSString *const ADDRESS = @"mobile-italia.com";
static NSString *const PORT = @"5555";
static NSString *const HISTORY_ID = @"id";
static NSString *const HISTORY_TIMESTAMP = @"timestamp";

typedef enum XServOperationCode : NSInteger {
    MESSAGECODE = 200,
    BINDCODE = 201,
    UNBINDCODE = 202,
    HISTORY = 203
} XServOperationCode;

@interface Xserv () <SRWebSocketDelegate>

@property (nonatomic, strong) SRWebSocket *webSocket;
@property (nonatomic, strong) NSString *appId;
@property (nonatomic, strong) NSMutableArray *operations;
//@property (nonatomic, strong) NSMutableArray *sentOperations;

@end

@implementation Xserv

- (instancetype)initWithAppId:(NSString *) appId
{
    self = [super init];
    if (self) {
        self.appId = appId;
        self.operations = [NSMutableArray new];
    //    self.sentOperations = [NSMutableArray new];
    }
    return self;
}

-(NSString *) bindWithTopic:(NSString *) topic withEvent:(NSString *) event
{
    if(![self isConnected]) return nil;
    
    NSString *UUID = [[NSUUID UUID] UUIDString];
    
    NSDictionary *dict = @{
                           @"uuid" : UUID,
                           @"op" : [NSNumber numberWithInteger:BINDCODE],
                           @"topic" : topic,
                           @"event" : event
                          // @"auth_endpoint" : [NSDictionary new]
                           };
    
  //  [self.sentOperations addObject:dict];
    NSString *s = [self bv_jsonStringWithPrettyPrint:NO withDict:dict];
    NSLog(@"--> bind: %@", s);
    
    [self.webSocket send:s];
    
    return UUID;
}

- (NSString *)  unbindWithTopic:(NSString *) topic withEvent:(NSString *) event {
    
    if(![self isConnected]) return nil;
    
    NSString *UUID = [[NSUUID UUID] UUIDString];
    
    NSDictionary *dict = @{
                           @"uuid" : UUID,
                           @"op" : [NSNumber numberWithInteger:UNBINDCODE],
                           @"topic" : topic,
                           @"event" : event
                           };
  //  [self.sentOperations addObject:dict];
    NSString *s = [self bv_jsonStringWithPrettyPrint:NO withDict:dict];
    NSLog(@"--> unbind: %@", s);
    
    
    [self.webSocket send:s];
    
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
    
  //  [self.sentOperations addObject:dict];
    NSString *s = [self bv_jsonStringWithPrettyPrint:NO withDict:dict];
    NSLog(@"historyById: %@", s);
    [self.webSocket send:s];
    
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
    
  //  [self.sentOperations addObject:dict];
    NSString *s = [self bv_jsonStringWithPrettyPrint:NO withDict:dict];
    NSLog(@"historyByTimeStamp: %@", s);
    [self.webSocket send:s];
    
    return UUID;
}

- (void) trigger:(NSString *) message withTopic:(NSString *) topic withEvent:(NSString *) event
{
    if(![self isConnected]) return;
    
    NSDictionary *dict = @{
                           @"op" : [NSNumber numberWithInteger:MESSAGECODE],
                           @"topic" : topic,
                           @"event" : event,
                           @"arg1" : message
                           };
    
    NSString *s = [self bv_jsonStringWithPrettyPrint:NO withDict:dict];
    NSLog(@"message: %@", s);
    [self.webSocket send:s];
}

- (BOOL) isConnected {
    
    return self.webSocket.readyState == SR_OPEN;
}

- (BOOL) checkConnection
{
    if([self isConnected])
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

#pragma mark -

- (void)connect {
    self.webSocket.delegate = nil;
    self.webSocket = nil;
    
    NSString *urlString = [NSString stringWithFormat:@"ws://%@:%@/ws/%@", ADDRESS, PORT, self.appId];
     self.webSocket =[[SRWebSocket alloc] initWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]]];
    
    self.webSocket.delegate = self;
    
    [self.webSocket open];
}

- (void) disconnect
{
  //  [self.operations removeAllObjects];
  //  [self.sentOperations removeAllObjects];
    [self.webSocket close];
    self.webSocket.delegate = nil;
    self.webSocket = nil;
    
    if ([self.delegate respondsToSelector:@selector(didCloseConnectionWithReason:)]) {
        [self.delegate didCloseConnection:nil];
    }
}

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
   
  //  NSString *message = [NSString stringWithFormat:@"Reason: %@ - Code: %li", reason, (long)code];
    
    NSDictionary *errorDictionary = @{ NSLocalizedDescriptionKey : reason,
                                       NSUnderlyingErrorKey : reason };
    
    NSError *error = [[NSError alloc] initWithDomain:@"XServError"
                                          code:code userInfo:errorDictionary];
    
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

- (void) addOperation:(NSDictionary *) operation
{
  /*
    BOOL checkOperations = NO;
    NSString *uuid = operation[@"uuid"];
    
    for(NSDictionary *op in self.sentOperations)
    {
        if([op[@"uuid"] isEqualToString:uuid]) {
            [self.sentOperations removeObject:op];
            checkOperations = YES;
            continue;
        }
    }
    
    if(!checkOperations) {
        NSLog(@"error: checkOperations: %@", operation);
        return;
    }
   */
    if([operation[@"rc"] intValue] == 1) {
        if([operation[@"op"] intValue] == UNBINDCODE) {
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
        else if([operation[@"op"] intValue] == BINDCODE) {
            [self.operations addObject:operation];
        }
    }
     
    
    if ([self.delegate respondsToSelector:@selector(didReceiveOpsResponse:)]) {
        [self.delegate didReceiveOpsResponse:operation];
    }
    
    NSLog(@"count operations: %@", self.operations);
}

- (void) sendOperations
{
    for(NSDictionary *op in self.operations)
    {
     //   [self.sentOperations addObject:op];
        NSString *s = [self bv_jsonStringWithPrettyPrint:NO withDict:op];
        NSLog(@"operation: %@", s);
        [self.webSocket send:s];
    }
}

@end
