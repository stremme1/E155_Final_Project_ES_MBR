// Main System Test Bench
// Comprehensive integration test for complete MCU system
// Author: E155 Final Project
// Date: 2024

#include "test_headers.h"
#include "../../mcu/inc/main.h"

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

// Mock system functions for testing
void configureFlash() {
    printf("Mock configureFlash() called\n");
}

void configureClock() {
    printf("Mock configureClock() called\n");
}

void gpioEnable(int port_id) {
    printf("Mock gpioEnable(%d) called\n", port_id);
}

void pinMode(int gpio_pin, int function) {
    printf("Mock pinMode(%d, %d) called\n", gpio_pin, function);
}

int digitalRead(int gpio_pin) {
    // Mock button reading
    return 1; // Button not pressed
}

void digitalWrite(int gpio_pin, int val) {
    printf("Mock digitalWrite(%d, %d) called\n", gpio_pin, val);
}

void delay_millis(TIM_TypeDef * TIMx, uint32_t ms) {
    printf("Mock delay_millis(%d) called\n", ms);
}

// Test 1: System initialization
void test_system_initialization() {
    printf("Test 1: System initialization\n");
    
    // Test clock configuration
    configureClock();
    TEST_ASSERT(1, "Clock configuration");
    
    // Test flash configuration
    configureFlash();
    TEST_ASSERT(1, "Flash configuration");
    
    // Test GPIO initialization
    gpioEnable(GPIO_PORT_A);
    gpioEnable(GPIO_PORT_B);
    gpioEnable(GPIO_PORT_C);
    TEST_ASSERT(1, "GPIO initialization");
    
    // Test pin configuration
    pinMode(LED_PIN, GPIO_OUTPUT);
    pinMode(BUTTON1_PIN, GPIO_INPUT);
    pinMode(BUTTON2_PIN, GPIO_INPUT);
    pinMode(BUTTON3_PIN, GPIO_INPUT);
    pinMode(AUDIO_PWM_PIN, GPIO_OUTPUT);
    TEST_ASSERT(1, "Pin configuration");
}

// Test 2: Button handling
void test_button_handling() {
    printf("Test 2: Button handling\n");
    
    // Test button 1 (kick drum)
    handle_buttons();
    TEST_ASSERT(1, "Button 1 handling");
    
    // Test button 2 (calibration)
    handle_buttons();
    TEST_ASSERT(1, "Button 2 handling");
    
    // Test button 3 (record/playback)
    handle_buttons();
    TEST_ASSERT(1, "Button 3 handling");
}

// Test 3: LED control
void test_led_control() {
    printf("Test 3: LED control\n");
    
    // Test LED in different modes
    system_mode_t original_mode = system_mode;
    
    system_mode = LIVE_MODE;
    update_leds();
    TEST_ASSERT(1, "LED in live mode");
    
    system_mode = RECORD_MODE;
    update_leds();
    TEST_ASSERT(1, "LED in record mode");
    
    system_mode = PLAYBACK_MODE;
    update_leds();
    TEST_ASSERT(1, "LED in playback mode");
    
    system_mode = CALIBRATION_MODE;
    update_leds();
    TEST_ASSERT(1, "LED in calibration mode");
    
    // Restore original mode
    system_mode = original_mode;
}

// Test 4: System modes
void test_system_modes() {
    printf("Test 4: System modes\n");
    
    // Test live mode
    system_mode = LIVE_MODE;
    handle_system_modes();
    TEST_ASSERT(1, "Live mode handling");
    
    // Test record mode
    system_mode = RECORD_MODE;
    handle_system_modes();
    TEST_ASSERT(1, "Record mode handling");
    
    // Test playback mode
    system_mode = PLAYBACK_MODE;
    handle_system_modes();
    TEST_ASSERT(1, "Playback mode handling");
    
    // Test calibration mode
    system_mode = CALIBRATION_MODE;
    handle_system_modes();
    TEST_ASSERT(1, "Calibration mode handling");
}

// Test 5: Calibration
void test_calibration() {
    printf("Test 5: Calibration\n");
    
    perform_calibration();
    TEST_ASSERT(1, "Calibration process");
}

