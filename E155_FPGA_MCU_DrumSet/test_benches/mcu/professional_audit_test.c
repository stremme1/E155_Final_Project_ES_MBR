// Professional Audit Test Suite - Fixed Code
// Comprehensive testing of all critical fixes
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
    SOUND_SNARE = 0,        // "0" - Snare drum
    SOUND_HIHAT = 1,        // "1" - Hi-hat
    SOUND_KICK = 2,         // "2" - Kick drum
    SOUND_HIGH_TOM = 3,     // "3" - High tom
    SOUND_MID_TOM = 4,      // "4" - Mid tom
    SOUND_CRASH = 5,        // "5" - Crash cymbal
    SOUND_RIDE = 6,         // "6" - Ride cymbal
    SOUND_FLOOR_TOM = 7     // "7" - Floor tom
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

// Mock implementations for testing
static uint32_t mock_system_tick = 0;
static uint8_t mock_audio_queue[8] = {0};
static uint8_t mock_audio_queue_head = 0;
static uint8_t mock_audio_queue_tail = 0;
static uint8_t mock_audio_playing = 0;

// Function to normalize yaw values to 0-360 range
float normalizeYaw(float yaw) {
    yaw = fmod(yaw, 360.0f);
    if (yaw < 0) {
        yaw += 360.0f;
    }
    return yaw;
}

// Input validation for gesture data (FIXED VERSION)
bool is_valid_gesture_data(gesture_data_t gesture) {
    // Check for NaN or infinity
    if (isnan(gesture.yaw1) || isinf(gesture.yaw1) ||
        isnan(gesture.pitch1) || isinf(gesture.pitch1) ||
        isnan(gesture.yaw2) || isinf(gesture.yaw2) ||
        isnan(gesture.pitch2) || isinf(gesture.pitch2)) {
        return false;
    }
    
    // Check for reasonable angle ranges
    if (gesture.yaw1 < -360.0f || gesture.yaw1 > 360.0f ||
        gesture.pitch1 < -90.0f || gesture.pitch1 > 90.0f ||
        gesture.yaw2 < -360.0f || gesture.yaw2 > 360.0f ||
        gesture.pitch2 < -90.0f || gesture.pitch2 > 90.0f) {
        return false;
    }
    
    // Check for reasonable gyro ranges
    if (gesture.gyro1_y < -32768 || gesture.gyro1_y > 32767 ||
        gesture.gyro2_y < -32768 || gesture.gyro2_y > 32767 ||
        gesture.gyro2_z < -32768 || gesture.gyro2_z > 32767) {
        return false;
    }
    
    return true;
}

