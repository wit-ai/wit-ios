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
#import "WITRecordingSessionDelegate.h"


@interface WITRecordingSession : NSObject <WITRecorderDelegate, WITUploaderDelegate>

@property (nonatomic, strong) WITRecorder *recorder;
@property (nonatomic, strong) WITUploader *uploader;
@property (nonatomic, weak) id <WITRecordingSessionDelegate> delegate;
@property (nonatomic, strong) id customData;
@property (nonatomic, copy) NSString *witToken;
@property (nonatomic, strong, readonly) NSDictionary *context;
@property (nonatomic, assign) BOOL isUploading;


-(instancetype)initWithWitContext:(NSDictionary *)upContext vadEnabled:(WITVadConfig)vadEnabled withWitToken:(NSString *)witToken withDelegate:(id<WITRecordingSessionDelegate>)delegate;
-(void)stop;
-(BOOL)isRecording;
@end


