//
//  WITCvad.m
//  Wit
//
//  Created by Anthony Kesich on 11/12/14.
//  Copyright (c) 2014 Willy Blandin. All rights reserved.
//

#include "WITCvad.h"


/*
 Adds value to the head of memory
 */
static void frame_memory_push(s_wv_detector_cvad_state *cvad_state, short int value);

/*
 Sums up the last N values of memory
 */
static int frame_memory_sum_last_n(s_wv_detector_cvad_state *cvad_state, int nb);


int wvs_cvad_detect_talking(s_wv_detector_cvad_state *cvad_state, short int *samples, float *fft_mags)
{
    double dfc;
    double band_energy[DETECTOR_CVAD_N_ENERGY_BANDS];
    double sfm;
    int fft_size = pow(2,floor(log2(cvad_state->samples_per_frame)));
    short int counter;
    int action = -1;
    int zero_crossings;
    
    //only process cvad_state->samples_per_frame samples at a time
    //frames_detector_cvad_fft(samples, fft_modules, cvad_state->samples_per_frame);
    dfc = frames_detector_cvad_most_dominant_freq(cvad_state, fft_mags, fft_size, cvad_state->samples_per_frame);
    sfm = frames_detector_cvad_spectral_flatness(fft_mags, fft_size);
    zero_crossings = frames_detector_cvad_zero_crossings(samples, cvad_state->samples_per_frame);
    frames_detector_cvad_multiband_energy(cvad_state, fft_mags, fft_size, band_energy, cvad_state->samples_per_frame);
    
    vw_detector_cvad_set_threshold(cvad_state);
    counter = vw_detector_cvad_check_frame(cvad_state, band_energy, dfc, sfm, zero_crossings);
    frame_memory_push(cvad_state, counter);
    
    if ((counter < 3 && cvad_state->talking == 0) || !cvad_state->thresh_initialized) {
        cvad_state->silence_count++;
        //only update reference levels if we don't detect speech
        wv_detector_cvad_update_ref_levels(cvad_state, band_energy, dfc, sfm);
    }
    if (cvad_state->thresh_initialized) {
        int start_sum = frame_memory_sum_last_n(cvad_state, DETECTOR_CVAD_N_FRAMES_CHECK_START);
        int stop_sum_long = frame_memory_sum_last_n(cvad_state, DETECTOR_CVAD_N_FRAMES_CHECK_END_LONG);
        int stop_sum_short = frame_memory_sum_last_n(cvad_state, DETECTOR_CVAD_N_FRAMES_CHECK_END_SHORT);
        int speech_time = (cvad_state->frame_number-cvad_state->speech_start_frame) * cvad_state->samples_per_frame * 1000 / cvad_state->sample_freq;
        
        if(start_sum > cvad_state->max_start_sum){
            cvad_state->max_start_sum = start_sum;
        }
        if (!cvad_state->talking && start_sum >= cvad_state->start_sum_threshold ) {
            cvad_state->talking = 1;
            cvad_state->speech_start_frame =  cvad_state->frame_number;
            action = 1;
        }
        else if (cvad_state->talking && speech_time > DETECTOR_CVAD_MINIMUM_LENGTH
                 && ((counter < 3
                      && stop_sum_long <= cvad_state->max_start_sum*cvad_state->end_sum_long_coeff
                      && stop_sum_short <= cvad_state->max_start_sum*cvad_state->end_sum_short_coeff)
                     || (cvad_state->max_speech_time > 0
                         &&  speech_time >= cvad_state->max_speech_time))) {
            cvad_state->talking = 0;
            action = 0;
            cvad_state->max_start_sum = 0;
        }
    }
    
    cvad_state->frame_number++;    

    return action;
}

