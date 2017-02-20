//
//  WitSession.h
//  Wit
//
//  Created by patrick on 20/02/2017.
//

#import <Foundation/Foundation.h>

/**
 A class which encapsulates the current state of your converstation. It is passed through all your delegate calls so you can update the context and store any custom data you may need.
 */
@interface WitSession : NSObject

/**
 A session ID that you generated and passed to Wit to identify this session. It is up to you to decide when a user has started a completely new conversation and all session information is to be discared.
 */
@property (readonly, strong, nonatomic) NSString *sessionID;
/**
 Wit uses the Context object to predict the next step of your Bot. The context is updated on your side only. Wit never updates the context. Client-side actions are responsible for managing the context by adding/removing keys. Important:
 As only the keys matter for now, don’t store the full state of your app in the Context object you pass to Wit. Adding too much information tend to confuse your bot so please only pass the keys that are important for the prediction (i.e. used in your Stories) or for the Bot answers. In short: keep the context as small as possible.
 Also don’t use the following reserved fields: user, state, entities, reference_time and timezone.
 */
@property (strong, nonatomic) NSDictionary *context;
/**
 Use this property to store local state information that you don't need to pass to the server.
 */
@property id customData;

/**
 Set this to YES if you wish to cancel further processing of this converse. Note that WitDelegate.didStopSession: will not be called as the server never stopped the session.
 */
@property Boolean isCancelled;


/**
 Inits a new WitSession with a sessionID that the client generates.

 @param sessionID A session ID that you generate to identify the session with WIT. A user may have multiple sessions as each new converstation thread should use a new session id to help Wit with recognizing completely different intents.
 @return A WitSession to be used with converseString
 */
- (instancetype)initWithSessionID: (NSString *) sessionID;
@end
