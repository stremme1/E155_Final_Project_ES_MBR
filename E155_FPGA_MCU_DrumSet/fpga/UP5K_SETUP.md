# iCE40UP5K Setup Guide - Two I2C Peripheral Blocks

## Overview

Your design **already uses two I2C peripheral blocks** - this is exactly what you need! The iCE40UP5K has two hardened I2C IP blocks that can operate independently.

## Current Design Configuration

Your `drum_system_top.sv` is already configured to use:

1. **I2C1 (Left I2C)** → IMU 1 (Right Hand)
2. **I2C2 (Right I2C)** → IMU 2 (Left Hand)

Both I2C controllers operate **independently** and use **different physical pins**.

## iCE40UP5K I2C Peripheral Blocks

The iCE40UP5K has **two hardened I2C IP blocks**:

- **Left I2C (I2C1)**: Located at upper left corner
- **Right I2C (I2C2)**: Located at upper right corner

These are **hardware I2C controllers** - not software implementations. They provide:
- Dedicated I2C protocol handling
- Hardware-level I2C transactions
- Independent operation (can run simultaneously)
- System Bus interface for control

## Module Generator Configuration for UP5K

### Step 1: Enable Both I2C Blocks

In Module Generator:

1. **General Tab**:
   - ✅ **Enable Left I2C** (I2C1)
   - ✅ **Enable Right I2C** (I2C2)
   - **System Clock**: 48 MHz (for HFOSC/HSOC)
   - **Configuration Clock Source**: HFOSC/HSOC

### Step 2: Configure I2C1 (Left I2C - IMU 1)

**I2C Tab**:
- **Mode**: Master
- **I2C Clock Rate (Desired)**: 400 kHz
- **System Clock**: 48 MHz
- **I2C Clock Rate (Actual)**: Should show ~400 kHz
- **Addressing**: 7-bit
- **Interrupts**: Enable "TX/RX Ready"

### Step 3: Configure I2C2 (Right I2C - IMU 2)

**I2C Tab**:
- **Mode**: Master
- **I2C Clock Rate (Desired)**: 400 kHz
- **System Clock**: 48 MHz
- **I2C Clock Rate (Actual)**: Should show ~400 kHz
- **Addressing**: 7-bit
- **Interrupts**: Enable "TX/RX Ready"

### Step 4: Generate IP

Click **Generate** to create the Soft IP wrappers for both I2C blocks.

## UP5K Pin Assignments

### I2C Pins (Automatic - Module Generator)

The Module Generator will automatically assign I2C pins. For UP5K:

**I2C1 (Left I2C)**:
- Uses dedicated I2C pins at upper left corner
- Pin numbers depend on your package (WLCSP or QFN)
- Check generated `.pdc` file for exact pin numbers

**I2C2 (Right I2C)**:
- Uses dedicated I2C pins at upper right corner
- Different pins from I2C1
- Pin numbers depend on your package

**Important**: 
- I2C pins are **open-drain** - pull-up resistors are required
- **On-board 10kΩ pull-ups**: If your board has them, these are **perfect** for 400kHz I2C
- **External 10kΩ pull-ups**: Use if on-board pull-ups are not available
- Internal pull-ups (50kΩ-100kΩ) are too weak for 400kHz I2C - **not recommended**
- Each I2C bus needs its own pull-ups (4 total: 2 for I2C1, 2 for I2C2)
- **See `I2C_PULLUP_GUIDE.md`** for detailed information on pull-up options

### User Interface Pins (Manual Assignment)

For UP5K, you have **39 GPIO pins** available (48-ball QFN package). Assign:

```
button1       -> Any GPIO (e.g., GPIO_0)
button2       -> Any GPIO (e.g., GPIO_1)
led1          -> Any GPIO (e.g., GPIO_2)
led2          -> Any GPIO (e.g., GPIO_3)
sound_id[0]   -> Any GPIO (e.g., GPIO_4)
sound_id[1]   -> Any GPIO (e.g., GPIO_5)
sound_id[2]   -> Any GPIO (e.g., GPIO_6)
sound_id[3]   -> Any GPIO (e.g., GPIO_7)
sound_id[4]   -> Any GPIO (e.g., GPIO_8)
sound_id[5]   -> Any GPIO (e.g., GPIO_9)
sound_id[6]   -> Any GPIO (e.g., GPIO_10)
sound_id[7]   -> Any GPIO (e.g., GPIO_11)
rst_n         -> Any GPIO or dedicated reset
```

