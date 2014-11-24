//
//  WITVadTracker.h
//  Wit
//
//  Created by Aric Lasry on 8/14/14.
//  Copyright (c) 2014 Willy Blandin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WITVadTracker : NSObject <NSURLConnectionDelegate> 

-(void)track:(NSString *)status withMessageId:(NSString *)messageId withVadSensitivity:(int)vadSensitivity withToken:(NSString *)token;



@end
