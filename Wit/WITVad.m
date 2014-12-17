//
//  WITVad.m
//  Wit
//
//  Created by Aric Lasry on 8/6/14.
//  Copyright (c) 2014 Willy Blandin. All rights reserved.
//

#import "WITVad.h"
#import "Wit.h"
#import "WITUploader.h"
#import "WITRecorder.h"

@implementation WITVad {
    s_wv_detector_cvad_state *vad_state;
    FFTSetup fft_setup;
}

-(void) gotAudioSamples:(NSData *)samples {
    UInt32 size = (UInt32)[samples length];
    short *bytes = (short*)[samples bytes];
    
    for(int sample_offset=0; sample_offset+self->vad_state->samples_per_frame < size/2; sample_offset+=self->vad_state->samples_per_frame){
        
        int nonZero=0;
        
        //check to make sure buffer actually has audio data
        for(int i=0; i<self->vad_state->samples_per_frame; i++){
            if(bytes[sample_offset+i] != 0){
                nonZero=1;
                break;
            }
        }

        //skip frame if it has nothing
        if(!nonZero) continue;

        float *fft_mags = [self get_fft:(bytes+sample_offset)];
        
        int detected_speech = wvs_cvad_detect_talking(self->vad_state, bytes+sample_offset, fft_mags);
        
        free(fft_mags);
        
        if ( detected_speech == 1){
            //someone just started talking
            NSLog(@"Starting......................");
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate vadStartedTalking];
            });
        } else if ( detected_speech == 0) {
            //someone just stopped talking
            NSLog(@"Stopping......................");
            self.stoppedUsingVad = YES;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate vadStoppedTalking];
            });
            break;
        }
    }

}

-(id) init {
    NSLog(@"WITVad init");
    self = [super init];
    int vadSensitivity = MIN(100,MAX(0,[Wit sharedInstance].vadSensitivity)); //must be between 0 and 100
    int vadTimeout = [Wit sharedInstance].vadTimeout;
    
    self->vad_state = wv_detector_cvad_init(kWitAudioSampleRate,vadSensitivity,vadTimeout);
    self.stoppedUsingVad = NO;
    
    //get the next power of 2 that'll fit our data
    int logN = log2(self->vad_state->samples_per_frame);  //samples_per_frame will be a power of 2
    //store the FFT setup for many later uses
    self->fft_setup = vDSP_create_fftsetup(logN, kFFTRadix2);
    
    return self;
}

-(void) dealloc {
    NSLog(@"Clean WITVad");
    wv_detector_cvad_clean(self->vad_state);
}

-(float*) get_fft:(short *)samples {
    int N = self->vad_state->samples_per_frame; //guarenteed to be a power of 2
    
    //dynamically allocate an array for our results since we don't want to mutate the input samples
    float *fft_mags = malloc(N/2 * sizeof(float));
    float *fsamples = malloc(N * sizeof(float));
    
    for(int i=0; i<N; i++){
        if(i<self->vad_state->samples_per_frame){
            fsamples[i] = samples[i];
        } else {
            fsamples[i] = 0;
        }
    }
    
    DSPSplitComplex tempSplitComplex;
    tempSplitComplex.realp = malloc(N/2 * sizeof(float));
    tempSplitComplex.imagp = malloc(N/2 * sizeof(float));
    
    //pack the real data into a split form for accelerate
    vDSP_ctoz((DSPComplex*)fsamples, 2, &tempSplitComplex, 1, N/2);
    
    //do the FFT
    vDSP_fft_zrip(self->fft_setup, &tempSplitComplex, 1, (int)log2(N), kFFTDirection_Forward);
    
    //get the magnitudes
    vDSP_zvabs(&tempSplitComplex, 1, fft_mags, 1, N/2);
    
    //clear up memory
    free(fsamples);
    free(tempSplitComplex.realp);
    free(tempSplitComplex.imagp);
    
    return fft_mags;
}

@end
