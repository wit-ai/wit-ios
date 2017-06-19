//
//  WITSFSpeechRecordingSession.m
//  Wit
//
//  Created by patrick on 30/08/2016.
//  Copyright © 2016 Willy Blandin. All rights reserved.
//

#import "WITSFSpeechRecordingSession.h"
@import Speech;

@interface WITSFSpeechRecordingSession () <SFSpeechRecognizerDelegate>

@property (assign) WITVadConfig vadEnabled;
@property (nonatomic, strong) WITContextSetter *wcs;
@property (nonatomic, strong) WITVad *vad;

@end

@implementation WITSFSpeechRecordingSession {
    SFSpeechRecognizer *speechRecognizer;
    SFSpeechAudioBufferRecognitionRequest *recognitionRequest;
    SFSpeechRecognitionTask *recognitionTask;
    AVAudioEngine  *audioEngine;
    float average1;
    float average2;
    
}


-(instancetype)initWithWitContext:(NSDictionary *)upContext locale: (NSString *) locale vadEnabled:(WITVadConfig)vadEnabled withWitToken:(NSString *)witToken customData: (id) customData withDelegate:(id<WITRecordingSessionDelegate>)delegate {
    self = [super init];
    if (self) {
        self.customData = customData;
        self.delegate = delegate;
        _vadEnabled = vadEnabled;
        self.witToken = witToken;
        //self.vad = [[WITVad alloc] init];
        
        
        speechRecognizer = [[SFSpeechRecognizer alloc] initWithLocale:[NSLocale localeWithLocaleIdentifier:locale]];
        audioEngine = [[AVAudioEngine alloc] init];
        average1 = 0.0;
        average2 = 0.0;
        
        speechRecognizer.delegate = self;
        
        [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
            // could be non main queue, careful
            switch (status) {
                case SFSpeechRecognizerAuthorizationStatusDenied:
                {
                    NSLog(@"Speech denied");
                    
                    NSDictionary *userInfo = @{
                                               NSLocalizedDescriptionKey: NSLocalizedString(@"Speech recognition not authorized. Please enable in the iOS Settings for this app.", nil)};
                    NSError *tempError = [NSError errorWithDomain:@"WitRecognition" code:SFSpeechRecognizerAuthorizationStatusDenied userInfo:userInfo];
            
                    [self.delegate recordingSessionReceivedError: tempError];
                    break;
                }
                case SFSpeechRecognizerAuthorizationStatusRestricted:
                {
                    NSDictionary *userInfo = @{
                                               NSLocalizedDescriptionKey: NSLocalizedString(@"Speech recognition not allowed on this device.",nil)};
                    NSError *tempError = [NSError errorWithDomain:@"WitRecognition" code:SFSpeechRecognizerAuthorizationStatusRestricted userInfo:userInfo];
                    
                    [self.delegate recordingSessionReceivedError: tempError];
                    NSLog(@"Speech restricted");
                    break;
                }
                    
                case SFSpeechRecognizerAuthorizationStatusAuthorized:
                    NSLog(@"Speech authorized");
                    [ self start];
                    break;
                    
                case SFSpeechRecognizerAuthorizationStatusNotDetermined:
                    NSLog(@"Speech not determined");
                    break;
                    
                default:
                    break;
            }
        }];
        
    }
    
    
    return self;
}

- (NSString *) fixGermanNumbers: (NSString *) numbers {
    return [[[[[[[[[[numbers stringByReplacingOccurrencesOfString:@" eins" withString:@" 1"]
            stringByReplacingOccurrencesOfString:@" zwei" withString:@" 2"]
            stringByReplacingOccurrencesOfString:@" drei" withString:@" 3"]
            stringByReplacingOccurrencesOfString:@" vier" withString:@" 4"]
            stringByReplacingOccurrencesOfString:@" fünf" withString:@" 5"]
            stringByReplacingOccurrencesOfString:@" sechs" withString:@" 6"]
            stringByReplacingOccurrencesOfString:@" sieben" withString:@" 7"]
            stringByReplacingOccurrencesOfString:@" acht" withString:@"8"]
            stringByReplacingOccurrencesOfString:@" neun" withString:@"9"]
            stringByReplacingOccurrencesOfString:@" zehn" withString:@"10"];
}

