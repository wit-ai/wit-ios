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
#import "util.h"
#import "WITContextSetter.h"

@interface WITUploader ()
@property (nonatomic, assign) BOOL requestEnding;

// queue used to send audio chunks in HTTP body
// will be suspended / resumed according to stream availability
@property (nonatomic, strong) NSOperationQueue *q;
@property (nonatomic, strong) WITRecorder *recorder;
@property (nonatomic, assign) AudioFormatID audioFormat;
@end

@implementation WITUploader {
    NSString* kWitSpeechURL;
    NSOutputStream *outStream;
    NSInputStream *inStream;
    NSDate *start; // used to time requests
    unsigned int bytesSent;
}

#pragma mark - Stream networking
-(BOOL)startRequestWithContext:(NSDictionary *)context {
    self.requestEnding = NO;
    NSString *token = [[WITState sharedInstance] accessToken];

    // CF wiring
    CFWriteStreamRef writeStream;
    CFReadStreamRef readStream;
    readStream = NULL;
    writeStream = NULL;
    CFStreamCreateBoundPair(NULL, &readStream, &writeStream, 65536);
    bytesSent = 0;

    // convert to NSStream and set as property
    inStream = CFBridgingRelease(readStream);
    outStream = CFBridgingRelease(writeStream);

    [outStream setDelegate:self];
    [outStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [outStream open];

    NSString* urlString;

    // build HTTP Request
    // if context, add to URL
    if (context != nil) {
        NSString *encoded = [WITContextSetter jsonEncode:context];
        urlString = [NSString stringWithFormat:@"%@&context=%@&verbose=true", kWitSpeechURL, encoded];
    } else {
        urlString = kWitSpeechURL;
    }

    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    [req setHTTPMethod:@"POST"];
    [req setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [req setTimeoutInterval:15.0];
    [req setHTTPBodyStream:inStream];
    [req setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
    
    NSString *contentType = nil;
    
    switch (self.audioFormat) {
        case kAudioFormatULaw:
            contentType = @"audio/ulaw";
            break;
        case kAudioFormatAppleIMA4:
            contentType = @"audio/raw;encoding=ima-adpcm;bits=16;rate=16000;endian=little";
            break;
        case kAudioFormatLinearPCM:
            contentType = @"wit/ios";
            break;
        default:
            contentType = @"wit/ios";
            break;
    }
    [req setValue:contentType forHTTPHeaderField:@"Content-type"];
    [req setValue:@"chunked" forHTTPHeaderField:@"Transfer-encoding"];
    [req setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    debug(@"HTTP %@ %@", req.HTTPMethod, urlString);

    // send HTTP request
    [NSURLConnection sendAsynchronousRequest:req
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               if (WIT_DEBUG) {
                                   NSHTTPURLResponse* httpResp = (NSHTTPURLResponse*)response;
                                   NSTimeInterval t = [[NSDate date] timeIntervalSinceDate:start];
                                   NSLog(@"Wit response %ld (%f s) %@",
                                         (long)[httpResp statusCode],
                                         t,
                                         [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
                               }

                               if (connectionError) {
                                   debug(@"Got connection error: %@", connectionError.localizedDescription);
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
                                   debug(@"Wit error: %@", object[@"error"]);
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
- (void)sendChunk:(NSData *)chunk {
    
    debug(@"Adding operation %u bytes", (unsigned int)[chunk length]);
    bytesSent = bytesSent + (unsigned int)[chunk length];
    [self.q addOperationWithBlock:^{
        if (outStream) {
            [self.q setSuspended:YES];

            debug(@"Uploading %u bytes", (unsigned int)[chunk length]);
            [outStream write:[chunk bytes] maxLength:[chunk length]];
        }

        NSUInteger cnt = self.q.operationCount;
        debug(@"Operation count: %d", cnt);
        if (self.requestEnding && cnt <= 1) {
            [self cleanUp];
        }
    }];
}

- (void)cleanUp {
        debug(@"Cleaning up uploader");
        if (outStream) {
            debug(@"Cleaning up output stream");
            outStream.delegate = nil;
            [outStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            [outStream close];
            outStream = nil;
            inStream = nil;
            
            start = [NSDate date];
        }
        
        [self.q cancelAllOperations];
        [self.q setSuspended:NO];
}

-(void)endRequest {
    debug(@"Ending request");
    self.requestEnding = YES;
    if (self.q.operationCount <= 0) {
        [self cleanUp];
    }
}

#pragma mark - NSStreamDelegate
-(void)stream:(NSStream *)s handleEvent:(NSStreamEvent)eventCode {
    switch (eventCode) {
        case NSStreamEventOpenCompleted:
            debug(@"Stream open completed");
            break;
        case NSStreamEventHasBytesAvailable:
            debug(@"Stream has bytes available");
            break;
        case NSStreamEventHasSpaceAvailable:
            if (s == outStream) {
//                debug(@"outStream has space, resuming dispatch");
                if ([self.q isSuspended]) {
                    [self.q setSuspended:NO];
                }
            }
            break;
        case NSStreamEventErrorOccurred:
            debug(@"Stream error occurred");
            [self cleanUp];
            break;
        case NSStreamEventEndEncountered:
            debug(@"Stream end encountered");
            [self cleanUp];
            break;
        case NSStreamEventNone:
            debug(@"Stream event none");
            break;
    }
}

- (instancetype)init {
    return [self initWithAudioFormat:kAudioFormatLinearPCM];
}

- (instancetype)initWithAudioFormat:(AudioFormatID) audioFormat {
    self = [self init];
    if (self) {
        _q = [[NSOperationQueue alloc] init];
        [_q setMaxConcurrentOperationCount:1];
        kWitSpeechURL = [NSString stringWithFormat: @"%@/speech?v=%@", kWitAPIUrl, kWitAPIVersion];
        _audioFormat = audioFormat;
    }
    
    return self;
}
- (void)dealloc {
    debug(@"dealloc WITUploader, total bytes sent %d", bytesSent);
    if (outStream) {
        [outStream close];
        outStream = nil;
    }
    if (inStream) {
        [inStream close];
        inStream = nil;
    }
    if (self.q) {
        [self.q cancelAllOperations];
    }
}

@end
