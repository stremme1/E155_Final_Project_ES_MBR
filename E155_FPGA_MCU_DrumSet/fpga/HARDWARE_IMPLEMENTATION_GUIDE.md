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
3. **MCU Board** (Arduino, ESP32, STM32, or similar) - Receives sound codes via SPI
4. **Calibration Button** (momentary push button)
5. **Kick Button** (optional, for kick drum trigger)
6. **Power Supply** (3.3V or 5V for sensors and FPGA)
7. **Resistors** (10kΩ pull-ups for buttons and CS signals)
8. **Breadboard/Jumper Wires**

### BNO085 Sensor Pinout

```
BNO085 Breakout Board:
┌─────────────────┐
│  VIN  GND  RST  │
│  INT   CS  SDA  │
│  DI   SCL  ADR  │
└─────────────────┘

SPI Pin Functions (from Adafruit BNO085 Datasheet):
- VIN: Power (3.3V or 5V) - Power input with onboard regulator
- GND: Ground - Common ground
- SCL: SPI Clock (SCK) - Input to chip, clock signal
- DI: Data In / MOSI - Data FROM processor TO sensor (FPGA sends data)
- SDA: Data Out / MISO - Data FROM sensor TO processor (FPGA receives data)
- CS: Chip Select - Input to chip, pull LOW to start SPI transaction
- INT: Interrupt - Active Low (optional, not used in polling mode)
- RST: Reset - Active Low, tie to 3.3V (keep HIGH, required for stable SPI)
- ADR: I2C Address pin (not used in SPI mode)
```

### Wiring Diagram

#### **BNO085 Sensor 1 (Right Hand)**
```
BNO085-1 Pin      FPGA Pin    FPGA Signal
─────────────────────────────────────────
VIN      →       3.3V (or 5V) → Power
GND      →       GND          → Ground
SCL      →       P20          → sclk1 (SPI clock)
DI       →       P13          → mosi1 (FPGA sends data)
SDA      →       P12          → miso1 (sensor sends data)
CS       →       P18          → cs_n1 (chip select, with 10kΩ pull-up)
INT      →       (unconnected) → Not used (polling mode)
RST      →       3.3V         → Reset (keep HIGH, active LOW)
```

#### **BNO085 Sensor 2 (Left Hand)**
```
BNO085-2 Pin      FPGA Pin    FPGA Signal
─────────────────────────────────────────
VIN      →       3.3V (or 5V) → Power
GND      →       GND          → Ground
SCL      →       P4           → sclk2 (SPI clock)
DI       →       P47          → mosi2 (FPGA sends data)
SDA      →       P6           → miso2 (sensor sends data)
CS       →       P48          → cs_n2 (chip select, with 10kΩ pull-up)
INT      →       (unconnected) → Not used (polling mode)
RST      →       3.3V         → Reset (keep HIGH, active LOW)
```

**Important**: 
- BNO085 **DI** pin = **MOSI** (data FROM FPGA TO sensor)
- BNO085 **SDA** pin = **MISO** (data FROM sensor TO FPGA)
- These are BNO085 pin names, NOT FPGA pin names

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

---

## Pull-Up/Pull-Down Requirements

### **Critical: External Pull-Up Resistors Required**

#### **1. CS_N (Chip Select) - REQUIRES PULL-UP**
- **Signal**: `cs_n1`, `cs_n2`, `mcu_cs_n`
- **Idle State**: HIGH (1) - inactive
- **Active State**: LOW (0) - active
- **Requirement**: **10kΩ pull-up resistor to 3.3V**
- **Why**: CS must stay HIGH when FPGA is not driving it (during power-up, reset, or when idle). Without pull-up, CS may float LOW and accidentally select the slave device.
- **Connection**: 
  ```
  CS_N pin → 10kΩ resistor → 3.3V
  ```

#### **2. RST_N (Reset) - REQUIRES PULL-UP**
- **Signal**: `rst_n`
- **Idle State**: HIGH (1) - system running
- **Active State**: LOW (0) - system reset
- **Requirement**: **10kΩ pull-up resistor to 3.3V**
- **Why**: Reset must stay HIGH during normal operation. Button pulls to GND when pressed.
- **Connection**: 
  ```
  RST_N pin → 10kΩ resistor → 3.3V
  RST_N pin → Button → GND (when pressed)
  ```

