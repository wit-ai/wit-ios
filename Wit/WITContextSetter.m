//
//  WITContextSetter.m
//  Wit
//
//  Created by Aric Lasry on 10/29/14.
//  Copyright (c) 2014 Willy Blandin. All rights reserved.
//

#import "WITContextSetter.h"
#import "WitPrivate.h"
#import "util.h"
#import <CoreLocation/CoreLocation.h>

@implementation WITContextSetter {
    CLLocationManager *locationManager;
}


- (void)ensureReferenceTime:(NSMutableDictionary *)context {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    [dateFormatter setLocale:enUSPOSIXLocale];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];
    
    NSDate *now = [NSDate date];
    NSString *iso8601String = [dateFormatter stringFromDate:now];
    [context setObject:iso8601String forKey:@"reference_time"];
    
}

- (NSDictionary *)contextFillup:(NSDictionary *)context {
    NSMutableDictionary *mutableContext = [context mutableCopy];
    [self ensureReferenceTime:mutableContext];
    return [mutableContext copy];
}

+ (NSString *)jsonEncode:(NSDictionary *)context {
    NSError* serializationError;
    NSData *data = [NSJSONSerialization dataWithJSONObject:context
                                                   options:0
                                                     error:&serializationError];
    NSString *encoded = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    encoded = urlencodeString(encoded);
    
    return encoded;
}

@end
