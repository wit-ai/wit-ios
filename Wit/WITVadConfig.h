//
//  WITVadConfig.h
//  Wit
//
//  Created by Aric Lasry on 10/13/14.
//  Copyright (c) 2014 Willy Blandin. All rights reserved.
//

#ifndef Wit_WITVadConfig_h
#define Wit_WITVadConfig_h

/* Values for WITVadConfig */
typedef NS_ENUM(NSInteger, WITVadConfig) {
    WITVadConfigDisabled = 0,    // Voice Actvity Detection disabled
    WITVadConfigDetectSpeechStop = 1, // Only detect when speech stops
    WITVadConfigFull = 2 // Detect speech start and stop
} NS_ENUM_AVAILABLE_IOS(6_0);

typedef NS_ENUM(NSInteger, WITVadTuning) {
    WITVadCloseTuning = 0,    // Higher voice discrimination, like from a personal mic or phone
    WITVadAmbientTuning = 1   // Higher voice sensitivity, like for a fixed mic
} NS_ENUM_AVAILABLE_IOS(6_0);

#endif