#### **3. MOSI (Master Out) - NO PULL-UP/PULL-DOWN NEEDED**
- **Signal**: `mosi1`, `mosi2`, `mcu_mosi`
- **Idle State**: LOW (0) for MCU SPI, driven by FPGA for BNO085
- **Requirement**: **No external resistor needed**
- **Why**: MOSI is always driven by FPGA (output). FPGA controls the signal state.

#### **4. SCLK (SPI Clock) - NO PULL-UP/PULL-DOWN NEEDED**
- **Signal**: `sclk1`, `sclk2`, `mcu_sclk`
- **Idle State**: 
  - BNO085 SPI: HIGH (CPOL=1)
  - MCU SPI: LOW (CPOL=0)
- **Requirement**: **No external resistor needed**
- **Why**: SCLK is always driven by FPGA (output). FPGA controls the clock state.

#### **5. CLK (System Clock) - NO PULL-UP/PULL-DOWN NEEDED**
- **Signal**: `clk`
- **Requirement**: **No external resistor needed**
- **Why**: Clock is driven by oscillator/crystal. Always has a defined state.

#### **6. MISO (Master In) - OPTIONAL PULL-UP**
- **Signal**: `miso1`, `miso2`, `mcu_miso`
- **Requirement**: **Optional 10kΩ pull-up to 3.3V** (recommended for reliability)
- **Why**: MISO is an input to FPGA. Pull-up ensures a defined state when slave is not driving (though most SPI slaves drive MISO actively).

### **Summary Table**

| Signal | Type | Idle State | Pull-Up/Pull-Down | Value |
|--------|------|------------|-------------------|-------|
| `cs_n1`, `cs_n2`, `mcu_cs_n` | Output | HIGH | **Pull-Up Required** | 10kΩ to 3.3V |
| `rst_n` | Input | HIGH | **Pull-Up Required** | 10kΩ to 3.3V |
| `mosi1`, `mosi2`, `mcu_mosi` | Output | LOW/HIGH | None | Always driven |
| `sclk1`, `sclk2`, `mcu_sclk` | Output | LOW/HIGH | None | Always driven |
| `clk` | Input | N/A | None | Driven by oscillator |
| `miso1`, `miso2`, `mcu_miso` | Input | N/A | Optional Pull-Up | 10kΩ to 3.3V (recommended) |

### **Wiring with Pull-Up Resistors**

```
FPGA Pin → 10kΩ Resistor → 3.3V
         ↓
    (Signal line)
         ↓
    Connected Device
```

**Example for CS_N:**
```
FPGA Pin (cs_n1) → 10kΩ → 3.3V
                 ↓
            (SPI bus)
                 ↓
            BNO085 CS pin
```

**Example for RST_N:**
```
FPGA Pin (rst_n) → 10kΩ → 3.3V
                 ↓
            (Reset line)
                 ↓
            Button → GND (when pressed)
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
set_io clk         <clock_pin> # System clock (check board docs)
set_io rst_n       Reset       # Reset button (active low)

# BNO085 Sensor 1 (Right Hand)
set_io sclk1       P20         # SPI Clock
set_io mosi1       P13         # SPI MOSI
set_io miso1       P12         # SPI MISO
set_io cs_n1       P18         # Chip Select

# BNO085 Sensor 2 (Left Hand)
set_io sclk2       P4          # SPI Clock
set_io mosi2       P47         # SPI MOSI
set_io miso2       P6          # SPI MISO
set_io cs_n2       P48         # Chip Select

# User Interface
set_io calib_button P11        # Calibration button (left button)
set_io kick_button   P2        # Kick button (right button)

# SPI Output to MCU
set_io mcu_sclk    P21         # SPI clock to MCU
set_io mcu_mosi    P10         # SPI MOSI to MCU
set_io mcu_cs_n    P19         # Chip select to MCU (needs 10kΩ pull-up)

# Status LEDs
set_io led_initialized P28          # LED when initialized (HIGH when both sensors ready)
set_io led_error       P38          # LED for errors (HIGH when sensor error detected)
```

**Important**: Adjust pin numbers based on your specific FPGA board!

---

## Implementation Steps

### Step 1: Prepare FPGA Project

1. **Create new project** in your FPGA toolchain (Vivado, Quartus, Diamond, etc.)
2. **Add all SystemVerilog files**:
   - `spi_master.sv` - SPI master for BNO085 sensors
   - `bno085_controller.sv` - BNO085 sensor controller
   - `quaternion_to_euler.sv` - Quaternion to Euler conversion
   - `gesture_detector.sv` - Gesture detection logic
   - `spi_to_mcu.sv` - SPI master for MCU communication
   - `spi_slave_model.sv` - SPI slave model (for simulation only)
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
   - Add 10kΩ pull-up resistors to CS_N pins (cs_n1, cs_n2)
