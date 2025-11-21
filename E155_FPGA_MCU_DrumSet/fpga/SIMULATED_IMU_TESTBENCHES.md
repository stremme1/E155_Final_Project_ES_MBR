# Simulated IMU Testbenches

## Overview

These testbenches allow you to test the drum set system **without physical IMU sensors**. They use simulated BNO085 sensor models that generate realistic sensor data.

## Testbenches Created

### 1. `tb_gesture_scenarios.sv`
**Purpose**: Tests gesture detection with various simulated drumming scenarios.

**Features**:
- Tests 10 different gesture scenarios
- Simulates right and left hand drumming
- Tests all yaw zones and pitch thresholds
- Verifies correct sound code generation

**Usage**:
```bash
iverilog -g2012 -o tb_gesture_test gesture_detector.sv tb_gesture_scenarios.sv
vvp tb_gesture_test
```

**Test Scenarios**:
1. Right: Snare drum (yaw=50°)
2. Right: High tom (yaw=10°, low pitch)
3. Right: Crash cymbal (yaw=10°, high pitch)
4. Right: Mid tom (yaw=320°, low pitch)
5. Right: Ride cymbal (yaw=320°, high pitch)
6. Right: Floor tom (yaw=250°, low pitch)
7. Left: Snare (yaw=10°, low pitch)
8. Left: Hi-hat (yaw=10°, high pitch, low rotation)
9. Left: Crash (yaw=340°, high pitch)
10. No strike (gyro above threshold)

### 2. `tb_system_with_sim_imu.sv`
**Purpose**: Full system testbench with complete BNO085 sensor simulation.

**Features**:
- Complete BNO085 sensor model (`bno085_sim_model`)
- Simulates SHTP protocol over SPI
- Generates realistic quaternion and gyroscope data
- Tests full system integration
- Includes UART receiver for output verification

**Usage**:
```bash
iverilog -g2012 -o tb_system_test \
    spi_master.sv bno085_controller.sv quaternion_to_euler.sv \
    gesture_detector.sv uart_tx.sv drum_set_top.sv \
    tb_system_with_sim_imu.sv
vvp tb_system_test
```

**BNO085 Sensor Model**:
- Implements SPI slave interface
- Responds to SHTP protocol commands
- Generates rotation vector reports (quaternion data)
- Generates gyroscope reports
- Cycles through different gesture scenarios automatically

## Simulated Sensor Data

### Quaternion Data (Q14 format)
- Format: Little-endian 16-bit signed integers
- Range: -1.0 to +1.0 (represented as -16384 to +16384)
- Example: `quat_w = 16'd16384` represents 0.5

### Gyroscope Data (Q9 format)
- Format: Little-endian 16-bit signed integers
- Units: rad/s × 900
- Example: `gyro_y = -16'd2500` represents strike detection threshold

### Gesture Scenarios
The sensor model cycles through different scenarios:
- **Scenario 0**: Snare drum gesture
- **Scenario 1**: High tom gesture
- **Scenario 2**: Crash cymbal gesture
- **Scenario 3**: Hi-hat gesture
- **Scenario 4+**: Other gestures or no strike

## Testing Without Physical Hardware

### Advantages
1. **No Hardware Required**: Test entire system in simulation
2. **Reproducible**: Same scenarios every time
3. **Fast**: No need to wait for physical sensor responses
4. **Debuggable**: Can inspect all internal signals
5. **Comprehensive**: Test edge cases and error conditions

### Limitations
1. **Simplified Model**: Sensor model is simplified compared to real BNO085
2. **Timing**: May not match exact real-world timing
3. **Calibration**: Real sensors need calibration, simulated ones don't

## Running All Testbenches

```bash
cd E155_FPGA_MCU_DrumSet/fpga

# Test gesture scenarios
iverilog -g2012 -o tb_gesture_test gesture_detector.sv tb_gesture_scenarios.sv
vvp tb_gesture_test

# Test full system (when all modules are ready)
iverilog -g2012 -o tb_system_test \
    spi_master.sv bno085_controller.sv quaternion_to_euler.sv \
    gesture_detector.sv uart_tx.sv drum_set_top.sv \
    tb_system_with_sim_imu.sv
vvp tb_system_test
```

## Expected Output

### Gesture Scenarios Testbench
```
========================================
Gesture Scenario Testbench
========================================

--- Scenario 0: Right: Snare (yaw=50) ---
  PASS: Correct sound detected (code=0)

--- Scenario 1: Right: High Tom (yaw=10, low pitch) ---
  PASS: Correct sound detected (code=3)

...

========================================
Test Summary
========================================
Total scenarios: 10
Passed: 9
Failed: 1
========================================
```

### System Testbench
```
========================================
System Testbench with Simulated IMU
========================================

System reset released

Waiting for sensor initialization...

=== Test 1: System Initialization ===
PASS: System initialized (LED on)

=== Test 2: Calibration ===
Pressing calibration button...
Calibration button released

=== Test 3: Simulating Drumming Gestures ===
Sending simulated sensor data for various gestures...

[123456] UART Output: 0x30 ('0') - Sound code: 0
[234567] UART Output: 0x33 ('3') - Sound code: 3

...
```

## Customizing Simulated Data

To test different scenarios, modify the sensor model in `tb_system_with_sim_imu.sv`:

```systemverilog
// In bno085_sim_model, modify the gesture_scenario case statement:
case (gesture_scenario)
    0: begin  // Your custom scenario
        quat_w <= 16'd16384;   // Adjust quaternion
        quat_x <= 16'd0;
        quat_y <= 16'd0;
        quat_z <= 16'd0;
        gyro_y <= -16'd3000;   // Adjust gyro for strike
    end
    // Add more scenarios...
endcase
```

## Debugging Tips

1. **Waveform Viewer**: Use GTKWave or similar to view all signals
2. **Monitor Statements**: Uncomment `$monitor` in testbenches for detailed output
3. **Breakpoints**: Add `$stop` statements to pause simulation
4. **Signal Inspection**: Check intermediate signals (yaw_norm, printed_gyro1_y, etc.)

## Next Steps

1. Run testbenches and verify outputs
2. Adjust simulated data to match expected behavior
3. Test edge cases (boundary conditions, error cases)
4. Verify timing with waveform viewer
5. Compare with real sensor data when hardware is available


