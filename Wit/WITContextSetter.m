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



-(void)ensureLocation:(NSMutableDictionary *)context {
    if ([self locationAccess] == NO) {
        return ;
    }
    CLLocationDegrees latitude = locationManager.location.coordinate.latitude;
    CLLocationDegrees longitude = locationManager.location.coordinate.longitude;
    NSNumber *oLatitude = [[NSNumber alloc] initWithDouble:latitude];
    NSNumber *oLongitude = [[NSNumber alloc] initWithDouble:longitude];
    NSDictionary *locationData = [[NSDictionary alloc] initWithObjectsAndKeys:oLatitude, @"latitude", oLongitude, @"longitude", nil];
    [context setObject:locationData forKey:@"location"];
}

-(void)ensureReferenceTime:(NSMutableDictionary *)context {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    [dateFormatter setLocale:enUSPOSIXLocale];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];
    
    NSDate *now = [NSDate date];
    NSString *iso8601String = [dateFormatter stringFromDate:now];
    [context setObject:iso8601String forKey:@"reference_time"];
    
}

-(BOOL)locationAccess {
    if (locationManager == nil) {
        locationManager = [[CLLocationManager alloc] init];
    }
    
    
    CLAuthorizationStatus currentStatus = [CLLocationManager authorizationStatus];
    if (currentStatus == kCLAuthorizationStatusDenied
        || currentStatus == kCLAuthorizationStatusRestricted) {
        return NO;
    }
    if (currentStatus == kCLAuthorizationStatusNotDetermined) {
        [locationManager requestWhenInUseAuthorization];
        currentStatus = [CLLocationManager authorizationStatus];
    }
    if (currentStatus == kCLAuthorizationStatusDenied
        || currentStatus == kCLAuthorizationStatusRestricted) {
        return NO;
    }
    NSLog(@"Location access status: %d", currentStatus);
    [locationManager startMonitoringSignificantLocationChanges];
    
    return YES;
}

-(void)contextFillup:(NSMutableDictionary *)context {
    [self ensureLocation:context];
    [self ensureReferenceTime:context];
}

-(id)init {
    self = [super init];
    [self locationAccess];
    
    return self;
}

+(NSString *)jsonEncode: (NSMutableDictionary *)context {
    NSError* serializationError;
    NSData *data = [NSJSONSerialization dataWithJSONObject:context
                                                   options:0
                                                     error:&serializationError];
    NSString *encoded = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    encoded = urlencodeString(encoded);
    
    return encoded;
}

@end