3. **Connect MCU** to FPGA SPI pins (see SPI Connection to MCU diagram)
   - Add 10kΩ pull-up resistor to mcu_cs_n
4. **Connect calibration button** with 10kΩ pull-up resistor
5. **Connect reset button** with 10kΩ pull-up resistor
6. **Double-check all connections**
7. **Power on** (FPGA first, then sensors, then MCU)

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
   
   #define CS_PIN 10  // Chip select pin from FPGA
   
   void setup() {
     Serial.begin(115200);
     pinMode(CS_PIN, INPUT);  // CS pin from FPGA
     SPI.begin();  // Initialize SPI in slave mode
     // SPI Mode 0: CPOL=0, CPHA=0
     // Clock idle low, sample on rising edge
     Serial.println("MCU SPI Slave Ready");
   }
   
   void loop() {
     if (digitalRead(CS_PIN) == LOW) {  // CS asserted by FPGA
       // Wait for CS to go low, then read data
       byte sound_code = SPI.transfer(0);  // Read 8-bit data
       sound_code = sound_code & 0x0F;  // Lower 4 bits contain sound code (0-7)
       
       Serial.print("Sound Code: ");
       Serial.println(sound_code);
       
       // Trigger audio playback based on sound_code:
       // 0 = Snare, 1 = Hi-hat, 2 = Kick, 3 = High tom
       // 4 = Mid tom, 5 = Crash, 6 = Ride, 7 = Floor tom
       playSound(sound_code);
     }
   }
   
   void playSound(byte code) {
     // Your audio playback code here
     // e.g., trigger WAV files, MIDI notes, etc.
   }
   ```

2. **Test**: 
   - Wave sticks → FPGA detects gestures → Sends sound codes via SPI
   - MCU receives sound codes (0-7) → Triggers audio playback
   - Verify all 8 sound codes are received correctly

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
- Check SPI wiring (SCLK, MOSI, CS_N, GND)
- **Add 10kΩ pull-up resistor to mcu_cs_n** (critical!)
- Verify SPI mode matches (Mode 0: CPOL=0, CPHA=0)
  - Clock idle LOW
  - Data sampled on rising edge
- Check clock speed (adjust CLK_DIV in `spi_to_mcu.sv` if too fast for MCU)
  - Default: CLK_DIV=16 for 50MHz → 3.125MHz SPI clock
- Verify MCU is configured as SPI slave
- Check CS polarity (active low - CS goes LOW during transfer)
- Use logic analyzer to verify SPI signals:
  - CS should go LOW before SCLK starts
  - 8 SCLK cycles per transfer
  - MOSI data should be stable before SCLK rising edge
- Verify MCU SPI settings match FPGA:
  - MSB first
  - 8-bit transfers
  - Mode 0 (CPOL=0, CPHA=0)
- Check that MCU reads data when CS goes LOW, not on SCLK edges

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

### FPGA Setup
- [ ] FPGA synthesizes without errors
- [ ] All pins assigned correctly
- [ ] Bitstream programs successfully
- [ ] Pull-up resistors installed (CS_N, RST_N, buttons)

### Sensor Communication
- [ ] SPI signals visible on oscilloscope/logic analyzer
- [ ] Sensors initialize (check `led_initialized` signal)
- [ ] Quaternion data received (check `quat_valid`)
- [ ] Gyroscope data received (check `gyro_valid`)
- [ ] Euler angles calculated correctly

### Calibration
- [ ] Calibration button works (see CALIBRATION_GUIDE.md)
- [ ] Yaw offsets captured correctly
- [ ] Normalized yaw values update after calibration

### Gesture Detection
- [ ] Gesture detection triggers sound codes
- [ ] All zones detect correctly (8 zones total)
- [ ] Cymbal detection works (high pitch)
- [ ] Hi-hat detection works (pitch + rotation)
- [ ] Strike detection works (gyro threshold)

### MCU Communication
- [ ] SPI to MCU signals visible (SCLK, MOSI, CS_N)
- [ ] MCU configured as SPI slave (Mode 0)
- [ ] MCU receives sound codes correctly
- [ ] All 8 sound codes (0-7) received
- [ ] MCU triggers audio playback based on sound codes

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

