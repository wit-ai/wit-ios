//
//  WitPrivate.h
//  Wit
//
//  Created by Willy Blandin on 05/11/2013.
//  Copyright (c) 2013 Willy Blandin. All rights reserved.
//

#ifndef Wit_WitPrivate_h
#define Wit_WitPrivate_h

#import "Wit.h"

static __unused NSString* const kWitAPIUrl = @"https://api.wit.ai";
static __unused NSString* const kWitAPIVersion = @"20141022";

static __unused NSString* const kWitNotificationAudioPowerChanged = @"WITAudioPowerChanged";

static __unused NSString* const kWitKeyResponse = @"response";
static __unused NSString* const kWitKeyError = @"error";
static __unused NSString* const kWitKeyOutcome = @"outcomes";
static __unused NSString* const kWitKeyProgress = @"progress"; // file upload, etc.
static __unused NSString* const kWitKeyURL = @"url"; // record completed
static __unused NSString* const kWitKeyBody = @"msg_body"; // response's msg body
static __unused NSString* const kWitKeyMsgId = @"msg_id"; // response's msg id
static __unused NSString* const kWitKeyConfidence = @"confidence";


#if WIT_DEBUG
#define debug(x, ...) NSLog(x, ##__VA_ARGS__);
#else
#define WIT_DEBUG 0
#define debug(x, ...) ;
#endif

#endif
