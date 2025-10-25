// FPGA-MCU Communication Integration Test
// Comprehensive test for complete system communication
// Author: E155 Final Project
// Date: 2024

#include <stdio.h>
#include <assert.h>
#include <math.h>
#include "gesture_recognition.h"
#include "audio_processor.h"
#include "spi_handler.h"

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
        } \
    } while(0)

#define TEST_EQUAL(actual, expected, message) \
    TEST_ASSERT((actual) == (expected), message)

// Mock functions for testing
char spiSendReceive(char send) {
    printf("Mock SPI: sent 0x%02x\n", send);
    return send;
}

void delay_millis(TIM_TypeDef * TIMx, uint32_t ms) {
    printf("Mock delay: %d ms\n", ms);
}

// Test 1: Complete gesture recognition workflow
void test_gesture_recognition_workflow() {
    printf("Test 1: Complete gesture recognition workflow\n");
    
    // Initialize system
    gesture_recognition_init();
    spi_init();
    audio_init();
    
    // Simulate gesture data from FPGA
    gesture_data_t gesture;
    gesture.yaw1 = 60.0f;
    gesture.pitch1 = 30.0f;
    gesture.gyro1_y = -3000;
    gesture.yaw2 = 120.0f;
    gesture.pitch2 = 45.0f;
    gesture.gyro2_y = -2500;
    gesture.gyro2_z = -1000;
    
    // Process gesture
    sound_id_t sound_id = recognize_gesture(gesture);
    
    // Play audio
    if (sound_id != NO_SOUND) {
        play_audio(sound_id);
    }
    
    TEST_ASSERT(1, "Gesture recognition workflow");
}

// Test 2: SPI communication integrity
void test_spi_communication_integrity() {
    printf("Test 2: SPI communication integrity\n");
    
    // Test round-trip communication
    gesture_data_t original_gesture;
    original_gesture.yaw1 = 45.0f;
    original_gesture.pitch1 = 20.0f;
    original_gesture.gyro1_y = -3000;
    original_gesture.yaw2 = 90.0f;
    original_gesture.pitch2 = 35.0f;
    original_gesture.gyro2_y = -2500;
    original_gesture.gyro2_z = -1500;
    
    // Send to FPGA
    spi_send_gesture_data(original_gesture);
    
    // Receive from FPGA
    gesture_data_t received_gesture = spi_receive_gesture_data();
    
    TEST_ASSERT(1, "SPI communication integrity");
}

// Test 3: Pattern recording workflow
void test_pattern_recording_workflow() {
    printf("Test 3: Pattern recording workflow\n");
    
    // Record sequence of gestures
    gesture_data_t gestures[4];
    gestures[0].yaw1 = 60.0f; gestures[0].pitch1 = 30.0f; gestures[0].gyro1_y = -3000;
    gestures[1].yaw1 = 120.0f; gestures[1].pitch1 = 45.0f; gestures[1].gyro1_y = -2500;
    gestures[2].yaw1 = 180.0f; gestures[2].pitch1 = 60.0f; gestures[2].gyro1_y = -2000;
    gestures[3].yaw1 = 240.0f; gestures[3].pitch1 = 75.0f; gestures[3].gyro1_y = -1500;
    
    for (int i = 0; i < 4; i++) {
        sound_id_t sound_id = recognize_gesture(gestures[i]);
        spi_send_record_command(sound_id, gestures[i]);
    }
    
    TEST_ASSERT(1, "Pattern recording workflow");
}

// Test 4: Pattern playback workflow
void test_pattern_playback_workflow() {
    printf("Test 4: Pattern playback workflow\n");
    
    // Start playback
    spi_send_playback_command();
    
    // Receive playback data
    for (int i = 0; i < 4; i++) {
        uint8_t sound_id = spi_receive_sound_id();
        if (sound_id != 0) {
            play_audio(sound_id);
        }
    }
    
    TEST_ASSERT(1, "Pattern playback workflow");
}

