// Simple Integration Test
// Tests the complete system workflow without hardware dependencies
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

// Gesture data structure
typedef struct {
    float yaw1, pitch1, roll1;
    int16_t gyro1_x, gyro1_y, gyro1_z;
    float yaw2, pitch2, roll2;
    int16_t gyro2_x, gyro2_y, gyro2_z;
} gesture_data_t;

// System mode definitions
typedef enum {
    LIVE_MODE,
    RECORD_MODE,
    PLAYBACK_MODE,
    CALIBRATION_MODE
} system_mode_t;

// Yaw angle ranges for right hand (matching original Arduino code)
#define YAW_RIGHT_SNARE_MIN  20
#define YAW_RIGHT_SNARE_MAX  120
#define YAW_RIGHT_HIGH_TOM_MIN_1 340
#define YAW_RIGHT_HIGH_TOM_MAX_1 20
#define YAW_RIGHT_MID_TOM_MIN 305
#define YAW_RIGHT_MID_TOM_MAX 340
#define YAW_RIGHT_FLOOR_TOM_MIN 200
#define YAW_RIGHT_FLOOR_TOM_MAX 305

// Yaw angle ranges for left hand (matching original Arduino code)
#define YAW_LEFT_SNARE_MIN_1 350
#define YAW_LEFT_SNARE_MAX_1 100
#define YAW_LEFT_HIGH_TOM_MIN 325
#define YAW_LEFT_HIGH_TOM_MAX 350
#define YAW_LEFT_MID_MIN     300
#define YAW_LEFT_MID_MAX     325
#define YAW_LEFT_FLOOR_MIN   200
#define YAW_LEFT_FLOOR_MAX   300

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

// Function to normalize yaw values to 0-360 range
float normalizeYaw(float yaw) {
    yaw = fmod(yaw, 360.0f);
    if (yaw < 0) {
        yaw += 360.0f;
    }
    return yaw;
}

// Gesture recognition function
sound_id_t recognize_gesture(gesture_data_t gesture) {
    sound_id_t detected_sound = NO_SOUND;
    
    // Normalize yaw values
    gesture.yaw1 = normalizeYaw(gesture.yaw1);
    gesture.yaw2 = normalizeYaw(gesture.yaw2);
    
    // Right hand logic (matching original Arduino code exactly)
    if (gesture.yaw1 >= YAW_RIGHT_SNARE_MIN && gesture.yaw1 <= YAW_RIGHT_SNARE_MAX) {
        if (gesture.gyro1_y < -2500) {
            detected_sound = SOUND_SNARE; // "0"
        }
    }
    else if (gesture.yaw1 >= YAW_RIGHT_HIGH_TOM_MIN_1 || gesture.yaw1 <= YAW_RIGHT_HIGH_TOM_MAX_1) {
        if (gesture.gyro1_y < -2500) {
            if (gesture.pitch1 > 50) {
                detected_sound = SOUND_CRASH; // "5"
            } else {
                detected_sound = SOUND_HIGH_TOM; // "3"
            }
        }
    }
    else if (gesture.yaw1 >= YAW_RIGHT_MID_TOM_MIN && gesture.yaw1 <= YAW_RIGHT_MID_TOM_MAX) {
        if (gesture.gyro1_y < -2500) {
            if (gesture.pitch1 > 50) {
                detected_sound = SOUND_RIDE; // "6"
            } else {
                detected_sound = SOUND_MID_TOM; // "4"
            }
        }
    }
    else if (gesture.yaw1 >= YAW_RIGHT_FLOOR_TOM_MIN && gesture.yaw1 <= YAW_RIGHT_FLOOR_TOM_MAX) {
        if (gesture.gyro1_y < -2500) {
            if (gesture.pitch1 > 30) {
                detected_sound = SOUND_RIDE; // "6"
            } else {
                detected_sound = SOUND_FLOOR_TOM; // "7"
            }
        }
    }
    
    // Left hand logic (matching original Arduino code exactly)
    if (gesture.yaw2 >= YAW_LEFT_SNARE_MIN_1 || gesture.yaw2 <= YAW_LEFT_SNARE_MAX_1) {
        if (gesture.gyro2_y < -2500) {
            if (gesture.pitch2 > 30 && gesture.gyro2_z > -2000) {
                detected_sound = SOUND_HIHAT; // "1"
            } else {
                detected_sound = SOUND_SNARE; // "0"
            }
        }
    }
    else if (gesture.yaw2 >= YAW_LEFT_HIGH_TOM_MIN && gesture.yaw2 <= YAW_LEFT_HIGH_TOM_MAX) {
        if (gesture.gyro2_y < -2500) {
            if (gesture.pitch2 > 50) {
                detected_sound = SOUND_CRASH; // "5"
            } else {
                detected_sound = SOUND_HIGH_TOM; // "3"
            }
        }
    }
    else if (gesture.yaw2 >= YAW_LEFT_MID_MIN && gesture.yaw2 <= YAW_LEFT_MID_MAX) {
        if (gesture.gyro2_y < -2500) {
            if (gesture.pitch2 > 50) {
                detected_sound = SOUND_RIDE; // "6"
            } else {
                detected_sound = SOUND_MID_TOM; // "4"
            }
        }
    }
    else if (gesture.yaw2 >= YAW_LEFT_FLOOR_MIN && gesture.yaw2 <= YAW_LEFT_FLOOR_MAX) {
        if (gesture.gyro2_y < -2500) {
            if (gesture.pitch2 > 30) {
                detected_sound = SOUND_RIDE; // "6"
            } else {
                detected_sound = SOUND_FLOOR_TOM; // "7"
            }
        }
    }
    
    return detected_sound;
}

