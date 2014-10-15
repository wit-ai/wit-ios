//
//  WITRecordingSession.h
//  Wit
//
//  Created by Aric Lasry on 8/14/14.
//  Copyright (c) 2014 Willy Blandin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WITSessionToggle.h"
#import "WITRecorder.h"
#import "WITUploader.h"
#import "WITVadTracker.h"
#import "WitPrivate.h"

@protocol WITRecordingSessionDelegate;


@interface WITRecordingSession : NSObject <WITRecorderDelegate, WITUploaderDelegate>

@property NSObject <WITSessionToggle> *starter;
@property WITRecorder *recorder;
@property WITUploader *uploader;
@property id <WITRecordingSessionDelegate> delegate;
@property id customData;
@property NSString *witToken;
@property NSDictionary *context;
@property BOOL isUploading;


-(id)initWithWitContext:(NSDictionary *)upContext vadEnabled:(WITVadConfig)vadEnabled withToggleStarter:(id <WITSessionToggle>) starter withWitToken:(NSString *)witToken withDelegate:(id<WITRecordingSessionDelegate>)delegate;
-(void)stop;
-(BOOL)isRecording;
-(void)trackVad:(NSString *)messageId;

@end


@protocol WITRecordingSessionDelegate <NSObject>

-(void)recordingSessionActivityDetectorStarted;
-(void)recordingSessionDidStartRecording;
-(void)recordingSessionDidStopRecording;
-(void)recordingSessionRecorderGotChunk:(NSData*)chunk;
-(void)recordingSessionGotResponse:(NSDictionary*)resp error:(NSError*)err;

-(void)stop;

@end