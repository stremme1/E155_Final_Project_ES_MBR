#!/bin/bash
# Simple Test Runner for E155 Drum Set
# Runs basic functionality tests without hardware dependencies
# Author: E155 Final Project
# Date: 2024

echo "=== E155 Drum Set Simple Test Suite ==="
echo "Running basic functionality tests..."
echo

# Test results tracking
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Function to run test and track results
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo "Running: $test_name"
    echo "Command: $test_command"
    echo "----------------------------------------"
    
    if eval "$test_command"; then
        echo "✓ $test_name PASSED"
        ((PASSED_TESTS++))
    else
        echo "✗ $test_name FAILED"
        ((FAILED_TESTS++))
    fi
    ((TOTAL_TESTS++))
    echo
}

# MCU Simple Tests
echo "=== MCU Simple Tests ==="
echo

# Gesture Recognition Test
run_test "Gesture Recognition Test" "cd mcu && gcc -o simple_gesture_test simple_gesture_test.c -lm && ./simple_gesture_test"

# Audio System Test
run_test "Audio System Test" "cd mcu && gcc -o simple_audio_test simple_audio_test.c -lm && ./simple_audio_test"

# Integration Test
run_test "Integration Test" "cd mcu && gcc -o simple_integration_test simple_integration_test.c -lm && ./simple_integration_test"

# Print final results
echo "=== Final Test Results ==="
echo "Total Tests: $TOTAL_TESTS"
echo "Passed: $PASSED_TESTS"
echo "Failed: $FAILED_TESTS"
echo

if [ $FAILED_TESTS -eq 0 ]; then
    echo "✓ ALL TESTS PASSED!"
    echo "Core functionality is working correctly."
    exit 0
else
    echo "✗ SOME TESTS FAILED!"
    echo "Please fix the failing tests."
    exit 1
fi
