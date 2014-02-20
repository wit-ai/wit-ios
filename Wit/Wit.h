//
//  Created by Willy Blandin on 12. 8. 16..
//  Copyright (c) 2012년 Willy Blandin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "WITMicButton.h"

@protocol WitDelegate;

@interface Wit : NSObject
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
 Singleton instance accessor
 */
+ (Wit*)sharedInstance;

/**
 Pops a new view and records user voice. The sender to which the modal will be presented (Can be null if no UI wanted)
 */
- (void)toggleCaptureVoiceIntent:(id)sender;

/**
 Starts a new recording
 */
- (void)start;

/**
 Stops the current recording if any
 */
- (void)stop;

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
 Called when Wit start recording the audio entry
 */
- (void)witDidStartRecording;

/**
 Called when Wit stop recording the audio entry
 */
- (void)witDidStopRecording;

@end