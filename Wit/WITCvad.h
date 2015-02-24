//
//  WITCvad.h
//  Wit
//
//  Created by Anthony Kesich on 11/12/14.
//  Copyright (c) 2014 Willy Blandin. All rights reserved.
//

#ifndef Wit_WITCvad_h
#define Wit_WITCvad_h


#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <string.h>


/*
 * This speech algorithm looks at multiple auditory compenents related to speech:
 *  - Energy divided into 1 KHz bands
 *  - Dominant Frequency Component
 *  - Spectral Flatness Measure
 *  - Zero-crossings
 *
 * If many features of speech are present for a period of time (~150 ms), speech is detected.
 * The end of speech is determined by most features of speech disappearing for an extended period of time (~1 sec)
 */

#define DETECTOR_CVAD_FRAMES_INIT 40 /* number of frames to use to initialize values */
#define DETECTOR_CVAD_E_TH_COEFF_LOW_BAND 2.5f     /* Energy threshold coefficient */
#define DETECTOR_CVAD_E_TH_COEFF_UPPER_BANDS 2.0f     /* Energy threshold coefficient */
#define DETECTOR_CVAD_SFM_TH 3.0f   /* Spectral Flatness Measure threshold */
#define DETECTOR_CVAD_DFC_TH 250.0f   /* most Dominant Frequency Component threshold */
#define DETECTOR_CVAD_MIN_ZERO_CROSSINGS 5   /* fewest zero crossings for speech */
#define DETECTOR_CVAD_MAX_ZERO_CROSSINGS 15  /* maximum zero crossings for speech */
#define DETECTOR_CVAD_RESULT_MEMORY 130 /* number of frame results to keep in memory */
#define DETECTOR_CVAD_ENERGY_MEMORY 20 /* number of frame results to keep in memory */
#define DETECTOR_CVAD_N_ENERGY_BANDS 5 /* number of 1 KHz energy bands to compute */
#define DETECTOR_CVAD_MINIMUM_LENGTH 1000 /* minimum length of vad in ms */

//final speech detection variables
#define DETECTOR_CVAD_N_FRAMES_CHECK_START 15
#define DETECTOR_CVAD_COUNT_SUM_START 4.5*DETECTOR_CVAD_N_FRAMES_CHECK_START
#define DETECTOR_CVAD_COUNT_SUM_START_SENSITIVE 3.8*DETECTOR_CVAD_N_FRAMES_CHECK_START
#define DETECTOR_CVAD_N_FRAMES_CHECK_END_SHORT 1.5*DETECTOR_CVAD_N_FRAMES_CHECK_START
#define DETECTOR_CVAD_COUNT_END_SHORT_FACTOR 0.6
#define DETECTOR_CVAD_COUNT_END_SHORT_FACTOR_SENSITIVE 0.3
#define DETECTOR_CVAD_N_FRAMES_CHECK_END_LONG 6.5*DETECTOR_CVAD_N_FRAMES_CHECK_START
#define DETECTOR_CVAD_COUNT_END_LONG_FACTOR 1.8
#define DETECTOR_CVAD_COUNT_END_LONG_FACTOR_SENSITIVE 1.5

typedef struct {
    double energy_thresh_coeff_lower;
    double energy_thresh_coeff_upper;
    double sfm_thresh;
    double dfc_thresh;
    double th_energy[DETECTOR_CVAD_N_ENERGY_BANDS];
    double th_sfm;
    double th_dfc;
    double ref_energy[DETECTOR_CVAD_N_ENERGY_BANDS];
    double ref_sfm;
    double ref_dfc;
    double ref_dfc_var;
    double energy_update_coeff[DETECTOR_CVAD_N_ENERGY_BANDS];
    double energy_prev_variance[DETECTOR_CVAD_N_ENERGY_BANDS];
    double energy_history[DETECTOR_CVAD_N_ENERGY_BANDS][DETECTOR_CVAD_ENERGY_MEMORY];
    double sfm_update_coeff;
    double dfc_history[DETECTOR_CVAD_FRAMES_INIT];
    double dfc_update_coeff;
    float end_sum_long_coeff;
    float end_sum_short_coeff;
    int frame_number;
    int speech_start_frame;
    int max_speech_time;
    int energy_history_index;
    int min_zero_crossings;
    int max_zero_crossings;
    int thresh_initialized;
    int silence_count;
    int talking;
    int sample_freq;
    int samples_per_frame;
    int max_start_sum;
    int n_frames_check_start;
    int n_frames_check_end_short;
    int n_frames_check_end_long;
    int start_sum_threshold;
    int previous_state_index;
    short int previous_state[DETECTOR_CVAD_RESULT_MEMORY];
} s_wv_detector_cvad_state;

