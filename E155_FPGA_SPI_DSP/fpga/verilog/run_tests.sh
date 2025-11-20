#!/bin/bash
# Test Runner Script for Drum System
# Professional Engineering Audit - Comprehensive Testing
# Author: E155 Final Project

echo "=========================================="
echo "DRUM SYSTEM - COMPREHENSIVE TEST SUITE"
echo "=========================================="
echo ""

# Check for iVerilog
if ! command -v iverilog &> /dev/null; then
    echo "ERROR: iVerilog not found. Please install iVerilog."
    exit 1
fi

# Compile all modules
echo "Compiling SystemVerilog modules..."
iverilog -g2012 -DSIMULATION -o drum_system_test \
    spi_controller.sv \
    bno085_spi_interface.sv \
    quaternion_to_euler_dsp.sv \
    yaw_normalize.sv \
    gesture_recognition_full.sv \
    calibration_logic.sv \
    bno085_mock.sv \
    drum_system_top.sv \
    drum_system_top_tb.sv

if [ $? -ne 0 ]; then
    echo "ERROR: Compilation failed!"
    exit 1
fi

echo "Compilation successful!"
echo ""

# Run test bench
echo "Running comprehensive test suite..."
echo "=========================================="
echo ""

vvp drum_system_test

TEST_RESULT=$?

echo ""
echo "=========================================="
if [ $TEST_RESULT -eq 0 ]; then
    echo "✓ ALL TESTS PASSED"
    echo "System is READY FOR FPGA DEPLOYMENT"
else
    echo "✗ SOME TESTS FAILED"
    echo "Review test output above"
fi
echo "=========================================="

# Cleanup
rm -f drum_system_test

exit $TEST_RESULT

