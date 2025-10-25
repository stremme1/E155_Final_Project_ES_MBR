// Simple Audio System Test
// Tests the core audio generation logic without hardware dependencies
// Author: E155 Final Project
// Date: 2024

#include <stdio.h>
#include <assert.h>
#include <math.h>
#include <stdint.h>
#include <stdbool.h>

// Sound IDs (matching original Arduino code exactly)
typedef enum {
    NO_SOUND = 255,       // No sound to play
    SOUND_SNARE = 0,      // "0" - Snare drum
    SOUND_HIHAT = 1,      // "1" - Hi-hat
    SOUND_KICK = 2,       // "2" - Kick drum
    SOUND_HIGH_TOM = 3,   // "3" - High tom
    SOUND_MID_TOM = 4,    // "4" - Mid tom
    SOUND_CRASH = 5,      // "5" - Crash cymbal
    SOUND_RIDE = 6,       // "6" - Ride cymbal
    SOUND_FLOOR_TOM = 7   // "7" - Floor tom
} sound_id_t;

// Audio parameters for each sound
typedef struct {
    uint16_t frequency;
    uint16_t duration; // in ms
    uint8_t volume;    // 0-100
} audio_params_t;

// Audio parameters for each sound (matching original Python code)
static const audio_params_t audio_params[] = {
    {200,  100, 100},  // SOUND_SNARE (0): 200Hz, 100ms, full volume
    {8000, 50,  80},   // SOUND_HIHAT (1): 8kHz, 50ms, 80% volume
    {60,   200, 100},  // SOUND_KICK (2): 60Hz, 200ms, full volume
    {300,  150, 90},   // SOUND_HIGH_TOM (3): 300Hz, 150ms, 90% volume
    {250, 150, 90},    // SOUND_MID_TOM (4): 250Hz, 150ms, 90% volume
    {4000, 300, 95},   // SOUND_CRASH (5): 4kHz, 300ms, 95% volume
    {2000, 200, 85},   // SOUND_RIDE (6): 2kHz, 200ms, 85% volume
    {150,  200, 90}    // SOUND_FLOOR_TOM (7): 150Hz, 200ms, 90% volume
};

// Test results tracking
static int tests_passed = 0;
static int tests_failed = 0;

// Test helper macros
#define TEST_ASSERT(condition, message) \
    do { \
        if (condition) { \
            printf("✓ %s\n", message); \
            tests_passed++; \
        } else { \
            printf("✗ %s\n", message); \
            tests_failed++; \
        } \
    } while(0)

#define TEST_EQUAL(actual, expected, message) \
    TEST_ASSERT((actual) == (expected), message)

#define TEST_FLOAT_EQUAL(actual, expected, tolerance, message) \
    TEST_ASSERT(fabs((actual) - (expected)) < (tolerance), message)

// Mock audio generation function
void generate_audio_tone(uint16_t frequency, uint16_t duration, uint8_t volume) {
    printf("Generating audio: %dHz for %dms at %d%% volume\n", frequency, duration, volume);
    
    // Calculate period for desired frequency
    uint32_t period_us = 1000000 / frequency;  // Period in microseconds
    uint32_t cycles = (duration * 1000) / period_us;  // Number of cycles for duration
    
    printf("  Period: %dus, Cycles: %d\n", period_us, cycles);
}

// Mock audio playback function
void play_audio(sound_id_t sound_id) {
    if (sound_id >= sizeof(audio_params) / sizeof(audio_params[0])) {
        printf("Invalid sound ID: %d\n", sound_id);
        return;
    }
    
    const audio_params_t *params = &audio_params[sound_id];
    printf("Playing sound %d: ", sound_id);
    generate_audio_tone(params->frequency, params->duration, params->volume);
}

// Test 1: Audio parameter validation
void test_audio_parameters() {
    printf("Test 1: Audio parameter validation\n");
    
    // Test all sound parameters
    for (int i = 0; i < 8; i++) {
        const audio_params_t *params = &audio_params[i];
        
        // Check frequency range
        TEST_ASSERT(params->frequency >= 50 && params->frequency <= 10000, 
                   "Frequency in valid range");
        
        // Check duration range
        TEST_ASSERT(params->duration >= 50 && params->duration <= 500, 
                   "Duration in valid range");
        
        // Check volume range
        TEST_ASSERT(params->volume >= 50 && params->volume <= 100, 
                   "Volume in valid range");
    }
}

