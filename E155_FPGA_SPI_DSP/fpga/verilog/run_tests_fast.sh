#!/bin/bash
# Fast Test Runner - Shows progress and results
echo "=========================================="
echo "COMPLETE SYSTEM TEST BENCH"
echo "=========================================="
echo ""
echo "Compiling..."
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
echo "Running test bench..."
echo "Note: Reset sequence takes ~100ms (5M cycles), please wait..."
echo "=========================================="
echo ""

# Run and capture output
vvp complete_test > test_output_full.txt 2>&1 &
TEST_PID=$!

# Show progress
while kill -0 $TEST_PID 2>/dev/null; do
    echo -n "."
    sleep 1
done
echo ""
echo ""

# Show results
echo "=========================================="
echo "TEST RESULTS:"
echo "=========================================="
tail -30 test_output_full.txt | grep -E "(TEST SUITE|PASS|FAIL|SUMMARY|Total Tests|Passed|Failed|ALL TESTS|SOME TESTS)"
echo ""
echo "Full output saved to: test_output_full.txt"
echo "=========================================="

rm -f complete_test
exit 0

