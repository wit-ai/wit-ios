//
//  WITRecordingSession.h
//  Wit
//
//  Created by Aric Lasry on 8/14/14.
//  Copyright (c) 2014 Willy Blandin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WITRecorder.h"
#import "WITUploader.h"
#import "WITVadTracker.h"
#import "WitPrivate.h"

@protocol WITRecordingSessionDelegate;

@interface WITRecordingSession : NSObject <WITRecorderDelegate, WITUploaderDelegate>

@property(nonatomic, strong) WITRecorder *recorder;
@property(nonatomic, strong) WITUploader *uploader;
@property(nonatomic, weak) id <WITRecordingSessionDelegate> delegate;
@property(nonatomic, strong) id customData;
@property(nonatomic, strong) NSString *witToken;
@property(nonatomic, strong, readonly) NSMutableDictionary *context;
@property BOOL isUploading;


-(id)initWithWitContext:(NSDictionary *)upContext vadEnabled:(WITVadConfig)vadEnabled withWitToken:(NSString *)witToken withDelegate:(id<WITRecordingSessionDelegate>)delegate;
-(void)stop;
-(BOOL)isRecording;
-(void)trackVad:(NSString *)messageId;

@end


@protocol WITRecordingSessionDelegate <NSObject>

-(void)recordingSessionActivityDetectorStarted;
-(void)recordingSessionDidStartRecording;
-(void)recordingSessionDidStopRecording;
-(void)recordingSessionDidDetectSpeech;
-(void)recordingSessionRecorderGotChunk:(NSData*)chunk;
-(void)recordingSessionGotResponse:(NSDictionary*)resp customData:(id)customData error:(NSError*)err;

-(void)stop;

@end
