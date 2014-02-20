//
//  Created by Willy Blandin on 12. 8. 16..
//  Copyright (c) 2012년 Willy Blandin. All rights reserved.
//

#import "WitPrivate.h"
#import "WITState.h"
#import "WITRecorder.h"
#import "WITUploader.h"

@interface Wit () <WITRecorderDelegate, WITUploaderDelegate>
@property (strong) WITState *state;
@end

@implementation Wit {
}
@synthesize delegate, state;

#pragma mark - Public API
- (void)toggleCaptureVoiceIntent:(id)sender {
    if ([self isRecording]) {
        [self stop];
    } else {
        [self start];
    }
}

- (void)start {
    [state.uploader startRequest];
    [state.recorder start];
}

- (void)stop {
    [state.recorder stop];
    [state.uploader endRequest];
}

- (BOOL)isRecording {
    return [self.state.recorder isRecording];
}

#pragma mark - WITRecorderDelegate
-(void)recorderGotChunk:(NSData*)chunk {
    [state.uploader sendChunk:chunk];
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
    self.state.recorder.delegate = self;
    self.state.uploader.delegate = self;
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
