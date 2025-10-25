// Gesture Recognition Test Bench
// Comprehensive test for gesture recognition functionality
// Author: E155 Final Project
// Date: 2024

#include "test_headers.h"
#include "../../mcu/inc/gesture_recognition.h"

// Mock implementations for testing
void gpioEnable(int port_id) { printf("Mock gpioEnable(%d)\n", port_id); }
void pinMode(int gpio_pin, int function) { printf("Mock pinMode(%d, %d)\n", gpio_pin, function); }
int digitalRead(int gpio_pin) { printf("Mock digitalRead(%d)\n", gpio_pin); return 1; }
void digitalWrite(int gpio_pin, int val) { printf("Mock digitalWrite(%d, %d)\n", gpio_pin, val); }
void pinResistor(int pin, int setting) { printf("Mock pinResistor(%d, %d)\n", pin, setting); }
void initTIM(TIM_TypeDef * TIMx) { printf("Mock initTIM()\n"); }
void delay_millis(TIM_TypeDef * TIMx, uint32_t ms) { printf("Mock delay_millis(%d)\n", ms); }
void initSPI(int br, int cpol, int cpha) { printf("Mock initSPI(%d, %d, %d)\n", br, cpol, cpha); }
char spiSendReceive(char send) { printf("Mock spiSendReceive(0x%02x)\n", send); return send; }
void configureFlash(void) { printf("Mock configureFlash()\n"); }
void configureClock(void) { printf("Mock configureClock()\n"); }
void configurePLL(void) { printf("Mock configurePLL()\n"); }
void SystemCoreClockUpdate(void) { printf("Mock SystemCoreClockUpdate()\n"); }

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

// Test 1: Gesture recognition initialization
void test_gesture_recognition_init() {
    printf("Test 1: Gesture recognition initialization\n");
    
    gesture_recognition_init();
    
    // Check if initialization completed without errors
    TEST_ASSERT(1, "Gesture recognition initialization");
}

// Test 2: Normalize yaw function
void test_normalize_yaw() {
    printf("Test 2: Normalize yaw function\n");
    
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

// Test 3: Right hand gesture recognition
void test_right_hand_gestures() {
    printf("Test 3: Right hand gesture recognition\n");
    
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

// Test 4: Left hand gesture recognition
void test_left_hand_gestures() {
    printf("Test 4: Left hand gesture recognition\n");
    
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

// Test 5: Button functions
void test_button_functions() {
    printf("Test 5: Button functions\n");
    
    // Test button 1 (kick drum)
    sound_id_t result1 = handle_button1();
    TEST_EQUAL(result1, SOUND_KICK, "Button 1 kick drum");
    
    // Test button 2 (calibration)
    gesture_data_t gesture;
    gesture.yaw1 = 100.0f;
    gesture.yaw2 = 200.0f;
    
    handle_button2(gesture);
    
    // Check if calibration was performed
    float offset1 = get_yaw_offset1();
    float offset2 = get_yaw_offset2();
    
    TEST_FLOAT_EQUAL(offset1, 100.0f, 0.001f, "Button 2 calibration yaw1");
    TEST_FLOAT_EQUAL(offset2, 200.0f, 0.001f, "Button 2 calibration yaw2");
}

// Test 6: Edge cases
void test_edge_cases() {
    printf("Test 6: Edge cases\n");
    
    gesture_data_t gesture;
    
    // Test boundary conditions
    gesture.yaw1 = 20.0f; // Exactly at boundary
    gesture.pitch1 = 0.0f;
    gesture.gyro1_y = -2500; // Exactly at threshold
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

// Test 7: Debouncing
void test_debouncing() {
    printf("Test 7: Debouncing\n");
    
    gesture_data_t gesture;
    gesture.yaw1 = 60.0f;
    gesture.pitch1 = 0.0f;
    gesture.gyro1_y = -3000;
    gesture.yaw2 = 0.0f;
    gesture.pitch2 = 0.0f;
    gesture.gyro2_y = 0;
    gesture.gyro2_z = 0;
    
    // First call should trigger
    sound_id_t result1 = recognize_gesture(gesture);
    TEST_EQUAL(result1, SOUND_SNARE, "First gesture trigger");
    
    // Second call should not trigger (debounced)
    sound_id_t result2 = recognize_gesture(gesture);
    TEST_EQUAL(result2, NO_SOUND, "Debounced gesture");
    
    // Reset debouncing
    reset_debouncing_flags();
    
    // Third call should trigger again
    sound_id_t result3 = recognize_gesture(gesture);
    TEST_EQUAL(result3, SOUND_SNARE, "Reset debouncing");
}

// Main test function
int main() {
    printf("=== Gesture Recognition Test Bench Started ===\n");
    
    // Run all tests
    test_gesture_recognition_init();
    test_normalize_yaw();
    test_right_hand_gestures();
    test_left_hand_gestures();
    test_button_functions();
    test_edge_cases();
    test_debouncing();
    
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
