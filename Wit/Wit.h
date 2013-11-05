//
//  Created by Willy Blandin on 12. 8. 16..
//  Copyright (c) 2012년 Willy Blandin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AFNetworking/AFNetworking.h>
#import "WITMicButton.h"

@protocol WitDelegate;

@interface Wit : NSObject <AVAudioPlayerDelegate>
/**
 Delegate to send feedback for the application
 */
@property(nonatomic, strong) id <WitDelegate> delegate;

/**
 Delegate to send command based on intent received
 */
@property(nonatomic, strong) id commandDelegate;

/**
 Paths to sounds played at various eventss
 keys are startRecording, stopRecording
 */
@property (strong) NSDictionary* sounds;

/**
 Access token used to contact Wit.ai
 */
@property (strong) NSString* accessToken;

/**
 Wit Instance ID used to contact Wit.ai
 */
@property (strong) NSString* instanceId;

/**
 Singleton instance accessor
 */
+ (Wit*)sharedInstance;

/**
 Pops a new view and records user voice. The sender to which the modal will be presented (Can be null if no UI wanted)
 */
- (void)toggleCaptureVoiceIntent:(id)sender;

/**
 Cancel the current recording if any.
 */
- (void)cancel;

/**
 YES if Wit is recording audio
 */
- (BOOL)isRecording;
@end

/**
 * Protocol used by Wit to communicate with the app
 */
@protocol WitDelegate <NSObject>

/**
 Called when Wit understood what has been sent
 \param intent The intent recognized
 \param entities An array of entities linked to this intent
 \param error Nil if no error occurred during processing
 */
- (void)witDidGraspIntent:(NSString *)intent entities:(NSDictionary *)entities body:(NSString *)body error:(NSError*)e;

@optional
/**
 Called when Wit start analyzing the audio entry
 */
- (void)witDidStartAnalyzing;

/**
 Called when Wit stop analyzing the audio entry
 */
- (void)witDidStopAnalyzing;

/**
 Called when Wit start recording the audio entry
 */
- (void)witDidStartRecording;

/**
 Called when Wit stop recording the audio entry
 */
- (void)witDidStopRecording;

@end

static __unused NSString* const kWitNotificationUploadProgress = @"WITUploaderProgress";
static __unused NSString* const kWitNotificationRecordingStarted = @"WITRecordingStarted";
static __unused NSString* const kWitNotificationRecordingCompleted = @"WITRecordingStopped";
static __unused NSString* const kWitNotificationResponseReceived = @"WITResponseReceived";

static __unused NSString* const kWitKeyResponse = @"response";
static __unused NSString* const kWitKeyError = @"error";
static __unused NSString* const kWitKeyOutcome = @"outcome";
static __unused NSString* const kWitKeyProgress = @"progress"; // file upload, etc.
static __unused NSString* const kWitKeyURL = @"url"; // record completed
static __unused NSString* const kWitKeyBody = @"msg_body"; // response's msg body

#if DEBUG
#define debug(x, ...) NSLog(x, ##__VA_ARGS__);
#else
#define debug(x, ...) ;
#endif