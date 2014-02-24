//
//  Recorder.m
//  Wit
//
//  Created by Willy Blandin on 12. 8. 24..
//  Copyright (c) 2012년 Willy Blandin. All rights reserved.
//

#import "WITRecorder.h"
#import "WitPrivate.h"
#import <AudioToolbox/AudioToolbox.h>

#define kNumberRecordBuffers 5

struct RecorderState {
    AudioStreamBasicDescription fmt;
    AudioQueueRef queue;
    AudioQueueBufferRef buffers[kNumberRecordBuffers];
    BOOL recording;
};
typedef struct RecorderState RecorderState;

@interface WITRecorder ()
@property (nonatomic, assign) RecorderState *state;
@property (strong) NSOperationQueue* chunksQueue;
@end

@implementation WITRecorder {
    CADisplayLink* displayLink;
}

#pragma mark - AudioQueue callbacks
static void audioQueueInputCallback(void* data,
                                    AudioQueueRef q,
                                    AudioQueueBufferRef buffer,
                                    const AudioTimeStamp *ts,
                                    UInt32 numberPacketDescriptions,
                                    const AudioStreamPacketDescription *packetDescs) {
    void * const bytes = buffer->mAudioData;
    UInt32 size        = buffer->mAudioDataByteSize;

    if (WIT_DEBUG) {
        const UInt32 capa = buffer->mAudioDataBytesCapacity;
        debug(@"Audio chunk %u/%u", (unsigned int)size, (unsigned int)capa);
    }

    if (size > 0) {
        WITRecorder* recorder = (__bridge WITRecorder*)data;
        [recorder.chunksQueue addOperationWithBlock:^{
            NSData* audio = [NSData dataWithBytes:bytes length:size];
            [recorder.delegate recorderGotChunk:audio];
        }];
    }

    AudioQueueEnqueueBuffer(q, buffer, 0, NULL);
}

static void MyPropertyListener(void *userData, AudioQueueRef queue, AudioQueuePropertyID propertyID) {
    if (propertyID == kAudioQueueProperty_IsRunning)
        debug(@"Queue running state changed");
}

#pragma mark - Recording
- (BOOL) start {
    int err;
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    self.state->recording = YES;

    for (int i = 0; i < kNumberRecordBuffers; i++) {
        err = AudioQueueEnqueueBuffer(self.state->queue, self.state->buffers[i], 0, NULL);
        if (err) {
            debug(@"error while enqueuing buffer %d", err);
        }
    }

    err = AudioQueueStart(self.state->queue, NULL);
    if (err) {
        debug(@"ERROR while starting audio queue: %d", err);
        return NO;
    }

    [displayLink setPaused:NO];
    [[NSNotificationCenter defaultCenter] postNotificationName:kWitNotificationAudioStart object:nil];

    return YES;
}

- (BOOL)stop {
    int err;
    err = AudioQueueReset(self.state->queue);
    if (err) {
        NSLog(@"[Wit] ERROR: could not flush audio queue (%d)", err);
    }
    err = AudioQueuePause(self.state->queue);
    if (err) {
        NSLog(@"[Wit] ERROR: could not pause audio queue (%d)", err);
    }
    [[AVAudioSession sharedInstance] setActive:NO error:nil];
    self.state->recording = NO;
//    [self.chunksQueue cancelAllOperations];

    [displayLink setPaused:YES];
    self.power = -999;
    [[NSNotificationCenter defaultCenter] postNotificationName:kWitNotificationAudioEnd object:nil];

    return YES;
}

- (BOOL)isRecording {
    return self.state->recording;
}

- (void)clean {
}

#pragma mark - CADisplayLink target
- (void)updatePower {
    if (![self isRecording]) {
        return;
    }
//    debug(@"Recorder: updating power");
    AudioQueueLevelMeterState meters[1];
    UInt32 dlen = sizeof(meters);
    int err;
    err = AudioQueueGetProperty(self.state->queue, kAudioQueueProperty_CurrentLevelMeterDB, meters, &dlen);
    if (err) {
        debug(@"Error while reading meters %d", err);
        return;
    }

    self.power = meters[0].mAveragePower;
}

#pragma mark - Lifecycle
- (void)initialize {
    // init recorder
    displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updatePower)];
    [displayLink setPaused:YES];
    [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];

    // create dispatch queue to process audio chunks
    self.chunksQueue = [[NSOperationQueue alloc] init];

    // create audio session
    AVAudioSession* session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [session setActive:YES error: nil];
    if([[AVAudioSession sharedInstance] respondsToSelector:@selector(requestRecordPermission:)])
    {
        [session requestRecordPermission:^(BOOL granted) {
            debug(@"Permission granted: %d", granted);
        }];
    }

    // create audio queue
    int err;
    RecorderState* state = (RecorderState*)malloc(sizeof(RecorderState));
    AudioStreamBasicDescription fmt;
    memset(&fmt, 0, sizeof(fmt));
    fmt.mFormatID         = kAudioFormatLinearPCM;
    fmt.mFormatFlags      = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    fmt.mChannelsPerFrame = 1;
    fmt.mSampleRate       = 16000.0;
    fmt.mBitsPerChannel	  = 16;
    fmt.mBytesPerPacket	  = fmt.mBytesPerFrame = (fmt.mBitsPerChannel / 8) * fmt.mChannelsPerFrame;
    fmt.mFramesPerPacket  = 1;
    AudioQueueNewInput(&fmt,
                       audioQueueInputCallback,
                       (__bridge void *)(self), // user data
                       NULL,   // run loop
                       NULL,   // run loop mode
                       0,      // flags
                       &state->queue);

    int bytes = (int)ceil(0.5 /* seconds */ * fmt.mSampleRate) * fmt.mBytesPerFrame;
    debug(@"AudioQueue buffer size: %d bytes", bytes);

    for (int i = 0; i < kNumberRecordBuffers; i++) {
        err = AudioQueueAllocateBuffer(state->queue, bytes, &state->buffers[i]);
        if (err) {
            debug(@"error while allocating buffer %d", err);
        }
    }

    UInt32 on = 1;
    AudioQueueSetProperty(state->queue, kAudioQueueProperty_EnableLevelMetering, &on, sizeof(on));
    err = AudioQueueAddPropertyListener(state->queue, kAudioQueueProperty_IsRunning,
                                        MyPropertyListener, &state);
    if (err) {
        debug(@"error while adding listener buffer %d", err);
    }

    state->fmt = fmt;
    state->recording = NO;
    self.state = state;
}

- (id)init {
    self = [super init];
    if (self) {
        [self initialize];
    }

    return self;
}

- (void)dealloc {
    [displayLink invalidate];
    AudioQueueDispose(self.state->queue, YES);
    free(self.state);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
