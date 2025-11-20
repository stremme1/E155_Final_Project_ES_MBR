# FPGA Drum System - SPI + DSP + BRAM Implementation

## Architecture Overview

This is a fresh implementation optimized for iCE40UP5K using:
- **SPI** for gyroscope communication (instead of I2C)
- **DSP blocks** for math operations (multiply, accumulate)
- **BRAM** for data buffering and storage
- **Ultra-minimal** design to fit within 5280 LUTs

## Key Advantages

### SPI vs I2C
- **Faster data transfer** (up to 10+ MHz vs 400 kHz I2C)
- **Simpler protocol** - easier to implement in FPGA
- **Less resource usage** - no need for hardened I2C IP blocks
- **More flexible** - can use soft SPI controller

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
2. **Use SPI** for BNO055 gyroscope communication
3. **Leverage DSP blocks** for all multiplications
4. **Use BRAM** for data storage and buffering
5. **Minimal state machines** - keep logic simple

## File Structure

```
E155_FPGA_SPI_DSP/
├── fpga/
│   ├── README.md (this file)
│   ├── verilog/
│   │   ├── drum_system_top.sv          # Top-level module
│   │   ├── spi_controller.sv            # SPI master controller
│   │   ├── bno055_spi_gyro.sv           # BNO055 SPI interface (gyro only)
│   │   ├── gesture_recognition_dsp.sv   # Gesture recognition using DSP
│   │   └── bram_buffer.sv               # BRAM data buffer
│   └── docs/
│       ├── SPI_SETUP.md                 # SPI configuration guide
│       ├── DSP_USAGE.md                 # DSP block usage guide
│       └── BRAM_USAGE.md                # BRAM usage guide
```

## Resource Allocation Plan

### LUTs (Target: <5000)
- SPI Controller: ~300-500 LUTs
- BNO055 Interface: ~200-300 LUTs
- Gesture Recognition: ~300-400 LUTs
- Top-level logic: ~200-300 LUTs
- **Total: ~1000-1500 LUTs** (plenty of margin!)

### DSP Blocks (8 available)
- Gyro data filtering: 1-2 DSP blocks
- Gesture calculations: 1-2 DSP blocks
- **Total: 2-4 DSP blocks** (well within limit)

### BRAM (120 kb available)
- Gyro data buffer: ~2-4 kb (256-512 samples)
- Filter coefficients: ~1 kb
- Gesture thresholds: ~1 kb
- **Total: ~4-6 kb** (plenty of space!)

## Next Steps

1. Create SPI controller module
2. Create BNO055 SPI interface
3. Create gesture recognition with DSP
4. Create BRAM buffer module
5. Integrate everything in top-level module

