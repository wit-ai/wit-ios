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

/**
 * compute_avg - compute the average based on an initial average and a new value
 *  @avg: initial average
 *  @n: number of item(s) used to compute avg
 *  @new_value: the new value used to compute the new average
 *
 * Return the new average
 */
static double compute_avg(double avg, int n, double new_value);

/**
 * compute_avg_minus - compute the new average based on an original average,
 * a new value and a value to substract
 *  @avg: original average
 *  @n: number of item(s) used to compute avg
 *  @new_value: the new value to add to the avg
 *  @minus: the value to substract
 *
 * Return the new average
 */
static double compute_avg_minus(double avg, int n, double new_value, double minus);

/**
 * stack_push_double - push data into a size limited queue
 *  @memory: the queue
 *  @length: maximum number of element into the queue
 *  @value: the element to push at the beginning of the queue
 */
static void stack_push_double(double *memory, int length, double value);


int wvs_still_talking(wvs_state *state, short int *samples, int nb_samples)
{
    double *dbfss;
    double minus;
    double distance;
    double dbfs;
    
    dbfss = wvs_pcm16short2dbfs(samples, nb_samples);
    for (int i_sample = 0; i_sample < nb_samples; i_sample++) {
        dbfs = dbfss[i_sample];
        if (isinf(dbfs)) {
            continue;
        }
        dbfs = fabs(dbfs);
        state->total_avg = compute_avg(state->total_avg, state->total_avg_n, dbfs);
        state->total_avg_n++;
        if (state->last_nth_avg_n == state->min_samples) {
            minus = state->last_n_values[state->min_samples - 1];
            state->last_nth_avg = compute_avg_minus(state->last_nth_avg, state->last_nth_avg_n, dbfs, minus);
        } else {
            state->last_nth_avg = compute_avg(state->last_nth_avg, state->last_nth_avg_n, dbfs);
            state->last_nth_avg_n++;
        }
        stack_push_double(state->last_n_values, state->min_samples, dbfs);
        if (state->activity_started == 0) {
            distance = fabs(state->total_avg - state->last_nth_avg);
            state->activity_started = (distance > state->distance_th) ? 1 : 0;
            state->avg_activity_started = state->total_avg;
        } else if (state->activity_started == 1) {
            distance = (fabs(state->avg_activity_started - state->last_nth_avg));
            if (distance < (state->distance_th / 2)) {
                return 0;
            }
        }
    }
    free(dbfss);

    return (state->activity_started ? 1 : -1);
}


wvs_state *wvs_init(double threshold, int min_samples)
{
    wvs_state *state;
    
    state = malloc(sizeof(wvs_state));
    state->distance_th = threshold;
    state->min_samples = min_samples;
    state->total_avg = 0;
    state->total_avg_n = 0;
    state->last_nth_avg = 0;
    state->last_nth_avg_n = 0;
    state->last_n_values = malloc(sizeof(* state->last_n_values) * min_samples);
    state->activity_started = 0;
    state->avg_activity_started = 0;
    memset(state->last_n_values, 0, sizeof(state->last_n_values) * min_samples);
    
    return state;
}

void wvs_clean(wvs_state *state)
{
    free(state->last_n_values);
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
        dbfss[i] = fabs(dbfss[i]);
    }
    
    return dbfss;
}

static double compute_avg(double avg, int n, double new_value)
{
    double new_avg;
    
    new_avg = (avg * n) + new_value;
    new_avg = new_avg / (n + 1);
    
    return new_avg;
}

static double compute_avg_minus(double avg, int n, double new_value, double minus)
{
    double new_avg;
    
    new_avg = avg * n;
    new_avg = (new_avg - minus + new_value) / n;
    
    return new_avg;
}


static void stack_push_double(double *memory, int length, double value)
{
    while (--length > 0) {
        memory[length] = memory[length - 1];
    }
    memory[0] = value;
}
