//
//  Uploader.h
//  Wit
//
//  Created by Willy Blandin on 12. 9. 3..
//  Copyright (c) 2012년 Willy Blandin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>

/**
* Uploader class that will upload the wav file and return back the response as NSString to the delegate
*/
@interface WITUploader : AFHTTPClient

+(WITUploader*)sharedInstance;
-(BOOL)uploadSampleWithURL:(NSURL*)url;
@end
