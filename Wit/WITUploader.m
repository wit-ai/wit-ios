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

static NSString* const kWitSpeechURL = @"http://localhost:8081/speech";

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

    // build and send HTTP request
    NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:kWitSpeechURL]];
    [req setHTTPMethod:@"POST"];
    [req setCachePolicy:NSURLCacheStorageNotAllowed];
    [req setHTTPBodyStream:inStream];
    [req setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
    [req setValue:@"wit/ios" forHTTPHeaderField:@"Content-type"];
    [req setValue:@"chunked" forHTTPHeaderField:@"Transfer-encoding"];

    AFHTTPRequestOperation *op = [[AFHTTPRequestOperation alloc] initWithRequest:req];
    [op setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (WIT_DEBUG) {
            NSTimeInterval t = [[NSDate date] timeIntervalSinceDate:start];
            NSLog(@"Wit response (%f s): %@", t, [operation responseString]);
        }

        NSError *parsingError;
        NSString* responseString = [operation responseString];
        NSDictionary* response = [NSJSONSerialization JSONObjectWithData:[responseString dataUsingEncoding:NSUTF8StringEncoding]
                                                                 options:0 error:&parsingError];

        if (parsingError) {
            [self.delegate gotResponse:nil error:parsingError];
            return;
        }

        [self.delegate gotResponse:response error:nil];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (WIT_DEBUG) {
            NSTimeInterval t = [[NSDate date] timeIntervalSinceDate:start];
            NSLog(@"Wit error (%f s): %@", t, error);
        }

        [self.delegate gotResponse:nil error:error];
    }];

    [op setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        debug(@"Uploaded %lld", totalBytesWritten);
    }];

    [[NSOperationQueue mainQueue] addOperation:op];

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
                debug(@"outStream has space, resuming dispatch");
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
        instance = [[WITUploader alloc] initWithBaseURL:[NSURL URLWithString:kWitSpeechURL]];
    });

    return instance;
}
-(instancetype)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
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