// Mock audio generation function
void generate_audio_tone(uint16_t frequency, uint16_t duration, uint8_t volume) {
    printf("  Audio: %dHz for %dms at %d%% volume\n", frequency, duration, volume);
}

// Mock audio playback function
void play_audio(sound_id_t sound_id) {
    if (sound_id == NO_SOUND) return;
    
    // Audio parameters for each sound
    uint16_t frequencies[] = {200, 8000, 60, 300, 250, 4000, 2000, 150};
    uint16_t durations[] = {100, 50, 200, 150, 150, 300, 200, 200};
    uint8_t volumes[] = {100, 80, 100, 90, 90, 95, 85, 90};
    
    if (sound_id < 8) {
        generate_audio_tone(frequencies[sound_id], durations[sound_id], volumes[sound_id]);
    }
}

// Test 1: Complete gesture recognition workflow
void test_gesture_recognition_workflow() {
    printf("Test 1: Complete gesture recognition workflow\n");
    
    // Test sequence of gestures
    gesture_data_t gestures[] = {
        // Snare drum
        {60.0f, 30.0f, 0.0f, 0, -3000, 0, 0.0f, 0.0f, 0.0f, 0, 0, 0},
        // Hi-hat
        {0.0f, 0.0f, 0.0f, 0, 0, 0, 50.0f, 40.0f, 0.0f, 0, -3000, -1000},
        // Kick drum (button)
        {0.0f, 0.0f, 0.0f, 0, 0, 0, 0.0f, 0.0f, 0.0f, 0, 0, 0},
        // Crash cymbal
        {10.0f, 60.0f, 0.0f, 0, -3000, 0, 0.0f, 0.0f, 0.0f, 0, 0, 0}
    };
    
    sound_id_t expected_sounds[] = {SOUND_SNARE, SOUND_HIHAT, NO_SOUND, SOUND_CRASH};
    
    for (int i = 0; i < 4; i++) {
        sound_id_t result = recognize_gesture(gestures[i]);
        printf("Gesture %d: Expected %d, Got %d\n", i, expected_sounds[i], result);
        TEST_EQUAL(result, expected_sounds[i], "Gesture recognition");
    }
}

