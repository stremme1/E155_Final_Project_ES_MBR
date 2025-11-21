# Hardware Implementation Guide
## FPGA Drum Set Gesture Detection System

## What This System Does

This is an **invisible drum set** that detects drumming gestures using motion sensors. Instead of hitting physical drums, you wave drumsticks with IMU sensors attached, and the system:

1. **Tracks drumstick position** (yaw angle - which direction you're pointing)
2. **Detects strikes** (gyroscope detects fast downward motion)
3. **Identifies cymbals** (pitch angle - how high you're holding the stick)
4. **Outputs sound codes** (0-7) via SPI to an MCU that triggers different drum sounds

### Example:
- Point right stick at 50° (Zone 1) and strike down → **Snare drum** (code 0)
- Point right stick at 10° (Zone 2) with high pitch and strike → **Crash cymbal** (code 5)
- Point left stick at 10° with high pitch and rotation → **Hi-hat** (code 1)

---

## System Architecture

```
┌─────────────────┐         ┌─────────────────┐
│  BNO085 Sensor  │         │  BNO085 Sensor  │
│   (Right Hand)  │         │   (Left Hand)   │
└────────┬────────┘         └────────┬────────┘
         │ SPI                        │ SPI
         │                            │
    ┌────▼────┐                  ┌────▼────┐
    │ SPI M1  │                  │ SPI M2  │
    └────┬────┘                  └────┬────┘
         │                            │
    ┌────▼────┐                  ┌────▼────┐
    │ BNO085  │                  │ BNO085  │
    │ Control │                  │ Control │
    └────┬────┘                  └────┬────┘
         │                            │
         └──────────┬─────────────────┘
                    │
            ┌───────▼────────┐
            │ Quaternion to  │
            │    Euler       │
            └───────┬────────┘
                    │
            ┌───────▼────────┐
            │   Gesture      │
            │   Detector     │
            └───────┬────────┘
                    │
            ┌───────▼────────┐
            │   SPI to MCU  │
            └───────┬────────┘
                    │
            ┌───────▼────────┐
            │      MCU       │
            │  (Play Sounds) │
            └────────────────┘
```

---

## How It Works (Step by Step)

### 1. **SPI Communication** (`spi_master.sv`)
- FPGA talks to BNO085 sensors using SPI protocol
- Sends commands and receives sensor data
- Clock speed: ~3MHz (adjustable via CLK_DIV parameter)

### 2. **BNO085 Controller** (`bno085_controller.sv`)
- Implements SHTP (Sensor Hub Transport Protocol)
- Initializes sensors on startup
- Requests quaternion and gyroscope data every 20ms (50Hz)
- Parses incoming data packets

### 3. **Quaternion to Euler** (`quaternion_to_euler.sv`)
- Converts quaternion (w,x,y,z) → Euler angles (roll, pitch, yaw)
- Quaternion describes 3D orientation
- Euler angles are easier to work with (degrees)

### 4. **Gesture Detector** (`gesture_detector.sv`)
- **Yaw zones**: Determines which drum based on direction
  - Right hand: 4 zones (Snare, High tom, Mid tom, Floor tom)
  - Left hand: 4 zones (Snare/Hi-hat, High tom, Mid tom, Floor tom)
- **Pitch detection**: High pitch → cymbals (Crash, Ride)
- **Gyro detection**: Fast downward motion → strike detected
- **Output**: Sound code (0-7) when strike is detected

### 5. **SPI to MCU** (`spi_to_mcu.sv`)
- Sends sound codes (0-7) to MCU via SPI
- FPGA acts as SPI master, MCU as SPI slave
- Simple protocol: Single byte transfer with chip select
- SPI Mode 0 (CPOL=0, CPHA=0)

---

## Hardware Wiring

### Required Components

1. **FPGA Board** (e.g., Lattice iCE40, Xilinx Artix-7, Altera Cyclone)
2. **2x BNO085 IMU Sensors** (Adafruit breakout boards)
3. **USB-to-UART Adapter** (FTDI, CP2102, or similar)
4. **Calibration Button** (momentary push button)
5. **Power Supply** (3.3V or 5V for sensors)
6. **Resistors** (10kΩ pull-ups for buttons)
7. **Breadboard/Jumper Wires**

### BNO085 Sensor Pinout

```
BNO085 Breakout Board:
┌─────────────────┐
│  VIN  GND  RST  │
│  INT   CS  SDO  │
│  SDA  SCL  ADR  │
└─────────────────┘

Pin Functions:
- VIN: Power (3.3V or 5V)
- GND: Ground
- SCL/SCK: SPI Clock (from FPGA)
- SDA/MOSI: SPI Master Out (from FPGA)
- SDO/MISO: SPI Master In (to FPGA)
- CS: Chip Select (from FPGA, active low)
- INT: Interrupt (optional, to FPGA)
- RST: Reset (optional, can be tied high)
- ADR: I2C Address (not used in SPI mode)
```

### Wiring Diagram

#### **BNO085 Sensor 1 (Right Hand)**
```
BNO085-1          FPGA
─────────────────────────
VIN      →       3.3V (or 5V)
GND      →       GND
SCL/SCK  →       GPIO Pin (e.g., Pin 1) → sclk1
SDA/MOSI →       GPIO Pin (e.g., Pin 2) → mosi1
SDO/MISO →       GPIO Pin (e.g., Pin 3) → miso1
CS       →       GPIO Pin (e.g., Pin 4) → cs_n1
INT      →       GPIO Pin (e.g., Pin 5) → int1 (optional)
RST      →       3.3V (or leave floating with pull-up)
```

#### **BNO085 Sensor 2 (Left Hand)**
```
BNO085-2          FPGA
─────────────────────────
VIN      →       3.3V (or 5V)
GND      →       GND
SCL/SCK  →       GPIO Pin (e.g., Pin 6) → sclk2
SDA/MOSI →       GPIO Pin (e.g., Pin 7) → mosi2
SDO/MISO →       GPIO Pin (e.g., Pin 8) → miso2
CS       →       GPIO Pin (e.g., Pin 9) → cs_n2
INT      →       GPIO Pin (e.g., Pin 10) → int2 (optional)
RST      →       3.3V (or leave floating with pull-up)
```

#### **SPI Connection to MCU**
```
MCU (SPI Slave)   FPGA (SPI Master)
─────────────────────────────────────
SCLK        ←     GPIO Pin (e.g., Pin 11) → mcu_sclk
MOSI        ←     GPIO Pin (e.g., Pin 12) → mcu_mosi
MISO        →     GPIO Pin (e.g., Pin 13) → mcu_miso (optional)
CS          ←     GPIO Pin (e.g., Pin 14) → mcu_cs_n
GND         →     GND
```

#### **Calibration Button**
```
Button            FPGA
─────────────────────────
One side   →     3.3V (via 10kΩ pull-up)
Other side →     GPIO Pin (e.g., Pin 12) → calib_button
                  └─ Also connect to GND via button
```

#### **System Clock**
```
Clock Source      FPGA
─────────────────────────
External OSC     → Clock input pin (check your board)
OR
Internal PLL      → Configure in FPGA toolchain
```

---

## FPGA Pin Assignment (Example)

Create a constraints file (`.pcf` for Lattice, `.xdc` for Xilinx, `.qsf` for Altera):

### Lattice iCE40 Example (`constraints.pcf`):
```
set_io clk         21          # System clock (50MHz)
set_io rst_n       23          # Reset button (active low)

# BNO085 Sensor 1 (Right Hand)
set_io sclk1       1           # SPI Clock
set_io mosi1       2           # SPI MOSI
set_io miso1       3           # SPI MISO
set_io cs_n1       4           # Chip Select
set_io int1        5           # Interrupt (optional)

# BNO085 Sensor 2 (Left Hand)
set_io sclk2       6           # SPI Clock
set_io mosi2       7           # SPI MOSI
set_io miso2       8           # SPI MISO
set_io cs_n2       9           # Chip Select
set_io int2        10          # Interrupt (optional)

# User Interface
set_io calib_button 12         # Calibration button
set_io kick_button  13         # Kick button (optional)

# SPI Output to MCU
set_io mcu_sclk    14          # SPI clock to MCU
set_io mcu_mosi    15          # SPI MOSI to MCU
set_io mcu_miso    16          # SPI MISO from MCU (optional)
set_io mcu_cs_n    17          # Chip select to MCU

# Status LEDs (optional)
set_io led_initialized 15      # LED when initialized
set_io led_error       16      # LED for errors
```

**Important**: Adjust pin numbers based on your specific FPGA board!

---

## Implementation Steps

### Step 1: Prepare FPGA Project

1. **Create new project** in your FPGA toolchain (Vivado, Quartus, Diamond, etc.)
2. **Add all SystemVerilog files**:
   - `spi_master.sv`
   - `bno085_controller.sv`
   - `quaternion_to_euler.sv`
   - `gesture_detector.sv`
   - `uart_tx.sv`
   - `drum_set_top.sv` (top-level)
3. **Set top-level module**: `drum_set_top`
4. **Set system clock frequency**: e.g., 50MHz

### Step 2: Configure Parameters

#### In `spi_to_mcu.sv`:
```systemverilog
parameter CLK_DIV = 16;  // For 50MHz clock: 50MHz/16 = 3.125MHz SPI
// Adjust based on your MCU's SPI speed requirements
// Typical MCU SPI: 1-10MHz, adjust CLK_DIV accordingly
```

#### In `spi_master.sv` (for BNO085 sensors):
```systemverilog
parameter CLK_DIV = 16;  // For 50MHz clock: 50MHz/16 = 3.125MHz SPI (within 3MHz max)
// Adjust based on your clock: CLK_DIV = CLK_FREQ / (2 * SPI_FREQ)
```

### Step 3: Assign Pins

1. **Create constraints file** with pin assignments (see example above)
2. **Map all I/O signals** to physical pins
3. **Verify pin types** (input/output) match your board

### Step 4: Synthesize and Build

1. **Run synthesis** (check for errors)
2. **Run place & route**
3. **Generate bitstream**
4. **Program FPGA** with bitstream

### Step 5: Wire Hardware

1. **Power off everything**
2. **Connect BNO085 sensors** to FPGA (see wiring diagram)
3. **Connect UART** to computer
4. **Connect calibration button**
5. **Double-check all connections**
6. **Power on** (FPGA first, then sensors)

### Step 6: Test SPI Communication

Use a logic analyzer or oscilloscope to verify:

1. **SPI Clock**: Should be ~3MHz, idle high
2. **Chip Select**: Should go low during transactions
3. **MOSI**: Should show data being sent
4. **MISO**: Should show data being received

**Expected behavior**:
- After reset, FPGA sends initialization commands
- Sensors respond with acknowledgment packets
- Data reports arrive every 20ms (50Hz)

### Step 7: Test SPI Output to MCU

1. **Connect MCU** to FPGA SPI pins
2. **Configure MCU as SPI slave**:
   - Set up SPI in slave mode
   - Configure to receive on MOSI pin
   - Monitor CS pin for chip select
   - Read data when CS goes low
3. **Expected behavior**:
   - When gesture detected, FPGA asserts CS (low)
   - Sends 8-bit data: `0000XXXX` where XXXX is sound code (0-7)
   - Deasserts CS (high) after transfer
   - MCU receives sound code and can trigger audio playback

### Step 8: Test Gesture Detection

1. **Attach sensors to drumsticks**
2. **Hold sticks in calibration position**
3. **Press calibration button** (LED should indicate calibration)
4. **Wave sticks in different zones**:
   - Right stick at 50° → Should output '0' (Snare)
   - Right stick at 10° with high pitch → Should output '5' (Crash)
   - Left stick at 10° with rotation → Should output '1' (Hi-hat)

### Step 9: Connect MCU and Test

1. **Program MCU** with SPI slave code:
   ```c
   // Example Arduino/ESP32 code
   #include <SPI.h>
   
   void setup() {
     SPI.begin();  // Initialize SPI in slave mode
     pinMode(SS, INPUT);  // CS pin
     SPI.setClockDivider(SPI_CLOCK_DIV2);
     Serial.begin(115200);
   }
   
   void loop() {
     if (digitalRead(SS) == LOW) {  // CS asserted
       byte sound_code = SPI.transfer(0);  // Read data
       Serial.print("Sound: ");
       Serial.println(sound_code);
       // Trigger audio playback based on sound_code
     }
   }
   ```

2. **Test**: Wave sticks → MCU should receive sound codes (0-7) → Trigger audio playback

---

## Troubleshooting

### Problem: No SPI Communication

**Symptoms**: No data on MISO, sensors not responding

**Solutions**:
- Check SPI wiring (MOSI, MISO, SCLK, CS)
- Verify SPI mode (Mode 3: CPOL=1, CPHA=1)
- Check clock speed (should be <3MHz)
- Verify power to sensors (3.3V or 5V)
- Check chip select polarity (active low)

### Problem: Sensors Not Initializing

**Symptoms**: `initialized` signal stays low, no data reports

**Solutions**:
- Check SHTP protocol implementation
- Verify report enable commands are sent correctly
- Check sensor datasheet for initialization sequence
- Use logic analyzer to capture SPI transactions
- Verify sensor is in SPI mode (not I2C)

### Problem: Wrong Gesture Detection

**Symptoms**: Wrong sound codes, or no detection

**Solutions**:
- Recalibrate (press button in desired zero position)
- Check yaw normalization (should be 0-360°)
- Verify thresholds match your movement range
- Check quaternion to Euler conversion accuracy
- Test with known angles using testbench

### Problem: SPI to MCU Not Working

**Symptoms**: MCU not receiving data, no response

**Solutions**:
- Check SPI wiring (SCLK, MOSI, CS, GND)
- Verify SPI mode matches (Mode 0: CPOL=0, CPHA=0)
- Check clock speed (adjust CLK_DIV if too fast for MCU)
- Verify MCU is configured as SPI slave
- Check CS polarity (active low)
- Use logic analyzer to verify SPI signals
- Verify MCU SPI settings match FPGA (MSB first, 8-bit transfers)

### Problem: Timing Issues

**Symptoms**: Missed strikes, delayed responses

**Solutions**:
- Check system clock frequency
- Verify SPI clock divider
- Increase report rate (reduce interval in `bno085_controller.sv`)
- Check pipeline delays in quaternion conversion
- Optimize gesture detector timing

---

## Testing Checklist

- [ ] FPGA synthesizes without errors
- [ ] All pins assigned correctly
- [ ] Bitstream programs successfully
- [ ] SPI signals visible on oscilloscope/logic analyzer
- [ ] Sensors initialize (check `initialized` signal)
- [ ] Quaternion data received (check `quat_valid`)
- [ ] Gyroscope data received (check `gyro_valid`)
- [ ] Euler angles calculated correctly
- [ ] SPI outputs sound codes to MCU
- [ ] MCU receives sound codes correctly
- [ ] Calibration button works
- [ ] Gesture detection triggers sound codes
- [ ] MCU receives sound codes and triggers audio playback
- [ ] All zones detect correctly
- [ ] Cymbal detection works (high pitch)
- [ ] Hi-hat detection works (pitch + rotation)

---

## Advanced Configuration

### Adjusting Sensitivity

**Gyro Threshold** (in `gesture_detector.sv`):
```systemverilog
localparam GYRO_Y_THRESHOLD = -16'd2500;  // More negative = less sensitive
```

**Pitch Thresholds**:
```systemverilog
localparam PITCH_CRASH = 16'd50;  // Adjust for cymbal detection
localparam PITCH_RIDE = 16'd30;   // Adjust for ride cymbal
```

### Changing Report Rate

In `bno085_controller.sv`, modify report interval:
```systemverilog
spi_tx_data <= 8'd50;  // 50 = 50Hz (20ms), 100 = 100Hz (10ms)
```

### Adding More Sensors

To add a third sensor (e.g., for kick drum):
1. Add another SPI master and BNO085 controller
2. Connect to `drum_set_top.sv`
3. Add gesture detection logic
4. Assign new pins

---

## Safety Notes

⚠️ **Important**:
- Double-check power connections (wrong voltage can damage sensors)
- Use proper pull-up resistors for buttons
- Don't hot-plug sensors while FPGA is running
- Verify SPI clock doesn't exceed 3MHz
- Use proper grounding between FPGA and sensors

---

## Next Steps

1. **Build and test** basic SPI communication
2. **Verify** sensor initialization
3. **Test** gesture detection with known angles
4. **Calibrate** thresholds for your movement style
5. **Integrate** with audio playback
6. **Fine-tune** for optimal performance

Good luck with your implementation! 🥁

