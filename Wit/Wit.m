//
//  Created by Willy Blandin on 12. 8. 16..
//  Copyright (c) 2012년 Willy Blandin. All rights reserved.
//

#import "WitPrivate.h"
#import "WITState.h"

@interface Wit ()
@property (strong) WITState *state;
@end

@implementation Wit {
    NSDictionary* _sounds;
}
@synthesize delegate, state;
@dynamic sounds;

#pragma mark - Public API
- (void)toggleCaptureVoiceIntent:(id)sender {
    if ([self isRecording]) {
        [state.recorder performSelectorInBackground:@selector(stop) withObject:nil];

        NSString* soundPath = self.sounds[@"stopRecording"];
        if (soundPath) {
            [state.recorder performSelectorOnMainThread:@selector(play:) withObject:soundPath waitUntilDone:NO];
        }
    } else {
        [state.recorder performSelectorInBackground:@selector(record) withObject:nil];
        NSString* soundPath = self.sounds[@"startRecording"];
        if (soundPath) {
            [state.recorder performSelectorOnMainThread:@selector(play:) withObject:soundPath waitUntilDone:NO];
        }
    }
}

- (void)cancel {
    [state.recorder cancel];
}

- (BOOL)isRecording {
    return [self.state.recorder isRecording];
}

#pragma mark - NSNotificationCenter
- (void)responseReceived:(NSNotification*)n {
    NSDictionary* resp = [n userInfo];
    NSError* e = resp[kWitKeyError];
    
    if (e) {
        [self error:e];
        return;
    }
    
    resp = resp[kWitKeyResponse];
    [self processMessage:resp];
}

- (void)recordingStarted:(NSNotification*)n {
    if ([self.delegate respondsToSelector:@selector(witDidStartRecording)]) {
        [self.delegate witDidStartRecording];
    }
}

- (void)recordingCompleted:(NSNotification*)n {
    NSDictionary* data = [n userInfo];
    NSError* e = data[kWitKeyError];

    if (e) {
        [self error:e];
        return;
    }

    [state.uploader uploadSampleWithURL:data[kWitKeyURL]];
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
    }
}

#pragma mark - Getters and setters
- (NSString *)instanceId {
    return state.instanceId;
}

- (void)setInstanceId:(NSString *)instanceId {
    state.instanceId = instanceId;
}

- (NSString *)accessToken {
    return state.accessToken;
}

- (void)setAccessToken:(NSString *)accessToken {
    state.accessToken = accessToken;
}

- (NSDictionary *)sounds {
    return _sounds;
}

- (void)setSounds:(NSDictionary *)sounds {
    _sounds = sounds;
}

#pragma mark - Lifecycle
- (id)init {
    self = [super init];
    if (self) {
        state = [WITState sharedInstance];
        [self observeNotifications];
    }
    return self;
}

- (void)observeNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(responseReceived:)
                                                 name:kWitNotificationResponseReceived object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recordingStarted:)
                                                 name:kWitNotificationRecordingStarted object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recordingCompleted:)
                                                 name:kWitNotificationRecordingCompleted object:nil];
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
