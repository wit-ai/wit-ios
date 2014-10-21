//
//  Created by Willy Blandin on 12. 8. 16..
//  Copyright (c) 2012년 Willy Blandin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "WITVadConfig.h"
#import "WITMicButton.h"



@class WITRecordingSession;
@protocol WitDelegate;
@protocol WITRecordingSessionDelegate;


@interface Wit : NSObject  <WITRecordingSessionDelegate>
/**
 Delegate to send feedback for the application
 */
@property(nonatomic, strong) id <WitDelegate> delegate;

/**
 Delegate to send command based on intent received
 */
@property(nonatomic, strong) id commandDelegate;

/**
 Access token used to contact Wit.ai
 */
@property (strong) NSString* accessToken;

/**
 Enable / Disable voice activity detection
 */
@property WITVadConfig detectSpeechStop;

/**
 Singleton instance accessor
 */
+ (Wit*)sharedInstance;

/**
 Pops a new view and records user voice. The sender to which the modal will be presented (Can be null if no UI wanted)
 */
- (void)toggleCaptureVoiceIntent:(id)sender;
- (void)toggleCaptureVoiceIntent:(id)sender withCustomData:(id) customData;

/**
 Starts a new recording
 */
- (void)start;
- (void)start:(id)sender customData:(id)customData;

/**
 Stops the current recording if any
 */
- (void)stop;

/**
 YES if Wit is recording audio
 */
- (BOOL)isRecording;

/**
 Sends an NSString to wit.ai for interpretation
 */
- (void)interpretString:(NSString *)string;

#pragma mark - Context management

/**
 Sets context from NSDictionary. Merge semantics!
 */
- (void)setContext:(NSDictionary*)dict;
/**
 Returns the current context
 */
- (NSDictionary*)getContext;
@end

/**
 * Protocol used by Wit to communicate with the app
 */
@protocol WitDelegate <NSObject>

/**
 Called when the Wit request is completed.
 \param intent The intent recognized
 \param entities An array of entities linked to this intent
 \param body The spoken text returned by the api
 \param messageId the message id returned by the api
 \param confidence the confidence level of Wit about the returned semantic, ranging between 0 and 1.
 \param customData any data attached when starting the request. See [Wit sharedInstance toggleCaptureVoiceIntent:... (id)customData] and [[Wit sharedInstance] start:... (id)customData];
 \param error Nil if no error occurred during processing
 */
- (void)witDidGraspIntent:(NSString *)intent entities:(NSDictionary *)entities body:(NSString *)body messageId:(NSString *)messageId confidence:(NSNumber *)confidence customData:(id) customData error:(NSError*)e;

@optional

/**
 * When using the hands free voice activity detection option (WITVadConfigFull), this callback will be called when the microphone started to listen
 * and is waiting to detect voice activity in order to start streaming the data to the Wit API.
 * This function will not be called if the [Wit sharedInstance].detectSpeechStop is not equal to WITVadConfigFull
 */
- (void)witActivityDetectorStarted;

/**
 * Called when the streaming of the audio data to the Wit API starts.
 * The streaming to the Wit API starts right after calling one of the start methods when
 * detectSpeechStop is equal to WITVadConfigDisabled or WITVadConfigDetectSpeechStop.
 * If detectSpeechStop is equal to WITVadConfigFull, the streaming to the Wit API starts only when the SDK
 * detected a voice activity.
 */
- (void)witDidStartRecording;

/**
 Called when Wit stop recording the audio input.
 */
- (void)witDidStopRecording;

@end
