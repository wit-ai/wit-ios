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

static NSString* const kWitSpeechURL = @"https://api.wit.ai/speech";

@implementation WITUploader {
    NSOutputStream *outStream;
    NSInputStream *inStream;
    NSDate *start; // used to time requests

    // queue used to send audio chunks in HTTP body
    // will be suspended / resumed according to stream availability
    NSOperationQueue* q;
}

#pragma mark - Stream networking
-(BOOL)startRequest {
    NSString* token = [[WITState sharedInstance] accessToken];

    // CF wiring
    CFWriteStreamRef writeStream;
    CFReadStreamRef readStream;
    readStream = NULL;
    writeStream = NULL;
    CFStreamCreateBoundPair(NULL, &readStream, &writeStream, 65536);

    // convert to NSStream and set as property
    inStream = CFBridgingRelease(readStream);
    outStream = CFBridgingRelease(writeStream);

    [outStream setDelegate:self];
    [outStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [outStream open];

    // build HTTP request
    NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:kWitSpeechURL]];
    [req setHTTPMethod:@"POST"];
    [req setCachePolicy:NSURLCacheStorageNotAllowed];
    [req setTimeoutInterval:15.0];
    [req setHTTPBodyStream:inStream];
    [req setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
    [req setValue:@"wit/ios" forHTTPHeaderField:@"Content-type"];
    [req setValue:@"chunked" forHTTPHeaderField:@"Transfer-encoding"];
    [req setValue:@"application/json" forHTTPHeaderField:@"Accept"];

    // send HTTP request
    [NSURLConnection sendAsynchronousRequest:req
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               if (WIT_DEBUG) {
                                   NSTimeInterval t = [[NSDate date] timeIntervalSinceDate:start];
                                   NSLog(@"Wit response (%f s) %@",
                                         t, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
                               }

                               if (connectionError) {
                                   [self.delegate gotResponse:nil error:connectionError];
                                   return;
                               }

                               NSError *serializationError;
                               NSDictionary *object = [NSJSONSerialization JSONObjectWithData:data
                                                                                      options:0
                                                                                        error:&serializationError];
                               if (serializationError) {
                                   [self.delegate gotResponse:nil error:serializationError];
                                   return;
                               }

                               if (object[@"error"]) {
                                   NSDictionary *infos = @{NSLocalizedDescriptionKey: object[@"error"],
                                                           kWitKeyError: object[@"code"]};
                                   [self.delegate gotResponse:nil
                                                        error:[NSError errorWithDomain:@"WitProcessing"
                                                                                            code:1
                                                                                        userInfo:infos]];
                                   return;
                               }

                               [self.delegate gotResponse:object error:nil];
                           }];

    return YES;
}
-(void)sendChunk:(NSData*)chunk {
    [q addOperationWithBlock:^{
        if (outStream) {
            debug(@"Uploading %u bytes", (unsigned int)[chunk length]);
            [outStream write:[chunk bytes] maxLength:[chunk length]];
            [q setSuspended:YES];
        }
    }];
}
-(void)endRequest {
    debug(@"Ending request");

    if (outStream) {
        start = [NSDate date];
        [outStream close];
        [outStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        outStream = nil;
        inStream = nil;
    }

    [q cancelAllOperations];
    [q setSuspended:NO];
}

#pragma mark - NSStreamDelegate
-(void)stream:(NSStream *)s handleEvent:(NSStreamEvent)eventCode {
    switch (eventCode) {
        case NSStreamEventErrorOccurred:
            debug(@"Stream error occured");
            break;
        case NSStreamEventOpenCompleted:
            debug(@"Stream open completed");
            break;
        case NSStreamEventHasBytesAvailable:
            debug(@"Stream has bytes available");
            break;
        case NSStreamEventHasSpaceAvailable:
            if (s == outStream) {
//                debug(@"outStream has space, resuming dispatch");
                if ([q isSuspended]) {
                    [q setSuspended:NO];
                }
            }
            break;
        case NSStreamEventEndEncountered:
            debug(@"Stream end encountered");
            break;
        case NSStreamEventNone:
            debug(@"Stream event none");
            break;
    }
}

#pragma mark - Lifecycle
+(WITUploader*)sharedInstance {
    static WITUploader *instance;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        instance = [[WITUploader alloc] init];
    });

    return instance;
}
-(id)init {
    self = [super init];
    if (self) {
        q = [[NSOperationQueue alloc] init];
        [q setMaxConcurrentOperationCount:1];
    }
    return self;
}
-(void)dealloc {
    if (outStream) {
        [outStream close];
        outStream = nil;
    }
    if (inStream) {
        [inStream close];
        inStream = nil;
    }
    if (q) {
        [q cancelAllOperations];
    }
}
@end
