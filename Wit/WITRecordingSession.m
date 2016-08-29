//
//  WITRecordingSession.m
//  Wit
//
//  Created by Aric Lasry on 8/14/14.
//  Copyright (c) 2014 Willy Blandin. All rights reserved.
//

#import "WITRecordingSession.h"
#import "WITVadConfig.h"
#import "WITContextSetter.h"

#import <CoreTelephony/CTTelephonyNetworkInfo.h>

#import <GCNetworkReachability/GCNetworkReachability.h>
@interface WITRecordingSession ()

@property (assign) WITVadConfig vadEnabled;
@property (nonatomic, strong) NSMutableArray *dataBuffer;
@property (assign) int buffersToSave;
@property (nonatomic, strong) WITContextSetter *wcs;

@end

@implementation WITRecordingSession {
}

-(instancetype)initWithWitContext:(NSDictionary *)upContext vadEnabled:(WITVadConfig)vadEnabled withWitToken:(NSString *)witToken withDelegate:(id<WITRecordingSessionDelegate>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
        _dataBuffer = [[NSMutableArray alloc] init];
        _vadEnabled = vadEnabled;

        AudioFormatID formatToUse = [self configureFormat];
        _uploader = [[WITUploader alloc] initWithAudioFormat:formatToUse];
        _recorder = [[WITRecorder alloc] initWithAudioFormat:formatToUse];

        _uploader.delegate = self;
        _isUploading = false;
        _context = upContext;
        _recorder.delegate = self;
        [_recorder start];
        _witToken = witToken;
        _buffersToSave = 25; //hardcode for now
        if (vadEnabled == WITVadConfigDisabled) {
            [self startUploader];
        } else  {
            [_recorder enabledVad];
            if (vadEnabled == WITVadConfigDetectSpeechStop) {
                [self startUploader];
            } else if (vadEnabled == WITVadConfigFull) {
                
            }
        }
    }

    return self;
}

- (AudioFormatID)configureFormat
{
    GCNetworkReachability *reachability = [GCNetworkReachability reachabilityForInternetConnection];

    CTTelephonyNetworkInfo *networkInfo = [[CTTelephonyNetworkInfo alloc] init];
    NSString *connectionType = networkInfo.currentRadioAccessTechnology;
    AudioFormatID formatToUse = kAudioFormatLinearPCM;
    switch ([reachability currentReachabilityStatus]) {
        case GCNetworkReachabilityStatusWWAN:
            // e.g. download smaller file sized images...

            if ([connectionType isEqualToString:CTRadioAccessTechnologyGPRS] || [connectionType isEqualToString:CTRadioAccessTechnologyWCDMA] || [connectionType isEqualToString:CTRadioAccessTechnologyEdge] || [connectionType isEqualToString:CTRadioAccessTechnologyCDMA1x] || [connectionType isEqualToString:CTRadioAccessTechnologyHSUPA] || [connectionType isEqualToString:CTRadioAccessTechnologyCDMAEVDORev0]  || [connectionType isEqualToString:CTRadioAccessTechnologyCDMAEVDORevA]  || [connectionType isEqualToString:CTRadioAccessTechnologyCDMAEVDORevB] || [connectionType isEqualToString:CTRadioAccessTechnologyHSDPA]) {
                formatToUse = kAudioFormatULaw;
                debug(@"Got SLOW connection");
            } else {
                debug(@"Got FAST default connection");
                formatToUse = kAudioFormatLinearPCM;
            }


            break;
        default:
            debug(@"Got FAST default connection");
            formatToUse = kAudioFormatLinearPCM;
            break;
    }
    return formatToUse;
}

- (void)startUploader
{
   _context = [[Wit sharedInstance].wcs contextFillup:_context];
    
    [_uploader startRequestWithContext:_context];
    _isUploading = true;
    [_delegate recordingSessionDidStartRecording];
}

- (void)stop
{
    [self.recorder stop];
    // self.isUploading = false;
    [self.delegate recordingSessionDidStopRecording];

}

- (BOOL)isRecording {
    return [self.recorder isRecording];
}

- (void)gotResponse:(NSDictionary*)resp error:(NSError*)err {
    if (err) {
        NSLog(@"Wit stopped recording because of a (network?) error");
        [self stop];
    }

    [self.delegate recordingSessionGotResponse:resp customData:self.customData error:err sender: self];
    
    [self clean];
}



#pragma mark - WITRecorderDelegate implementation

- (void)recorderGotChunk:(NSData*)chunk {
    dispatch_async(dispatch_get_main_queue(), ^{
    if(self.isUploading) {
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
        [self.delegate recordingSessionRecorderGotChunk:chunk];
    });
}

- (void)recorderDetectedSpeech {
    [self.delegate recordingSessionDidDetectSpeech];
    
    if (self.vadEnabled == WITVadConfigFull) {
        dispatch_async(dispatch_get_main_queue(), ^{
            //start the uploader
            [self startUploader];
    
            //then prepend buffered data
            for (NSData *bufferedData in self.dataBuffer){
                [self.uploader sendChunk:bufferedData];
            }
        });
    }
}

- (void)recorderStarted {
    [self.delegate recordingSessionActivityDetectorStarted];
}

- (void)recorderStopped {
    [self.uploader endRequest];
}


- (void)recorderVadStoppedTalking {
    [self.delegate stop];
}


#pragma mark - cleaning

-(void)clean {
    self.recorder = nil;
    self.uploader = nil;
}


-(void)dealloc {
    
    debug(@"Clean WITRecordingSession");
}

@end
