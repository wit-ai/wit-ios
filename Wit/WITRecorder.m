//
//  Recorder.m
//  Wit
//
//  Created by Willy Blandin on 12. 8. 24..
//  Copyright (c) 2012년 Willy Blandin. All rights reserved.
//

#import "WITRecorder.h"
#import "WitPrivate.h"
#import <AVFoundation/AVFoundation.h>

static NSString *const kSampleFilename = @"%@%d-wit.wav";

@interface WITRecorder ()
@property (nonatomic, copy) AVAudioSession *session;
@property (strong) AVAudioRecorder *recorder;
@property (strong) AVAudioPlayer* player;
@end

@implementation WITRecorder {
    NSLock* noiseLock; // lock to prevent playing sfx while recording
    CADisplayLink* displayLink;
}
@synthesize recorder, session, player;

#pragma mark - Recording
- (BOOL)record {
    NSError *err = nil;
    NSString *path = [NSString stringWithFormat:kSampleFilename,
                                                NSTemporaryDirectory(), (int) [[NSDate date] timeIntervalSince1970]];
    NSURL *url = [NSURL fileURLWithPath:path];
    NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithInt:kAudioFormatLinearPCM], AVFormatIDKey,
            [NSNumber numberWithFloat:16000], AVSampleRateKey,
            [NSNumber numberWithInt:1], AVNumberOfChannelsKey,
            [NSNumber numberWithInt:16], AVLinearPCMBitDepthKey,
            [NSNumber numberWithBool:NO], AVLinearPCMIsBigEndianKey,
            [NSNumber numberWithBool:NO], AVLinearPCMIsFloatKey,
            nil];

    recorder = [[AVAudioRecorder alloc] initWithURL:url settings:settings error:&err];
    recorder.delegate = self;

    if (!recorder) {
        NSLog(@"Recorder, not allocated: %@ %@ %d %@",
                [err description],
                [err domain],
                [err code],
                [[err userInfo] description]);
    }

    debug(@"Recorder, initialized with %@", [url lastPathComponent]);
    debug(@"Recorder, recording to %@", [[recorder url] lastPathComponent]);

    [session setActive:YES error:nil];
    [recorder prepareToRecord];
    [recorder setMeteringEnabled:YES];

    [[NSNotificationCenter defaultCenter] postNotificationName:kWitNotificationRecordingStarted object:nil];

    // acquire lock to make sure there is no sound playing at the same time
    [noiseLock lock];
    [recorder record];
    [noiseLock unlock];

    [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    
    return YES;
}

- (BOOL)stop {
    [recorder stop];
    [session setActive:NO error:nil];
    [displayLink removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    self.power = -999;
    
    return YES;
}

- (void)cancel {
    [self stop];
}

- (BOOL)isRecording {
    return self.recorder.recording;
}

- (void)clean {
    [recorder deleteRecording];
}

#pragma mark - Playing
- (void)play:(NSString*)soundPath {
    [noiseLock lock];
    
    NSURL* url = [[NSBundle mainBundle] URLForResource:soundPath withExtension:nil];
    NSData* data = [NSData dataWithContentsOfURL:url];
    NSError* error;

    player = [[AVAudioPlayer alloc] initWithData:data error:&error];
    player.volume = 1.0;
    player.delegate = self;

    BOOL ok = [player prepareToPlay];

    if (!ok) {
        debug(@"ERROR: couldn't prepare to play: %@", soundPath);
        return;
    }
    [player play];

    double delayInSeconds = player.duration;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [noiseLock unlock];
    });
}

#pragma mark - AVAudioRecorderDelegate
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)r successfully:(BOOL)success {
    if (success) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kWitNotificationRecordingCompleted object:nil
                                                          userInfo:@{kWitKeyURL: r.url}];
    } else {
        debug(@"Recorder, failed recording audio file");
        NSError* e = [NSError errorWithDomain:@"WitRecorder" code:1
                                     userInfo:@{NSLocalizedDescriptionKey: @"Failed uploading audio file"}];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kWitNotificationRecordingCompleted object:nil
                                                    userInfo:@{kWitKeyError: e}];
    }
}

#pragma mark - AVAudioPlayerDelegate
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    debug(@"Played successfully? %@", flag?@"YES":@"NO");
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error {
    debug(@"ERROR: AVAudioPlayer decode: %@", error.localizedDescription);
}

#pragma mark - CADisplayLink target
- (void)updatePower {
    [recorder updateMeters];
    self.power = [recorder averagePowerForChannel:0];
}

#pragma mark - Lifecycle
- (id)init {
    self = [super init];
    if (self) {
        [self initialize];
    }
    
    return self;
}

- (void)initialize {
    // create audio session and add listener
    session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryRecord error:nil];

    noiseLock = [[NSLock alloc] init];
    displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updatePower)];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clean)
                                                 name:kWitNotificationResponseReceived object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
