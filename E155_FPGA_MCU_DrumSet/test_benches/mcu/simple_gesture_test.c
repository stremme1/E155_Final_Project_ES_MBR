// Simple Gesture Recognition Test
// Tests the core gesture recognition logic without hardware dependencies
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

#define TEST_FLOAT_EQUAL(actual, expected, tolerance, message) \
    TEST_ASSERT(fabs((actual) - (expected)) < (tolerance), message)

// Function to normalize yaw values to 0-360 range (from original Arduino code)
float normalizeYaw(float yaw) {
    yaw = fmod(yaw, 360.0f);
    if (yaw < 0) {
        yaw += 360.0f;
    }
    return yaw;
}

// Gesture recognition function (simplified for testing)
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
    
    return detected_sound;
}

// Test 1: Normalize yaw function
void test_normalize_yaw() {
    printf("Test 1: Normalize yaw function\n");
    
    // Test normal case
    float result1 = normalizeYaw(45.0f);
    TEST_FLOAT_EQUAL(result1, 45.0f, 0.001f, "Normal yaw (45°)");
    
    // Test negative case
    float result2 = normalizeYaw(-45.0f);
    TEST_FLOAT_EQUAL(result2, 315.0f, 0.001f, "Negative yaw (-45°)");
    
    // Test overflow case
    float result3 = normalizeYaw(450.0f);
    TEST_FLOAT_EQUAL(result3, 90.0f, 0.001f, "Overflow yaw (450°)");
    
    // Test underflow case
    float result4 = normalizeYaw(-450.0f);
    TEST_FLOAT_EQUAL(result4, 270.0f, 0.001f, "Underflow yaw (-450°)");
}

// Test 2: Right hand gesture recognition
void test_right_hand_gestures() {
    printf("Test 2: Right hand gesture recognition\n");
    
    gesture_data_t gesture;
    
    // Test snare drum (yaw 20-120°, gyro_y < -2500)
    gesture.yaw1 = 60.0f;
    gesture.pitch1 = 0.0f;
    gesture.gyro1_y = -3000;
    gesture.yaw2 = 0.0f;
    gesture.pitch2 = 0.0f;
    gesture.gyro2_y = 0;
    gesture.gyro2_z = 0;
    
    sound_id_t result1 = recognize_gesture(gesture);
    TEST_EQUAL(result1, SOUND_SNARE, "Right hand snare drum");
    
    // Test high tom (yaw 340-20°, gyro_y < -2500, pitch <= 50)
    gesture.yaw1 = 10.0f;
    gesture.pitch1 = 30.0f;
    gesture.gyro1_y = -3000;
    
    sound_id_t result2 = recognize_gesture(gesture);
    TEST_EQUAL(result2, SOUND_HIGH_TOM, "Right hand high tom");
    
    // Test crash cymbal (yaw 340-20°, gyro_y < -2500, pitch > 50)
    gesture.yaw1 = 10.0f;
    gesture.pitch1 = 60.0f;
    gesture.gyro1_y = -3000;
    
    sound_id_t result3 = recognize_gesture(gesture);
    TEST_EQUAL(result3, SOUND_CRASH, "Right hand crash cymbal");
}

// Test 3: Left hand gesture recognition
void test_left_hand_gestures() {
    printf("Test 3: Left hand gesture recognition\n");
    
    gesture_data_t gesture;
    
    // Test hi-hat (yaw 350-100°, gyro_y < -2500, pitch > 30, gyro_z > -2000)
    gesture.yaw1 = 0.0f;
    gesture.pitch1 = 0.0f;
    gesture.gyro1_y = 0;
    gesture.yaw2 = 50.0f;
    gesture.pitch2 = 40.0f;
    gesture.gyro2_y = -3000;
    gesture.gyro2_z = -1000;
    
    sound_id_t result1 = recognize_gesture(gesture);
    TEST_EQUAL(result1, SOUND_HIHAT, "Left hand hi-hat");
    
    // Test snare drum (yaw 350-100°, gyro_y < -2500, pitch <= 30)
    gesture.yaw2 = 50.0f;
    gesture.pitch2 = 20.0f;
    gesture.gyro2_y = -3000;
    
    sound_id_t result2 = recognize_gesture(gesture);
    TEST_EQUAL(result2, SOUND_SNARE, "Left hand snare drum");
}

// Test 4: Edge cases
void test_edge_cases() {
    printf("Test 4: Edge cases\n");
    
    gesture_data_t gesture;
    
    // Test boundary conditions
    gesture.yaw1 = 20.0f; // Exactly at boundary
    gesture.pitch1 = 0.0f;
    gesture.gyro1_y = -2501; // Just below threshold
    gesture.yaw2 = 0.0f;
    gesture.pitch2 = 0.0f;
    gesture.gyro2_y = 0;
    gesture.gyro2_z = 0;
    
    sound_id_t result = recognize_gesture(gesture);
    TEST_EQUAL(result, SOUND_SNARE, "Boundary condition snare");
    
    // Test no gesture (gyro_y >= -2500)
    gesture.gyro1_y = -2000;
    result = recognize_gesture(gesture);
    TEST_EQUAL(result, NO_SOUND, "No gesture detected");
}

// Main test function
int main() {
    printf("=== Simple Gesture Recognition Test Started ===\n");
    
    // Run all tests
    test_normalize_yaw();
    test_right_hand_gestures();
    test_left_hand_gestures();
    test_edge_cases();
    
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
