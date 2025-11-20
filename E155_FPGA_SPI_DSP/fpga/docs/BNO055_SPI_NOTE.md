# BNO055 SPI Support - Critical Note

## ⚠️ IMPORTANT: BNO055 vs BNO085

Based on the datasheets:

### BNO055 (Original Sensor)
- **Interface**: **I2C ONLY** (does NOT support SPI)
- **Addresses**: 0x28 (default), 0x29 (with ADR pin)
- **Quaternion + Euler + Gyro** data available
- **Used in original C/Python code**

### BNO085 (Alternative Sensor)
- **Interface**: **I2C AND SPI** (supports both)
- **Similar hardware** to BNO055 but different firmware
- **More features** (activity classification, tap detection, etc.)
- **SPI support** available

## Decision for This Project

Since the original code uses **BNO055** and we want to match the original specs:

### Option 1: Use BNO055 with I2C (Recommended)
- **Matches original code exactly**
- **Use hardened I2C IP blocks** on iCE40UP5K
- **Two I2C controllers** available (I2C1 and I2C2)
- **Address 0x28** for IMU1, **0x29** for IMU2

### Option 2: Use BNO085 with SPI
- **Requires different sensor hardware**
- **SPI interface** (faster, simpler)
- **Different register map** - code needs adaptation
- **More features** but different from original

## Recommendation

**Use BNO055 with I2C** to match the original implementation exactly:
- Same sensor as original code
- Same register addresses
- Same data format
- Same calibration procedure

However, if you want to use SPI for simplicity, you would need to:
1. Switch to BNO085 sensors, OR
2. Use a different IMU that supports SPI

## Current Implementation Plan

This implementation will support **BNO055 with I2C** to match original specs, but the architecture can be adapted for SPI if BNO085 sensors are used instead.

