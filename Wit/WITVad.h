//
//  WITVad.h
//  Wit
//
//  Created by Aric Lasry on 8/6/14.
//  Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import <Accelerate/Accelerate.h>
#import "WITCvad.h"

@protocol WITVadDelegate;

@interface WITVad : NSObject

@property (nonatomic, weak) id<WITVadDelegate> delegate;

@property (nonatomic, assign) BOOL stoppedUsingVad;


- (void)gotAudioSamples:(NSData *)samples;

@end


@protocol WITVadDelegate <NSObject>

-(void) vadStartedTalking;
-(void) vadStoppedTalking;

@end
