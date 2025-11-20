# Gesture Recognition Logic - Complete Specification

## Overview

This document describes the complete gesture recognition algorithm matching the original C/Python code in `src/main.c`.

## Sound IDs

```
0 = Snare drum
1 = Hi-hat
2 = Kick drum (button)
3 = High tom
4 = Mid tom
5 = Crash cymbal
6 = Ride cymbal
7 = Floor tom
255 = No sound
```

## Thresholds

- **Gyro Y threshold**: -2500 (negative Y = downward motion = hit)
- **Gyro Z threshold**: -2000 (for hi-hat detection)
- **Pitch high threshold**: 50 degrees (cymbal vs tom)
- **Pitch low threshold**: 30 degrees (ride vs floor tom)

## Right Hand Logic (IMU1, address 0x28)

### Yaw Ranges and Sounds

1. **Yaw 20-120°**: Snare drum
   - Trigger: `gyro1_y < -2500`
   - Sound: 0 (Snare)

2. **Yaw 340-360° or 0-20°**: High tom or Crash
   - Trigger: `gyro1_y < -2500`
   - If `pitch1 > 50°`: Sound 5 (Crash)
   - Else: Sound 3 (High tom)

3. **Yaw 305-340°**: Mid tom or Ride
   - Trigger: `gyro1_y < -2500`
   - If `pitch1 > 50°`: Sound 6 (Ride)
   - Else: Sound 4 (Mid tom)

4. **Yaw 200-305°**: Floor tom or Ride
   - Trigger: `gyro1_y < -2500`
   - If `pitch1 > 30°`: Sound 6 (Ride)
   - Else: Sound 7 (Floor tom)

## Left Hand Logic (IMU2, address 0x29)

### Yaw Ranges and Sounds

1. **Yaw 350-360° or 0-100°**: Snare or Hi-hat
   - Trigger: `gyro2_y < -2500`
   - If `pitch2 > 30°` AND `gyro2_z > -2000`: Sound 1 (Hi-hat)
   - Else: Sound 0 (Snare)

2. **Yaw 325-350°**: High tom or Crash
   - Trigger: `gyro2_y < -2500`
   - If `pitch2 > 50°`: Sound 5 (Crash)
   - Else: Sound 3 (High tom)

3. **Yaw 300-325°**: Mid tom or Ride
   - Trigger: `gyro2_y < -2500`
   - If `pitch2 > 50°`: Sound 6 (Ride)
   - Else: Sound 4 (Mid tom)

4. **Yaw 200-300°**: Floor tom or Ride
   - Trigger: `gyro2_y < -2500`
   - If `pitch2 > 30°`: Sound 6 (Ride)
   - Else: Sound 7 (Floor tom)

## Button Logic

### Button1 (Right Hand)
- **Function**: Kick drum
- **Sound**: 2 (Kick)
- **Debounce**: 50 ms

### Button2 (Left Hand)
- **Function**: Calibration
- **Action**: Sets current yaw values as new zero (north)
- **Updates**: `yawOffset1` and `yawOffset2`
- **Debounce**: 50 ms

## Yaw Normalization

Yaw values are normalized to 0-360° range:
```c
yaw = fmod(yaw, 360.0);
if (yaw < 0) {
    yaw += 360.0;
}
```

## Gyro Debouncing

Each IMU has a debounce flag (`printedForGyro1y`, `printedForGyro2y`):
- **Set** when `gyro_y < -2500` and flag is false
- **Clear** when `gyro_y >= -2500` and flag is true
- **Prevents** multiple triggers from single hit

## Data Flow

1. **Read quaternion** from BNO055 (w, x, y, z)
2. **Convert to Euler** (yaw, pitch, roll) using DSP blocks
3. **Read gyroscope** (x, y, z)
4. **Apply yaw offsets** and normalize
5. **Check yaw ranges** and gyro triggers
6. **Apply pitch thresholds** for cymbal distinction
7. **Output sound ID**

## Implementation Notes

- **Fixed-point arithmetic** for FPGA efficiency
- **DSP blocks** for quaternion multiplication
- **BRAM** for data buffering
- **State machines** for I²C communication
- **Pipeline** for quaternion→Euler conversion

