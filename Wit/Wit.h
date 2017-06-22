//
//  Created by Willy Blandin on 12. 8. 16..
//  Copyright (c) 2012년 Willy Blandin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "WITVadConfig.h"
#import "WITMicButton.h"
#import "WITRecordingSession.h"
#import "WitSession.h"



@class WITRecordingSession;
@class WITContextSetter;
@protocol WitDelegate;

@interface Wit : NSObject

@property(nonatomic, strong) WITRecordingSession *recordingSession;

@property(strong, readonly) WITContextSetter *wcs;

/**
 Delegate to send feedback for the application
 */
@property(nonatomic, weak) id<WitDelegate> delegate;

/**
 Access token used to contact Wit.ai
 */
@property (nonatomic, copy) NSString *accessToken;

/**
 On iOS 10 and above wit-ios-sdk uses Apple's speech recognition. The speech recognition
 needs to know which locale to use for recognition. A list of supported locales can be found via:
 https://developer.apple.com/documentation/speech/sfspeechrecognizer/1649889-supportedlocales
 Note that this locale must match the language of your wit model.
 The default value is @"en_US"
 */
@property (nonatomic, copy) NSString *speechRecognitionLocale;

/**
 * Configure the voice activity detection algorithm:
 * - WITVadConfigDisabled
 * - WITVadConfigDetectSpeechStop (default)
 * - WITVadConfigFull
 */
@property (nonatomic, assign) WITVadConfig detectSpeechStop;

/**
 * Set the maximum length of time recorded by the VAD in ms
 * Set to -1 for no timeout
 * Defaults to 7000
 */
@property (nonatomic, assign) NSInteger vadTimeout;

/**
 * Set VAD sensitivity (0-100):
 * - Lower values are for strong voice signals like for a cellphone or personal mic.
 * - Higher values are for use with a fixed-position mic or any application with voice buried in ambient noise.
 * - Defaults to 0
 */
@property (nonatomic, assign) NSInteger vadSensitivity;

/**
 Singleton instance accessor.
 */
+ (Wit *)sharedInstance;

/**
 * Starts a new recording session. [self.delegate witDidGraspIntent:...] will be called once completed.
 */
- (void)start;

/**
 * Same as the start method but allow a custom object to be passed, which will be passed back as an argument of the
 * [self.delegate witDidGraspIntent:... customData:(id)customData]. This is how you should link a request to a response, if needed.
 */
- (void)start:(id)customData;

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
- (void)interpretString:(NSString *)string customData:(id)customData;

/**
 * Sends an NSString to wit.ai for conversation. To get the next message in the conversation.
 */

- (void) converseWithString:(NSString *)string witSession: (WitSession *) session;


#pragma mark - Context management

/**
 * Sets context from NSDictionary. Merge semantics! 
 * See the context documentation in our doc for for more information:  http://wit.ai/docs/http/20140923#context-link
 */
- (void)setContext:(NSDictionary *)dict;

/**
 * Returns the current context
 */
- (NSDictionary *)getContext;
@end



/**
 * Protocol used by Wit to communicate with the app
 */
@protocol WitDelegate <NSObject>



@optional

/**
 Called when your story triggers a merge and includes any new entities from Wit. Update session.context with any keys required for the next step of the story and return it here, wit-ios-sdk will automatically perform the next converse request for you and call the appropriate delegate method. In many cases may wish to call simply call your didReceiveAction implementation and handle the merge there. Implementing this is required if you are using the converse api.
 
 @param entities Any entities Wit found, as specified in your story.
 @param session The previous WitSession object. Update session.context with any context changes (these will be sent to the Wit server) and optionally store any futher data in session.customData (this will not be sent to the Wit server) and return this WitSession.
 @param confidence The confidence that Wit correctly guessed the users intent, between 0.0 and 1.0
 @return The WitSession to continue. Update the session parameter and return it. Returning nil is considered an error.
 */
- (WitSession *) didReceiveMergeEntities: (NSDictionary *) entities witSession: (WitSession *) session confidence: (double) confidence;


