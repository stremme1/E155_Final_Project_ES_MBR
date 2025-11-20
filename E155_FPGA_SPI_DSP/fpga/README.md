# FPGA Drum System - SPI + DSP + BRAM Implementation

## Architecture Overview

This is a fresh implementation optimized for iCE40UP5K using:
- **SPI** for BNO085 communication (soft controller, avoids massive I2C IP blocks)
- **DSP blocks** for quaternion-to-Euler math operations
- **BRAM** for data buffering and storage
- **Two IMUs** - Full gesture recognition matching original C/Python code
- **End-to-end** project with complete functionality

## Key Features

### Two BNO085 IMUs via SPI
- **SPI with CS1**: Right hand IMU
- **SPI with CS2**: Left hand IMU
- **Soft SPI controller** (~300-500 LUTs total, vs ~2000+ for I2C IP blocks)
- **Full data**: Quaternion (w,x,y,z), Gyroscope (x,y,z), Euler (yaw, pitch, roll)

### Complete Gesture Recognition
- **Quaternion → Euler conversion** using DSP blocks
- **Yaw-based drum position** detection (matching original code)
- **Pitch thresholds** for cymbal vs tom distinction
- **Gyro triggers** for hit detection
- **Calibration** via button2 (sets yaw offsets)

### DSP Blocks
- **Hardware multipliers** - 8 DSP blocks available on UP5K
- **Efficient math** - offloads computation from LUTs
- **16-bit x 16-bit multiply** with 32-bit accumulator
- **Perfect for** quaternion multiplication, atan2/asin approximations

### BRAM
- **120 kb EBR** available on UP5K
- **Fast access** - single cycle read/write
- **Useful for**:
  - Quaternion data buffering
  - Euler angle storage
  - Gyro data history
  - Filter coefficients

## Design Goals

1. **Fit within 5280 LUTs** (iCE40UP5K limit)
2. **Use SPI** for BNO085 communication (soft controller, avoids big I2C IP blocks)
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
│   │   ├── spi_controller.sv               # Soft SPI master controller
│   │   ├── bno085_spi_interface.sv         # BNO085 SPI interface (quaternion + gyro)
│   │   ├── quaternion_to_euler_dsp.sv      # Quaternion→Euler using DSP
│   │   ├── gesture_recognition_full.sv     # Full gesture recognition logic
│   │   ├── bram_quaternion_buffer.sv       # BRAM buffer for quaternion data
│   │   └── yaw_normalize.sv                # Yaw normalization (0-360)
│   └── docs/
│       ├── BNO055_SPI_NOTE.md              # BNO055 vs BNO085 (why SPI)
│       ├── SPI_SETUP.md                     # SPI configuration guide
│       ├── DSP_USAGE.md                     # DSP block usage guide
│       ├── BRAM_USAGE.md                    # BRAM usage guide
│       └── GESTURE_LOGIC.md                 # Gesture recognition algorithm
```

## Resource Allocation Plan

### LUTs (Target: <5000)
- SPI Controller (soft): ~300-500 LUTs (ONE controller for both IMUs!)
- BNO085 Interface (2x): ~400-600 LUTs
- Quaternion→Euler (DSP): ~200-300 LUTs (control logic)
- Gesture Recognition: ~500-700 LUTs
- BRAM control: ~100-200 LUTs
- Top-level logic: ~200-300 LUTs
- **Total: ~1700-2600 LUTs** (well under 5280 limit!)
- **Savings vs I2C**: ~500-1000 LUTs (no massive IP blocks!)

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
2. ⏳ SPI controller (soft, for both IMUs)
3. ⏳ BNO085 SPI interface (quaternion + gyro)
4. ⏳ Quaternion-to-Euler conversion (DSP)
5. ⏳ Full gesture recognition logic
6. ⏳ BRAM buffer implementation
7. ⏳ Calibration logic
8. ⏳ Test bench

## References

- [iCE40UP5K Datasheet](https://www.farnell.com/datasheets/3215488.pdf)
- [BNO055 Datasheet](https://cdn-learn.adafruit.com/downloads/pdf/adafruit-bno055-absolute-orientation-sensor.pdf)
- Original C code: `src/main.c`
- Original Python code: `PYTHON/collect_data.py`

