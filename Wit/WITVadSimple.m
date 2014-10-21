//
//  WITVadSimple.c
//  Wit
//
//  Created by Aric Lasry on 8/6/14.
//  Copyright (c) 2014 Willy Blandin. All rights reserved.
//


#include "WITVadSimple.h"

/**
 * wvs_pcm16short2dbfs - converts short (16 bits) samples to decibel full scale
 *  @samples: array of pcm 16 bits samples
 *  @size: numbers of sample
 *
 *  Return a new allocated buffer of double, which will need to be free later
 */
static double * wvs_pcm16short2dbfs(short int *samples, int size);

static double frames_detector_esf_energy(double *samples, int nb_samples);
static void detector_esf_minimum(wvs_state *state, double energy, int n);
static int detector_esf_check_frame(wvs_state *state, double energy);
static void memory_push(int *memory, int length, int value);
static int frame_memory_lte(int *memory, int value, int nb);
static int frame_memory_gte(int *memory, int value, int nb);
static int wvs_check(wvs_state *state, double *samples, int nb_samples);


int wvs_detect_talking(wvs_state *state, short int *samples, int nb_samples)
{
    double *dbfss;
    double db;
    int result;
    
    dbfss = wvs_pcm16short2dbfs(samples, nb_samples);
    for (int i_sample = 0; i_sample < nb_samples; i_sample++) {
        db = dbfss[i_sample];
        if (isinf(db)) {
            continue;
        }
        if (state->current_nb_samples == state->samples_per_frame) {
            result = wvs_check(state, state->samples, state->current_nb_samples);
            if (result == 0) {
                free(dbfss);
                return 0;
            } else if(result == 1) {
                free(dbfss);
                return 1;
            }
            state->current_nb_samples = 0;
        }
        state->samples[state->current_nb_samples] = db;
        state->current_nb_samples++;
    }
    free(dbfss);
    
    return -1;
}

/**
 * -1 if still establishing backgound levels or no speech and no previous detection
 * 0 if stopped talking
 * 1 if started talking
 **/
static int wvs_check(wvs_state *state, double *samples, int nb_samples)
{
    int counter;
    double energy;
    int action;
    
    action = -1;
    energy = frames_detector_esf_energy(samples, nb_samples);
    
    if (state->sequence <= state->init_frames) {
        detector_esf_minimum(state, energy, state->sequence);
    }
    counter = detector_esf_check_frame(state, energy);
    if (state->sequence >= state->init_frames && !counter && !state->talking) {
        detector_esf_minimum(state, energy, state->sequence);
    }
    memory_push(state->previous_state, state->previous_state_maxlen, counter);
    if (state->sequence < state->init_frames) {
        state->sequence++;
        return -1;
    }
    if (state->talking == 0 && frame_memory_gte(state->previous_state, 1, 10)) {
        state->talking = 1;
            action = 1;
        }
        else if (state->talking == 1 && frame_memory_lte(state->previous_state, 0, state->previous_state_maxlen)) {
            state->talking = 0;
            action = 0;
        }
    state->sequence++;
    
    return action;
}


wvs_state *wvs_init(double threshold, int sample_rate)
{
    wvs_state *state;
    
    state = malloc(sizeof(*state));
    state->sequence = 0;
    state->min_initialized = 0;
    state->init_frames = 30;
    state->energy_threshold = 8.0;
    state->previous_state_maxlen = 30;
    state->previous_state = malloc(sizeof(*state->previous_state) * state->previous_state_maxlen);
    state->talking = 0;
    state->sample_rate = sample_rate;
    state->samples_per_frame = state->sample_rate / 100;
    state->samples = malloc(sizeof(*state->samples) * state->samples_per_frame);
    state->current_nb_samples = 0;
    state->min_energy = 0.0;
    
    return state;
}

void wvs_clean(wvs_state *state)
{
    free(state->samples);
    free(state->previous_state);
    free(state);
}

static double * wvs_pcm16short2dbfs(short int *samples, int size)
{
    double *dbfss;
    double max_ref;
    
    max_ref = 32768; //pow(2.0, 16.0) / 2; signed 16 bits w/o the -1
    dbfss = malloc(sizeof(*dbfss) * size);
    
    for (int i = 0; i < size; i++) {
        dbfss[i] = 0 - 20 * log10(fabs(samples[i] / max_ref));
    }
    
    return dbfss;
}

static double frames_detector_esf_energy(double *samples, int nb_samples)
{
    double energy = 0.0f;
    int i;
    
    for (i = 0; i < nb_samples; i++) {
        energy += samples[i];
    }
    energy /= nb_samples;
    
    return energy;
}

static void detector_esf_minimum(wvs_state *state, double energy, int n)
{
    n = (n > 10) ? 10 : n; //this correspond to 1/10 of a second
    state->min_energy = (state->min_energy * n + energy) / (n + 1);
    state->min_initialized = 1;
}

static int detector_esf_check_frame(wvs_state *state, double energy)
{
    int counter;
    
    counter = 0;
    if ((0 - (energy - state->min_energy)) >= state->energy_threshold) {
        counter++;
    }
    
    return counter;
}

static void memory_push(int *memory, int length, int value)
{
    while (--length) {
        memory[length] = memory[length - 1];
    }
    memory[0] = value;
}

static int frame_memory_gte(int *memory, int value, int nb)
{
    int i = 0;
    
    for (i = 0; i < nb; i++) {
        if (memory[i] < value) {
            return 0;
        }
    }
    
    return 1;
}

static int frame_memory_lte(int *memory, int value, int nb)
{
    int i;
    
    for (i = 0; i < nb; i++) {
        if (memory[i] > value) {
            return 0;
        }
    }
    
    return 1;
}
