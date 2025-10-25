#!/bin/bash
# Comprehensive Test Runner
# Runs all test benches and reports results
# Author: E155 Final Project
# Date: 2024

echo "=== E155 Drum Set Comprehensive Test Suite ==="
echo "Starting all test benches..."
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

# FPGA Test Benches
echo "=== FPGA Test Benches ==="
echo

# I2C Master Test
run_test "I2C Master Test" "cd fpga && iverilog -o i2c_master_tb i2c_master_tb.sv ../../fpga/verilog/i2c_master.sv && vvp i2c_master_tb"

# Quaternion Processor Test
run_test "Quaternion Processor Test" "cd fpga && iverilog -o quaternion_processor_tb quaternion_processor_tb.sv ../../fpga/verilog/quaternion_processor.sv && vvp quaternion_processor_tb"

# Pattern Recorder Test
run_test "Pattern Recorder Test" "cd fpga && iverilog -o pattern_recorder_tb pattern_recorder_tb.sv ../../fpga/verilog/pattern_recorder.sv && vvp pattern_recorder_tb"

# SPI Interface Test
run_test "SPI Interface Test" "cd fpga && iverilog -o spi_interface_tb spi_interface_tb.sv ../../fpga/verilog/spi_interface.sv && vvp spi_interface_tb"

# Drum System Top Test
run_test "Drum System Top Test" "cd fpga && iverilog -o drum_system_top_tb drum_system_top_tb.sv ../../fpga/verilog/drum_system_top.sv && vvp drum_system_top_tb"

# MCU Test Benches
echo "=== MCU Test Benches ==="
echo

# Gesture Recognition Test
run_test "Gesture Recognition Test" "cd mcu && gcc -I. -o gesture_recognition_tb gesture_recognition_tb.c ../../mcu/src/gesture_recognition.c -lm && ./gesture_recognition_tb"

# Audio Processor Test
run_test "Audio Processor Test" "cd mcu && gcc -I. -o audio_processor_tb audio_processor_tb.c ../../mcu/src/audio_processor.c -lm && ./audio_processor_tb"

# SPI Handler Test
run_test "SPI Handler Test" "cd mcu && gcc -I. -o spi_handler_tb spi_handler_tb.c ../../mcu/src/spi_handler.c -lm && ./spi_handler_tb"

# Main System Test
run_test "Main System Test" "cd mcu && gcc -I. -o main_tb main_tb.c ../../mcu/src/main.c -lm && ./main_tb"

# Integration Test Benches
echo "=== Integration Test Benches ==="
echo

# FPGA-MCU Communication Test
run_test "FPGA-MCU Communication Test" "cd integration && gcc -o fpga_mcu_communication_tb fpga_mcu_communication_tb.c -lm && ./fpga_mcu_communication_tb"

# Print final results
echo "=== Final Test Results ==="
echo "Total Tests: $TOTAL_TESTS"
echo "Passed: $PASSED_TESTS"
echo "Failed: $FAILED_TESTS"
echo

if [ $FAILED_TESTS -eq 0 ]; then
    echo "✓ ALL TESTS PASSED!"
    echo "System is ready for deployment."
    exit 0
else
    echo "✗ SOME TESTS FAILED!"
    echo "Please fix the failing tests before deployment."
    exit 1
fi
