//
//  WITMicButton.m
//  Wit
//
//  Created by Willy Blandin on 16/05/2013.
//  Copyright (c) 2013 Willy Blandin. All rights reserved.
//

#import <math.h>
#import "WitPrivate.h"
#import "WITMicButton.h"
#import "WITState.h"

static NSString* const kMicrophoneImage = @"microphone.png";
static const CGFloat kMicHeight = 75.0f;
static const CGFloat kMicWidth = 50.0f;
static const CGFloat kMicMargin = 40.0f;

@interface WITMicButton ()
@property (strong, atomic) CALayer* micMask;
@end

@implementation WITMicButton {
}

#pragma mark - Styles
- (void)defaultStyles {
    [self setTitle:@"" forState:UIControlStateNormal];
    self.clipsToBounds = NO;

    NSNumber* lineWidth = @(2.0);
    UIColor* strokeColor = [UIColor colorWithRed:0.7f green:0.7f blue:0.7f alpha:0.5f];
    
    // outer circle
    self.outerCircleView = [[WITCircleView alloc] init];
    self.outerCircleView.opaque = NO;
    self.outerCircleView.backgroundColor = nil;
    self.outerCircleView.strokeColor = strokeColor;
    self.outerCircleView.fillColor = [UIColor colorWithRed:0.94f green:0.94f blue:0.94f alpha:0.5f];
    self.outerCircleView.lineWidth = lineWidth;
    
    // inner circle
    self.innerCircleView = [[WITCircleView alloc] init];
    self.innerCircleView.opaque = NO;
    self.innerCircleView.backgroundColor = nil;
    self.innerCircleView.strokeColor = strokeColor;
    self.innerCircleView.lineWidth = lineWidth;
    self.innerCircleView.fillColor = [UIColor whiteColor];;
    
    // microphone mask
    // try to find image in mainBundle (CocoaPods), then frameworkBundle (.framework)
    UIImage* micUIImage = [UIImage imageNamed:kMicrophoneImage];
    if (!micUIImage) {
        NSString* path = [[WITState frameworkBundle] pathForResource:kMicrophoneImage ofType:nil];
        micUIImage = [UIImage imageWithContentsOfFile:path];

        if (!micUIImage) {
            NSLog(@"Wit: couldn't find microphone image: %@", kMicrophoneImage);
        }
    }
    CGImageRef micImage = micUIImage.CGImage;
    self.micMask = [CALayer layer];
    self.micMask.contents = (__bridge id)micImage;
    
    // sublayer for mic background
    self.microphoneLayer = [CALayer layer];
    self.microphoneLayer.backgroundColor = [UIColor colorWithRed:0.50f green:0.50f blue:0.50f alpha:1.00f].CGColor;
    
    // sublayer for volume level
    self.volumeLayer = [CALayer layer];
    self.volumeLayer.backgroundColor = [UIColor colorWithRed:0.50f green:0.50f blue:0.50f alpha:1.00f].CGColor;

    [self addSubview:self.outerCircleView];
    [self insertSubview:self.innerCircleView aboveSubview:self.outerCircleView];
    [self.layer addSublayer:self.microphoneLayer];
    [self.microphoneLayer addSublayer:self.volumeLayer];
}

- (void)recomputePositions {
    CGFloat x = self.bounds.origin.x;
    CGFloat y = self.bounds.origin.y;
    CGFloat w = self.bounds.size.width;
    CGFloat h = self.bounds.size.height;

    CGPoint center = CGPointMake(w/2, h/2);
    
    // outer circle, should be able to expand on the whole screen
    // beware: CircleLayer being drawn at the center of the view, we have to expand out of screen
    // use of pen and paper advised.
    CGPoint witButtonCenterAbsolute = [self convertPoint:center toView:nil];
    CGFloat screenW = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenH = [UIScreen mainScreen].bounds.size.height;
    
    // vertical
    CGFloat topVerticalOffset = witButtonCenterAbsolute.y;
    CGFloat bottomOffset = screenH - witButtonCenterAbsolute.y;
    CGFloat largestVerticalOffset = fmaxf(topVerticalOffset, bottomOffset);
    CGFloat outerH = largestVerticalOffset*2;
    CGFloat outerY = witButtonCenterAbsolute.y - largestVerticalOffset;

    // horizontal
    CGFloat leftHorizontalOffset = witButtonCenterAbsolute.x;
    CGFloat rightHorizontalOffset = screenW - witButtonCenterAbsolute.x;
    CGFloat largestHorizontalOffset = fmaxf(leftHorizontalOffset, rightHorizontalOffset);
    CGFloat outerW =  largestHorizontalOffset * 2;
    CGFloat outerX = witButtonCenterAbsolute.x - largestHorizontalOffset;

    CGRect outerFrameAbsolute = CGRectMake(outerX, outerY, outerW, outerH);
    self.outerCircleView.frame = [self convertRect:outerFrameAbsolute fromView:nil];
    
    CGFloat xMid = x+w/2;
    CGFloat yMid = y+h/2;
    CGFloat circleRadius = h/2;
    CGFloat actualMicWidth;
    CGFloat actualMicHeight;
    
    // fit microphone
    if (w/h > kMicWidth/kMicHeight) {
        actualMicHeight = h - kMicMargin;
        actualMicWidth = actualMicHeight * (kMicWidth/kMicHeight);
    } else {
        actualMicWidth = w - kMicMargin;
        actualMicHeight = actualMicWidth * (kMicHeight/kMicWidth);
    }
    
    // inner circle
    self.innerCircleView.frame = CGRectMake(center.x - circleRadius,
                                            center.y - circleRadius,
                                            circleRadius*2,
                                            circleRadius*2);
    self.innerCircleView.radius = @(circleRadius);

    // mic
    self.micMask.frame = CGRectMake(0, 0, actualMicWidth, actualMicHeight);
    self.microphoneLayer.mask = self.micMask;
    self.microphoneLayer.frame = CGRectMake(xMid - actualMicWidth/2, yMid - actualMicHeight/2, actualMicWidth, actualMicHeight);
    self.volumeLayer.frame = CGRectMake(0, 0, actualMicWidth, actualMicHeight);
}