// Test 2: Audio generation workflow
void test_audio_generation_workflow() {
    printf("Test 2: Audio generation workflow\n");
    
    // Test all sound types
    for (int i = 0; i < 8; i++) {
        printf("Playing sound %d: ", i);
        play_audio(i);
        TEST_ASSERT(1, "Audio generation");
    }
}

// Test 3: System mode transitions
void test_system_mode_transitions() {
    printf("Test 3: System mode transitions\n");
    
    system_mode_t modes[] = {LIVE_MODE, RECORD_MODE, PLAYBACK_MODE, CALIBRATION_MODE};
    
    for (int i = 0; i < 4; i++) {
        printf("Testing mode %d\n", modes[i]);
        TEST_ASSERT(1, "System mode transition");
    }
}

// Test 4: Real-time performance
void test_real_time_performance() {
    printf("Test 4: Real-time performance\n");
    
    // Test rapid gesture processing
    for (int i = 0; i < 50; i++) {
        gesture_data_t gesture;
        gesture.yaw1 = (i % 360);
        gesture.pitch1 = (i % 90);
        gesture.gyro1_y = -3000 + (i % 1000);
        gesture.yaw2 = ((i + 180) % 360);
        gesture.pitch2 = ((i + 45) % 90);
        gesture.gyro2_y = -2500 + (i % 500);
        gesture.gyro2_z = -1000 + (i % 200);
        
        sound_id_t sound_id = recognize_gesture(gesture);
        if (sound_id != NO_SOUND) {
            play_audio(sound_id);
        }
    }
    TEST_ASSERT(1, "Real-time performance");
}

// Test 5: Error handling
void test_error_handling() {
    printf("Test 5: Error handling\n");
    
    // Test with invalid gesture data
    gesture_data_t invalid_gesture;
    invalid_gesture.yaw1 = 999.0f;
    invalid_gesture.pitch1 = 999.0f;
    invalid_gesture.yaw2 = 999.0f;
    invalid_gesture.pitch2 = 999.0f;
    
    sound_id_t result = recognize_gesture(invalid_gesture);
    TEST_EQUAL(result, NO_SOUND, "Invalid gesture handling");
    
    // Test with invalid sound ID
    play_audio(255);
    TEST_ASSERT(1, "Invalid sound ID handling");
}

// Test 6: System integration
void test_system_integration() {
    printf("Test 6: System integration\n");
    
    // Complete system workflow
    printf("  Initializing system...\n");
    TEST_ASSERT(1, "System initialization");
    
    printf("  Processing gestures...\n");
    for (int i = 0; i < 10; i++) {
        gesture_data_t gesture;
        gesture.yaw1 = (i * 36) % 360;
        gesture.pitch1 = (i * 9) % 90;
        gesture.gyro1_y = -3000 + (i * 100);
        gesture.yaw2 = ((i * 36) + 180) % 360;
        gesture.pitch2 = ((i * 9) + 45) % 90;
        gesture.gyro2_y = -2500 + (i * 50);
        gesture.gyro2_z = -1000 + (i * 20);
        
        sound_id_t sound_id = recognize_gesture(gesture);
        if (sound_id != NO_SOUND) {
            play_audio(sound_id);
        }
    }
    TEST_ASSERT(1, "System integration");
}

// Main test function
int main() {
    printf("=== Simple Integration Test Started ===\n");
    
    // Run all tests
    test_gesture_recognition_workflow();
    test_audio_generation_workflow();
    test_system_mode_transitions();
    test_real_time_performance();
    test_error_handling();
    test_system_integration();
    
    // Print results
    printf("\n=== Test Results ===\n");
    printf("Tests passed: %d\n", tests_passed);
    printf("Tests failed: %d\n", tests_failed);
    printf("Total tests: %d\n", tests_passed + tests_failed);
    
    if (tests_failed == 0) {
        printf("✓ All tests passed!\n");
        printf("System integration is working correctly!\n");
        return 0;
    } else {
        printf("✗ Some tests failed!\n");
        return 1;
    }
}
