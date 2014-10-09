//
//  Created by Willy Blandin on 12. 8. 16..
//  Copyright (c) 2012년 Willy Blandin. All rights reserved.
//

#import "WitPrivate.h"
#import "WITState.h"
#import "WITRecorder.h"
#import "WITUploader.h"
#import "util.h"
#import "WITRecordingSession.h"

@interface Wit () <WITRecordingSessionDelegate>
@property (strong) WITState *state;
@property WITRecordingSession *recordingSession;
@end

@implementation Wit {
}
@synthesize delegate, state;

#pragma mark - Public API
- (void)toggleCaptureVoiceIntent:(id)sender {
    [self toggleCaptureVoiceIntent:sender withCustomData:nil];
}

- (void)toggleCaptureVoiceIntent:(id)sender withCustomData:(id) customData {
    if ([self isRecording]) {
        [self stop];
    } else {
        [self start:sender customData:customData];
    }
}

- (void)start {
    [self start:nil customData:nil];
}


- (void)start:(id)sender customData:(id)customData {
    self.recordingSession = [[WITRecordingSession alloc] initWithWitContext:state.context
                                                                 vadEnabled:[Wit sharedInstance].detectSpeechStop withToggleStarter:sender withWitToken:[WITState sharedInstance].accessToken];
    self.recordingSession.customData = customData;
    self.recordingSession.delegate = self;
}

- (void)stop{
    [self.recordingSession stop];
    self.recordingSession = nil;
}

- (BOOL)isRecording {
    return [self.recordingSession isRecording];
}

- (void) interpretString: (NSString *) string {
    NSDate *start = [NSDate date];
    NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.wit.ai/message?q=%@&v=%@", urlencodeString(string), kWitAPIVersion]]];
    [req setCachePolicy:NSURLCacheStorageNotAllowed];
    [req setTimeoutInterval:15.0];
    [req setValue:[NSString stringWithFormat:@"Bearer %@", self.accessToken] forHTTPHeaderField:@"Authorization"];
    [req setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [NSURLConnection sendAsynchronousRequest:req
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               if (WIT_DEBUG) {
                                   NSTimeInterval t = [[NSDate date] timeIntervalSinceDate:start];
                                   NSLog(@"Wit response (%f s) %@",
                                         t, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
                               }
                               
                               if (connectionError) {
                                   [self gotResponse:nil error:connectionError];
                                   return;
                               }
                               
                               NSError *serializationError;
                               NSDictionary *object = [NSJSONSerialization JSONObjectWithData:data
                                                                                      options:0
                                                                                        error:&serializationError];
                               if (serializationError) {
                                   [self gotResponse:nil error:serializationError];
                                   return;
                               }
                               
                               if (object[@"error"]) {
                                   NSDictionary *infos = @{NSLocalizedDescriptionKey: object[@"error"],
                                                           kWitKeyError: object[@"code"]};
                                   [self gotResponse:nil
                                               error:[NSError errorWithDomain:@"WitProcessing"
                                                                         code:1
                                                                     userInfo:infos]];
                                   return;
                               }
                               
                               [self gotResponse:object error:nil];
                           }];
}

#pragma mark - Context management
-(void)setContext:(NSDictionary *)dict {
    NSMutableDictionary* newContext = [state.context mutableCopy];
    if (!newContext) {
        newContext = [@{} mutableCopy];
    }

    [dict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        newContext[key] = obj;
    }];

    state.context = newContext;
}

-(NSDictionary*)getContext {
    return state.context;
}

#pragma mark - NSNotificationCenter
- (void)audioend:(NSNotification*)n {
    if ([self.delegate respondsToSelector:@selector(witDidStopRecording)]) {
        [self.delegate witDidStopRecording];
    }
}

- (void)audiostart:(NSNotification*)n {
    if ([self.delegate respondsToSelector:@selector(witDidStartRecording)]) {
        [self.delegate witDidStartRecording];
    }
}

#pragma mark - WITUploaderDelegate
- (void)gotResponse:(NSDictionary*)resp error:(NSError*)err {
    if (err) {
        [self error:err];
        return;
    }
    [self processMessage:resp];
}
-(void)gotResponse:(NSDictionary *)resp error:(NSError *)err customData:(id)customData {
    [self gotResponse:resp error:err];
}

