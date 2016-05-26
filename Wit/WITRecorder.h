//
//  Recorder.h
//  Wit
//
//  Created by Willy Blandin on 12. 8. 24..
//  Copyright (c) 2012년 Willy Blandin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "WITVad.h"


@protocol WITRecorderDelegate;

//
// Handles recording of audio data using Audio Queue Services
//
@interface WITRecorder : NSObject <WITVadDelegate>
@property (nonatomic, weak) id<WITRecorderDelegate> delegate;
@property (atomic) CGFloat power; // recording volume power

#pragma mark - Recording
- (BOOL)start;
- (BOOL)stop;
- (BOOL)isRecording;
- (BOOL)stoppedUsingVad;
- (void)enabledVad;
- (instancetype)initWithAudioFormat:(AudioFormatID)audioFormat;
@end

@protocol WITRecorderDelegate <NSObject>

- (void)recorderDetectedSpeech;
- (void)recorderGotChunk:(NSData *)chunk;
- (void)recorderStarted;
- (void)recorderStopped;
- (void)recorderVadStoppedTalking;



- (void)stop;
@end