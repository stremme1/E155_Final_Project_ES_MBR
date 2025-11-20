# SPI Configuration for BNO085

## Overview

Using SPI instead of I2C for BNO085 communication provides:
- **Faster data transfer** (up to 10+ MHz vs 400 kHz I2C)
- **Simpler implementation** (soft SPI controller, no hardened IP)
- **Much lower resource usage** (~300-500 LUTs vs ~1000+ per I2C IP block)
- **Shared bus** - one SPI controller for both IMUs (just different CS lines)

## BNO085 SPI Configuration

### SPI Mode
- **Mode 3**: CPOL=1, CPHA=1 (clock idle high, data on falling edge)
- **Clock Speed**: 1-10 MHz (BNO085 supports up to 10 MHz)
- **Bit Order**: MSB first

### SPI Protocol
- **SHTP (Sensor Hub Transport Protocol)** - BNO085 specific
- **Header-based protocol** (not register-based like BNO055)
- **Reports**: Request specific report types (quaternion, gyro, etc.)
- **16-bit length field** followed by data

### Key Reports (BNO085)
- **Rotation Vector (Quaternion)**: Report ID 0x05
- **Gyroscope**: Report ID 0x06
- **Game Rotation Vector**: Report ID 0x08 (alternative)
- **Magnetometer**: Report ID 0x09

### Two IMUs Setup
- **Shared SPI bus** (SCLK, MOSI, MISO)
- **Separate CS lines**: CS1 (Right hand), CS2 (Left hand)
- **Time-multiplexed** access (select one IMU at a time)

## Implementation Notes

1. **SPI Controller**: Soft implementation, no hardened IP needed
2. **Clock Divider**: Divide system clock (48 MHz) to get 1-10 MHz SPI clock
3. **CS Management**: Assert CS before transaction, deassert after
4. **Time-multiplexing**: Alternate between CS1 and CS2 for two IMUs
5. **Data Format**: Same quaternion/gyro/Euler as BNO055 (compatible)

## Resource Usage

- **LUTs**: ~300-500 for soft SPI controller (ONE controller for both IMUs!)
- **Savings**: ~1500-2000 LUTs vs using two I2C IP blocks
- **No DSP blocks needed** for SPI communication
- **No BRAM needed** for SPI (use registers for buffering)

