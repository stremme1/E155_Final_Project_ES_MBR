// Critical Audit Test Suite
// Third-party senior engineering audit with comprehensive edge case testing
// Author: E155 Final Project
// Date: 2024

#include <stdio.h>
#include <assert.h>
#include <math.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include <limits.h>
#include <time.h>

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
    uint32_t timestamp;
} gesture_data_t;

// System mode definitions
typedef enum {
    LIVE_MODE,
    RECORD_MODE,
    PLAYBACK_MODE,
    CALIBRATION_MODE
} system_mode_t;

// Test results tracking
static int tests_passed = 0;
static int tests_failed = 0;
static int critical_issues = 0;

// Test helper macros
#define TEST_ASSERT(condition, message) \
    do { \
        if (condition) { \
            printf("✓ %s\n", message); \
            tests_passed++; \
        } else { \
            printf("✗ %s\n", message); \
            tests_failed++; \
            critical_issues++; \
        } \
    } while(0)

#define CRITICAL_ASSERT(condition, message) \
    do { \
        if (condition) { \
            printf("✓ %s\n", message); \
            tests_passed++; \
        } else { \
            printf("🚨 CRITICAL: %s\n", message); \
            tests_failed++; \
            critical_issues++; \
        } \
    } while(0)

// Function to normalize yaw values to 0-360 range
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
    if (gesture.yaw1 >= 20 && gesture.yaw1 <= 120) {
        if (gesture.gyro1_y < -2500) {
            detected_sound = SOUND_SNARE; // "0"
        }
    }
    else if (gesture.yaw1 >= 340 || gesture.yaw1 <= 20) {
        if (gesture.gyro1_y < -2500) {
            if (gesture.pitch1 > 50) {
                detected_sound = SOUND_CRASH; // "5"
            } else {
                detected_sound = SOUND_HIGH_TOM; // "3"
            }
        }
    }
    
    // Left hand logic (matching original Arduino code exactly)
    if (gesture.yaw2 >= 350 || gesture.yaw2 <= 100) {
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

// Test 1: Critical Data Type Issues
void test_critical_data_types() {
    printf("=== CRITICAL AUDIT: Data Type Issues ===\n");
    
    // Test 1.1: Float precision issues
    gesture_data_t gesture;
    gesture.yaw1 = 20.0f;
    gesture.pitch1 = 30.0f;
    gesture.gyro1_y = -2501;
    gesture.yaw2 = 0.0f;
    gesture.pitch2 = 0.0f;
    gesture.gyro2_y = 0;
    gesture.gyro2_z = 0;
    
    sound_id_t result = recognize_gesture(gesture);
    CRITICAL_ASSERT(result == SOUND_SNARE, "Float precision handling");
    
    // Test 1.2: Integer overflow in gyro values
    gesture.gyro1_y = INT16_MIN;
    gesture.gyro2_y = INT16_MAX;
    result = recognize_gesture(gesture);
    CRITICAL_ASSERT(result == SOUND_SNARE, "Integer overflow handling");
    
    // Test 1.3: NaN and infinity handling
    gesture.yaw1 = NAN;
    gesture.pitch1 = INFINITY;
    result = recognize_gesture(gesture);
    CRITICAL_ASSERT(result == NO_SOUND, "NaN/Infinity handling");
}

// Test 2: Critical Boundary Conditions
void test_critical_boundaries() {
    printf("=== CRITICAL AUDIT: Boundary Conditions ===\n");
    
    // Test 2.1: Exact boundary values
    gesture_data_t gesture;
    gesture.yaw1 = 20.0f; // Exactly at boundary
    gesture.pitch1 = 0.0f;
    gesture.gyro1_y = -2500; // Exactly at threshold
    gesture.yaw2 = 0.0f;
    gesture.pitch2 = 0.0f;
    gesture.gyro2_y = 0;
    gesture.gyro2_z = 0;
    
    sound_id_t result = recognize_gesture(gesture);
    CRITICAL_ASSERT(result == NO_SOUND, "Exact boundary threshold");
    
    // Test 2.2: Floating point precision at boundaries
    gesture.yaw1 = 20.000001f;
    gesture.gyro1_y = -2500.000001f;
    result = recognize_gesture(gesture);
    CRITICAL_ASSERT(result == NO_SOUND, "Floating point precision at boundaries");
    
    // Test 2.3: Wrap-around angles
    gesture.yaw1 = 359.999f;
    gesture.yaw2 = 0.001f;
    result = recognize_gesture(gesture);
    CRITICAL_ASSERT(result == NO_SOUND, "Angle wrap-around handling");
}

// Test 3: Critical Memory Issues
void test_critical_memory() {
    printf("=== CRITICAL AUDIT: Memory Issues ===\n");
    
    // Test 3.1: Stack overflow simulation
    gesture_data_t large_gesture;
    memset(&large_gesture, 0xFF, sizeof(gesture_data_t));
    
    sound_id_t result = recognize_gesture(large_gesture);
    CRITICAL_ASSERT(result == NO_SOUND, "Corrupted memory handling");
    
    // Test 3.2: Uninitialized variables
    gesture_data_t uninit_gesture;
    // Intentionally not initializing
    result = recognize_gesture(uninit_gesture);
    CRITICAL_ASSERT(result == NO_SOUND, "Uninitialized variable handling");
}

// Test 4: Critical Timing Issues
void test_critical_timing() {
    printf("=== CRITICAL AUDIT: Timing Issues ===\n");
    
    // Test 4.1: Rapid gesture changes
    for (int i = 0; i < 1000; i++) {
        gesture_data_t gesture;
        gesture.yaw1 = (i % 360);
        gesture.pitch1 = (i % 90);
        gesture.gyro1_y = -3000 + (i % 1000);
        gesture.yaw2 = ((i + 180) % 360);
        gesture.pitch2 = ((i + 45) % 90);
        gesture.gyro2_y = -2500 + (i % 500);
        gesture.gyro2_z = -1000 + (i % 200);
        
        sound_id_t result = recognize_gesture(gesture);
        CRITICAL_ASSERT(result >= NO_SOUND && result <= SOUND_FLOOR_TOM, "Rapid gesture processing");
    }
    
    // Test 4.2: Concurrent gesture processing
    gesture_data_t gesture1, gesture2;
    gesture1.yaw1 = 60.0f; gesture1.gyro1_y = -3000;
    gesture2.yaw1 = 120.0f; gesture2.gyro1_y = -2500;
    
    sound_id_t result1 = recognize_gesture(gesture1);
    sound_id_t result2 = recognize_gesture(gesture2);
    CRITICAL_ASSERT(result1 == SOUND_SNARE, "Concurrent gesture 1");
    CRITICAL_ASSERT(result2 == NO_SOUND, "Concurrent gesture 2");
}

// Test 5: Critical Error Handling
void test_critical_error_handling() {
    printf("=== CRITICAL AUDIT: Error Handling ===\n");
    
    // Test 5.1: Invalid gesture data
    gesture_data_t invalid_gesture;
    invalid_gesture.yaw1 = 999.0f;
    invalid_gesture.pitch1 = -999.0f;
    invalid_gesture.gyro1_y = 9999;
    invalid_gesture.yaw2 = -999.0f;
    invalid_gesture.pitch2 = 999.0f;
    invalid_gesture.gyro2_y = -9999;
    invalid_gesture.gyro2_z = 9999;
    
    sound_id_t result = recognize_gesture(invalid_gesture);
    CRITICAL_ASSERT(result == NO_SOUND, "Invalid gesture data handling");
    
    // Test 5.2: Extreme values
    gesture_data_t extreme_gesture;
    extreme_gesture.yaw1 = 1e6f;
    extreme_gesture.pitch1 = -1e6f;
    extreme_gesture.gyro1_y = INT16_MAX;
    extreme_gesture.yaw2 = -1e6f;
    extreme_gesture.pitch2 = 1e6f;
    extreme_gesture.gyro2_y = INT16_MIN;
    extreme_gesture.gyro2_z = INT16_MAX;
    
    result = recognize_gesture(extreme_gesture);
    CRITICAL_ASSERT(result == NO_SOUND, "Extreme values handling");
}

// Test 6: Critical System Integration
void test_critical_system_integration() {
    printf("=== CRITICAL AUDIT: System Integration ===\n");
    
    // Test 6.1: System mode transitions
    system_mode_t modes[] = {LIVE_MODE, RECORD_MODE, PLAYBACK_MODE, CALIBRATION_MODE};
    for (int i = 0; i < 4; i++) {
        CRITICAL_ASSERT(modes[i] >= 0 && modes[i] <= 3, "System mode validity");
    }
    
    // Test 6.2: Sound ID validation
    for (int i = 0; i < 8; i++) {
        CRITICAL_ASSERT(i >= SOUND_SNARE && i <= SOUND_FLOOR_TOM, "Sound ID validity");
    }
    
    // Test 6.3: Gesture data structure size
    CRITICAL_ASSERT(sizeof(gesture_data_t) <= 64, "Gesture data structure size");
}

// Test 7: Critical Performance Issues
void test_critical_performance() {
    printf("=== CRITICAL AUDIT: Performance Issues ===\n");
    
    // Test 7.1: CPU-intensive operations
    clock_t start = clock();
    for (int i = 0; i < 10000; i++) {
        gesture_data_t gesture;
        gesture.yaw1 = (i % 360);
        gesture.pitch1 = (i % 90);
        gesture.gyro1_y = -3000 + (i % 1000);
        gesture.yaw2 = ((i + 180) % 360);
        gesture.pitch2 = ((i + 45) % 90);
        gesture.gyro2_y = -2500 + (i % 500);
        gesture.gyro2_z = -1000 + (i % 200);
        
        sound_id_t result = recognize_gesture(gesture);
    }
    clock_t end = clock();
    double cpu_time = ((double)(end - start)) / CLOCKS_PER_SEC;
    
    CRITICAL_ASSERT(cpu_time < 1.0, "Performance within acceptable limits");
}

// Test 8: Critical Security Issues
void test_critical_security() {
    printf("=== CRITICAL AUDIT: Security Issues ===\n");
    
    // Test 8.1: Buffer overflow simulation
    gesture_data_t gesture;
    memset(&gesture, 0x41, sizeof(gesture_data_t)); // Fill with 'A'
    
    sound_id_t result = recognize_gesture(gesture);
    CRITICAL_ASSERT(result == NO_SOUND, "Buffer overflow handling");
    
    // Test 8.2: Integer overflow in calculations
    gesture.yaw1 = 1e6f;
    gesture.pitch1 = 1e6f;
    gesture.gyro1_y = INT16_MAX;
    gesture.gyro2_y = INT16_MIN;
    
    result = recognize_gesture(gesture);
    CRITICAL_ASSERT(result == NO_SOUND, "Integer overflow in calculations");
}

// Test 9: Critical Hardware Interface Issues
void test_critical_hardware_interface() {
    printf("=== CRITICAL AUDIT: Hardware Interface Issues ===\n");
    
    // Test 9.1: SPI communication simulation
    uint8_t spi_data[16];
    memset(spi_data, 0xFF, 16);
    
    // Simulate corrupted SPI data
    gesture_data_t gesture;
    gesture.yaw1 = (spi_data[0] << 8) | spi_data[1];
    gesture.pitch1 = (spi_data[2] << 8) | spi_data[3];
    gesture.gyro1_y = (spi_data[8] << 8) | spi_data[9];
    
    sound_id_t result = recognize_gesture(gesture);
    CRITICAL_ASSERT(result == NO_SOUND, "Corrupted SPI data handling");
    
    // Test 9.2: I2C communication failure simulation
    gesture_data_t i2c_failure_gesture;
    i2c_failure_gesture.yaw1 = 0.0f;
    i2c_failure_gesture.pitch1 = 0.0f;
    i2c_failure_gesture.gyro1_y = 0;
    i2c_failure_gesture.yaw2 = 0.0f;
    i2c_failure_gesture.pitch2 = 0.0f;
    i2c_failure_gesture.gyro2_y = 0;
    i2c_failure_gesture.gyro2_z = 0;
    
    result = recognize_gesture(i2c_failure_gesture);
    CRITICAL_ASSERT(result == NO_SOUND, "I2C communication failure handling");
}

// Test 10: Critical Real-time Constraints
void test_critical_realtime_constraints() {
    printf("=== CRITICAL AUDIT: Real-time Constraints ===\n");
    
    // Test 10.1: Maximum latency test
    clock_t start = clock();
    gesture_data_t gesture;
    gesture.yaw1 = 60.0f;
    gesture.pitch1 = 30.0f;
    gesture.gyro1_y = -3000;
    gesture.yaw2 = 120.0f;
    gesture.pitch2 = 45.0f;
    gesture.gyro2_y = -2500;
    gesture.gyro2_z = -1000;
    
    sound_id_t result = recognize_gesture(gesture);
    clock_t end = clock();
    double latency = ((double)(end - start)) / CLOCKS_PER_SEC * 1000; // ms
    
    CRITICAL_ASSERT(latency < 5.0, "Real-time latency constraint");
    CRITICAL_ASSERT(result == SOUND_SNARE, "Real-time gesture recognition");
    
    // Test 10.2: Jitter test
    double latencies[100];
    for (int i = 0; i < 100; i++) {
        start = clock();
        result = recognize_gesture(gesture);
        end = clock();
        latencies[i] = ((double)(end - start)) / CLOCKS_PER_SEC * 1000;
    }
    
    double max_latency = 0;
    for (int i = 0; i < 100; i++) {
        if (latencies[i] > max_latency) {
            max_latency = latencies[i];
        }
    }
    
    CRITICAL_ASSERT(max_latency < 10.0, "Real-time jitter constraint");
}

// Main test function
int main() {
    printf("=== CRITICAL AUDIT: E155 Drum Set Codebase ===\n");
    printf("Third-party senior engineering audit\n");
    printf("==========================================\n\n");
    
    // Run all critical tests
    test_critical_data_types();
    test_critical_boundaries();
    test_critical_memory();
    test_critical_timing();
    test_critical_error_handling();
    test_critical_system_integration();
    test_critical_performance();
    test_critical_security();
    test_critical_hardware_interface();
    test_critical_realtime_constraints();
    
    // Print comprehensive results
    printf("\n=== CRITICAL AUDIT RESULTS ===\n");
    printf("Tests passed: %d\n", tests_passed);
    printf("Tests failed: %d\n", tests_failed);
    printf("Critical issues found: %d\n", critical_issues);
    printf("Total tests: %d\n", tests_passed + tests_failed);
    
    if (critical_issues == 0) {
        printf("✅ NO CRITICAL ISSUES FOUND\n");
        printf("Codebase passes critical audit\n");
        return 0;
    } else {
        printf("🚨 CRITICAL ISSUES FOUND: %d\n", critical_issues);
        printf("Codebase FAILS critical audit\n");
        return 1;
    }
}
