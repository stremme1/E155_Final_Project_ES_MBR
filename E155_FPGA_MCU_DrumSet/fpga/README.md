# FPGA Drum System Implementation for iCE40

This directory contains the SystemVerilog implementation of the gesture recognition drum system for the iCE40 FPGA. The design uses the iCE40's hardened I2C IP blocks to communicate with BNO055 IMU sensors and implements gesture recognition logic directly in hardware.

## Architecture Overview

The system uses the iCE40's hardened I2C IP blocks to communicate with two BNO055 IMU sensors, processes the quaternion data to extract Euler angles, and implements gesture recognition logic to determine which drum sound to play.

### System Components

1. **drum_system_top.sv** - Top-level module that instantiates all sub-modules
   - Handles clock generation (HFOSC/HSOC for synthesis, external clock for simulation)
   - Manages calibration and button debouncing
   - Connects to I2C IP via System Bus interface
   
2. **system_bus_master.sv** - System Bus master for communicating with I2C hardened IP
   - Implements System Bus protocol (read/write operations)
   - Handles address and data transfers
   
3. **bno055_i2c_controller.sv** - I2C controller for BNO055 sensor communication
   - Manages I2C transactions through System Bus
   - Reads quaternion and gyroscope data
   - Handles sensor initialization
   
4. **quaternion_to_euler.sv** - Converts quaternion data to Euler angles (yaw, pitch, roll)
   - Uses fixed-point arithmetic for FPGA efficiency
   - Implements atan2 and asin approximations
   
5. **gesture_recognition.sv** - Implements gesture recognition logic from C code
   - Matches C code logic exactly
   - Handles debouncing and threshold detection
   - Outputs sound IDs (0-7, 255 = no sound)

6. **drum_system_top_tb.sv** - Test bench for top-level module
   - Compatible with Questa Simulator
   - Tests button functionality and system initialization

## iCE40 I2C Hardened IP Integration

**CRITICAL**: The Module Generator creates a **Soft IP wrapper** around the Hard IP. You must connect to this wrapper, not directly to the Hard IP.

### Module Generator Setup

1. **Generate I2C IP using Module Generator:**
   - Enable Left I2C (I2C1) for IMU 1 (Right Hand)
   - Enable Right I2C (I2C2) for IMU 2 (Left Hand)
   - Configure as Master mode
   - Set I2C clock rate (typically 100kHz or 400kHz)
   - Set System Clock frequency (e.g., 48MHz if using HFOSC/HSOC)
   - Enable interrupts (TX/RX Ready recommended)

2. **Soft IP Wrapper Interface:**
   The Module Generator creates a Soft IP wrapper with:
   - **System Bus Interface** (same as Hard IP)
   - **IPLOAD** - Start IP configuration (set to 1)
   - **IPDONE** - IP configuration complete (wait for 1)
   
   **IMPORTANT**: You must set IPLOAD=1 and wait for IPDONE=1 before using the I2C IP.

3. **System Bus Interface:**
   According to Table 4.1 of the datasheet, the System Bus interface signals are:
   - `SBCLKi` (I) - System clock input
   - `SBWRi` (I) - Read/Write (0=read, 1=write)
   - `SBSTBi` (I) - Strobe signal (assert with address/data, wait for SBACKo)
   - `SBADRi[7:0]` (I) - Register address
   - `SBDATi[7:0]` (I) - Data input
   - `SBDATo[7:0]` (O) - Data output
   - `SBACKo` (O) - Acknowledge (wait for this before completing transaction)
   - `I2CPIRQ` (O) - Interrupt request

4. **I2C Register Map:**
   The I2C IP has internal registers accessed via System Bus. These are **NOT** BNO055 register addresses.
   - Refer to Advanced iCE40 I2C and SPI Hardened IP Usage Guide (FPGA-TN-02011) for register map
   - The generated Soft IP wrapper code will show exact register addresses

## BNO055 Sensor Communication

The BNO055 sensor uses I2C with:
- Default address: 0x28 (can be 0x29 if ADR pin is high)
- Quaternion data: Registers 0x20-0x27 (8 bytes: W, X, Y, Z - each 16-bit signed)
- Gyroscope data: Registers 0x14-0x19 (6 bytes: X, Y, Z - each 16-bit signed)

### Sensor Initialization Sequence

1. Soft reset (write 0x20 to register 0x3F)
2. Wait 650ms
3. Set operation mode to NDOF (write 0x0C to register 0x3D)
4. Wait 30ms
5. Start reading quaternion and gyro data

## Data Flow

```
BNO055 Sensors (I2C)
    ↓
I2C Hardened IP (via System Bus)
    ↓
bno055_i2c_controller
    ↓
Quaternion Data (W, X, Y, Z)
    ↓
quaternion_to_euler
    ↓
Euler Angles (Yaw, Pitch, Roll)
    ↓
gesture_recognition
    ↓
Sound ID (0-7, 255 = no sound)
```

## Gesture Recognition Logic

The gesture recognition module implements the same logic as the C code:

### Right Hand (IMU 1):
- **Snare (0)**: Yaw 0-120°, Gyro Y < -2500
- **High Tom (3)**: Yaw 340-360°, Gyro Y < -2500, Pitch ≤ 50°
- **Crash (5)**: Yaw 340-360°, Gyro Y < -2500, Pitch > 50°
- **Mid Tom (4)**: Yaw 305-340°, Gyro Y < -2500, Pitch ≤ 50°
- **Ride (6)**: Yaw 305-340° or 200-305°, Gyro Y < -2500, Pitch > 30-50°
- **Floor Tom (7)**: Yaw 200-305°, Gyro Y < -2500, Pitch ≤ 30°