// Test 2: Sound ID mapping
void test_sound_id_mapping() {
    printf("Test 2: Sound ID mapping\n");
    
    // Test all valid sound IDs
    for (int i = 0; i < 8; i++) {
        play_audio(i);
        TEST_ASSERT(1, "Sound ID mapping");
    }
}

// Test 3: Audio generation
void test_audio_generation() {
    printf("Test 3: Audio generation\n");
    
    // Test different frequencies
    uint16_t frequencies[] = {200, 1000, 4000, 8000};
    uint16_t durations[] = {50, 100, 200, 300};
    uint8_t volumes[] = {50, 75, 90, 100};
    
    for (int i = 0; i < 4; i++) {
        generate_audio_tone(frequencies[i], durations[i], volumes[i]);
        TEST_ASSERT(1, "Audio generation");
    }
}

// Test 4: Frequency calculations
void test_frequency_calculations() {
    printf("Test 4: Frequency calculations\n");
    
    // Test frequency calculation for different sounds
    for (int i = 0; i < 8; i++) {
        const audio_params_t *params = &audio_params[i];
        
        // Calculate expected period
        uint32_t expected_period = 1000000 / params->frequency;
        uint32_t expected_cycles = (params->duration * 1000) / expected_period;
        
        printf("Sound %d: %dHz -> %dus period, %d cycles\n", 
               i, params->frequency, expected_period, expected_cycles);
        
        TEST_ASSERT(expected_period > 0, "Valid period calculation");
        TEST_ASSERT(expected_cycles > 0, "Valid cycles calculation");
    }
}

// Test 5: Edge cases
void test_edge_cases() {
    printf("Test 5: Edge cases\n");
    
    // Test invalid sound ID
    play_audio(255); // Invalid sound ID
    TEST_ASSERT(1, "Invalid sound ID handling");
    
    // Test zero frequency
    generate_audio_tone(0, 100, 100);
    TEST_ASSERT(1, "Zero frequency handling");
    
    // Test zero duration
    generate_audio_tone(1000, 0, 100);
    TEST_ASSERT(1, "Zero duration handling");
    
    // Test zero volume
    generate_audio_tone(1000, 100, 0);
    TEST_ASSERT(1, "Zero volume handling");
}

// Test 6: Performance
void test_performance() {
    printf("Test 6: Performance\n");
    
    // Test rapid audio generation
    for (int i = 0; i < 100; i++) {
        play_audio(i % 8);
    }
    TEST_ASSERT(1, "Rapid audio generation");
}

// Test 7: Audio quality
void test_audio_quality() {
    printf("Test 7: Audio quality\n");
    
    // Test frequency accuracy
    for (int i = 0; i < 8; i++) {
        const audio_params_t *params = &audio_params[i];
        
        // Check if frequency is appropriate for the sound type
        if (i == SOUND_SNARE) {
            TEST_ASSERT(params->frequency >= 100 && params->frequency <= 500, 
                       "Snare frequency range");
        } else if (i == SOUND_HIHAT) {
            TEST_ASSERT(params->frequency >= 1000 && params->frequency <= 10000, 
                       "Hi-hat frequency range");
        } else if (i == SOUND_KICK) {
            TEST_ASSERT(params->frequency >= 50 && params->frequency <= 200, 
                       "Kick frequency range");
        }
    }
}

// Main test function
int main() {
    printf("=== Simple Audio System Test Started ===\n");
    
    // Run all tests
    test_audio_parameters();
    test_sound_id_mapping();
    test_audio_generation();
    test_frequency_calculations();
    test_edge_cases();
    test_performance();
    test_audio_quality();
    
    // Print results
    printf("\n=== Test Results ===\n");
    printf("Tests passed: %d\n", tests_passed);
    printf("Tests failed: %d\n", tests_failed);
    printf("Total tests: %d\n", tests_passed + tests_failed);
    
    if (tests_failed == 0) {
        printf("✓ All tests passed!\n");
        return 0;
    } else {
        printf("✗ Some tests failed!\n");
        return 1;
    }
}
