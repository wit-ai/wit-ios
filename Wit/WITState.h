//
//  WITState.h
//  Wit
//
//  Created by Willy Blandin on 12. 10. 29..
//  Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
//

#import "WITUploader.h"
#import "WITRecorder.h"

@interface WITState : NSObject
@property (nonatomic, strong) WITRecorder* recorder;
@property (nonatomic, strong) WITUploader* uploader;
@property (nonatomic, copy) NSString *accessToken;
@property (nonatomic, strong) NSDictionary *context;

+ (WITState *)sharedInstance;
+ (NSString *)UUID;
@end
