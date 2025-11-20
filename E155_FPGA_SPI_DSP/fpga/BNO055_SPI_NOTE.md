# CRITICAL: BNO055 Does NOT Support SPI

## Important Finding

After reviewing the [BNO055 datasheet](https://cdn-learn.adafruit.com/downloads/pdf/adafruit-bno055-absolute-orientation-sensor.pdf), **BNO055 does NOT support SPI interface**.

### BNO055 Supported Interfaces:
- **I²C** (up to 400 kHz Fast Mode)
- **UART** (up to 115200 baud)

### BNO055 Does NOT Support:
- ❌ **SPI** - Not available on this sensor

## Options

### Option 1: Use I²C (Recommended)
- BNO055 natively supports I²C
- Can use iCE40UP5K's hardened I²C IP blocks
- Well-documented interface
- **This is what we'll implement**

### Option 2: Use UART
- BNO055 supports UART
- Requires UART controller in FPGA
- More complex than I²C

### Option 3: Use Different IMU with SPI
- Would require hardware change
- Not recommended if you already have BNO055

## Decision

**We will use I²C for BNO055 communication** (not SPI), but still leverage:
- ✅ **DSP blocks** for quaternion-to-Euler conversion
- ✅ **BRAM** for data buffering
- ✅ **Two IMUs** via I²C (can use both I²C controllers on UP5K)

## Updated Architecture

- **I²C1**: Connect to BNO055 #1 (Right hand)
- **I²C2**: Connect to BNO055 #2 (Left hand)
- **DSP blocks**: For quaternion math (multiply, accumulate)
- **BRAM**: For quaternion/Euler data buffering
- **Full gesture recognition**: Matching original C/Python code logic

