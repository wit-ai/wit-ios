//
//  WITState.m
//  Wit
//
//  Created by Willy Blandin on 12. 10. 29..
//  Copyright (c) 2012년 Willy Blandin. All rights reserved.
//

#import "WITState.h"

@implementation WITState

#pragma mark - Util
+(NSString*)UUID {
    static NSString* uuidString;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        CFUUIDRef newUniqueId = CFUUIDCreate(kCFAllocatorDefault);
        uuidString = (__bridge_transfer NSString*)CFUUIDCreateString(kCFAllocatorDefault, newUniqueId);
        CFRelease(newUniqueId);
    });
    
    return uuidString;
}

// Load the framework bundle.
+ (NSBundle *)frameworkBundle {
    static NSBundle* frameworkBundle = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        NSString* mainBundlePath = [[NSBundle mainBundle] resourcePath];
        NSString* frameworkBundlePath = [mainBundlePath stringByAppendingPathComponent:@"Wit.bundle"];
        frameworkBundle = [NSBundle bundleWithPath:frameworkBundlePath];
    });
    return frameworkBundle;
}

#pragma mark - Defaults
- (void)readPlist {
    self.accessToken = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"WitAccessToken"];
    NSString *accessToken = [[NSUserDefaults standardUserDefaults] stringForKey:@"accessToken"];
    if (accessToken && [accessToken length] > 0) self.accessToken = accessToken;
}

#pragma mark - Lifecycle
+(WITState*)sharedInstance {
    static WITState* instance;
    static dispatch_once_t once;

    dispatch_once(&once, ^{
        instance = [[WITState alloc] init];
    });
    
    return instance;
}

-(id)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.resourcePath = [[self.class frameworkBundle] resourcePath];
    [self readPlist];
    self.context = [[NSMutableDictionary alloc] init];
    
    return self;
}
@end
