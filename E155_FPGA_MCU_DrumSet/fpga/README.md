# BNO085 FPGA Drum Set Implementation

This directory contains the SystemVerilog implementation of a gesture detection system for an invisible drum set using BNO085 IMU sensors and an FPGA.

## Overview

This implementation ports the gesture detection logic from the Arduino-based system (`main.c`) to SystemVerilog for FPGA execution. The system uses two BNO085 sensors (one per drumstick) connected via SPI, processes quaternion and gyroscope data, and outputs drum sound codes via UART.

## System Architecture

```
BNO085 Sensor 1 (Right Hand)
    ↓ SPI
SPI Master 1 → BNO085 Controller 1 → Quaternion to Euler → Gesture Detector
                                                                  ↓
                                                              UART TX
                                                                  ↓
BNO085 Sensor 2 (Left Hand)                                 Python Script
    ↓ SPI                                                         ↓
SPI Master 2 → BNO085 Controller 2 → Quaternion to Euler → Audio Playback
```

## Modules

### 1. `spi_master.sv`
- SPI master module for BNO085 communication
- Supports SPI Mode 3 (CPOL=1, CPHA=1)
- Configurable clock divider
- Full-duplex communication

### 2. `bno085_controller.sv`
- Implements SHTP (Sensor Hub Transport Protocol) over SPI
- Handles sensor initialization
- Enables Rotation Vector and Gyroscope reports
- Parses incoming sensor data packets

### 3. `quaternion_to_euler.sv`
- Converts quaternion (w, x, y, z) to Euler angles (roll, pitch, yaw)
- Uses fixed-point arithmetic
- Outputs angles in degrees

### 4. `gesture_detector.sv`
- Implements the same gesture detection logic from `main.c`
- Detects drum hits based on:
  - Yaw zones (direction of drumstick)
  - Pitch angles (elevation for cymbal detection)
  - Gyroscope thresholds (strike detection)
- Outputs sound codes (0-7) matching the original system

### 5. `uart_tx.sv`
- UART transmitter for outputting sound codes
- Configurable baud rate (default: 115200)
- Converts sound codes to ASCII characters

### 6. `drum_set_top.sv`
- Top-level module integrating all components
- Manages two BNO085 sensors
- Handles calibration button
- Outputs to UART

## Sound Code Mapping

| Code | Sound        |
|------|--------------|
| 0    | Snare drum   |
| 1    | Hi-hat       |
| 2    | Kick drum    |
| 3    | High tom     |
| 4    | Mid tom      |
| 5    | Crash cymbal |
| 6    | Ride cymbal  |
| 7    | Floor tom    |

## Gesture Detection Zones

### Right Hand (IMU 1)
- **Zone 1 (20°-120°)**: Snare drum
- **Zone 2 (340°-20°)**: High tom or Crash (if pitch > 50°)
- **Zone 3 (305°-340°)**: Mid tom or Ride (if pitch > 50°)
- **Zone 4 (200°-305°)**: Floor tom or Ride (if pitch > 30°)

### Left Hand (IMU 2)
- **Zone 1 (350°-100°)**: Snare or Hi-hat (if pitch > 30° and gyro_z > -2000)
- **Zone 2 (325°-350°)**: High tom or Crash (if pitch > 50°)
- **Zone 3 (300°-325°)**: Mid tom or Ride (if pitch > 50°)
- **Zone 4 (200°-300°)**: Floor tom or Ride (if pitch > 30°)

## Thresholds

- **Gyro Y Threshold**: -2500 (strike detection)
- **Gyro Z Threshold**: -2000 (hi-hat rotation detection)
- **Pitch Crash Threshold**: 50° (crash/ride detection)
- **Pitch Ride Threshold**: 30° (ride detection)

## Hardware Connections

### BNO085 Sensor Connections (per sensor)
- **VIN**: 3.3V or 5V (board has regulator)
- **GND**: Ground
- **SCL/SCK**: SPI Clock (from FPGA)
- **SDA/MOSI**: SPI Master Out (from FPGA)
- **SDO/MISO**: SPI Master In (to FPGA)
- **CS**: Chip Select (from FPGA, active low)
- **INT**: Interrupt (optional, to FPGA)
- **RST**: Reset (optional, to FPGA or pull-up)

### FPGA Pin Assignments
Assign pins based on your FPGA board:
- SPI clocks, MOSI, MISO, CS for each sensor
- UART TX pin
- Button inputs (calibration, kick)
- Status LEDs (optional)

## Setup Instructions

1. **Synthesize the design**:
   ```bash
   # Using your FPGA toolchain (e.g., Lattice Diamond, Vivado, Quartus)
   # Add all .sv files to your project
   ```

2. **Set clock frequency**:
   - Update `CLK_FREQ` in `uart_tx.sv` to match your system clock
   - Adjust `CLK_DIV` in `spi_master.sv` to achieve ~3MHz SPI clock

3. **Configure BNO085 sensors**:
   - Ensure sensors are configured for SPI mode (not I2C)
   - Check that ADR pins are set correctly if using multiple sensors

4. **Connect to Python script**:
   - Use the existing `play_sound.py` script
   - Update serial port in Python script to match your UART connection

5. **Calibration**:
   - Press calibration button while holding drumsticks in desired "zero" position
   - System will capture current yaw values as offsets

## Important Notes

### BNO085 SHTP Protocol
The BNO085 uses a packet-based protocol (SHTP) over SPI:
- 4-byte header: [Length LSB, Length MSB, Channel, Sequence]
- Variable-length payload
- Reports arrive on different channels

### Quaternion Format
- BNO085 outputs quaternions in Q14 format (1.14 fixed point)
- Range: -1.0 to +1.0
- Convert to Q16 format for Euler conversion

### Gyroscope Format
- BNO085 outputs gyro in rad/s * 900 (Q9 format)
- Scale appropriately for your thresholds

### Limitations
1. **Quaternion to Euler conversion**: Current implementation uses simplified math. For production, consider using CORDIC algorithm or lookup tables for accurate atan2/asin calculations.

2. **SPI timing**: Ensure SPI clock meets BNO085 specifications (max 3MHz).

3. **Data rate**: System processes data at ~50Hz (20ms intervals). Adjust report intervals in `bno085_controller.sv` if needed.

4. **Error handling**: Basic error handling is implemented. Add more robust error recovery for production use.

## Testing

1. **Simulation**: Create testbenches for each module to verify functionality
2. **Hardware**: Use oscilloscope/logic analyzer to verify SPI communication
3. **Integration**: Test with actual BNO085 sensors and verify gesture detection

## Future Improvements

- [ ] Implement CORDIC for accurate quaternion to Euler conversion
- [ ] Add velocity sensitivity based on gyro magnitude
- [ ] Implement pattern recording/playback
- [ ] Add more robust error handling and recovery
- [ ] Optimize for lower latency
- [ ] Add support for additional sensors (piezo, buttons)

## References

- [BNO085 Datasheet](https://cdn-learn.adafruit.com/downloads/pdf/adafruit-9-dof-orientation-imu-fusion-breakout-bno085.pdf)
- Original Arduino implementation: `../src/main.c`
- Python audio playback: `../PYTHON/play_sound.py`


