# BNO055 vs BNO085 - SPI Implementation

## ⚠️ IMPORTANT: Sensor Selection

### BNO055 (Original Sensor)
- **Interface**: **I2C ONLY** (does NOT support SPI)
- **Requires hardened I2C IP blocks** (~1000+ LUTs each)
- **Too resource-intensive** for our design

### BNO085 (SPI-Compatible Sensor)
- **Interface**: **I2C AND SPI** (supports both)
- **Similar hardware** to BNO055 (same physical chip)
- **Different firmware** (Hillcrest SH-2 vs Bosch)
- **SPI support** - can use soft SPI controller (~300-500 LUTs)
- **Same sensor data** available (quaternion, gyro, Euler)

## Decision: Use BNO085 with SPI

**Why SPI?**
- **Avoid massive I2C IP blocks** (saves ~1000+ LUTs per IMU)
- **Soft SPI controller** is much smaller (~300-500 LUTs total)
- **Faster communication** (up to 10 MHz vs 400 kHz)
- **Simpler protocol** - easier to implement

**Why BNO085?**
- **Same physical hardware** as BNO055
- **SPI interface** available
- **Same sensor data** (quaternion, gyro, Euler angles)
- **Compatible** with original gesture recognition logic

## Implementation Notes

- **Two BNO085 sensors** via SPI (two CS lines)
- **Soft SPI controller** (no hardened IP needed)
- **Same gesture recognition** logic (quaternion→Euler→yaw/pitch/gyro)
- **Same thresholds** and ranges as original code
- **Resource savings**: ~1500-2000 LUTs vs I2C IP blocks

## BNO085 SPI Protocol

- **Mode 3**: CPOL=1, CPHA=1 (clock idle high)
- **Clock**: 1-10 MHz (BNO085 supports up to 10 MHz)
- **CS lines**: One per IMU (CS1, CS2)
- **Data format**: Same quaternion/gyro/Euler as BNO055

