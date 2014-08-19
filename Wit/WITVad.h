//
//  WITVad.h
//  Wit
//
//  Created by Aric Lasry on 8/6/14.
//  Copyright (c) 2014 Willy Blandin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WITVadSimple.h"

@interface WITVad : NSObject

@property BOOL stoppedUsingVad;
-(void) gotAudioSamples:(NSData *)samples;

@end