s_wv_detector_cvad_state* wv_detector_cvad_init(int sample_rate, int sensitivity, int speech_timeout)
{
    s_wv_detector_cvad_state *cvad_state = malloc(sizeof(s_wv_detector_cvad_state));
    cvad_state->energy_thresh_coeff_lower = DETECTOR_CVAD_E_TH_COEFF_LOW_BAND;
    cvad_state->energy_thresh_coeff_upper = DETECTOR_CVAD_E_TH_COEFF_UPPER_BANDS;
    cvad_state->sfm_thresh= DETECTOR_CVAD_SFM_TH;
    cvad_state->dfc_thresh= DETECTOR_CVAD_DFC_TH;
    cvad_state->min_zero_crossings= DETECTOR_CVAD_MIN_ZERO_CROSSINGS;
    cvad_state->max_zero_crossings= DETECTOR_CVAD_MAX_ZERO_CROSSINGS;
    memset(cvad_state->energy_update_coeff, 0.20, DETECTOR_CVAD_N_ENERGY_BANDS * sizeof(double));
    memset(cvad_state->energy_prev_variance, -1, DETECTOR_CVAD_N_ENERGY_BANDS * sizeof(double));
    memset(cvad_state->energy_history, 0, DETECTOR_CVAD_ENERGY_MEMORY * DETECTOR_CVAD_N_ENERGY_BANDS * sizeof(double));
    cvad_state->energy_history_index = 0;
    cvad_state->dfc_update_coeff = 0.10;
    cvad_state->sfm_update_coeff = 0.10;
    cvad_state->frame_number = 0;
    cvad_state->speech_start_frame = -1;
    cvad_state->max_speech_time = speech_timeout;
    cvad_state->thresh_initialized = 0;
    cvad_state->silence_count = 0;
    cvad_state->talking = 0;
    memset(cvad_state->ref_energy, 0, DETECTOR_CVAD_N_ENERGY_BANDS * sizeof(double));
    cvad_state->ref_dfc = 0;
    cvad_state->ref_sfm = 0;
    memset(cvad_state->dfc_history, 0, DETECTOR_CVAD_FRAMES_INIT * sizeof(double));
    cvad_state->sample_freq = sample_rate;
    cvad_state->max_start_sum = 0;
    cvad_state->samples_per_frame = pow(2,ceil(log2(cvad_state->sample_freq/150))); //around 100 frames per second, but must be a power of two
    cvad_state->previous_state_index = 0;
    memset(cvad_state->previous_state, 0, DETECTOR_CVAD_RESULT_MEMORY * sizeof(short int));
    
    wv_detector_cvad_set_sensitivity(cvad_state, sensitivity);
    
    return cvad_state;
}

void wv_detector_cvad_clean(s_wv_detector_cvad_state *cvad_state)
{
    free(cvad_state);
}

void wv_detector_cvad_set_sensitivity(s_wv_detector_cvad_state *cvad_state, int sensitivity)
{
    float sensitivity_frac = MAX(0,MIN(100,sensitivity))/100.0;
    cvad_state->n_frames_check_start=DETECTOR_CVAD_N_FRAMES_CHECK_START;
    cvad_state->n_frames_check_end_short=DETECTOR_CVAD_N_FRAMES_CHECK_END_SHORT;
    cvad_state->n_frames_check_end_long=DETECTOR_CVAD_N_FRAMES_CHECK_END_LONG;
    
    cvad_state->start_sum_threshold = DETECTOR_CVAD_COUNT_SUM_START_SENSITIVE*sensitivity_frac;
    cvad_state->start_sum_threshold += DETECTOR_CVAD_COUNT_SUM_START*(1-sensitivity_frac);
    
    cvad_state->end_sum_short_coeff = DETECTOR_CVAD_COUNT_END_SHORT_FACTOR_SENSITIVE*sensitivity_frac;
    cvad_state->end_sum_short_coeff += DETECTOR_CVAD_COUNT_END_SHORT_FACTOR*(1-sensitivity_frac);
    
    cvad_state->end_sum_long_coeff = DETECTOR_CVAD_COUNT_END_LONG_FACTOR_SENSITIVE*sensitivity_frac;
    cvad_state->end_sum_long_coeff += DETECTOR_CVAD_COUNT_END_LONG_FACTOR*(1-sensitivity_frac);
}