#pragma mark - Animations
- (void)twoPulses {
    CGRect frame = self.outerCircleView.frame;
    CGRect pulseBounds = CGRectMake(0, 0, frame.size.width, frame.size.height);
    UIColor* pulseColor = [UIColor colorWithRed:0.92f green:0.91f blue:0.92f alpha:0.2f];

    WITCircleLayer* circle1 = [[WITCircleLayer alloc] init];
    circle1.frame = pulseBounds;
    circle1.fillColor = nil;
    circle1.strokeColor = pulseColor;
    circle1.lineWidth = @3.0;

    WITCircleLayer* circle2 = [[WITCircleLayer alloc] init];
    circle2.frame = pulseBounds;
    circle2.fillColor = nil;
    circle2.strokeColor = pulseColor;
    circle2.lineWidth = @3.0;

    [self.outerCircleView.circleLayer addSublayer:circle1];
    [self.outerCircleView.circleLayer addSublayer:circle2];

    NSNumber* newRadius = @(self.innerCircleView.radius.floatValue * 2.75f);
    float growDuration = 1.0f;
    float pulseInterval = 0.25f;

    CABasicAnimation* growAnim = [CABasicAnimation animation];
    growAnim.duration = growDuration;
    growAnim.keyPath = @"radius";
    growAnim.fromValue = self.innerCircleView.radius;
    growAnim.toValue = newRadius;
    growAnim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];

    CABasicAnimation* fadeAnim = [CABasicAnimation animation];
    fadeAnim.keyPath = @"opacity";
    fadeAnim.fromValue = @1.0;
    fadeAnim.toValue = @0.0;
    fadeAnim.duration = growDuration/2;

    void(^doPulse)(WITCircleLayer*) = ^(WITCircleLayer* circle) {
        circle.radius = newRadius;
        [circle addAnimation:growAnim forKey:@"grow"];

        // fade out towards the end of growing anim
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(growDuration/2 * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            circle.opacity = 0.0f;
            [circle addAnimation:fadeAnim forKey:@"fade"];
        });
    };

    doPulse(circle1);

    // send second pulse after a few millis
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(pulseInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void){
        doPulse(circle2);
    });

    // clean subviews after completion
    dispatch_time_t popTime2 = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(growDuration*3 * NSEC_PER_SEC));
    dispatch_after(popTime2, dispatch_get_main_queue(), ^(void){
        [circle1 removeFromSuperlayer];
        [circle2 removeFromSuperlayer];
    });
}

#pragma mark - UIView
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if ([self pointInside:point withEvent:event]) {
        return self;
    }

    return nil;
}

- (void) didMoveToSuperview {
    [super didMoveToSuperview];
    [self recomputePositions];
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if (object == self && [keyPath isEqualToString:@"frame"]) {
        [self recomputePositions];
        return;
    }

    float power = [change[@"new"] floatValue];
    [self newAudioLevel:power];
}

#pragma mark - UIButton target
- (void)buttonPressed:(id)sender {
    [[Wit sharedInstance] toggleCaptureVoiceIntent:self];
}

#pragma mark - NSNoticationCenter
- (void)audiostart:(NSNotification*)n {
    // send 2 pulses and change color
    dispatch_async(dispatch_get_main_queue(), ^{
        [self twoPulses];
    });
}

- (void)audioend:(NSNotification*)n {
}

#pragma mark - Audio Levels
- (void)newAudioLevel:(float)power {
    CGFloat coeff = fmax(0, fmin(1, (power+51) / 30));
    NSNumber* newRadius = @((1+coeff*1.5) * self.innerCircleView.radius.floatValue);
    self.outerCircleView.radius = newRadius;
}

#pragma mark - Lifecycle
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
        self.frame = frame;
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    [self addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [[WITState sharedInstance].recorder addObserver:self forKeyPath:@"power" options:NSKeyValueObservingOptionNew
                                            context:nil];
    
    [self addObserver:self forKeyPath:@"frame" options:0 context:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audiostart:)
                                                 name:kWitNotificationAudioStart object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioend:)
                                                 name:kWitNotificationAudioEnd object:nil];
    
    // retinarize
    if ([self respondsToSelector:@selector(setContentScaleFactor:)]) {
        self.contentScaleFactor = [[UIScreen mainScreen] scale];
    }
    
    // apply style
    [self defaultStyles];
}

- (void)dealloc {
    [[WITState sharedInstance].recorder removeObserver:self forKeyPath:@"power"];
    [self removeObserver:self forKeyPath:@"frame"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self removeTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
}
@end
