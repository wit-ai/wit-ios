//
//  WITVadSimple.h
//  Wit
//
//  Created by Aric Lasry on 8/6/14.
//  Copyright (c) 2014 Willy Blandin. All rights reserved.
//

#ifndef Wit_WITVadSimple_h
#define Wit_WITVadSimple_h

#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <string.h>

/**
 * This voice activity detection is very simple. It computes the average of the
 * audio powers from the beginning and the last second, and compare the distance 
 * between the two with a pre-defined threshold.
 *
 * The "audio powers" are average of audio chunks in DBFS. It could also be PCM samples...
 */

/* 
 state of the voice activity detection algorithm.
 */
typedef struct  {
    /* average value of all the audio samples received since the beginning of the stream */
    double total_avg;
    
    /* number of audio samples used to compute total_avg */
    int total_avg_n;
    
    /* average of the nth last audio samples from the stream */
    double last_nth_avg;
    
    /* number of audio samples used to compute the last_nth_avg */
    int last_nth_avg_n;
    
    /* the last (min_samples) PCM values stored to re-compute the last_nth_avg quickly  */
    double *last_n_values;
    
    /* distance threshold, in decibel full scale */
    double distance_th;
    
    /* minimum number of samples / before the algorithm can take a decision */
    int min_samples;
    
    /* check if the activity has been detected or not */
    int activity_started;
    
    /* the audio power average of the signal when the algorithm detected the "activity started" state */
    double avg_activity_started;
    
} wvs_state;


/**
 * wvs_still_talking - check if someone is (still) talking based on the PCM samples
 * of an audio source
 *  @state: represent the state of the VAD algorithm. One state is required for new audio stream / session
 *  @samples: audio samples
 *  @nb_samples: number of items in samples
 *
 * Return -1 when the talk did not start, 0 when the talk is over and 1 when the talk is still going on.
 */
int wvs_still_talking(wvs_state *state, short int *samples, int nb_samples);

/**
 * wvs_init - initialize the state object
 *  @threshold: the threshold used for the VAD algorithm
 *  @min_samples: the number of samples used to compute state.last_nth_avg
 *
 * The distance between state.total_avg and state.last_nth_avg will be compared to the
 * state.distance_th (in decibel full scale) to evaluate the status of the audio stream
 *
 * Return a pointer to the new wvs_state structure. 
 * This pointer will need to be freed by the caller using the wvs_clean function
 */
wvs_state *wvs_init(double threshold, int min_samples);

/**
 * wvs_clean - clean a wvs_state* structure
 *  @state: the structure to free.
 */
void wvs_clean(wvs_state *state);

#endif
