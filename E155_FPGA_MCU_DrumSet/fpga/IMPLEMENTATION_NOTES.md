# Implementation Notes and Critical Fixes

## Important Implementation Details

### 1. BNO085 SPI Communication

The BNO085 uses SHTP (Sensor Hub Transport Protocol) over SPI. Key points:

- **SPI Mode**: Mode 3 (CPOL=1, CPHA=1) - Clock idle high, data sampled on falling edge
- **Clock Speed**: Maximum 3MHz
- **Read Operation**: Must send dummy bytes (0x00) to receive data
- **Packet Format**: 4-byte header + variable payload

### 2. Quaternion to Euler Conversion

**Current Status**: Simplified implementation using basic math approximations.

**Limitations**:
- Uses simplified atan2 and asin approximations
- May have accuracy issues for edge cases
- Fixed-point arithmetic may introduce rounding errors

**Recommended Improvements**:
- Implement CORDIC algorithm for accurate atan2/asin
- Use lookup tables for trigonometric functions
- Consider using floating-point IP cores if available

**Quaternion Format**:
- BNO085 outputs in Q14 format (1.14 fixed point, range -1.0 to +1.0)
- Module expects Q16 format (1.15 fixed point)
- May need scaling/conversion layer

### 3. Gesture Detection Logic

The gesture detection logic matches the original `main.c` implementation:

- **Yaw Zones**: Same angular ranges for right and left hands
- **Thresholds**: Same gyro and pitch thresholds
- **Debouncing**: Sequential logic prevents multiple triggers

**Known Issues**:
- Zone overlap at 20° boundary (right hand zones 1 and 2)
- Fixed thresholds may need calibration per user

### 4. SPI Master Implementation

**Current Features**:
- Configurable clock divider
- Full-duplex communication
- Proper chip select control

**Considerations**:
- Ensure SPI clock meets BNO085 3MHz maximum
- Adjust CLK_DIV parameter based on system clock
- Verify timing with oscilloscope/logic analyzer

### 5. Data Flow and Timing

**Expected Timing**:
- Sensor initialization: ~100ms after reset
- Report rate: 50Hz (20ms intervals)
- Processing latency: <5ms per sensor
- Total system latency: <15ms (target)

**Potential Bottlenecks**:
- SPI communication speed
- Quaternion to Euler conversion (multi-cycle)
- UART transmission (115200 baud)

### 6. Critical Fixes Needed

#### A. BNO085 Controller - SPI Read Operations
**Status**: ✅ Fixed
- Now properly sends dummy bytes to read data
- Handles multi-byte packet reading

#### B. Quaternion Data Format
**Status**: ⚠️ Needs Verification
- Verify BNO085 quaternion output format (Q14 vs Q16)
- May need scaling/conversion
- Check byte order (little-endian vs big-endian)

#### C. Gyroscope Data Format
**Status**: ⚠️ Needs Verification
- BNO085 outputs in rad/s * 900 (Q9 format)
- Current thresholds assume different format
- May need scaling: `gyro_scaled = gyro_raw / 900`

#### D. Euler Angle Calculation
**Status**: ⚠️ Needs Improvement
- Current implementation uses approximations
- For production: implement CORDIC or use IP core

### 7. Testing Checklist

Before deployment, verify:

- [ ] SPI communication with BNO085 sensors
- [ ] Sensor initialization sequence completes
- [ ] Quaternion data received correctly
- [ ] Euler angle conversion produces reasonable values
- [ ] Gesture detection triggers on strikes
- [ ] Yaw zones correctly identified
- [ ] Pitch-based cymbal detection works
- [ ] UART output matches expected format
- [ ] Calibration button captures yaw offsets
- [ ] System latency meets requirements

### 8. Debugging Tips

**SPI Issues**:
- Use logic analyzer to verify SPI transactions
- Check clock polarity and phase
- Verify chip select timing
- Ensure proper idle states

**Data Issues**:
- Add debug outputs for raw quaternion/gyro values
- Compare with Arduino implementation outputs
- Verify data format and scaling

**Gesture Detection Issues**:
- Add debug outputs for yaw zones
- Log gyro threshold crossings
- Verify debounce logic timing

### 9. Performance Optimization

**Potential Optimizations**:
- Pipeline quaternion to Euler conversion
- Use parallel processing for two sensors
- Optimize SPI communication (reduce overhead)
- Implement data buffering for smooth operation

### 10. Known Limitations

1. **Simplified Math**: Quaternion conversion uses approximations
2. **Fixed Thresholds**: May need per-user calibration
3. **No Velocity Sensitivity**: All hits play at same volume
4. **Limited Error Handling**: Basic error detection only
5. **Single UART Output**: Can't distinguish which sensor triggered

### 11. Recommended Next Steps

1. **Verify Data Formats**: Test with actual BNO085 sensors to confirm data formats
2. **Improve Math**: Implement CORDIC for accurate angle calculations
3. **Add Simulation**: Create testbenches for each module
4. **Hardware Testing**: Test on actual FPGA hardware
5. **Calibration System**: Add more sophisticated calibration routine
6. **Performance Profiling**: Measure actual latencies and optimize

### 12. Compatibility Notes

**FPGA Compatibility**:
- Written in SystemVerilog (IEEE 1800)
- Should work with most modern FPGA toolchains
- May need minor syntax adjustments for older tools

**Sensor Compatibility**:
- Designed for BNO085 (not BNO055)
- Uses SPI interface (not I2C)
- Requires SHTP protocol support

## References

- Original implementation: `../../src/main.c`
- BNO085 Datasheet: See README.md
- SHTP Protocol: Refer to BNO085 documentation