### Left Hand (IMU 2):
- **Snare (0)**: Yaw 350-100° (wraps), Gyro Y < -2500, Pitch ≤ 30° or Gyro Z ≤ -2000
- **Hi-Hat (1)**: Yaw 350-100° (wraps), Gyro Y < -2500, Pitch > 30°, Gyro Z > -2000
- **High Tom (3)**: Yaw 325-350°, Gyro Y < -2500, Pitch ≤ 50°
- **Crash (5)**: Yaw 325-350°, Gyro Y < -2500, Pitch > 50°
- **Mid Tom (4)**: Yaw 300-325°, Gyro Y < -2500, Pitch ≤ 50°
- **Ride (6)**: Yaw 300-325° or 200-300°, Gyro Y < -2500, Pitch > 30-50°
- **Floor Tom (7)**: Yaw 200-300°, Gyro Y < -2500, Pitch ≤ 30°

### Buttons:
- **Button 1**: Kick drum (2)
- **Button 2**: Calibration (sets current yaw as zero offset)

## Fixed-Point Arithmetic

The design uses fixed-point arithmetic for FPGA efficiency:

- **Quaternions**: Q14 format (divide by 16384 to get float)
- **Euler Angles**: Q2 format (divide by 100 to get degrees)
  - Example: 3600 = 36.00 degrees

## Implementation Notes

### Current Status

The basic structure is in place, but the following need to be completed:

1. **BNO055 I2C Controller**: The I2C protocol implementation through the System Bus needs to be completed. The current implementation is a skeleton that needs:
   - Proper I2C start/stop condition generation
   - Register address writing
   - Multi-byte read sequences
   - Error handling and retry logic

2. **Quaternion to Euler Conversion**: The current implementation uses simplified approximations. For production, consider:
   - CORDIC algorithm for accurate atan2 and asin
   - Lookup tables for trigonometric functions
   - Pipeline stages for better timing

3. **System Bus Master**: May need adjustments based on actual I2C IP register map

### Next Steps

1. **Complete I2C Communication:**
   - Study the iCE40 I2C IP register map from the user guide
   - Implement proper I2C transaction sequences
   - Add initialization sequence for BNO055

2. **Improve Math Functions:**
   - Implement CORDIC for atan2 and asin
   - Add proper fixed-point scaling

3. **Testing:**
   - Create test benches for each module
   - Test with simulated I2C responses
   - Verify gesture recognition logic matches C code

4. **Integration:**
   - Connect to actual I2C hardened IP from Module Generator
   - Test with real BNO055 sensors
   - Verify timing constraints

## Module Generator Configuration

When generating the I2C IP using Lattice's Module Generator:

- **System Clock**: Set to your system clock frequency (e.g., 16MHz)
- **I2C Clock**: 100kHz or 400kHz (BNO055 supports up to 400kHz)
- **Master Mode**: Enabled
- **Interrupts**: Enable TX/RX Ready interrupts
- **I/O Buffers**: Include I/O buffers

## Clock Generation

The design supports both internal oscillator (for synthesis) and external clock (for simulation):

- **For Synthesis**: Uses `HFOSC` (or `HSOC` depending on tool) primitive to generate internal clock (~48MHz)
  - Configured via `ifdef SIMULATION` directive
  - Clock divider can be adjusted via `CLKHF_DIV` parameter
  - **Note**: Lattice Radiant uses `HFOSC`, some tools may use `HSOC` - check your tool documentation
  
- **For Simulation**: Uses external `clk_ext` input
  - Questa Simulator compatible (no HFOSC/HSOC in simulation)
  - Define `SIMULATION` macro in test bench

### Using in Questa Simulator

```systemverilog
`define SIMULATION
// Include your test bench
```

The design automatically uses external clock when `SIMULATION` is defined.

## Pin Assignments

The I2C pins are handled internally by the I2C IP wrapper generated by Module Generator. The physical pins are automatically assigned when you generate the I2C IP:
- I2C1_SCL, I2C1_SDA - IMU 1 (Right Hand)
- I2C2_SCL, I2C2_SDA - IMU 2 (Left Hand)

**Note**: The top-level module does NOT expose I2C pins as `inout` - they are handled by the I2C IP wrapper. Only the System Bus interface is exposed.

## Simulation

The test bench (`drum_system_top_tb.sv`) is designed to work with Questa Simulator:
- Defines `SIMULATION` macro automatically
- Provides external clock (16MHz)
- Mocks System Bus responses
- Tests button functionality and system initialization

To run simulation:
```bash
vlog -sv drum_system_top.sv system_bus_master.sv bno055_i2c_controller.sv quaternion_to_euler.sv gesture_recognition.sv drum_system_top_tb.sv
vsim drum_system_top_tb
```

## References

- iCE40 I2C and SPI Hardened IP User Guide (FPGA-TN-02010)
- BNO055 Datasheet
- Original C code: `E155_FPGA_MCU_DrumSet/mcu/src/gesture_recognition.c`
- iCE40 Oscillator Usage Guide (FPGA-TN-02008) - for HFOSC/HSOC details