/**
 Called when your story triggers an action and includes any new entities from Wit. Update session.context with any keys required for the next step of the story and return it here, wit-ios-sdk will automatically perform the next converse request for you and call the appropriate delegate method. Implementing this is required if you are using the converse api.

 @param action The action to perform, as specified in your story.
 @param entities Any entities Wit found, as specified in your story.
 @param session The previous WitSession object. Update session.context with any context changes (these will be sent to the Wit server) and optionally store any futher data in session.customData (this will not be sent to the Wit server) and return this WitSession.
 @param confidence The confidence that Wit correctly guessed the users intent, between 0.0 and 1.0
 @return The WitSession to continue. Update the session parameter and return it. Returning nil is considered an error.
 */
- (WitSession *) didReceiveAction: (NSString *) action entities: (NSDictionary *) entities witSession: (WitSession *) session confidence: (double) confidence;

/**
 Called when your story wants your app to display a message. Update session.context with any keys required for the next step of the story and return it here, wit-ios-sdk will automatically perform the next converse request for you and call the appropriate delegate method. wit-ios-sdk will automatically perform the next converse request for you and call the appropriate delegate method. Implementing this is required if you are using the converse api.

 @param message The message to display
 @param session The previous WitSession object. Update session.context with any context changes (these will be sent to the Wit server) and optionally store any futher data in session.customData (this will not be sent to the Wit server) and return this WitSession.
 @param confidence The confidence that Wit correctly guessed the users intent, between 0.0 and 1.0
 @return The WitSession to continue. Update the session parameter and return it. Returning nil is considered an error.
 */
- (WitSession *) didReceiveMessage: (NSString *) message quickReplies: (NSArray *) quickReplies witSession: (WitSession *) session confidence: (double) confidence;

/**
 Called when your story has completed. Implementing this is required if you are using the converse api.

 @param session The WitSession passed in from your last delegate call.
 */
- (void) didStopSession: (WitSession *) session;

/**
 Called when you receive an error from the converse endpoint. Implementing this is required if you are using the converse api.

 @param error The NSError you received.
 @param session The session that received the error.
 */
- (void) didReceiveConverseError: (NSError *) error witSession: (WitSession *) session;

/**
 * Called when a Wit request is completed. This is only called for legacy calls to interpretString (which uses the deprecated get /intent API). If you are using Wit stories (the post /converse API), use didReceiveAction, didReceiveMessage and didReceiveStop instead.
 * param outcomes a NSDictionary of outcomes returned by the Wit API. Outcomes are ordered by confidence, highest first. Each outcome contains (at least) the following keys:
 *       intent, entities[], confidence, _text. For more information please refer to our online documentation: https://wit.ai/docs/http/20141022#get-intent-via-text-link
 *
 * param messageId the message id returned by the api
 * param customData any data attached when starting the request. See [Wit sharedInstance toggleCaptureVoiceIntent:... (id)customData] and [[Wit sharedInstance] start:... (id)customData];
 * param error Nil if no error occurred during processing
 */
- (void)witDidGraspIntent:(NSArray *)outcomes messageId:(NSString *)messageId customData:(id)customData error:(NSError *)error;

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
 Called when Wit stops recording the audio input.
 */
- (void)witDidStopRecording;

/**
 Called when Wit detects speech from the audio input.
 */
- (void)witDidDetectSpeech;

/**
 Called whenever Wit receives an audio chunk. The format of the returned audio is 16-bit PCM, 16 kHz mono.
 */
- (void)witDidGetAudio:(NSData *)chunk;
/**
 Called whenever SFSpeech sends a recognition preview of the recording.
 */
- (void) witDidRecognizePreviewText: (NSString *) previewText final: (BOOL) isFinal;

- (void) witReceivedRecordingError: (NSError *) error;

@end

/***** Constants *****************/
static __unused NSString *const kWitNotificationAudioPowerChanged = @"WITAudioPowerChanged";
static int const kWitAudioSampleRate = 16000;
static int const kWitAudioBitDepth = 16;
