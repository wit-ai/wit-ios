//
//  WITCvad.m
//  Wit
//
//  Created by Anthony Kesich on 11/12/14.
//  Copyright (c) 2014 Willy Blandin. All rights reserved.
//

#define FIXED_POINT 16 //sets fft for fixed point data
#include "WITCVad.h"

int wvs_cvad_detect_talking(s_wv_detector_cvad_state *cvad_state, short int *samples, int nb_samples)
{
    double dfc;
    double *band_energy;
    kiss_fft_cpx *fft_modules;
    double sfm;
    int fft_size = nb_samples / 2 + 1;
    int counter;
    int action = -1;
    
    /*energy = frames_detector_cvad_energy(samples, nb_samples);*/
    fft_modules = frames_detector_cvad_fft(samples, nb_samples);
    dfc = frames_detector_cvad_most_dominant_freq(cvad_state, fft_modules, fft_size, nb_samples);
    sfm = frames_detector_cvad_spectral_flatness(fft_modules, fft_size);
    int zero_crossings = frames_detector_cvad_zero_crossings(samples, nb_samples);
    /*printf("%d\n",zero_crossings);*/
    band_energy = frames_detector_cvad_multiband_energy(cvad_state, fft_modules, fft_size, nb_samples);
    free(fft_modules);
    
    vw_detector_cvad_set_threshold(cvad_state);
    counter = vw_detector_cvad_check_frame(cvad_state, band_energy, dfc, sfm, zero_crossings);
    frame_memory_push(cvad_state->previous_state, DETECTOR_CVAD_RESULT_MEMORY, counter);
    
    if ((counter < 2 && cvad_state->talking == 0) || !cvad_state->thresh_initialized) {
        cvad_state->silence_count++;
        //only update reference levels if we don't detect speech
        wv_detector_cvad_update_ref_levels(cvad_state, band_energy, dfc, sfm);
    }
    if (cvad_state->thresh_initialized) {
        if (!cvad_state->talking
            && frame_memory_sum_last_n(cvad_state->previous_state, DETECTOR_CVAD_N_FRAMES_CHECK_START) >= DETECTOR_CVAD_COUNT_SUM_START ) {
            cvad_state->talking = 1;
            action = 1;
        }
        else if (cvad_state->talking && counter < 3
                 && frame_memory_sum_last_n(cvad_state->previous_state, DETECTOR_CVAD_N_FRAMES_CHECK_END_LONG) <= DETECTOR_CVAD_COUNT_SUM_END_LONG
                 && frame_memory_sum_last_n(cvad_state->previous_state, DETECTOR_CVAD_N_FRAMES_CHECK_END_SHORT) <= DETECTOR_CVAD_COUNT_SUM_END_SHORT ) {
            cvad_state->talking = 0;
            action = 0;
        }
    }
        
    cvad_state->frame_number++;
    
    return action;
}

void wv_detector_cvad_init(s_wv_detector_cvad_state *cvad_state)
{
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
    cvad_state->thresh_initialized = 0;
    cvad_state->silence_count = 0;
    cvad_state->talking = 0;
    memset(cvad_state->ref_energy, 0, DETECTOR_CVAD_N_ENERGY_BANDS * sizeof(double));
    cvad_state->ref_dfc = 0;
    cvad_state->ref_sfm = 99999;
    memset(cvad_state->dfc_history, 0, DETECTOR_CVAD_FRAMES_INIT * sizeof(double));
    cvad_state->sample_freq = 16000; //this should really check with the input
    memset(cvad_state->previous_state, 0, DETECTOR_CVAD_RESULT_MEMORY * sizeof(char));
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
        
        
        if(sfm < cvad_state->ref_sfm){
            cvad_state->ref_sfm = sfm;
        }
        
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

int vw_detector_cvad_check_frame(s_wv_detector_cvad_state *cvad_state, double *band_energy, double dfc, double sfm, int zero_crossings)
{
    int counter;
    
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
    
    if (fabs(log(dfc) - cvad_state->ref_dfc) > cvad_state->ref_dfc_var) {
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

double frames_detector_cvad_energy(float *samples, int nb_samples)
{
    double energy = 0.0f;
    int i;
    
    for (i = 0; i < nb_samples; i++) {
        energy += pow(samples[i], 2.0);
    }
    energy /= nb_samples;
    
    return energy;
}

kiss_fft_cpx* frames_detector_cvad_fft(short int *samples, int nb)
{
    int N = nb & 1 ? nb -1 : nb;
    kiss_fftr_cfg fft_state = kiss_fftr_alloc(N,0,0,0);
    int msize = sizeof(kiss_fft_cpx) * (N);
    kiss_fft_cpx *results = malloc(msize);
    
    //kiss_fft_scalar is a float
    kiss_fftr(fft_state, (kiss_fft_scalar*)samples, results);
    
    return results;
}


double frames_detector_cvad_most_dominant_freq(s_wv_detector_cvad_state *cvad_state, kiss_fft_cpx *modules, int nb_modules, double nb_samples)
{
    double k = 0.0f;
    double max = 0.0f;
    double amplitude;
    double amplitude_minimum = 1.0f;
    int i;
    
    for (i = 0; i < nb_modules; i++) {
        amplitude = frames_detector_cvad_c2r(modules[i]);
        if (amplitude > max && amplitude > amplitude_minimum) {
            max = amplitude;
            k = i;
        } else {
        }
    }
    
    return k * (double)cvad_state->sample_freq / (double)nb_samples;
}

double* frames_detector_cvad_multiband_energy(s_wv_detector_cvad_state *cvad_state, kiss_fft_cpx *fft_modules, int nb_modules, int nb_samples){
    //create a array to store our 4 results
    double* band_energy = malloc(DETECTOR_CVAD_N_ENERGY_BANDS*sizeof(double));
    int b = 0;
    int k = 0;
    
    for(b = 0; b<DETECTOR_CVAD_N_ENERGY_BANDS; b++){
        band_energy[b] = 0;
        while(k*cvad_state->sample_freq/nb_samples < 1000*(b+1)){
            band_energy[b]+=frames_detector_cvad_c2r(fft_modules[k]);
            k++;
        }
        /*printf("Band[%d]=%g, ",b,band_energy[b]);*/
    }
    /*printf("\n");*/
    
    return band_energy;
}

double frames_detector_cvad_spectral_flatness(kiss_fft_cpx *modules, int nb)
{
    double geo_mean = 0.0f;
    double arithm_mean = 0.0f;
    double value;
    double sfm = 0.0f;
    int i;
    
    for (i = 0; i < nb; i++) {
        value = frames_detector_cvad_c2r(modules[i]);
        if (value != 0.0f) {
            geo_mean += log(value);
            arithm_mean += value;
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

double frames_detector_cvad_c2r(kiss_fft_cpx module)
{
    double value;
    
    value = pow(module.r, 2) + pow(module.i, 2);
    value = pow(value, (double) 1/2);
    
    return value;
}

static void frame_memory_push(char *memory, int length, int value)
{
    while (--length) {
        memory[length] = memory[length - 1];
    }
    memory[0] = value;
}

static int frame_memory_sum_last_n(char *memory, int nb)
{
    int i = 0;
    int sum = 0;
    
    for (i = 0; i < nb; i++) {
        sum += memory[i];
    }
    
    return sum;
}

