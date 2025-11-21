# Testbench Documentation

This directory contains comprehensive testbenches for verifying the drum set gesture detection system before FPGA deployment.

## Testbenches

### 1. `tb_quaternion_to_euler.sv`
**Purpose**: Tests quaternion to Euler angle conversion accuracy and pipeline behavior.

**Tests**:
- Identity quaternion (no rotation)
- 90-degree rotations around X, Y, Z axes
- Arbitrary quaternions
- Pipeline behavior with continuous data

**Usage**:
```bash
# With your simulator (example for ModelSim/Questa)
vlog -sv quaternion_to_euler.sv tb_quaternion_to_euler.sv
vsim tb_quaternion_to_euler
run -all
```

**Expected Results**:
- All tests should pass with ±5 degree tolerance (due to simplified math)
- Pipeline should process data correctly with proper valid signals

---

### 2. `tb_gesture_detector.sv`
**Purpose**: Tests gesture detection logic with various sensor inputs.

**Tests**:
- Right hand zones: Snare, High tom, Crash, Mid tom, Ride, Floor tom
- Left hand zones: Snare, Hi-hat
- Pitch-based cymbal detection
- Gyro threshold detection
- Calibration functionality
- Yaw normalization

**Usage**:
```bash
vlog -sv gesture_detector.sv tb_gesture_detector.sv
vsim tb_gesture_detector
run -all
```

**Expected Results**:
- All gesture zones should be correctly identified
- Sound codes should match expected values (0-7)
- Calibration should capture yaw offsets

---

### 3. `tb_spi_master.sv`
**Purpose**: Tests SPI master communication protocol.

**Tests**:
- Single byte transmission
- Multiple byte transmission
- Continuous transmission
- Busy signal behavior
- Chip select timing

**Usage**:
```bash
vlog -sv spi_master.sv tb_spi_master.sv
vsim tb_spi_master
run -all
```

**Expected Results**:
- All SPI transactions should complete successfully
- CS signal should assert/deassert correctly
- Busy signal should track transmission state

---

### 4. `tb_drum_set_system.sv`
**Purpose**: Top-level system testbench with simulated BNO085 sensors.

**Tests**:
- System initialization
- Calibration functionality
- Gesture detection end-to-end
- Kick button
- Error detection

**Usage**:
```bash
# Compile all modules
vlog -sv spi_master.sv
vlog -sv bno085_controller.sv
vlog -sv quaternion_to_euler.sv
vlog -sv gesture_detector.sv
vlog -sv uart_tx.sv
vlog -sv drum_set_top.sv
vlog -sv tb_drum_set_system.sv
vsim tb_drum_set_system
run -all
```

**Expected Results**:
- System should initialize both sensors
- Calibration should work
- UART output should be generated for gestures
- No errors should be detected

---

## Running All Testbenches

### Using ModelSim/QuestaSim:
```bash
# Create a script to run all tests
cat > run_all_tests.do << EOF
vlog -sv *.sv
vsim tb_quaternion_to_euler -c -do "run -all; quit"
vsim tb_gesture_detector -c -do "run -all; quit"
vsim tb_spi_master -c -do "run -all; quit"
vsim tb_drum_set_system -c -do "run -all; quit"
EOF

vsim -do run_all_tests.do
```

### Using Verilator:
```bash
verilator --cc --exe --build \
    quaternion_to_euler.sv tb_quaternion_to_euler.sv \
    --top-module tb_quaternion_to_euler
./obj_dir/Vtb_quaternion_to_euler
```

### Using Icarus Verilog:
```bash
iverilog -g2012 -o tb_quaternion_to_euler \
    quaternion_to_euler.sv tb_quaternion_to_euler.sv
vvp tb_quaternion_to_euler
```

---

## Test Coverage

### Module Coverage:
- ✅ `quaternion_to_euler`: Basic functionality, edge cases
- ✅ `gesture_detector`: All zones, thresholds, calibration
- ✅ `spi_master`: Communication protocol, timing
- ✅ `bno085_controller`: Integration with SPI master (via system test)
- ✅ `uart_tx`: Integration test (via system test)
- ✅ `drum_set_top`: End-to-end system test

### Coverage Gaps:
- ⚠️ BNO085 controller unit test (tested via system test)
- ⚠️ UART TX unit test (tested via system test)
- ⚠️ Real BNO085 sensor simulation (simplified model used)

---

## Debugging Tips

1. **Waveform Analysis**: Use your simulator's waveform viewer to inspect signals
   - Check SPI timing (sclk, mosi, miso, cs_n)
   - Verify quaternion to Euler pipeline stages
   - Monitor gesture detection state machine

2. **Common Issues**:
   - **SPI timing**: Verify clock divider matches expected SPI frequency
   - **Pipeline delays**: Account for multi-cycle pipeline in quaternion conversion
   - **Yaw normalization**: Check wrap-around behavior at 0/360 degrees

3. **Adding Tests**:
   - Add test cases to existing testbenches
   - Create new testbenches for specific scenarios
   - Use `$display` and `$monitor` for debugging output

---

## Pre-FPGA Checklist

Before flashing to FPGA, ensure:

- [ ] All unit testbenches pass
- [ ] System testbench shows successful initialization
- [ ] No synthesis warnings (check for BRAM/DSP inference)
- [ ] Timing constraints met
- [ ] Resource utilization acceptable
- [ ] Pin assignments correct
- [ ] Clock frequencies verified

---

## Notes

- Testbenches use simplified models of BNO085 sensors
- Real hardware may behave differently - verify with actual sensors
- Some tests have tolerance for simplified math implementations
- UART receiver in system testbench is simplified - may need adjustment

---

## Support

For issues or questions:
1. Check synthesis logs for BRAM/DSP inference
2. Verify timing constraints are met
3. Review waveform outputs for unexpected behavior
4. Compare with original Arduino implementation behavior


