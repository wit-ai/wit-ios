//
//  Created by Willy Blandin on 12. 8. 16..
//  Copyright (c) 2012년 Willy Blandin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "WITVadConfig.h"
#import "WITMicButton.h"




@class WITRecordingSession;
@class WITContextSetter;
@protocol WitDelegate;
@protocol WITRecordingSessionDelegate;


@interface Wit : NSObject  <WITRecordingSessionDelegate>

@property(strong) WITContextSetter *wcs;

/**
 Delegate to send feedback for the application
 */
@property(nonatomic, strong) id <WitDelegate> delegate;

/**
 Access token used to contact Wit.ai
 */
@property (strong) NSString* accessToken;

/**
 * Configure the voice activity detection algorithm:
 * - WITVadConfigDisabled
 * - WITVadConfigDetectSpeechStop (default)
 * - WITVadConfigFull
 */
@property WITVadConfig detectSpeechStop;

/**
 * Allow you to configure the options to pass to the AVAudioSession.
 * This will be passed to the function [AVAudioSession setCategory:category withOptions:options error:outError]
 *
 * See https://developer.apple.com/library/IOs/documentation/AVFoundation/Reference/AVAudioSession_ClassReference/index.html#//apple_ref/c/econst/AVAudioSessionCategoryOptionMixWithOthers
 *
 */
@property AVAudioSessionCategoryOptions avAudioSessionCategoryOption;

/**
 Singleton instance accessor.
 */
+ (Wit*)sharedInstance;

/**
 * Starts a new recording session. [self.delegate witDidGraspIntent:...] will be called once completed.
 */
- (void)start;

/**
 * Same as the start method but allow a custom object to be passed, which will be passed back as an argument of the
 * [self.delegate witDidGraspIntent:... customData:(id)customData]. This is how you should link a request to a response, if needed.
 */
- (void)start: (id)customData;

/**
 * Start / stop the audio processing. Once the API response is received, [self.delegate witDidGraspIntent:...] method will be called.
 */
- (void)toggleCaptureVoiceIntent;

/**
 * Same as toggleCaptureVoiceIntent, allowing you to pass a customData object to the [self start:(id)customData] function.
 */
- (void)toggleCaptureVoiceIntent:(id) customData;


/**
 Stops the current recording if any, which will lead to [self.delegate witDidGraspIntent:...] call.
 */
- (void)stop;

/**
 YES if Wit is recording audio
 */
- (BOOL)isRecording;

/**
 * Sends an NSString to wit.ai for interpretation. Same as sending a voice input, but with text.
 */
- (void) interpretString: (NSString *) string customData:(id)customData;


#pragma mark - Context management

/**
 * Sets context from NSDictionary. Merge semantics! 
 * See the context documentation in our doc for for more information:  http://wit.ai/docs/http/20140923#context-link
 */
- (void)setContext:(NSDictionary*)dict;

/**
 * Returns the current context
 */
- (NSDictionary*)getContext;
@end

/**
 * Protocol used by Wit to communicate with the app
 */
@protocol WitDelegate <NSObject>

/**
 * Called when the Wit request is completed.
 * param outcomes a NSDictionary of outcomes returned by the Wit API. Outcomes are ordered by confidence, highest first. Each outcome contains (at least) the following keys:
 *       intent, entities[], confidence, _text. For more information please refer to our online documentation: https://wit.ai/docs/http/20141022#get-intent-via-text-link
 *
 * param messageId the message id returned by the api
 * param customData any data attached when starting the request. See [Wit sharedInstance toggleCaptureVoiceIntent:... (id)customData] and [[Wit sharedInstance] start:... (id)customData];
 * param error Nil if no error occurred during processing
 */
- (void)witDidGraspIntent:(NSArray *)outcomes messageId:(NSString *)messageId customData:(id) customData error:(NSError*)e;

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