#pragma mark - Response processing
- (void)errorWithDescription:(NSString*)errorDesc {
    NSError* e = [NSError errorWithDomain:@"WitProcessing" code:1 userInfo:@{NSLocalizedDescriptionKey: errorDesc}];
    [self error:e];
}

- (void)processMessage:(NSDictionary *)resp {
    id error = resp[kWitKeyError];
    if (error) {
        NSString* errorDesc = [NSString stringWithFormat:@"Code %@: %@", error[@"code"], error[@"message"]];
        return [self errorWithDescription:errorDesc];
    }

    NSDictionary* outcome = resp[kWitKeyOutcome];
    if (!outcome) {
        return [self errorWithDescription:@"No outcome"];
    }

    NSString *intent = outcome[@"intent"];
    if ((id)intent == [NSNull null]) {
        return [self errorWithDescription:@"Intent was null"];
    }
    
    NSDictionary *entities = outcome[@"entities"];
    [self.delegate witDidGraspIntent:intent entities:entities body:resp[kWitKeyBody] error:nil];
    [self dispatchIntent:intent withEntities:entities andBody:resp[kWitKeyBody]];
}

- (void)error:(NSError*)e {
    [self.delegate witDidGraspIntent:nil entities:nil body:nil error:e];
}

#pragma mark - Selector dispatch
- (SEL)selectorFromIntent:(NSString *)intent {
    // prepare regex for non-allowed characters
    NSRegularExpression *wrongChars = [NSRegularExpression regularExpressionWithPattern:@"[-\\[_!@#%\\^$&*()=+}{|\\]';:/?.>,<`~\\\\]"
                                                                                options:0
                                                                                  error:nil];

    // capitalize string and replace non-alphanum by spaces
    NSString *sel = [NSMutableString stringWithString:
            [wrongChars stringByReplacingMatchesInString:intent
                                                 options:0
                                                   range:NSMakeRange(0, [intent length])
                                            withTemplate:@" "]];

    sel = [sel capitalizedString];
    // remove spaces
    sel = [sel stringByReplacingOccurrencesOfString:@" " withString:@""];
    // uncapitalize first letter
    NSString *firstChar = [sel substringWithRange:NSMakeRange(0, 1)];
    sel = [sel stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:[firstChar lowercaseString]];
    // add : at the end
    sel = [sel stringByAppendingString:@":withBody:"];

    debug(@"%@ => %@", intent, sel);
    return NSSelectorFromString(sel);
}

- (void)dispatchIntent:(NSString *)intent withEntities:(NSDictionary *)entities andBody:(NSString *)body {
    if (!intent || (id)intent == [NSNull null]) {
        return;
    }

    SEL selector = [self selectorFromIntent:intent];
    if ([self.commandDelegate respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self.commandDelegate performSelector:selector withObject:entities withObject:body];
#pragma clang diagnostic pop
    } else {
        debug(@"Couldn't find selector: %@", NSStringFromSelector(selector));
        if ([self.commandDelegate respondsToSelector:@selector(didNotFindIntentSelectorForIntent:entities:body:)]) {
            NSMethodSignature * mySignature = [self.commandDelegate
                                               methodSignatureForSelector:@selector(didNotFindIntentSelectorForIntent:entities:body:)];
            NSInvocation * myInvocation = [NSInvocation
                                           invocationWithMethodSignature:mySignature];
            [myInvocation setTarget:self.commandDelegate];
            [myInvocation setSelector:@selector(didNotFindIntentSelectorForIntent:entities:body:)];
            [myInvocation setArgument:&intent atIndex:2];
            [myInvocation setArgument:&entities atIndex:3];
            [myInvocation setArgument:&body atIndex:4];
            [myInvocation invoke];
            
            
        }
    }
}

#pragma mark - Getters and setters
- (NSString *)accessToken {
    return state.accessToken;
}

- (void)setAccessToken:(NSString *)accessToken {
    state.accessToken = accessToken;
}

#pragma mark - Lifecycle
- (void)initialize {
    state = [WITState sharedInstance];
    [self observeNotifications];
    self.detectSpeechStop = NO;
}
- (id)init {
    self = [super init];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)observeNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audiostart:)
                                                 name:kWitNotificationAudioStart object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioend:)
                                                 name:kWitNotificationAudioEnd object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (Wit *)sharedInstance {
    static Wit *instance;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        instance = [[Wit alloc] init];
    });

    return instance;
}

@end
