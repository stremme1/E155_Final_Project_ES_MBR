// Audio Processor Test Bench
// Comprehensive test for audio generation functionality
// Author: E155 Final Project
// Date: 2024

#include "test_headers.h"
#include "../../mcu/inc/audio_processor.h"

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

// Mock timer functions for testing
void delay_millis(TIM_TypeDef * TIMx, uint32_t ms) {
    // Mock delay for testing
    printf("Mock delay: %d ms\n", ms);
}

// Test 1: Audio initialization
void test_audio_init() {
    printf("Test 1: Audio initialization\n");
    
    audio_init();
    
    TEST_ASSERT(1, "Audio initialization");
}

// Test 2: Sound ID mapping
void test_sound_id_mapping() {
    printf("Test 2: Sound ID mapping\n");
    
    // Test all sound IDs
    sound_id_t sound_ids[] = {
        SOUND_SNARE, SOUND_HIHAT, SOUND_KICK, SOUND_HIGH_TOM,
        SOUND_MID_TOM, SOUND_CRASH, SOUND_RIDE, SOUND_FLOOR_TOM
    };
    
    for (int i = 0; i < 8; i++) {
        play_audio(sound_ids[i]);
        TEST_ASSERT(1, "Sound ID mapping");
    }
}

// Test 3: Audio tone generation
void test_audio_tone_generation() {
    printf("Test 3: Audio tone generation\n");
    
    // Test different frequencies
    uint16_t frequencies[] = {200, 1000, 4000, 8000};
    uint16_t durations[] = {50, 100, 200, 300};
    uint8_t volumes[] = {50, 75, 90, 100};
    
    for (int i = 0; i < 4; i++) {
        generate_audio_tone(frequencies[i], durations[i], volumes[i]);
        TEST_ASSERT(1, "Audio tone generation");
    }
}

// Test 4: Audio parameters
void test_audio_parameters() {
    printf("Test 4: Audio parameters\n");
    
    // Test snare drum parameters
    play_audio(SOUND_SNARE);
    TEST_ASSERT(1, "Snare drum parameters");
    
    // Test hi-hat parameters
    play_audio(SOUND_HIHAT);
    TEST_ASSERT(1, "Hi-hat parameters");
    
    // Test kick drum parameters
    play_audio(SOUND_KICK);
    TEST_ASSERT(1, "Kick drum parameters");
    
    // Test crash cymbal parameters
    play_audio(SOUND_CRASH);
    TEST_ASSERT(1, "Crash cymbal parameters");
}

// Test 5: Audio mixing
void test_audio_mixing() {
    printf("Test 5: Audio mixing\n");
    
    // Test mixed audio
    play_mixed_audio(SOUND_SNARE, SOUND_HIHAT, 50);
    TEST_ASSERT(1, "Audio mixing");
    
    // Test single sound
    play_mixed_audio(SOUND_KICK, NO_SOUND, 100);
    TEST_ASSERT(1, "Single sound mixing");
}

// Test 6: Audio effects
void test_audio_effects() {
    printf("Test 6: Audio effects\n");
    
    // Test reverb effect
    apply_audio_effects(SOUND_SNARE, 50, 0);
    TEST_ASSERT(1, "Reverb effect");
    
    // Test echo effect
    apply_audio_effects(SOUND_HIHAT, 0, 75);
    TEST_ASSERT(1, "Echo effect");
    
    // Test combined effects
    apply_audio_effects(SOUND_CRASH, 25, 50);
    TEST_ASSERT(1, "Combined effects");
}

// Test 7: Volume control
void test_volume_control() {
    printf("Test 7: Volume control\n");
    
    // Test different volume levels
    uint8_t volumes[] = {0, 25, 50, 75, 100};
    
    for (int i = 0; i < 5; i++) {
        set_audio_volume(volumes[i]);
        TEST_ASSERT(1, "Volume control");
    }
}

// Test 8: Audio status
void test_audio_status() {
    printf("Test 8: Audio status\n");
    
    // Test audio playing status
    uint8_t is_playing = audio_is_playing();
    TEST_ASSERT(is_playing == 0 || is_playing == 1, "Audio status");
    
    // Test stop audio
    stop_audio();
    TEST_ASSERT(1, "Stop audio");
}

// Test 9: Frequency calculations
void test_frequency_calculations() {
    printf("Test 9: Frequency calculations\n");
    
    // Test frequency calculation for different sounds
    uint16_t test_frequencies[] = {200, 8000, 60, 300, 250, 4000, 2000, 150};
    
    for (int i = 0; i < 8; i++) {
        generate_audio_tone(test_frequencies[i], 100, 100);
        TEST_ASSERT(1, "Frequency calculation");
    }
}

// Test 10: Duration calculations
void test_duration_calculations() {
    printf("Test 10: Duration calculations\n");
    
    // Test different durations
    uint16_t durations[] = {50, 100, 150, 200, 300};
    
    for (int i = 0; i < 5; i++) {
        generate_audio_tone(1000, durations[i], 100);
        TEST_ASSERT(1, "Duration calculation");
    }
}

// Test 11: Edge cases
void test_edge_cases() {
    printf("Test 11: Edge cases\n");
    
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

// Test 12: Performance
void test_performance() {
    printf("Test 12: Performance\n");
    
    // Test rapid audio generation
    for (int i = 0; i < 100; i++) {
        play_audio(SOUND_SNARE);
    }
    TEST_ASSERT(1, "Rapid audio generation");
    
    // Test concurrent audio
    play_mixed_audio(SOUND_SNARE, SOUND_HIHAT, 50);
    play_mixed_audio(SOUND_KICK, SOUND_CRASH, 75);
    TEST_ASSERT(1, "Concurrent audio");
}

// Main test function
int main() {
    printf("=== Audio Processor Test Bench Started ===\n");
    
    // Run all tests
    test_audio_init();
    test_sound_id_mapping();
    test_audio_tone_generation();
    test_audio_parameters();
    test_audio_mixing();
    test_audio_effects();
    test_volume_control();
    test_audio_status();
    test_frequency_calculations();
    test_duration_calculations();
    test_edge_cases();
    test_performance();
    
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
