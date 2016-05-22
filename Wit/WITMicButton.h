//
//  WITMicButton.h
//  Wit
//
//  Created by Willy Blandin on 16/05/2013.
//  Copyright (c) 2013 Willy Blandin. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import "Wit.h"
#import "WITCircleLayer.h"
#import "WITCircleView.h"
#import "WITRecorder.h"

@interface WITMicButton : UIButton
@property (nonatomic, strong) CALayer* volumeLayer;
@property (nonatomic, strong) CALayer* microphoneLayer;
@property (nonatomic, strong) WITCircleView* outerCircleView;
@property (nonatomic, strong) WITCircleView* innerCircleView;
@property (nonatomic, strong) CALayer* micMask;

- (void)newAudioLevel:(NSNotification*)n;

@end