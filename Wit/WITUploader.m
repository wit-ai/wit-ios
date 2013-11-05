//
//  Uploader.m
//  Wit
//
//  Created by Willy Blandin on 12. 9. 3..
//  Copyright (c) 2012년 Willy Blandin. All rights reserved.
//

#import "WitPrivate.h"
#import "WITUploader.h"
#import "WITState.h"

static NSString* const kWitUploaderURL = @"https://api.wit.ai/";
static NSString* const kFormName = @"file";
static NSString* const kFileName = @"sample.wav";

@implementation WITUploader
+(WITUploader*)sharedInstance {
    static WITUploader *instance;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        instance = [[WITUploader alloc] initWithBaseURL:[NSURL URLWithString:kWitUploaderURL]];
    });

    return instance;
}

-(BOOL)uploadSampleWithURL:(NSURL *)url {
    WITState* state = [WITState sharedInstance];
    NSString* path = [self.baseURL.absoluteString stringByAppendingString:@"message"];
    NSDictionary* params = @{@"convid": [WITState UUID]};

    NSMutableURLRequest *req =
    [self multipartFormRequestWithMethod:@"POST"
                                    path:path
                              parameters:params
               constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                   NSData* data = [NSData dataWithContentsOfURL:url];
                   debug(@"Uploader, %@ (%d bytes) to %@ (access token: %@, instance id: %@)",
                         [url lastPathComponent], [data length], path, state.accessToken, state.instanceId);
                   [formData appendPartWithFileData:data
                                               name:kFormName
                                           fileName:kFileName
                                           mimeType:@"audio/wav"];
               }
     ];

    NSString *authValue = [NSString stringWithFormat:@"Bearer %@", state.accessToken];
    [req setValue:authValue forHTTPHeaderField:@"Authorization"];
    [req setValue:state.instanceId forHTTPHeaderField:@"X-Wit-Instance"];

    AFHTTPRequestOperation *op = [[AFHTTPRequestOperation alloc] initWithRequest:req];

    [op setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        debug(@"File uploaded successfully: %@", [operation responseString]);
        
        NSError *parsingError;
        NSString* responseString = [operation responseString];
        NSDictionary* response = [NSJSONSerialization JSONObjectWithData:[responseString dataUsingEncoding:NSUTF8StringEncoding]
                                                            options:0 error:&parsingError];
        
        if (parsingError) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kWitNotificationResponseReceived object:nil
                                                              userInfo:@{kWitKeyError: parsingError}];
            return;
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kWitNotificationResponseReceived object:nil
                                                          userInfo:@{kWitKeyResponse: response}];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        debug(@"Error during file upload: %@", error);
        [[NSNotificationCenter defaultCenter] postNotificationName:kWitNotificationResponseReceived object:nil
                                                          userInfo:@{kWitKeyError: error}];
    }];

    [op setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        double progress = (double)totalBytesWritten / (double)totalBytesExpectedToWrite;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kWitNotificationUploadProgress
                                                            object:nil
                                                          userInfo:@{kWitKeyProgress: @(progress)}];
    }];
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperation:op];

    return YES;
}
@end
