# BNO085 FPGA Drum Set Implementation

This directory contains the SystemVerilog implementation of a gesture detection system for an invisible drum set using BNO085 IMU sensors and an FPGA.

## Overview

This implementation ports the gesture detection logic from the Arduino-based system (`main.c`) to SystemVerilog for FPGA execution. The system uses two BNO085 sensors (one per drumstick) connected via SPI, processes quaternion and gyroscope data, and outputs drum sound codes via SPI to an MCU.

## System Architecture

```
BNO085 Sensor 1 (Right Hand)
    ↓ SPI
SPI Master 1 → BNO085 Controller 1 → Quaternion to Euler → Gesture Detector
                                                                  ↓
                                                              SPI to MCU
                                                                  ↓
BNO085 Sensor 2 (Left Hand)                                    MCU
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

### 5. `spi_to_mcu.sv`
- SPI master module for MCU communication
- SPI Mode 0 (CPOL=0, CPHA=0)
- Sends 8-bit sound codes to MCU
- Handles CS assertion/deassertion

### 6. `drum_set_top.sv`
- Top-level module integrating all components
- Manages two BNO085 sensors
- Handles calibration button
- Outputs to MCU via SPI
- Uses internal HSOSC for clock generation (3MHz)

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
- **DI/MOSI**: SPI Master Out (from FPGA)
- **SDA/MISO**: SPI Master In (to FPGA)
- **CS**: Chip Select (from FPGA, active low, 10kΩ pull-up)
- **INT**: Interrupt (REQUIRED for stable SPI, to FPGA, 10kΩ pull-up)
- **RST**: Reset (tie to 3.3V, active low, keep HIGH)
- **P0**: Mode select (MUST be HIGH/3.3V for SPI mode - CRITICAL!)
- **P1**: Mode select (MUST be HIGH/3.3V for SPI mode - CRITICAL!)

### FPGA Pin Assignments
See `constraints_example.txt` for complete pin assignments:
- **Sensor 1**: sclk1 (P20), mosi1 (P13), miso1 (P12), cs_n1 (P18), int1 (P9)
- **Sensor 2**: sclk2 (P4), mosi2 (P47), miso2 (P6), cs_n2 (P48), int2 (P3)
- **MCU SPI**: mcu_sclk (P21), mcu_mosi (P10), mcu_cs_n (P19)
- **Buttons**: calib_button (P11), kick_button (P2)
- **LEDs**: led_initialized (P28), led_error (P38)
- **Reset**: rst_n (P43, active LOW)

## Setup Instructions

1. **Synthesize the design**:
   ```bash
   # Using your FPGA toolchain (e.g., Lattice Diamond, Vivado, Quartus)
   # Add all .sv files to your project
   ```

2. **Clock configuration**:
   - System uses internal HSOSC (48MHz) divided to 3MHz
   - SPI clock is ~3MHz (meets BNO085 specifications)
   - For simulation, uncomment simulation clock in `drum_set_top.sv`

3. **Configure BNO085 sensors**:
   - **CRITICAL**: Connect P0 and P1 pins to 3.3V (HIGH) for SPI mode
   - Connect INT pins to FPGA (P9 for sensor 1, P3 for sensor 2) - REQUIRED for stable SPI
   - Connect RST to 3.3V (keep HIGH, active LOW)
   - See `BNO085_WIRING_GUIDE.md` for complete wiring instructions

4. **Connect MCU**:
   - FPGA acts as SPI master, MCU as SPI slave
   - MCU receives 8-bit sound codes via SPI Mode 0
   - See `HARDWARE_IMPLEMENTATION_GUIDE.md` for MCU connection details

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