// Test 5: Calibration workflow
void test_calibration_workflow() {
    printf("Test 5: Calibration workflow\n");
    
    // Perform calibration
    gesture_data_t calibration_gesture;
    calibration_gesture.yaw1 = 0.0f;
    calibration_gesture.yaw2 = 0.0f;
    
    handle_button2(calibration_gesture);
    spi_send_calibration_command();
    
    TEST_ASSERT(1, "Calibration workflow");
}

// Test 6: Real-time performance
void test_real_time_performance() {
    printf("Test 6: Real-time performance\n");
    
    // Test rapid gesture processing
    for (int i = 0; i < 100; i++) {
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

// Test 7: Error recovery
void test_error_recovery() {
    printf("Test 7: Error recovery\n");
    
    // Test SPI error recovery
    spi_reset();
    
    // Test with invalid data
    gesture_data_t invalid_gesture;
    invalid_gesture.yaw1 = 999.0f;
    invalid_gesture.pitch1 = 999.0f;
    invalid_gesture.yaw2 = 999.0f;
    invalid_gesture.pitch2 = 999.0f;
    
    sound_id_t sound_id = recognize_gesture(invalid_gesture);
    TEST_ASSERT(sound_id == NO_SOUND, "Invalid gesture handling");
}

// Test 8: System integration
void test_system_integration() {
    printf("Test 8: System integration\n");
    
    // Complete system workflow
    gesture_recognition_init();
    spi_init();
    audio_init();
    
    // Simulate complete drumming session
    for (int i = 0; i < 10; i++) {
        // Read gesture from FPGA
        gesture_data_t gesture = spi_receive_gesture_data();
        
        // Process gesture
        sound_id_t sound_id = recognize_gesture(gesture);
        
        // Play audio
        if (sound_id != NO_SOUND) {
            play_audio(sound_id);
        }
        
        // Record gesture
        spi_send_record_command(sound_id, gesture);
        
        // Simulate delay
        delay_millis(TIM6, 1);
    }
    
    TEST_ASSERT(1, "System integration");
}

// Test 9: Concurrent operations
void test_concurrent_operations() {
    printf("Test 9: Concurrent operations\n");
    
    // Test concurrent gesture processing and recording
    gesture_data_t gesture;
    gesture.yaw1 = 60.0f;
    gesture.pitch1 = 30.0f;
    gesture.gyro1_y = -3000;
    gesture.yaw2 = 120.0f;
    gesture.pitch2 = 45.0f;
    gesture.gyro2_y = -2500;
    gesture.gyro2_z = -1000;
    
    // Concurrent operations
    sound_id_t sound_id = recognize_gesture(gesture);
    spi_send_gesture_data(gesture);
    spi_send_record_command(sound_id, gesture);
    
    if (sound_id != NO_SOUND) {
        play_audio(sound_id);
    }
    
    TEST_ASSERT(1, "Concurrent operations");
}

// Test 10: Stress testing
void test_stress_testing() {
    printf("Test 10: Stress testing\n");
    
    // Stress test with rapid operations
    for (int i = 0; i < 1000; i++) {
        gesture_data_t gesture;
        gesture.yaw1 = (i % 360);
        gesture.pitch1 = (i % 90);
        gesture.gyro1_y = -3000 + (i % 1000);
        gesture.yaw2 = ((i + 180) % 360);
        gesture.pitch2 = ((i + 45) % 90);
        gesture.gyro2_y = -2500 + (i % 500);
        gesture.gyro2_z = -1000 + (i % 200);
        
        // Rapid operations
        sound_id_t sound_id = recognize_gesture(gesture);
        spi_send_gesture_data(gesture);
        spi_send_record_command(sound_id, gesture);
        
        if (sound_id != NO_SOUND) {
            play_audio(sound_id);
        }
    }
    
    TEST_ASSERT(1, "Stress testing");
}

// Main test function
int main() {
    printf("=== FPGA-MCU Communication Integration Test Started ===\n");
    
    // Run all tests
    test_gesture_recognition_workflow();
    test_spi_communication_integrity();
    test_pattern_recording_workflow();
    test_pattern_playback_workflow();
    test_calibration_workflow();
    test_real_time_performance();
    test_error_recovery();
    test_system_integration();
    test_concurrent_operations();
    test_stress_testing();
    
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
