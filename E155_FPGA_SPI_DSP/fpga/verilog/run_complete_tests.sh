#!/bin/bash
# Complete System Test Runner
# Tests entire system end-to-end

echo "=========================================="
echo "COMPLETE SYSTEM TEST BENCH"
echo "Testing entire pipeline comprehensively"
echo "=========================================="
echo ""

# Compile
echo "Compiling SystemVerilog modules..."
iverilog -g2012 -DSIMULATION -o complete_test \
    spi_controller.sv \
    bno085_spi_interface.sv \
    quaternion_to_euler_dsp.sv \
    yaw_normalize.sv \
    gesture_recognition_full.sv \
    calibration_logic.sv \
    drum_system_top.sv \
    drum_system_complete_tb.sv 2>&1

if [ $? -ne 0 ]; then
    echo "ERROR: Compilation failed!"
    exit 1
fi

echo "Compilation successful!"
echo ""
echo "Running complete system test..."
echo "=========================================="
echo ""

# Run test
vvp complete_test

TEST_RESULT=$?

echo ""
echo "=========================================="
if [ $TEST_RESULT -eq 0 ]; then
    echo "✓ TEST BENCH COMPLETED"
    echo "Review results above for pass/fail status"
else
    echo "✗ TEST BENCH FAILED"
fi
echo "=========================================="

# Cleanup
rm -f complete_test

exit $TEST_RESULT