/*
 Main entry point to the detection algorithm.
 This returns a -1 if there is no change in state, a 1 if some started talking, and a 0 if speech ended
 */
int wvs_cvad_detect_talking(s_wv_detector_cvad_state *cvad_state, short int *samples, float *fft_mags);


/*
 Initiate the cvad_state structure, which represents the state of
 one instance of the algorithm
 
 sensitive mode: 0 if for a close-up mic, 1 if for a fixed, distant mic
 */
s_wv_detector_cvad_state* wv_detector_cvad_init(int sample_rate, int sensitivity, int speech_timeout);

/*
 Safely frees memory for a cvad_state
 */
void wv_detector_cvad_clean(s_wv_detector_cvad_state *cvad_state);

/*
 Set VAD sensitivity (0-100)
 - Lower values are for strong voice signals like for a cellphone or personal mic
 - Higher values are for use with a fixed-position mic or any application with voice burried in ambient noise
 - Defaults to 0
 */

void wv_detector_cvad_set_sensitivity(s_wv_detector_cvad_state *cvad_state, int sensitivity);

/*
 Set the reference values of the energy, most dominant frequency componant and the spectral flatness measure.
 The threshold value is then set based on the "background" reference levels
 */
void wv_detector_cvad_update_ref_levels(s_wv_detector_cvad_state *cvad_state, double *band_energy, double dfc, double sfm);

/*
 Set the threshhold on the cvad_state.
 */
void vw_detector_cvad_set_threshold(s_wv_detector_cvad_state *cvad_state);

/*
 Computes the variance of the energy over the past few windows and adapts the update ceoffs accordingly
 */
void wv_detector_cvad_modify_update_coeffs(s_wv_detector_cvad_state *cvad_state);

/*
 Compare the distance between the value and the minimum value of each component and return how many
 component(s) reponded positiviely.
 Each frame with more than 2 (out of 3) matching features are qualified as a speech frame.
 example : energy - cvad_state->min_energy > cvad_state->th_energy
 */
short int vw_detector_cvad_check_frame(s_wv_detector_cvad_state *cvad_state, double *band_energy, double dfc, double sfm, int zero_crossings);

/*
 Return the frequency with the biggest amplitude (from a frame).
 */
double frames_detector_cvad_most_dominant_freq(s_wv_detector_cvad_state *cvad_state, float *fft_mags, int nb_modules, double nb_samples);

/*
 Computes the energy of the first DETECTOR_CVAD_N_ENERGY_BANDS 1 KHz bands
 */
void frames_detector_cvad_multiband_energy(s_wv_detector_cvad_state *cvad_state, float *fft_mags, int nb_modules, double *band_energy, int nb_samples);

/*
 Compute the spectral flatness of a frame.
 It tells us if all the frequencies have a similar amplitude, which would means noise
 or if there is some dominant frequencies, which could mean voice.
 */
double frames_detector_cvad_spectral_flatness(float *fft_mags, int nb);

/*
 Counts the number of times the signal crosses zero
 Even soft vocalizations have a fairly regular number of zero crossings (~5-15 for 10ms)
 */
int frames_detector_cvad_zero_crossings(short int *samples, int nb);

#endif
