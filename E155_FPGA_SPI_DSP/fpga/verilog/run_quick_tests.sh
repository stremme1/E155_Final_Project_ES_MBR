#!/bin/bash
echo "=========================================="
echo "DRUM SYSTEM - QUICK TEST SUITE"
echo "=========================================="
echo ""

echo "Compiling simplified test bench..."
iverilog -g2012 -DSIMULATION -o simple_test \
    spi_controller.sv \
    bno085_spi_interface.sv \
    quaternion_to_euler_dsp.sv \
    yaw_normalize.sv \
    gesture_recognition_full.sv \
    calibration_logic.sv \
    drum_system_top.sv \
    drum_system_simple_tb.sv

if [ $? -ne 0 ]; then
    echo "ERROR: Compilation failed!"
    exit 1
fi

echo "Compilation successful!"
echo ""
echo "Running test suite..."
echo "=========================================="
echo ""

vvp simple_test

TEST_RESULT=$?

echo ""
echo "=========================================="
if [ $TEST_RESULT -eq 0 ]; then
    echo "✓ ALL TESTS PASSED"
    echo "System is READY FOR FPGA DEPLOYMENT"
else
    echo "✗ SOME TESTS FAILED"
fi
echo "=========================================="

rm -f simple_test
exit $TEST_RESULT
