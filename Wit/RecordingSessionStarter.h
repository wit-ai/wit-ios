//
//  RecordingSessionStarter.h
//  Wit
//
//  Created by Aric Lasry on 8/14/14.
//  Copyright (c) 2014 Willy Blandin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WITRecorder.h"

@protocol RecordingSessionStarter <NSObject>

-(void)sessionDidStart:(WITRecorder *)recorder;
-(void)sessionEnded:(WITRecorder *)recorder;

@end
