//
//  Created by Willy Blandin on 12. 8. 16.
//  Copyright (c) 2012년 Willy Blandin. All rights reserved.
//

#import "WitPrivate.h"
#import "WITState.h"
#import "WITRecorder.h"
#import "WITUploader.h"
#import "util.h"
//#import "WITRecordingSession.h"
#import "WITContextSetter.h"
#import "WITRecordingSessionDelegate.h"

@interface Wit () <WITRecordingSessionDelegate>
@property (nonatomic, strong) WITState *state;
@end

@implementation Wit {
    WITContextSetter* _wcs;
}

#pragma mark - Public API
- (void)toggleCaptureVoiceIntent {
    [self toggleCaptureVoiceIntent: nil];
}

- (void)toggleCaptureVoiceIntent:(id)customData {
    if ([self isRecording]) {
        [self stop];
    } else {
        [self start: customData];
    }
}

- (void)start {
    [self start: nil];
}


- (void)start: (id)customData {
    self.recordingSession = [[WITRecordingSession alloc] initWithWitContext:self.state.context
                                                                 vadEnabled:[Wit sharedInstance].detectSpeechStop withWitToken:[WITState sharedInstance].accessToken
                                                               withDelegate:self];
    self.recordingSession.customData = customData;
    self.recordingSession.delegate = self;
}

- (void)stop{
    [self.recordingSession stop];
}

- (BOOL)isRecording {
    return [self.recordingSession isRecording];
}

- (void)interpretString:(NSString *) string customData:(id)customData {
    NSDictionary *context = [self.wcs contextFillup:self.state.context];
    NSDate *start = [NSDate date];
    NSString *contextEncoded = [WITContextSetter jsonEncode:context];
    NSString *urlString = [NSString stringWithFormat:@"https://api.wit.ai/message?q=%@&v=%@&context=%@&verbose=true", urlencodeString(string), kWitAPIVersion, contextEncoded];
    NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString: urlString]];
    [req setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
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
                                   [self gotResponse:nil customData:customData error:connectionError];
                                   return;
                               }

                               NSError *serializationError;
                               NSDictionary *object = [NSJSONSerialization JSONObjectWithData:data
                                                                                      options:0
                                                                                        error:&serializationError];
                               if (serializationError) {
                                   [self gotResponse:nil customData:customData error:serializationError];
                                   return;
                               }

                               if (object[@"error"]) {
                                   NSDictionary *infos = @{NSLocalizedDescriptionKey: object[@"error"],
                                                           kWitKeyError: object[@"code"]};
                                   [self gotResponse:nil customData:customData
                                               error:[NSError errorWithDomain:@"WitProcessing"
                                                                         code:1
                                                                     userInfo:infos]];
                                   return;
                               }

                               [self gotResponse:object customData:customData error:nil];
                           }];
}

#pragma mark - Context management
-(void)setContext:(NSDictionary *)dict {
    self.state.context = dict;
}

-(NSDictionary*)getContext {
    return self.state.context;
}

#pragma mark - WITUploaderDelegate
- (void)gotResponse:(NSDictionary*)resp customData:(id)customData error:(NSError*)err {
    if (err) {
        [self error:err customData:customData];
        return;
    }
    [self processMessage:resp customData:customData];
}

#pragma mark - Response processing
- (void)errorWithDescription:(NSString*)errorDesc customData:(id)customData {
    NSError *e = [NSError errorWithDomain:@"WitProcessing" code:1 userInfo:@{NSLocalizedDescriptionKey: errorDesc}];
    [self error:e customData:customData];
}

- (void)processMessage:(NSDictionary *)resp customData:(id)customData {
    id error = resp[kWitKeyError];
    if (error) {
        NSString *errorDesc = [NSString stringWithFormat:@"Code %@: %@", error[@"code"], error[@"message"]];
        return [self errorWithDescription:errorDesc customData:customData];
    }

    NSArray* outcomes = resp[kWitKeyOutcome];
    if (!outcomes || [outcomes count] == 0) {
        return [self errorWithDescription:@"No outcome" customData:customData];
    }
    NSString *messageId = resp[kWitKeyMsgId];

    [self.delegate witDidGraspIntent:outcomes messageId:messageId customData:customData error:error];

}

- (void)error:(NSError*)e customData:(id)customData; {
    [self.delegate witDidGraspIntent:nil messageId:nil customData:customData error:e];
}

#pragma mark - Getters and setters
- (NSString *)accessToken {
    return self.state.accessToken;
}

- (void)setAccessToken:(NSString *)accessToken {
    self.state.accessToken = accessToken;
}

#pragma mark - Lifecycle
- (void)initialize {
    self.state = [WITState sharedInstance];
    self.detectSpeechStop = WITVadConfigDetectSpeechStop;
    self.vadTimeout = 7000;
    self.vadSensitivity = 0;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initialize];
    }
    return self;
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

- (WITContextSetter *)wcs {
    if (!_wcs) {
        _wcs = [[WITContextSetter alloc] init];
    }
    return _wcs;
}

#pragma mark - WITRecordingSessionDelegate

- (void)recordingSessionActivityDetectorStarted {
    if ([self.delegate respondsToSelector:@selector(witActivityDetectorStarted)]) {
        [self.delegate witActivityDetectorStarted];
    }
}

- (void)recordingSessionDidStartRecording {
    if ([self.delegate respondsToSelector:@selector(witDidStartRecording)]) {
        [self.delegate witDidStartRecording];
    }
}

- (void)recordingSessionDidStopRecording {
    if ([self.delegate respondsToSelector:@selector(witDidStopRecording)]) {
        [self.delegate witDidStopRecording];
    }
}

- (void)recordingSessionDidDetectSpeech {
    if ([self.delegate respondsToSelector:@selector(witDidDetectSpeech)]) {
        [self.delegate witDidDetectSpeech];
    }
}

- (void)recordingSessionRecorderGotChunk:(NSData *)chunk {
    if ([self.delegate respondsToSelector:@selector(witDidGetAudio:)]) {
        [self.delegate witDidGetAudio:chunk];
    }
}

- (void)recordingSessionRecorderPowerChanged:(float)power {

}

- (void)recordingSessionGotResponse:(NSDictionary *)resp customData:(id)customData error:(NSError *)err sender:(id) sender {
    [self gotResponse:resp customData:customData error:err];
    if (self.recordingSession == sender) {
        self.recordingSession = nil;
    }
}

@end
