//
//  Recorder.h
//  Wit
//
//  Created by Willy Blandin on 12. 8. 24..
//  Copyright (c) 2012년 Willy Blandin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

//
// Wraps AVAudioRecorder
//
@interface WITRecorder : NSObject <AVAudioPlayerDelegate, AVAudioRecorderDelegate>

/**
 Delegate to send feedback for the application
 */
@property (atomic) float power; // recording volume power

#pragma mark - Recording
-(BOOL)record;
-(BOOL)stop;
-(void)cancel;
-(BOOL)isRecording;

#pragma mark - Playing
-(void)play:(NSString*)soundPath;
@end
