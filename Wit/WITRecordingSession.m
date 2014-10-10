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
@property NSMutableArray *dataBuffer;
@property int buffersToSave;
@end

@implementation WITRecordingSession


-(id)initWithWitContext:(NSDictionary *)upContext vadEnabled:(BOOL)vadEnabled withToggleStarter:(id <WITSessionToggle>) starter withWitToken:(NSString *)witToken {
    self = [super init];
    if (self) {
        self.dataBuffer = [[NSMutableArray alloc] init];
        self.starter = starter;
        self.vadEnabled = vadEnabled;
        self.uploader = [[WITUploader alloc] init];
        self.uploader.delegate = self;
        self.isUploading = false;
        self.context = upContext;
        self.recorder = [[WITRecorder alloc] init];
        self.recorder.delegate = self;
        if (vadEnabled) {
            [self.recorder enabledVad];
        }
        [self.recorder start];
        [self.starter sessionDidStart:self.recorder];
        self.witToken = witToken;
        self.buffersToSave = 3; //hardcode for now
    }
    
    return self;
}

-(void)startUploader
{
    [self.uploader startRequestWithContext:self.context];
    self.isUploading = true;
}

-(void)stop
{
    [self.recorder stop];
    [self.uploader endRequest];
    self.isUploading = false;
    [self.starter sessionDidEnd:self.recorder];
}

- (BOOL)isRecording {
    return [self.recorder isRecording];
}

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

-(void)trackVad:(NSString *)messageId {
    if (self.vadEnabled && ![self.recorder stoppedUsingVad]) {
        NSLog(@"Tracking vad failure");
        [[[WITVadTracker alloc] init] track:@"vadFailed" withMessageId:messageId withToken:self.witToken];
    }
}

-(void)recorderGotChunk:(NSData*)chunk {
    dispatch_async(dispatch_get_main_queue(), ^{
    if(self.isUploading){
        [self.uploader sendChunk:chunk];
    } else {
        //not uploading, so save the chunk to the buffer and remove old chunk
        if ([self.dataBuffer count] >= self.buffersToSave){
            //if we have enough entries, remove the oldest one
            [self.dataBuffer removeObjectAtIndex:0];
        }
        //enqueue the new data
        [self.dataBuffer addObject:chunk];
    }
    });
}

-(void)recorderDetectedSpeech{
        dispatch_async(dispatch_get_main_queue(), ^{
    //start the uploader
    [self startUploader];
    
    //then prepend buffered data
    
    for(NSData* bufferedData in self.dataBuffer){
        [self.uploader sendChunk:bufferedData];
    }
        });
}

-(void)clean {
    self.recorder = nil;
    self.uploader = nil;
}


-(void)dealloc {
    NSLog(@"Clean WITRecordingSession");
}

@end
