# SPI Configuration for BNO085

## Overview

Using SPI instead of I2C for BNO085 communication provides:
- **Faster data transfer** (up to 10+ MHz vs 400 kHz I2C)
- **Simpler implementation** (soft SPI controller, no hardened IP)
- **Much lower resource usage** (~300-500 LUTs vs ~1000+ per I2C IP block)
- **Shared bus** - one SPI controller for both IMUs (just different CS lines)

## BNO085 SPI Configuration

### ⚠️ CRITICAL: Protocol Selection Pins
- **PS0 (P0)**: Must be **HIGH (3.3V)** to enable SPI mode
- **PS1 (P1)**: Must be **HIGH (3.3V)** to enable SPI mode
- **If PS0/PS1 are not HIGH, BNO085 will NOT work in SPI mode!**

### SPI Mode
- **Mode 3**: CPOL=1, CPHA=1 (clock idle high, data on falling edge)
- **Clock Speed**: 1-10 MHz (BNO085 supports up to 10 MHz)
- **Recommended**: 5 MHz for reliable operation
- **Bit Order**: MSB first

### SPI Protocol: SHTP (Sensor Hub Transport Protocol)
- **Header-based protocol** (NOT register-based like BNO055)
- **Reports**: Request specific report types (quaternion, gyro, etc.)
- **Packet structure**: [Header] [Length LSB] [Length MSB] [Data...]
- **16-bit length field** followed by data payload

### Key Reports (BNO085)
- **Rotation Vector (Quaternion)**: Report ID `0x05` - 4x 16-bit (w, x, y, z)
- **Gyroscope**: Report ID `0x06` - 3x 16-bit (x, y, z)
- **Game Rotation Vector**: Report ID `0x08` (alternative quaternion)
- **Magnetometer**: Report ID `0x09`

### Required Pins (Per BNO085)
- **CS**: Chip Select (active LOW, unique per IMU)
- **INT**: Interrupt (active LOW, data ready signal) - **REQUIRED**
- **RST**: Reset (active LOW, reset control) - **REQUIRED**

### Two IMUs Setup
- **Shared SPI bus**: SCLK, MOSI, MISO (shared between both)
- **Separate CS lines**: CS1 (Right hand), CS2 (Left hand)
- **Separate INT lines**: INT1, INT2 (data ready per IMU)
- **Separate RST lines**: RST1, RST2 (reset control per IMU)
- **Time-multiplexed** access (select one IMU at a time via CS)

## Implementation Notes

1. **SPI Controller**: Soft implementation, no hardened IP needed
2. **Clock Divider**: Divide system clock (48 MHz) by 10 = 4.8 MHz SPI clock
3. **CS Management**: Assert CS (LOW) before transaction, deassert (HIGH) after
4. **INT Handling**: Poll INT pins or use edge detection for data ready
5. **RST Management**: Hold RST LOW for 100ms on power-up, then HIGH
6. **Time-multiplexing**: Alternate between CS1 and CS2 for two IMUs
7. **SHTP Protocol**: Must implement SHTP packet parsing (header + length + data)
8. **Report Enable**: Must send enable commands for each report type (quaternion, gyro)
9. **Data Format**: Same quaternion/gyro/Euler as BNO055 (compatible for gesture recognition)

## Resource Usage

- **LUTs**: ~300-500 for soft SPI controller (ONE controller for both IMUs!)
- **Savings**: ~1500-2000 LUTs vs using two I2C IP blocks
- **No DSP blocks needed** for SPI communication
- **No BRAM needed** for SPI (use registers for buffering)