- (void) start {
    NSLog(@"START CALLED");
      NSError *error;
    
    /*
    AVAudioSession *audiosession = [AVAudioSession sharedInstance];
   
    [audiosession setMode: AVAudioSessionModeMeasurement error:&error];
    if (error) {
        NSLog(@"mode error was %@", error);
    }
     */
     /*
    [audiosession setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];
    if (error) {
        NSLog(@"activate error was %@", error);
    }
     */
  
    recognitionRequest = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
    
    AVAudioInputNode *inputNode = audioEngine.inputNode;
    
    
    recognitionRequest.shouldReportPartialResults = YES;
    
    // A recognition task represents a speech recognition session.
    // We keep a reference to the task so that it can be cancelled.
    
    recognitionTask = [speechRecognizer recognitionTaskWithRequest:recognitionRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
        BOOL isFinal = result.isFinal;
        NSLog(@"Speech result %d: %@", isFinal, result.bestTranscription.formattedString);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate recordingSessionDidRecognizePreviewText:result.bestTranscription.formattedString final: isFinal];

    });
        
        if (error || isFinal) {
            [audioEngine stop];
            [inputNode removeTapOnBus:0];
            recognitionRequest = nil;
            recognitionTask = nil;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate recordingSessionDidStopRecording];
                NSNumber *newPower = [[NSNumber alloc] initWithFloat:-999];
                [[NSNotificationCenter defaultCenter] postNotificationName:kWitNotificationAudioPowerChanged object:newPower];
                
                if (isFinal) {
                    if ([self.customData isKindOfClass:[WitSession class]]) {
                        [[Wit sharedInstance] converseWithString:[self fixGermanNumbers: result.bestTranscription.formattedString] witSession:self.customData];
                    } else {
                        [[Wit sharedInstance] interpretString:[self fixGermanNumbers: result.bestTranscription.formattedString] customData:nil];
                    }

                }
                if (error) {
                    [self.delegate recordingSessionReceivedError: error];
                }
            });
        }
    }];
    
    AVAudioFormat *recordingFormat = [inputNode outputFormatForBus:0];
    [inputNode installTapOnBus:0 bufferSize:1024 format:recordingFormat block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
        [recognitionRequest appendAudioPCMBuffer:buffer];
        
        //NSData* audio = [NSData dataWithBytes:buffer.audioBufferList->mBuffers[0].mData length:buffer.audioBufferList->mBuffers[0].mDataByteSize];
       // [self.vad gotAudioSamples:audio];
        
        UInt32 inNumberFrames = buffer.frameLength;

        Float32* samples = (Float32*)buffer.floatChannelData[0];
        Float32 avgValue = 0;
            
        vDSP_meamgv((Float32*)samples, 1, &avgValue, inNumberFrames);
        average1 = (0.9*((avgValue==0)?-100:20.0*log10f(avgValue))) + ((1-0.9)*average1 + 20) ;

        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSNumber *newPower = [[NSNumber alloc] initWithFloat:average1];
            [[NSNotificationCenter defaultCenter] postNotificationName:kWitNotificationAudioPowerChanged object:newPower];
        });
        
    }];
    [audioEngine prepare];
    [audioEngine startAndReturnError:&error];
    [self.delegate recordingSessionDidStartRecording];
    if (error) {
        NSLog(@"start and return error was %@", error);
    }
    
}
- (void)speechRecognizer:(SFSpeechRecognizer *)speechRecognizer availabilityDidChange:(BOOL)available {
    NSLog(@"speech recognizer is now %d", available);
}

- (BOOL)isRecording {
    if (audioEngine.isRunning) {
        return YES;
    }
    return NO;
}

- (void)stop {
    [audioEngine stop];
    [recognitionRequest endAudio];
    NSLog(@"Stopping recording");
}

@end
