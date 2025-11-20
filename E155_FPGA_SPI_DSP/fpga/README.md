# FPGA Drum System - I²C + DSP + BRAM Implementation

## Architecture Overview

This is a fresh implementation optimized for iCE40UP5K using:
- **I²C** for BNO055 communication (BNO055 doesn't support SPI - see BNO055_SPI_NOTE.md)
- **DSP blocks** for quaternion-to-Euler math operations
- **BRAM** for data buffering and storage
- **Two IMUs** - Full gesture recognition matching original C/Python code
- **End-to-end** project with complete functionality

## Key Features

### Two BNO055 IMUs
- **I²C1**: Right hand IMU (address 0x28)
- **I²C2**: Left hand IMU (address 0x29)
- **Full data**: Quaternion (w,x,y,z), Gyroscope (x,y,z), Euler (yaw, pitch, roll)

### Complete Gesture Recognition
- **Quaternion → Euler conversion** using DSP blocks
- **Yaw-based drum position** detection (matching original code)
- **Pitch thresholds** for cymbal vs tom distinction
- **Gyro triggers** for hit detection
- **Calibration** via button2 (sets yaw offsets)

### Sound IDs (8 sounds)
- 0 = Snare, 1 = Hi-hat, 2 = Kick, 3 = High tom
- 4 = Mid tom, 5 = Crash, 6 = Ride, 7 = Floor tom
- 255 = No sound

### DSP Blocks
- **Hardware multipliers** - 8 DSP blocks available on UP5K
- **Efficient math** - offloads computation from LUTs
- **16-bit x 16-bit multiply** with 32-bit accumulator
- **Perfect for** gyro data processing, filtering, gesture calculations

### BRAM
- **120 kb EBR** available on UP5K
- **Fast access** - single cycle read/write
- **Useful for**:
  - Gyro data buffering
  - Filter coefficients storage
  - Gesture pattern matching
  - Sound ID lookup tables

## Design Goals

1. **Fit within 5280 LUTs** (iCE40UP5K limit)
2. **Use I²C** for BNO055 communication (both I²C controllers on UP5K)
3. **Leverage DSP blocks** for quaternion math (multiply, accumulate)
4. **Use BRAM** for quaternion/Euler data buffering
5. **Full gesture recognition** matching original C/Python code
6. **Two IMUs** with complete functionality

## File Structure

```
E155_FPGA_SPI_DSP/
├── fpga/
│   ├── README.md (this file)
│   ├── verilog/
│   │   ├── drum_system_top.sv              # Top-level module
│   │   ├── bno055_i2c_controller.sv         # BNO055 I²C controller (quaternion + gyro)
│   │   ├── quaternion_to_euler_dsp.sv       # Quaternion→Euler using DSP
│   │   ├── gesture_recognition_full.sv      # Full gesture recognition logic
│   │   ├── bram_quaternion_buffer.sv        # BRAM buffer for quaternion data
│   │   └── yaw_normalize.sv                 # Yaw normalization (0-360)
│   └── docs/
│       ├── BNO055_SPI_NOTE.md               # Why we use I²C (not SPI)
│       ├── DSP_USAGE.md                      # DSP block usage guide
│       ├── BRAM_USAGE.md                     # BRAM usage guide
│       └── GESTURE_LOGIC.md                  # Gesture recognition algorithm
```

## Resource Allocation Plan

### LUTs (Target: <5000)
- I²C Controllers (2x): ~800-1000 LUTs (using hardened IP)
- BNO055 Interface (2x): ~400-600 LUTs
- Quaternion→Euler (DSP): ~200-300 LUTs (control logic)
- Gesture Recognition: ~500-700 LUTs
- BRAM control: ~100-200 LUTs
- Top-level logic: ~200-300 LUTs
- **Total: ~2200-3100 LUTs** (well under 5280 limit!)

### DSP Blocks (8 available)
- Quaternion multiply (w*x, y*z, etc.): 2-3 DSP blocks
- atan2 approximation: 1-2 DSP blocks
- asin approximation: 1 DSP block
- **Total: 4-6 DSP blocks** (well within limit)

### BRAM (120 kb available)
- Quaternion buffer (2 IMUs): ~4-8 kb (128-256 samples each)
- Euler angle buffer: ~2-4 kb
- Gyro data buffer: ~2-4 kb
- **Total: ~8-16 kb** (plenty of space!)

## Implementation Status

1. ✅ Architecture defined
2. ⏳ BNO055 I²C controller (quaternion + gyro)
3. ⏳ Quaternion-to-Euler conversion (DSP)
4. ⏳ Full gesture recognition logic
5. ⏳ BRAM buffer implementation
6. ⏳ Calibration logic
7. ⏳ Test bench

## References

- [iCE40UP5K Datasheet](https://www.farnell.com/datasheets/3215488.pdf)
- [BNO055 Datasheet](https://cdn-learn.adafruit.com/downloads/pdf/adafruit-bno055-absolute-orientation-sensor.pdf)
- Original C code: `src/main.c`
- Original Python code: `PYTHON/collect_data.py`

