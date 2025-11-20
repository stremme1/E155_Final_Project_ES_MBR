# SPI Configuration for BNO055

## Overview

Using SPI instead of I2C for BNO055 communication provides:
- **Faster data transfer** (up to 10+ MHz)
- **Simpler implementation** (no hardened IP needed)
- **Lower resource usage** (soft SPI controller)

## BNO055 SPI Configuration

### SPI Mode
- **Mode 3**: CPOL=1, CPHA=1 (clock idle high, data on falling edge)
- **Clock Speed**: 1-10 MHz (BNO055 supports up to 10 MHz)
- **Bit Order**: MSB first

### SPI Protocol
- **8-bit transfers**
- **Read**: Set bit 7 of address (0x80)
- **Write**: Clear bit 7 of address (0x00)
- **Multi-byte**: Auto-increment address if bit 6 is set

### Gyroscope Registers (SPI)
- **GYRO_DATA_X_LSB**: 0x14 (read-only, 2 bytes)
- **GYRO_DATA_Y_LSB**: 0x16 (read-only, 2 bytes)
- **GYRO_DATA_Z_LSB**: 0x18 (read-only, 2 bytes)
- **PAGE_ID**: 0x07 (to select register page)

## Implementation Notes

1. **SPI Controller**: Soft implementation, no hardened IP needed
2. **Clock Divider**: Divide system clock (48 MHz) to get 1-10 MHz SPI clock
3. **CS Management**: Assert CS before transaction, deassert after
4. **Data Format**: 16-bit signed integers (same as I2C version)

## Resource Usage

- **LUTs**: ~300-500 for soft SPI controller
- **No DSP blocks needed** for SPI
- **No BRAM needed** for SPI (use registers for buffering)

