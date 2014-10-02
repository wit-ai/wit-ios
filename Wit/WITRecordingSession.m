//
//  WITRecordingSession.m
//  Wit
//
//  Created by Aric Lasry on 8/14/14.
//  Copyright (c) 2014 Willy Blandin. All rights reserved.
//

#import "WITRecordingSession.h"

@interface WITRecordingSession ()

@property BOOL vadEnabled;
@end

@implementation WITRecordingSession


-(id)initWithWitContext:(NSDictionary *)upContext vadEnabled:(BOOL)vadEnabled withToggleStarter:(id <WITSessionToggle>) starter withWitToken:(NSString *)witToken {
    self = [super init];
    if (self) {
        self.starter = starter;
        self.vadEnabled = vadEnabled;
        self.uploader = [[WITUploader alloc] init];
        self.uploader.delegate = self;
        [self.uploader startRequestWithContext:upContext];
        self.recorder = [[WITRecorder alloc] init];
        self.recorder.delegate = self;
        if (vadEnabled) {
            [self.recorder enabledVad];
        }
        [self.recorder start];
        [self.starter sessionDidStart:self.recorder];
        self.witToken = witToken;

    }
    
    return self;
}

-(void)stop
{
    [self.recorder stop];
    [self.uploader endRequest];
    [self.starter sessionDidEnd:self.recorder];
}

- (BOOL)isRecording {
    return [self.recorder isRecording];
}

/**
 * Implementing WITUploaderDelegate
 */
-(void)gotResponse:(NSDictionary*)resp error:(NSError*)err {
    if ([self.delegate respondsToSelector:@selector(gotResponse:error:customData:)]) {
        [self.delegate gotResponse:resp error:err customData:self.customData];
    } else {
        [self.delegate gotResponse:resp error:err];
    }
    
    if (!err && resp[kWitKeyMsgId]) {
        [self trackVad:resp[kWitKeyMsgId]];
    }
    if (err) {
        NSLog(@"Wit stopped recording because of a (network?) error");
        [self stop];
    }
    [self clean];
}


/**
 * @end
 */

-(void)trackVad:(NSString *)messageId {
    if (self.vadEnabled && ![self.recorder stoppedUsingVad]) {
        NSLog(@"Tracking vad failure");
        [[[WITVadTracker alloc] init] track:@"vadFailed" withMessageId:messageId withToken:self.witToken];
    }
}

-(void)recorderGotChunk:(NSData*)chunk {
    [self.delegate recorderGotChunk:chunk];
}

-(void)clean {
    self.recorder = nil;
    self.uploader = nil;
}


-(void)dealloc {
    NSLog(@"Clean WITRecordingSession");
}


@end
