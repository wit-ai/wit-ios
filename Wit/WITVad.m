//
//  WITVad.m
//  Wit
//
//  Created by Aric Lasry on 8/6/14.
//  Copyright (c) 2014 Willy Blandin. All rights reserved.
//

#import "WITVad.h"
#import "Wit.h"

@implementation WITVad {
    wvs_state *vad_state;
}

-(void) gotAudioSamples:(NSData *)samples {
    UInt32 size = [samples length];
    short *bytes = (short*)[samples bytes];
    if (wvs_still_talking(self->vad_state, bytes, size / 2) == 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[Wit sharedInstance] stop];
        });
    }
}

-(id) init {
    NSLog(@"WITVad init");
    self = [super init];
    self->vad_state = wvs_init(8.0, 16000);
    
    return self;
}

-(void) dealloc {
    NSLog(@"WITVad clean");
    wvs_clean(self->vad_state);
}

@end
