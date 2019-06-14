//
//  WITMicButton.h
//  Wit
//
//  Created by Willy Blandin on 16/05/2013.
//  Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
//

#import <UIKit/UIKit.h>
//#import "Wit.h"
#import "WITCircleLayer.h"
#import "WITCircleView.h"
#import "WITRecorder.h"
#import "WitSession.h"

@interface WITMicButton : UIButton
@property (nonatomic, strong) CALayer* volumeLayer;
@property (nonatomic, strong) CALayer* microphoneLayer;
@property (nonatomic, strong) WITCircleView* outerCircleView;
@property (nonatomic, strong) WITCircleView* innerCircleView;
@property (nonatomic, strong) WitSession *session;
/**
 If you have a override-microphone.png in your mainbundle then that image will be used for the mic button, else the default image from the framework will be used.
 */
@property (nonatomic, strong) CALayer* micMask;

- (void)newAudioLevel:(NSNotification*)n;

@end