void wv_detector_cvad_update_ref_levels(s_wv_detector_cvad_state *cvad_state,
                                        double *band_energy,
                                        double dfc,
                                        double sfm)
{
    int b=0;
    if (!cvad_state->thresh_initialized) {
        //if still initializing, accumulate values to average
        for(b=0; b<DETECTOR_CVAD_N_ENERGY_BANDS; b++){
            cvad_state->ref_energy[b] += band_energy[b];
        }
        
        
        cvad_state->ref_sfm += sfm;
        
        cvad_state->dfc_history[cvad_state->frame_number] = dfc > 0 ? log(dfc) : 0;
    }
    
    //record energy history
    for(b=0; b<DETECTOR_CVAD_N_ENERGY_BANDS; b++){
        cvad_state->energy_history[b][cvad_state->energy_history_index] = band_energy[b];
    }
    cvad_state->energy_history_index++;
    cvad_state->energy_history_index%=DETECTOR_CVAD_ENERGY_MEMORY;
    
    if (cvad_state->frame_number >= DETECTOR_CVAD_FRAMES_INIT) {
        if(!cvad_state->thresh_initialized) {
            //if done initializing, divide by number of samples to get an average
            cvad_state->thresh_initialized = 1;
            for(b=0; b<DETECTOR_CVAD_N_ENERGY_BANDS; b++){
                cvad_state->ref_energy[b] /= cvad_state->frame_number;
            }
            
            cvad_state->ref_sfm /= cvad_state->frame_number;
            
            double sum = 0;
            double sq_sum = 0;
            for(b=0; b<DETECTOR_CVAD_FRAMES_INIT; b++){
                cvad_state->ref_dfc+=cvad_state->dfc_history[b];
                sum += cvad_state->dfc_history[b];
                sq_sum += pow(cvad_state->dfc_history[b],2);
            }
            cvad_state->ref_dfc /= cvad_state->frame_number;
            cvad_state->ref_dfc_var = (sq_sum-sum*sum/cvad_state->frame_number)/(cvad_state->frame_number -1);
            
        } else if (cvad_state->talking == 0) {
            //otherwise update thresholds based on adaptive rules if there's no speech
            wv_detector_cvad_modify_update_coeffs(cvad_state);
            for(b=0; b<DETECTOR_CVAD_N_ENERGY_BANDS; b++){
                cvad_state->ref_energy[b] *= (1-cvad_state->energy_update_coeff[b]);
                cvad_state->ref_energy[b] += cvad_state->energy_update_coeff[b]*band_energy[b];
            }

        }
    }
    
}

void vw_detector_cvad_set_threshold(s_wv_detector_cvad_state *cvad_state)
{
    //update thresholds to be a multiple of the reference level
    int b;
    cvad_state->th_energy[0] = cvad_state->ref_energy[0]*cvad_state->energy_thresh_coeff_lower;
    for(b=1; b<DETECTOR_CVAD_N_ENERGY_BANDS; b++){
        cvad_state->th_energy[b] = cvad_state->ref_energy[b]*cvad_state->energy_thresh_coeff_upper;
    }
    cvad_state->th_dfc = cvad_state->ref_dfc+cvad_state->dfc_thresh;
    cvad_state->th_sfm = cvad_state->ref_sfm+cvad_state->sfm_thresh;
}

void wv_detector_cvad_modify_update_coeffs(s_wv_detector_cvad_state *cvad_state){
    int b;
    for(b=0; b<DETECTOR_CVAD_N_ENERGY_BANDS; b++){
        double sum=0;
        double sq_sum=0;
        int h;
        for(h=0; h<DETECTOR_CVAD_ENERGY_MEMORY; h++){
            sum+=cvad_state->energy_history[b][h];
            sq_sum+=pow(cvad_state->energy_history[b][h],2);
        }
        double variance = (sq_sum-sum*sum/DETECTOR_CVAD_ENERGY_MEMORY)/(DETECTOR_CVAD_ENERGY_MEMORY-1);
        double ratio = variance/cvad_state->energy_prev_variance[b];
        if(ratio > 1.25){
            cvad_state->energy_update_coeff[b] = 0.25;
        } else if(ratio > 1.10){
            cvad_state->energy_update_coeff[b] = 0.20;
        } else if(ratio > 1.00){
            cvad_state->energy_update_coeff[b] = 0.15;
        } else if(ratio > 0.00){
            cvad_state->energy_update_coeff[b] = 0.10;
        } else {
            //negative value indicates that this is the first pass of variance. Just set the coeff to 0.2
            cvad_state->energy_update_coeff[b] = 0.20;
        }
        cvad_state->energy_prev_variance[b] = variance;
    }
}

