//
//  WITSessionToggle.h
//  Wit
//
//  Created by Aric Lasry on 8/14/14.
//  Copyright (c) 2014 Willy Blandin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WITRecorder.h"

@protocol WITSessionToggle <NSObject>

-(void)sessionDidStart:(WITRecorder *)recorder;
-(void)sessionDidEnd:(WITRecorder *)recorder;

@end
