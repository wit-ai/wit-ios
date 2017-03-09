# Wit-iOS-sdk

*This SDK is community-maintained. Please use the HTTP API or the Node.js/Python/Ruby SDKs for non-experimental needs (https://wit.ai/docs). We gladly accept pull requests*

The wit.ai iOS SDK is the easiest way to integrate [wit.ai](https://wit.ai) features into your iOS application.

The SDK can capture intents and entities from:

- the microphone of the device (legacy GET /message API only)
- text


## Link to the SDK


#### Using CocoaPods

Add the following dependency to your Podfile:
```ruby
pod 'Wit', '~> 4.2.0'
```

And then run the following command in your project home directory:
```bash
pod install
```



## API

##### @property and static methods
```objc
Delegate to send feedback for the application
@property(nonatomic, strong) id <WitDelegate> delegate;
```

```objc
Access token used to contact Wit.ai
@property (strong) NSString* accessToken;
```

```objc
Configure the voice activity detection algorithm:
- WITVadConfigDisabled
- WITVadConfigDetectSpeechStop (default)
- WITVadConfigFull
@property WITVadConfig detectSpeechStop;
```

```objc
Set the maximum length of time recorded by the VAD in ms
- Set to -1 for no timeout
- Defaults to 7000
@property int vadTimeout;
```

```objc
Set VAD sensitivity (0-100)
- Lower values are for strong voice signals like for a cellphone or personal mic
- Higher values are for use with a fixed-position mic or any application with voice burried in ambient noise
- Defaults to 0
@property int VadSensitivity;
```

```objc
Singleton instance accessor.
+ (Wit*)sharedInstance;
```

##### Understanding text
```objc
InterpretString (deprecated)
Sends an NSString to wit.ai for interpretation. Same as sending a voice input, but with text. This uses the legacy GET /message API. If you are using stories this is NOT for you.
- (void) interpretString: (NSString *) string customData:(id)customData;
```

```objc
ConverseString
Sends an NSString to wit.ai for interpretation. Will call delegate methods for every step of your story.
- (void) converseWithString:(NSString *)string witSession: (WitSession *) session;
```



##### Recording audio
**The audio part of the API currently only supports the legacy GET /message API. If you are using stories (POST /converse) then this will not work, use ConverseString instead.

```objc
Starts a new recording session. [self.delegate witDidGraspIntent:…] will be called once completed.
- (void)start;
```

```objc
Same as the start method but allow a custom object to be passed, which will be passed back as an argument of the
[self.delegate witDidGraspIntent:… customData:(id)customData]. This is how you should link a request to a response, if needed.
- (void)start: (id)customData;
```

```objc
Stops the current recording if any, which will lead to [self.delegate witDidGraspIntent:…] call.
- (void)stop;
```

```objc
Start / stop the audio processing. Once the API response is received, [self.delegate witDidGraspIntent:…] method will be called.
- (void)toggleCaptureVoiceIntent;
```

```objc
Same as toggleCaptureVoiceIntent, allowing you to pass a customData object to the [self start:(id)customData] function.
- (void)toggleCaptureVoiceIntent:(id) customData;
```

```objc
YES if Wit is recording.
- (BOOL)isRecording;
```

##### Context
```objc
Sets context from NSDictionary. Merge semantics!
See the context documentation in our doc for for more information: Context documentation
- (void)setContext:(NSDictionary*)dict;
Returns the current context.
- (NSDictionary*)getContext;
```

##### Implementing the WitDelegate protocol

```objc
@protocol WitDelegate <NSObject>



@optional

/**
 Called when your story triggers an action and includes any new entities from Wit. Update session.context with any keys required for the next step of the story and return it here, wit-ios-sdk will automatically perform the next converse request for you and call the appropriate delegate method.

 @param action The action to perform, as specified in your story.
 @param entities Any entities Wit found, as specified in your story.
 @param session The previous WitSession object. Update session.context with any context changes (these will be sent to the Wit server) and optionally store any futher data in session.customData (this will not be sent to the Wit server) and return this WitSession.
 @param confidence The confidence that Wit correctly guessed the users intent, between 0.0 and 1.0
 @return The WitSession to continue. Update the session parameter and return it. Returning nil is considered an error.
 */
- (WitSession *) didReceiveAction: (NSString *) action entities: (NSDictionary *) entities witSession: (WitSession *) session confidence: (double) confidence;

/**
 Called when your story wants your app to display a message. Update session.context with any keys required for the next step of the story and return it here, wit-ios-sdk will automatically perform the next converse request for you and call the appropriate delegate method. wit-ios-sdk will automatically perform the next converse request for you and call the appropriate delegate method.

 @param message The message to display
 @param session The previous WitSession object. Update session.context with any context changes (these will be sent to the Wit server) and optionally store any futher data in session.customData (this will not be sent to the Wit server) and return this WitSession.
 @param confidence The confidence that Wit correctly guessed the users intent, between 0.0 and 1.0
 @return The WitSession to continue. Update the session parameter and return it. Returning nil is considered an error.
 */
- (WitSession *) didReceiveMessage: (NSString *) message quickReplies: (NSArray *) quickReplies witSession: (WitSession *) session confidence: (double) confidence;

/**
 Called when your story has completed.

 @param session The WitSession passed in from your last delegate call.
 */
- (void) didStopSession: (WitSession *) session;

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
- (void) witDidRecognizePreviewText: (NSString *) previewText;

- (void) witReceivedRecordingError: (NSError *) error;

@end
```

##### Notifications
```objc
// A NSNotification is sent on the default center when the power of the audio signal changes
NSNumber *newPower = [[NSNumber alloc] initWithFloat:power];
[[NSNotificationCenter defaultCenter] postNotificationName:kWitNotificationAudioPowerChanged object:newPower];        
```

##### Constants
```objc
static NSString* const kWitNotificationAudioPowerChanged = @"WITAudioPowerChanged";
static int const kWitAudioSampleRate = 16000;
static int const kWitAudioBitDepth = 16;
```