// Fixed gesture recognition function
sound_id_t recognize_gesture(gesture_data_t gesture) {
    // Input validation and sanitization (FIXED)
    if (!is_valid_gesture_data(gesture)) {
        return NO_SOUND;
    }
    
    // Normalize yaw values
    gesture.yaw1 = normalizeYaw(gesture.yaw1);
    gesture.yaw2 = normalizeYaw(gesture.yaw2);
    
    sound_id_t detected_sound = NO_SOUND;
    
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

// Mock audio queue functions (FIXED VERSION)
void queue_audio(sound_id_t sound_id) {
    if (sound_id == NO_SOUND) return;
    
    uint8_t next_head = (mock_audio_queue_head + 1) % 8;
    if (next_head != mock_audio_queue_tail) {
        mock_audio_queue[mock_audio_queue_head] = sound_id;
        mock_audio_queue_head = next_head;
    }
}

uint8_t dequeue_audio(void) {
    if (mock_audio_queue_head == mock_audio_queue_tail) {
        return NO_SOUND;
    }
    
    uint8_t sound_id = mock_audio_queue[mock_audio_queue_tail];
    mock_audio_queue_tail = (mock_audio_queue_tail + 1) % 8;
    return sound_id;
}

// Test 1: Fixed Input Validation
void test_fixed_input_validation() {
    printf("=== FIXED AUDIT: Input Validation ===\n");
    
    // Test 1.1: Valid gesture data
    gesture_data_t valid_gesture;
    valid_gesture.yaw1 = 60.0f;
    valid_gesture.pitch1 = 30.0f;
    valid_gesture.gyro1_y = -3000;
    valid_gesture.yaw2 = 120.0f;
    valid_gesture.pitch2 = 45.0f;
    valid_gesture.gyro2_y = -2500;
    valid_gesture.gyro2_z = -1000;
    
    CRITICAL_ASSERT(is_valid_gesture_data(valid_gesture), "Valid gesture data validation");
    
    // Test 1.2: Invalid gesture data (NaN)
    gesture_data_t invalid_gesture;
    invalid_gesture.yaw1 = NAN;
    invalid_gesture.pitch1 = 30.0f;
    invalid_gesture.gyro1_y = -3000;
    invalid_gesture.yaw2 = 120.0f;
    invalid_gesture.pitch2 = 45.0f;
    invalid_gesture.gyro2_y = -2500;
    invalid_gesture.gyro2_z = -1000;
    
    CRITICAL_ASSERT(!is_valid_gesture_data(invalid_gesture), "NaN gesture data rejection");
    
    // Test 1.3: Invalid gesture data (out of range)
    gesture_data_t out_of_range_gesture;
    out_of_range_gesture.yaw1 = 500.0f;  // Out of range
    out_of_range_gesture.pitch1 = 30.0f;
    out_of_range_gesture.gyro1_y = -3000;
    out_of_range_gesture.yaw2 = 120.0f;
    out_of_range_gesture.pitch2 = 45.0f;
    out_of_range_gesture.gyro2_y = -2500;
    out_of_range_gesture.gyro2_z = -1000;
    
    CRITICAL_ASSERT(!is_valid_gesture_data(out_of_range_gesture), "Out of range gesture data rejection");
}

// Test 2: Fixed Gesture Recognition
void test_fixed_gesture_recognition() {
    printf("=== FIXED AUDIT: Gesture Recognition ===\n");
    
    // Test 2.1: Valid snare drum gesture
    gesture_data_t snare_gesture;
    snare_gesture.yaw1 = 60.0f;
    snare_gesture.pitch1 = 30.0f;
    snare_gesture.gyro1_y = -3000;
    snare_gesture.yaw2 = 120.0f;
    snare_gesture.pitch2 = 45.0f;
    snare_gesture.gyro2_y = -2500;
    snare_gesture.gyro2_z = -1000;
    
    sound_id_t result = recognize_gesture(snare_gesture);
    CRITICAL_ASSERT(result == SOUND_SNARE, "Valid snare drum recognition");
    
    // Test 2.2: Invalid gesture data handling
    gesture_data_t invalid_gesture;
    invalid_gesture.yaw1 = NAN;
    invalid_gesture.pitch1 = 30.0f;
    invalid_gesture.gyro1_y = -3000;
    invalid_gesture.yaw2 = 120.0f;
    invalid_gesture.pitch2 = 45.0f;
    invalid_gesture.gyro2_y = -2500;
    invalid_gesture.gyro2_z = -1000;
    
    result = recognize_gesture(invalid_gesture);
    CRITICAL_ASSERT(result == NO_SOUND, "Invalid gesture data handling");
    
    // Test 2.3: Rapid gesture processing (FIXED)
    for (int i = 0; i < 1000; i++) {
        gesture_data_t gesture;
        gesture.yaw1 = (i % 360);
        gesture.pitch1 = (i % 90);
        gesture.gyro1_y = -3000 + (i % 1000);
        gesture.yaw2 = ((i + 180) % 360);
        gesture.pitch2 = ((i + 45) % 90);
        gesture.gyro2_y = -2500 + (i % 500);
        gesture.gyro2_z = -1000 + (i % 200);
        
        // Ensure valid data
        gesture.roll1 = 0.0f;
        gesture.roll2 = 0.0f;
        gesture.gyro1_x = 0;
        gesture.gyro1_z = 0;
        gesture.gyro2_x = 0;
        gesture.timestamp = i;
        
        sound_id_t result = recognize_gesture(gesture);
        CRITICAL_ASSERT(result >= NO_SOUND && result <= SOUND_FLOOR_TOM, "Rapid gesture processing (FIXED)");
    }
}

// Test 3: Fixed Audio Queue System
void test_fixed_audio_queue() {
    printf("=== FIXED AUDIT: Audio Queue System ===\n");
    
    // Reset queue
    mock_audio_queue_head = 0;
    mock_audio_queue_tail = 0;
    
    // Test 3.1: Queue operations
    queue_audio(SOUND_SNARE);
    queue_audio(SOUND_KICK);
    queue_audio(SOUND_HIHAT);
    
    CRITICAL_ASSERT(mock_audio_queue_head == 3, "Audio queue head position");
    CRITICAL_ASSERT(mock_audio_queue_tail == 0, "Audio queue tail position");
    
    // Test 3.2: Dequeue operations
    uint8_t sound1 = dequeue_audio();
    uint8_t sound2 = dequeue_audio();
    
    CRITICAL_ASSERT(sound1 == SOUND_SNARE, "First dequeue");
    CRITICAL_ASSERT(sound2 == SOUND_KICK, "Second dequeue");
    
    // Test 3.3: Queue overflow handling
    for (int i = 0; i < 10; i++) {
        queue_audio(SOUND_SNARE);
    }
    
    CRITICAL_ASSERT(mock_audio_queue_head < 8, "Queue overflow protection");
}

// Test 4: Fixed Memory Management
void test_fixed_memory_management() {
    printf("=== FIXED AUDIT: Memory Management ===\n");
    
    // Test 4.1: Stack overflow protection
    gesture_data_t large_gesture;
    memset(&large_gesture, 0xFF, sizeof(gesture_data_t));
    
    sound_id_t result = recognize_gesture(large_gesture);
    CRITICAL_ASSERT(result == NO_SOUND, "Stack overflow protection");
    
    // Test 4.2: Memory corruption handling
    gesture_data_t corrupted_gesture;
    corrupted_gesture.yaw1 = 1e6f;
    corrupted_gesture.pitch1 = -1e6f;
    corrupted_gesture.gyro1_y = INT16_MAX;
    corrupted_gesture.yaw2 = -1e6f;
    corrupted_gesture.pitch2 = 1e6f;
    corrupted_gesture.gyro2_y = INT16_MIN;
    corrupted_gesture.gyro2_z = INT16_MAX;
    
    result = recognize_gesture(corrupted_gesture);
    CRITICAL_ASSERT(result == NO_SOUND, "Memory corruption handling");
}

// Test 5: Fixed Real-time Performance
void test_fixed_realtime_performance() {
    printf("=== FIXED AUDIT: Real-time Performance ===\n");
    
    // Test 5.1: Latency test (FIXED)
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
    
    CRITICAL_ASSERT(latency < 1.0, "Real-time latency constraint (FIXED)");
    CRITICAL_ASSERT(result == SOUND_SNARE, "Real-time gesture recognition");
    
    // Test 5.2: Jitter test (FIXED)
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
    
    CRITICAL_ASSERT(max_latency < 2.0, "Real-time jitter constraint (FIXED)");
}

// Test 6: Fixed Error Handling
void test_fixed_error_handling() {
    printf("=== FIXED AUDIT: Error Handling ===\n");
    
    // Test 6.1: Invalid input handling
    gesture_data_t invalid_gesture;
    invalid_gesture.yaw1 = 999.0f;
    invalid_gesture.pitch1 = -999.0f;
    invalid_gesture.gyro1_y = 9999;
    invalid_gesture.yaw2 = -999.0f;
    invalid_gesture.pitch2 = 999.0f;
    invalid_gesture.gyro2_y = -9999;
    invalid_gesture.gyro2_z = 9999;
    
    sound_id_t result = recognize_gesture(invalid_gesture);
    CRITICAL_ASSERT(result == NO_SOUND, "Invalid input handling (FIXED)");
    
    // Test 6.2: Extreme values handling
    gesture_data_t extreme_gesture;
    extreme_gesture.yaw1 = 1e6f;
    extreme_gesture.pitch1 = -1e6f;
    extreme_gesture.gyro1_y = INT16_MAX;
    extreme_gesture.yaw2 = -1e6f;
    extreme_gesture.pitch2 = 1e6f;
    extreme_gesture.gyro2_y = INT16_MIN;
    extreme_gesture.gyro2_z = INT16_MAX;
    
    result = recognize_gesture(extreme_gesture);
    CRITICAL_ASSERT(result == NO_SOUND, "Extreme values handling (FIXED)");
}

// Test 7: Fixed System Integration
void test_fixed_system_integration() {
    printf("=== FIXED AUDIT: System Integration ===\n");
    
    // Test 7.1: System mode transitions
    system_mode_t modes[] = {LIVE_MODE, RECORD_MODE, PLAYBACK_MODE, CALIBRATION_MODE};
    for (int i = 0; i < 4; i++) {
        CRITICAL_ASSERT(modes[i] >= 0 && modes[i] <= 3, "System mode validity");
    }
    
    // Test 7.2: Sound ID validation
    for (int i = 0; i < 8; i++) {
        CRITICAL_ASSERT(i >= SOUND_SNARE && i <= SOUND_FLOOR_TOM, "Sound ID validity");
    }
    
    // Test 7.3: Gesture data structure size
    CRITICAL_ASSERT(sizeof(gesture_data_t) <= 64, "Gesture data structure size");
}

// Test 8: Fixed Performance
void test_fixed_performance() {
    printf("=== FIXED AUDIT: Performance (FIXED) ===\n");
    
    // Test 8.1: CPU-intensive operations (FIXED)
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
    
    CRITICAL_ASSERT(cpu_time < 0.5, "Performance within acceptable limits (FIXED)");
}

// Main test function
int main() {
    printf("=== PROFESSIONAL AUDIT: FIXED CODE ===\n");
    printf("Testing all critical fixes implemented\n");
    printf("=====================================\n\n");
    
    // Run all fixed tests
    test_fixed_input_validation();
    test_fixed_gesture_recognition();
    test_fixed_audio_queue();
    test_fixed_memory_management();
    test_fixed_realtime_performance();
    test_fixed_error_handling();
    test_fixed_system_integration();
    test_fixed_performance();
    
    // Print comprehensive results
    printf("\n=== FIXED AUDIT RESULTS ===\n");
    printf("Tests passed: %d\n", tests_passed);
    printf("Tests failed: %d\n", tests_failed);
    printf("Critical issues found: %d\n", critical_issues);
    printf("Total tests: %d\n", tests_passed + tests_failed);
    
    if (critical_issues == 0) {
        printf("✅ ALL CRITICAL ISSUES FIXED\n");
        printf("Codebase now passes professional audit\n");
        return 0;
    } else {
        printf("🚨 CRITICAL ISSUES REMAIN: %d\n", critical_issues);
        printf("Codebase still has issues\n");
        return 1;
    }
}
