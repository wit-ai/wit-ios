//
//  WitPrivate.h
//  Wit
//
//  Created by Willy Blandin on 05/11/2013.
//  Copyright (c) 2013 Willy Blandin. All rights reserved.
//

#ifndef Wit_WitPrivate_h
#define Wit_WitPrivate_h

#import <AFNetworking/AFNetworking.h>
#import "Wit.h"

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

#endif
