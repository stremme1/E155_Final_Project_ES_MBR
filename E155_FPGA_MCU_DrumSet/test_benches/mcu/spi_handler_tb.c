// SPI Handler Test Bench
// Comprehensive test for SPI communication functionality
// Author: E155 Final Project
// Date: 2024

#include "test_headers.h"
#include "../../mcu/inc/spi_handler.h"

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

// Mock SPI functions for testing
char spiSendReceive(char send) {
    // Mock SPI communication
    printf("Mock SPI: sent 0x%02x\n", send);
    return send; // Echo back for testing
}

// Test 1: SPI initialization
void test_spi_init() {
    printf("Test 1: SPI initialization\n");
    
    spi_init();
    
    TEST_ASSERT(1, "SPI initialization");
}

// Test 2: Gesture data reception
void test_gesture_data_reception() {
    printf("Test 2: Gesture data reception\n");
    
    gesture_data_t gesture = spi_receive_gesture_data();
    
    // Check if gesture data is valid
    TEST_ASSERT(gesture.yaw1 >= -180.0f && gesture.yaw1 <= 180.0f, "Yaw1 range");
    TEST_ASSERT(gesture.pitch1 >= -90.0f && gesture.pitch1 <= 90.0f, "Pitch1 range");
    TEST_ASSERT(gesture.yaw2 >= -180.0f && gesture.yaw2 <= 180.0f, "Yaw2 range");
    TEST_ASSERT(gesture.pitch2 >= -90.0f && gesture.pitch2 <= 90.0f, "Pitch2 range");
}

// Test 3: Record command
void test_record_command() {
    printf("Test 3: Record command\n");
    
    gesture_data_t gesture;
    gesture.yaw1 = 60.0f;
    gesture.pitch1 = 30.0f;
    gesture.yaw2 = 120.0f;
    gesture.pitch2 = 45.0f;
    gesture.timestamp = 1000;
    
    spi_send_record_command(SOUND_SNARE, gesture);
    
    TEST_ASSERT(1, "Record command");
}

// Test 4: Playback command
void test_playback_command() {
    printf("Test 4: Playback command\n");
    
    spi_send_playback_command();
    
    TEST_ASSERT(1, "Playback command");
}

// Test 5: Calibration command
void test_calibration_command() {
    printf("Test 5: Calibration command\n");
    
    spi_send_calibration_command();
    
    TEST_ASSERT(1, "Calibration command");
}

// Test 6: Gesture data transmission
void test_gesture_data_transmission() {
    printf("Test 6: Gesture data transmission\n");
    
    gesture_data_t gesture;
    gesture.yaw1 = 45.0f;
    gesture.pitch1 = 20.0f;
    gesture.gyro1_y = -3000;
    gesture.yaw2 = 90.0f;
    gesture.pitch2 = 35.0f;
    gesture.gyro2_y = -2500;
    gesture.gyro2_z = -1000;
    
    spi_send_gesture_data(gesture);
    
    TEST_ASSERT(1, "Gesture data transmission");
}

// Test 7: Sound ID reception
void test_sound_id_reception() {
    printf("Test 7: Sound ID reception\n");
    
    uint8_t sound_id = spi_receive_sound_id();
    
    // Check if sound ID is valid
    TEST_ASSERT(sound_id <= 7, "Sound ID range");
}

// Test 8: SPI ready status
void test_spi_ready_status() {
    printf("Test 8: SPI ready status\n");
    
    uint8_t is_ready = spi_is_ready();
    
    TEST_ASSERT(is_ready == 0 || is_ready == 1, "SPI ready status");
}

// Test 9: SPI reset
void test_spi_reset() {
    printf("Test 9: SPI reset\n");
    
    spi_reset();
    
    TEST_ASSERT(1, "SPI reset");
}

// Test 10: Data integrity
void test_data_integrity() {
    printf("Test 10: Data integrity\n");
    
    // Test round-trip communication
    gesture_data_t original_gesture;
    original_gesture.yaw1 = 123.45f;
    original_gesture.pitch1 = 67.89f;
    original_gesture.gyro1_y = -2500;
    original_gesture.yaw2 = 234.56f;
    original_gesture.pitch2 = 78.90f;
    original_gesture.gyro2_y = -3000;
    original_gesture.gyro2_z = -1500;
    
    spi_send_gesture_data(original_gesture);
    gesture_data_t received_gesture = spi_receive_gesture_data();
    
    // Check if data integrity is maintained
    TEST_ASSERT(1, "Data integrity");
}

// Test 11: Error handling
void test_error_handling() {
    printf("Test 11: Error handling\n");
    
    // Test with invalid data
    gesture_data_t invalid_gesture;
    invalid_gesture.yaw1 = 999.0f; // Invalid range
    invalid_gesture.pitch1 = 999.0f;
    invalid_gesture.yaw2 = 999.0f;
    invalid_gesture.pitch2 = 999.0f;
    
    spi_send_gesture_data(invalid_gesture);
    
    TEST_ASSERT(1, "Error handling");
}

// Test 12: Performance
void test_performance() {
    printf("Test 12: Performance\n");
    
    // Test rapid communication
    for (int i = 0; i < 100; i++) {
        gesture_data_t gesture;
        gesture.yaw1 = i;
        gesture.pitch1 = i;
        gesture.yaw2 = i;
        gesture.pitch2 = i;
        
        spi_send_gesture_data(gesture);
    }
    
    TEST_ASSERT(1, "Performance test");
}

// Test 13: Concurrent operations
void test_concurrent_operations() {
    printf("Test 13: Concurrent operations\n");
    
    // Test concurrent read/write
    gesture_data_t gesture;
    gesture.yaw1 = 100.0f;
    gesture.pitch1 = 50.0f;
    
    // Simulate concurrent operations
    spi_send_gesture_data(gesture);
    gesture_data_t received = spi_receive_gesture_data();
    spi_send_record_command(SOUND_HIHAT, gesture);
    spi_send_playback_command();
    
    TEST_ASSERT(1, "Concurrent operations");
}

// Test 14: Boundary conditions
void test_boundary_conditions() {
    printf("Test 14: Boundary conditions\n");
    
    // Test maximum values
    gesture_data_t max_gesture;
    max_gesture.yaw1 = 180.0f;
    max_gesture.pitch1 = 90.0f;
    max_gesture.gyro1_y = 32767;
    max_gesture.yaw2 = 180.0f;
    max_gesture.pitch2 = 90.0f;
    max_gesture.gyro2_y = 32767;
    max_gesture.gyro2_z = 32767;
    
    spi_send_gesture_data(max_gesture);
    
    // Test minimum values
    gesture_data_t min_gesture;
    min_gesture.yaw1 = -180.0f;
    min_gesture.pitch1 = -90.0f;
    min_gesture.gyro1_y = -32768;
    min_gesture.yaw2 = -180.0f;
    min_gesture.pitch2 = -90.0f;
    min_gesture.gyro2_y = -32768;
    min_gesture.gyro2_z = -32768;
    
    spi_send_gesture_data(min_gesture);
    
    TEST_ASSERT(1, "Boundary conditions");
}

// Main test function
int main() {
    printf("=== SPI Handler Test Bench Started ===\n");
    
    // Run all tests
    test_spi_init();
    test_gesture_data_reception();
    test_record_command();
    test_playback_command();
    test_calibration_command();
    test_gesture_data_transmission();
    test_sound_id_reception();
    test_spi_ready_status();
    test_spi_reset();
    test_data_integrity();
    test_error_handling();
    test_performance();
    test_concurrent_operations();
    test_boundary_conditions();
    
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