short int vw_detector_cvad_check_frame(s_wv_detector_cvad_state *cvad_state, double *band_energy, double dfc, double sfm, int zero_crossings)
{
    short int counter;
    
    counter = 0;
    
    int band_counter = 0;
    if (band_energy[0] > cvad_state->th_energy[0]) {
        counter += 2;
    }
    
    int b;
    for(b=1; b<DETECTOR_CVAD_N_ENERGY_BANDS; b++){
        if(band_energy[b] > cvad_state->th_energy[b]){
            band_counter++;
        }
    }
    if(band_counter >= 2){
        counter+=2;
    }
    
    if (fabs((dfc > 0 ? log(dfc): 0) - cvad_state->ref_dfc) > cvad_state->ref_dfc_var) {
        counter++;
    }
    if (sfm > cvad_state->th_sfm) {
        counter++;
    }
    if(zero_crossings >= cvad_state->min_zero_crossings && zero_crossings <= cvad_state->max_zero_crossings){
        counter++;
    }
    
    return counter;
}


double frames_detector_cvad_most_dominant_freq(s_wv_detector_cvad_state *cvad_state, float *fft_mags, int nb_modules, double nb_samples)
{
    double k = 0.0f;
    double max = 0.0f;
    double amplitude_minimum = 1.0f;
    int i;
    
    for (i = 0; i < nb_modules; i++) {
        if (fft_mags[i] > max && fft_mags[i] > amplitude_minimum) {
            max = fft_mags[i];
            k = i;
        } 
    }
    
    return k * (double)cvad_state->sample_freq / (double)nb_samples;
}

void frames_detector_cvad_multiband_energy(s_wv_detector_cvad_state *cvad_state, float *fft_mags, int nb_modules, double *band_energy, int nb_samples){

    int b = 0;
    int k = 0;
        
    for(b = 0; b<DETECTOR_CVAD_N_ENERGY_BANDS; b++){
        band_energy[b] = 0;
        while(k*cvad_state->sample_freq/nb_samples < 1000*(b+1)){
            band_energy[b]+=fft_mags[k];
            k++;
        }
    }

}

double frames_detector_cvad_spectral_flatness(float *fft_mags, int nb)
{
    double geo_mean = 0.0f;
    double arithm_mean = 0.0f;
    double sfm = 0.0f;
    int i;
    
    for (i = 0; i < nb; i++) {
        if (fft_mags[i] != 0.0f) {
            geo_mean += log(fft_mags[i]);
            arithm_mean += fft_mags[i];
        }
    }
    geo_mean = exp(geo_mean / (double) nb);
    arithm_mean = arithm_mean / (double) nb;
    sfm = 10 * log10(geo_mean / arithm_mean);
    sfm = fabs(sfm);
    
    return sfm;
}

int frames_detector_cvad_zero_crossings(short int *samples, int nb){
    int num_zero_crossings = 0;
    int i;
    
    for(i=1; i<nb; i++){
        if(samples[i-1]*samples[i] < 0){
            //if the product is negative, then the entries must have opposite signs indicating a crossing
            num_zero_crossings++;
        }
    }
    
    return num_zero_crossings;
}

static void frame_memory_push(s_wv_detector_cvad_state *cvad_state, short int value)
{
    cvad_state->previous_state[cvad_state->previous_state_index] = value;
    cvad_state->previous_state_index++;
    cvad_state->previous_state_index%=DETECTOR_CVAD_RESULT_MEMORY;
}

static int frame_memory_sum_last_n(s_wv_detector_cvad_state *cvad_state, int nb)
{
    int i = 0;
    int sum = 0;
    
    for (i = 0; i < nb; i++) {
        int indx = (cvad_state->previous_state_index - (i+1) + DETECTOR_CVAD_RESULT_MEMORY) % DETECTOR_CVAD_RESULT_MEMORY;
        sum += cvad_state->previous_state[indx];
    }
    
    return sum;
}

