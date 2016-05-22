//
//  WITRecordingSessionDelegate.h
//  Wit
//
//  Created by patrick on 29/04/16.
//  Copyright © 2016 Willy Blandin. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol WITRecordingSessionDelegate <NSObject>

-(void)recordingSessionActivityDetectorStarted;
-(void)recordingSessionDidStartRecording;
-(void)recordingSessionDidStopRecording;
-(void)recordingSessionDidDetectSpeech;
-(void)recordingSessionRecorderGotChunk:(NSData *)chunk;
-(void)recordingSessionGotResponse:(NSDictionary *)resp customData:(id)customData error:(NSError *)err sender:(id) sender;

-(void)stop;

@end
