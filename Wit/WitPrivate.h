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

static __unused NSString* const kWitNotificationAudioStart = @"WITRecordingStarted";
static __unused NSString* const kWitNotificationAudioEnd = @"WITRecordingStopped";

static __unused NSString* const kWitKeyResponse = @"response";
static __unused NSString* const kWitKeyError = @"error";
static __unused NSString* const kWitKeyOutcome = @"outcome";
static __unused NSString* const kWitKeyProgress = @"progress"; // file upload, etc.
static __unused NSString* const kWitKeyURL = @"url"; // record completed
static __unused NSString* const kWitKeyBody = @"msg_body"; // response's msg body

#if WIT_DEBUG
#define debug(x, ...) NSLog(x, ##__VA_ARGS__);
#else
#define WIT_DEBUG 0
#define debug(x, ...) ;
#endif

#endif