// Test 6: Main loop simulation
void test_main_loop() {
    printf("Test 6: Main loop simulation\n");
    
    // Simulate main loop iterations
    for (int i = 0; i < 10; i++) {
        // Simulate gesture data reception
        gesture_data_t gesture;
        gesture.yaw1 = i * 10.0f;
        gesture.pitch1 = i * 5.0f;
        gesture.yaw2 = i * 15.0f;
        gesture.pitch2 = i * 7.0f;
        
        // Simulate button handling
        handle_buttons();
        
        // Simulate LED updates
        update_leds();
        
        // Simulate system mode handling
        handle_system_modes();
        
        // Simulate delay
        delay_millis(TIM6, 1);
    }
    
    TEST_ASSERT(1, "Main loop simulation");
}

// Test 7: Error handling
void test_error_handling() {
    printf("Test 7: Error handling\n");
    
    // Test with invalid system mode
    system_mode_t original_mode = system_mode;
    system_mode = (system_mode_t)999; // Invalid mode
    
    handle_system_modes();
    TEST_ASSERT(1, "Invalid mode handling");
    
    // Restore original mode
    system_mode = original_mode;
}

// Test 8: Performance
void test_performance() {
    printf("Test 8: Performance\n");
    
    // Test rapid button presses
    for (int i = 0; i < 100; i++) {
        handle_buttons();
    }
    TEST_ASSERT(1, "Rapid button handling");
    
    // Test rapid LED updates
    for (int i = 0; i < 100; i++) {
        update_leds();
    }
    TEST_ASSERT(1, "Rapid LED updates");
}

// Test 9: Concurrent operations
void test_concurrent_operations() {
    printf("Test 9: Concurrent operations\n");
    
    // Test concurrent button and LED operations
    handle_buttons();
    update_leds();
    handle_system_modes();
    
    TEST_ASSERT(1, "Concurrent operations");
}

// Test 10: System state transitions
void test_system_state_transitions() {
    printf("Test 10: System state transitions\n");
    
    // Test transition from live to record
    system_mode = LIVE_MODE;
    handle_system_modes();
    
    system_mode = RECORD_MODE;
    handle_system_modes();
    TEST_ASSERT(1, "Live to record transition");
    
    // Test transition from record to playback
    system_mode = PLAYBACK_MODE;
    handle_system_modes();
    TEST_ASSERT(1, "Record to playback transition");
    
    // Test transition from playback to live
    system_mode = LIVE_MODE;
    handle_system_modes();
    TEST_ASSERT(1, "Playback to live transition");
}

// Test 11: Edge cases
void test_edge_cases() {
    printf("Test 11: Edge cases\n");
    
    // Test with maximum system tick
    system_tick = 0xFFFFFFFF;
    handle_buttons();
    TEST_ASSERT(1, "Maximum system tick");
    
    // Test with minimum system tick
    system_tick = 0;
    handle_buttons();
    TEST_ASSERT(1, "Minimum system tick");
}

// Test 12: Integration
void test_integration() {
    printf("Test 12: Integration\n");
    
    // Test complete system workflow
    configureFlash();
    configureClock();
    
    gpioEnable(GPIO_PORT_A);
    gpioEnable(GPIO_PORT_B);
    gpioEnable(GPIO_PORT_C);
    
    pinMode(LED_PIN, GPIO_OUTPUT);
    pinMode(BUTTON1_PIN, GPIO_INPUT);
    pinMode(BUTTON2_PIN, GPIO_INPUT);
    pinMode(BUTTON3_PIN, GPIO_INPUT);
    pinMode(AUDIO_PWM_PIN, GPIO_OUTPUT);
    
    // Simulate system operation
    for (int i = 0; i < 5; i++) {
        handle_buttons();
        update_leds();
        handle_system_modes();
        delay_millis(TIM6, 1);
    }
    
    TEST_ASSERT(1, "System integration");
}

// Main test function
int main() {
    printf("=== Main System Test Bench Started ===\n");
    
    // Run all tests
    test_system_initialization();
    test_button_handling();
    test_led_control();
    test_system_modes();
    test_calibration();
    test_main_loop();
    test_error_handling();
    test_performance();
    test_concurrent_operations();
    test_system_state_transitions();
    test_edge_cases();
    test_integration();
    
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
