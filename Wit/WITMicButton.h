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
@property (strong, atomic) CALayer* volumeLayer;
@property (strong, atomic) CALayer* microphoneLayer;
@property (strong, atomic) WITCircleView* outerCircleView;
@property (strong, atomic) WITCircleView* innerCircleView;

- (void)newAudioLevel:(NSNotification*)n;

@end