## Hardware Connections for UP5K

### I2C1 Connections (Left I2C - IMU 1)

```
BNO055 Sensor 1 (Right Hand):
  VIN  -> 3.3V
  GND  -> GND
  SCL  -> I2C1_SCL pin (with 10kΩ pull-up to 3.3V)
  SDA  -> I2C1_SDA pin (with 10kΩ pull-up to 3.3V)
  ADR  -> GND (for address 0x28)
```

### I2C2 Connections (Right I2C - IMU 2)

```
BNO055 Sensor 2 (Left Hand):
  VIN  -> 3.3V
  GND  -> GND
  SCL  -> I2C2_SCL pin (with 10kΩ pull-up to 3.3V)
  SDA  -> I2C2_SDA pin (with 10kΩ pull-up to 3.3V)
  ADR  -> 3.3V (for address 0x29) OR GND (if using different addressing scheme)
```

**Note**: If both sensors use address 0x28, you must set one ADR to GND and one to 3.3V to get different addresses.

## Verification Checklist

- [ ] Module Generator: Both I2C1 and I2C2 enabled
- [ ] Module Generator: Both configured as Master, 400kHz
- [ ] Module Generator: I/O Buffers enabled for both
- [ ] Generated IP files added to project
- [ ] I2C1 and I2C2 use different pins (verify in pin assignment)
- [ ] Pull-up resistors (10kΩ) on all 4 I2C lines (I2C1_SCL, I2C1_SDA, I2C2_SCL, I2C2_SDA)
- [ ] BNO055 sensors connected to correct I2C buses
- [ ] BNO055 addresses configured (0x28 and 0x29)
- [ ] User interface pins assigned
- [ ] System Bus register addresses verified

## Current Design Status

Your design is **already configured correctly** for two I2C peripheral blocks:

✅ **I2C1 Controller**: `imu1_controller` instance
✅ **I2C2 Controller**: `imu2_controller` instance
✅ **Independent Operation**: Both can run simultaneously
✅ **System Bus Interface**: Properly connected for both
✅ **IPLOAD/IPDONE**: Handled for both I2C blocks

## Next Steps

1. **Generate I2C IP** with Module Generator (enable both I2C1 and I2C2)
2. **Instantiate generated wrappers** in your design (see SETUP_GUIDE.md)
3. **Assign user interface pins** (buttons, LEDs, sound_id)
4. **Verify I2C pin assignments** (should be automatic)
5. **Add pull-up resistors** to I2C lines
6. **Connect BNO055 sensors** to correct I2C buses
7. **Synthesize and program**

## Benefits of Using Two I2C Peripheral Blocks

1. **Independent Operation**: Each IMU can be read simultaneously
2. **Hardware Acceleration**: I2C protocol handled in hardware
3. **No Software Overhead**: No need to bit-bang I2C
4. **Reliable Timing**: Hardware ensures proper I2C timing
5. **Parallel Communication**: Can communicate with both sensors at the same time

## Troubleshooting

**If I2C communication fails**:
1. Verify pull-up resistors are present (10kΩ on SCL and SDA for each bus)
2. Check I2C addresses (one sensor should be 0x28, other 0x29)
3. Verify I2C1 and I2C2 are using different pins
4. Check System Bus register addresses match generated IP
5. Verify IPLOAD/IPDONE sequence completes for both I2C blocks

**If only one IMU works**:
1. Check both I2C blocks are enabled in Module Generator
2. Verify both IPLOAD/IPDONE sequences complete
3. Check both I2C buses have pull-up resistors
4. Verify sensor addresses are different (0x28 vs 0x29)

