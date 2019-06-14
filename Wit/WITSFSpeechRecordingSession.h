//
//  WITSFSpeechRecordingSession.h
//  Wit
//
//  Created by patrick on 30/08/2016.
//  Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
//

#import <Wit/Wit.h>
#import "WITRecordingSession.h"

@interface WITSFSpeechRecordingSession : WITRecordingSession
-(instancetype)initWithWitContext:(NSDictionary *)upContext locale: (NSString *) locale vadEnabled:(WITVadConfig)vadEnabled withWitToken:(NSString *)witToken customData: (id) customData withDelegate:(id<WITRecordingSessionDelegate>)delegate;
@end
