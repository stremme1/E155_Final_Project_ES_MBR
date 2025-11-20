# Gesture Recognition Logic - Complete Algorithm

## Overview

This document describes the complete gesture recognition algorithm matching the original C/Python code.

## Data Flow

1. **Read Quaternion** (w, x, y, z) from BNO055 via I²C
2. **Convert to Euler** (yaw, pitch, roll) using DSP blocks
3. **Normalize Yaw** to 0-360 range with offset calibration
4. **Read Gyroscope** (x, y, z) from BNO055 via I²C
5. **Detect Gesture** based on yaw ranges, pitch thresholds, and gyro triggers
6. **Output Sound ID** (0-7 or 255 for no sound)

## Sound IDs

```systemverilog
localparam NO_SOUND = 8'hFF;
localparam SOUND_SNARE = 8'h00;
localparam SOUND_HIHAT = 8'h01;
localparam SOUND_KICK = 8'h02;
localparam SOUND_HIGH_TOM = 8'h03;
localparam SOUND_MID_TOM = 8'h04;
localparam SOUND_CRASH = 8'h05;
localparam SOUND_RIDE = 8'h06;
localparam SOUND_FLOOR_TOM = 8'h07;
```

## Thresholds

```systemverilog
localparam signed [15:0] GYRO_THRESHOLD_Y = -16'd2500;  // Gyro Y trigger
localparam signed [15:0] GYRO_THRESHOLD_Z = -16'd2000;  // Gyro Z for hi-hat
localparam [7:0] PITCH_THRESHOLD_HIGH = 8'd50;          // Pitch for cymbals
localparam [7:0] PITCH_THRESHOLD_LOW = 8'd30;           // Pitch for ride/floor tom
```

## Right Hand Logic (IMU1)

### Yaw Ranges and Sounds

1. **Yaw 20-120°**: Snare drum
   - Trigger: `gyro1_y < -2500`
   - Sound: `SOUND_SNARE` (0)

2. **Yaw 340-360° or 0-20°**: High tom or Crash
   - Trigger: `gyro1_y < -2500`
   - If `pitch1 > 50`: `SOUND_CRASH` (5)
   - Else: `SOUND_HIGH_TOM` (3)

3. **Yaw 305-340°**: Mid tom or Ride
   - Trigger: `gyro1_y < -2500`
   - If `pitch1 > 50`: `SOUND_RIDE` (6)
   - Else: `SOUND_MID_TOM` (4)

4. **Yaw 200-305°**: Floor tom or Ride
   - Trigger: `gyro1_y < -2500`
   - If `pitch1 > 30`: `SOUND_RIDE` (6)
   - Else: `SOUND_FLOOR_TOM` (7)

## Left Hand Logic (IMU2)

### Yaw Ranges and Sounds

1. **Yaw 350-360° or 0-100°**: Snare or Hi-hat
   - Trigger: `gyro2_y < -2500`
   - If `pitch2 > 30 && gyro2_z > -2000`: `SOUND_HIHAT` (1)
   - Else: `SOUND_SNARE` (0)

2. **Yaw 325-350°**: High tom or Crash
   - Trigger: `gyro2_y < -2500`
   - If `pitch2 > 50`: `SOUND_CRASH` (5)
   - Else: `SOUND_HIGH_TOM` (3)

3. **Yaw 300-325°**: Mid tom or Ride
   - Trigger: `gyro2_y < -2500`
   - If `pitch2 > 50`: `SOUND_RIDE` (6)
   - Else: `SOUND_MID_TOM` (4)

4. **Yaw 200-300°**: Floor tom or Ride
   - Trigger: `gyro2_y < -2500`
   - If `pitch2 > 30`: `SOUND_RIDE` (6)
   - Else: `SOUND_FLOOR_TOM` (7)

## Button Logic

### Button 1: Kick Drum
- **Action**: Output `SOUND_KICK` (2) when pressed
- **Debounce**: 50 ms

### Button 2: Calibration
- **Action**: Set current yaw values as new zero (north)
- **Effect**: `yawOffset1 = current_yaw1`, `yawOffset2 = current_yaw2`
- **Debounce**: 50 ms

## Quaternion to Euler Conversion

From `bno055.c`:
```c
roll = atan2(2.0 * (w * x + y * z), 1.0 - 2.0 * (x * x + y * y));
pitch = asin(2.0 * (w * y - z * x));
yaw = atan2(2.0 * (w * z + x * y), 1.0 - 2.0 * (y * y + z * z));
// Convert to degrees
roll = roll * 180.0 / M_PI;
pitch = pitch * 180.0 / M_PI;
yaw = yaw * 180.0 / M_PI;
```

## Yaw Normalization

```c
float normalizeYaw(float yaw) {
    yaw = fmod(yaw, 360.0);
    if (yaw < 0) {
        yaw += 360.0;
    }
    return yaw;
}
```

After applying offset:
```c
yaw1 = normalizeYaw(yaw1 - yawOffset1);
yaw2 = normalizeYaw(yaw2 - yawOffset2);
```

## Debouncing

- **Gyro triggers**: Use edge detection to prevent multiple triggers
- **Flag reset**: Reset trigger flag when gyro returns above threshold
- **Button debounce**: 50 ms delay for buttons

