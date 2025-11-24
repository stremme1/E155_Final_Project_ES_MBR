# Oscilloscope Testing Guide
## FPGA Drum Set Gesture Detection System

This guide provides step-by-step instructions for testing your flashed FPGA code using an oscilloscope.

---

## Prerequisites

### Equipment Needed
- **Oscilloscope** (2+ channels recommended, 4+ channels ideal)
- **Oscilloscope probes** (x1 or x10)
- **BNO085 sensors** (2x) - connected to FPGA
- **Power supply** (3.3V or 5V)
- **Pull-up resistors** (10kΩ) - installed on CS_N pins and buttons
- **Reset button** - connected to `rst_n` pin (P43)
- **Calibration button** - connected to `calib_button` pin (P11)

### Oscilloscope Settings
- **Timebase**: Start with 1ms/div, adjust as needed (10µs/div for SPI details)
- **Voltage scale**: 1V/div or 2V/div (3.3V logic)
- **Trigger**: Edge trigger, rising or falling edge
- **Coupling**: DC coupling
- **Probe attenuation**: Match your probe setting (x1 or x10)

---

## Test 1: Power-On and Reset Verification

### Purpose
Verify the FPGA powers up correctly and reset signal works.

### Signals to Probe
1. **`rst_n`** (P43) - Reset signal
2. **`led_initialized`** (P28) - Initialization LED
3. **`led_error`** (P38) - Error LED

### Procedure

1. **Power on FPGA** (before connecting sensors)
2. **Probe `rst_n` pin (P43)**:
   - **Expected**: Should be **HIGH (3.3V)** when not pressed
   - **When reset button pressed**: Should go **LOW (0V)**
   - **When released**: Should return to **HIGH (3.3V)**
   - **If floating**: Check 10kΩ pull-up resistor to 3.3V

3. **Probe `led_initialized` pin (P28)**:
   - **Expected**: Starts **LOW (0V)**, goes **HIGH (3.3V)** when both sensors initialized
   - **Timing**: May take several seconds after power-on
   - **If stays LOW**: Sensors may not be initializing (check Test 2)

4. **Probe `led_error` pin (P38)**:
   - **Expected**: Should be **LOW (0V)** (no errors)
   - **If HIGH**: Sensor communication error (check SPI signals)

### Expected Waveforms

```
rst_n (P43):
    3.3V ────────────────────────────────
         │
    0V   └───┐     ┌────────────────────
             └─────┘
          (button press)

led_initialized (P28):
    0V   ───────────┐
                    │
    3.3V            └────────────────────
                    (after init)

led_error (P38):
    0V   ────────────────────────────────
         (should stay LOW)
```

---

## Test 2: BNO085 Sensor SPI Communication (Sensor 1)

### Purpose
Verify SPI communication with BNO085 Sensor 1 (Right Hand).

### Signals to Probe
1. **`sclk1`** (P20) - SPI clock
2. **`cs_n1`** (P18) - Chip select
3. **`mosi1`** (P13) - Master out (FPGA → Sensor)
4. **`miso1`** (P12) - Master in (Sensor → FPGA)
5. **`int1`** (P9) - Interrupt (REQUIRED for stable SPI, active LOW)

### Procedure

1. **Connect BNO085 Sensor 1** to FPGA (power, GND, SPI pins)
2. **Power on sensor** (3.3V or 5V)
3. **Set oscilloscope**:
   - **Timebase**: 10µs/div or 50µs/div (to see SPI clock cycles)
   - **Trigger**: Falling edge on `cs_n1` (chip select going active)
   - **Channels**: Use 4 channels if available, or probe pairs

4. **Probe `cs_n1` (P18)**:
   - **Expected idle**: **HIGH (3.3V)** - pulled up via 10kΩ resistor
   - **During transaction**: Goes **LOW (0V)** for ~50-100µs
   - **Frequency**: Should see periodic transactions every ~20ms (50Hz data reports)
   - **If always HIGH**: No SPI communication (check sensor power, wiring)
   - **If always LOW**: Missing pull-up resistor or short circuit

5. **Probe `sclk1` (P20)**:
   - **Expected idle**: **HIGH (3.3V)** - CPOL=1 (Mode 3)
   - **During transaction**: 
     - **Frequency**: ~3MHz (period ~333ns per clock cycle)
     - **8 clock cycles** per byte transfer
     - **Total transaction**: ~2-3µs per byte
   - **Waveform**: Square wave, 50% duty cycle
   - **If no clock**: Check sensor initialization, SPI master not starting

6. **Probe `mosi1` (P13)**:
   - **Expected idle**: **LOW (0V)** or **HIGH (3.3V)** (driven by FPGA)
   - **During transaction**: 
     - **Data changes on falling edge of SCLK** (CPHA=1)
     - **MSB first** (most significant bit first)
     - **8 bits per byte**
     - **Typical pattern**: Initialization commands, then periodic data requests
   - **If no data**: Check SPI master state machine

7. **Probe `miso1` (P12)**:
   - **Expected idle**: May float or be LOW
   - **During transaction**: 
     - **Sensor responds with data** after FPGA sends command
     - **Data changes on falling edge of SCLK**
     - **Typical pattern**: ACK packets, then quaternion/gyro data
   - **If no response**: Check sensor power, wiring, or sensor not in SPI mode

### Expected Waveforms

```
cs_n1 (P18):
    3.3V ────┐     ┌───────────────────┐     ┌───
             │     │                   │     │
    0V       └─────┘                   └─────┘
             (active)                  (active)
             ~50-100µs                 ~50-100µs
             every 20ms                every 20ms

sclk1 (P20):
    3.3V ────┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌───
             │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │
    0V       └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─
             (8 clock cycles per byte)
             ~333ns per cycle (~3MHz)

mosi1 (P13):
    3.3V ────┐     ┌───┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌───
             │     │   │ │ │ │ │ │ │ │ │ │
    0V       └─────┘   └─┘ └─┘ └─┘ └─┘ └─┘ └─
             (MSB first, 8 bits)

miso1 (P12):
    3.3V ────┐     ┌───┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌───
             │     │   │ │ │ │ │ │ │ │ │ │
    0V       └─────┘   └─┘ └─┘ └─┘ └─┘ └─┘ └─
             (Sensor response data)
```

### Timing Measurements

- **SPI Clock Frequency**: Should be ~3MHz (period = 333ns)
  - Measure: Time between rising edges of `sclk1`
  - Formula: `Frequency = 1 / period`
  
- **Transaction Duration**: ~50-100µs per SPI transaction
  - Measure: Time `cs_n1` is LOW
  
- **Data Report Rate**: ~20ms between transactions (50Hz)
  - Measure: Time between falling edges of `cs_n1`

### Troubleshooting

| Problem | Possible Cause | Solution |
|---------|---------------|----------|
| No `cs_n1` activity | Sensor not powered | Check sensor VIN and GND |
| `cs_n1` always LOW | Missing pull-up | Add 10kΩ pull-up to 3.3V |
| No `sclk1` | SPI master not starting | Check sensor initialization |
| `sclk1` wrong frequency | CLK_DIV parameter | Verify clock divider setting |
| No `miso1` response | Sensor not responding | Check wiring, sensor mode (SPI vs I2C) |
| `miso1` always LOW | Sensor not powered | Check sensor power supply |

---

## Test 3: BNO085 Sensor SPI Communication (Sensor 2)

### Purpose
Verify SPI communication with BNO085 Sensor 2 (Left Hand).

### Signals to Probe
1. **`sclk2`** (P4) - SPI clock
2. **`cs_n2`** (P48) - Chip select
3. **`mosi2`** (P47) - Master out
4. **`miso2`** (P6) - Master in

### Procedure
**Same as Test 2**, but probe Sensor 2 signals instead.

### Expected Behavior
- **Identical to Sensor 1** (same SPI protocol, same timing)
- **Independent operation**: Both sensors should communicate simultaneously
- **Both `led_initialized` should go HIGH** when both sensors are ready

---

## Test 4: Calibration Button

### Purpose
Verify calibration button input works correctly.

### Signals to Probe
1. **`calib_button`** (P11) - Calibration button input

### Procedure

1. **Probe `calib_button` pin (P11)**:
   - **Expected idle**: **HIGH (3.3V)** - pulled up via 10kΩ resistor
   - **When button pressed**: Goes **LOW (0V)**
   - **When released**: Returns to **HIGH (3.3V)**
   - **Debouncing**: May see brief bounces (normal for mechanical buttons)

2. **Test calibration**:
   - **Press and hold** calibration button
   - **Observe**: Button should go LOW, stay LOW while pressed
   - **Release**: Should return to HIGH
   - **Expected behavior**: System captures yaw offsets during calibration

### Expected Waveform

```
calib_button (P11):
    3.3V ────┐     ┌────────────────────
             │     │
    0V       └─────┘
             (button press)
             (may have brief bounces)
```

### Troubleshooting

| Problem | Possible Cause | Solution |
|---------|---------------|----------|
| Always LOW | Button stuck or short | Check button wiring |
| Always HIGH | Missing pull-up | Add 10kΩ pull-up to 3.3V |
| No response | Button not connected | Check wiring to P11 |

---

## Test 5: MCU SPI Output

### Purpose
Verify SPI output to MCU when gestures are detected.

### Signals to Probe
1. **`mcu_cs_n`** (P19) - Chip select to MCU
2. **`mcu_sclk`** (P21) - SPI clock to MCU
3. **`mcu_mosi`** (P10) - Data to MCU

### Procedure

1. **Connect MCU** (optional - can test without MCU connected)
2. **Set oscilloscope**:
   - **Timebase**: 10µs/div or 50µs/div
   - **Trigger**: Falling edge on `mcu_cs_n` (chip select going active)
   - **Channels**: 3 channels (or probe sequentially)

3. **Probe `mcu_cs_n` (P19)**:
   - **Expected idle**: **HIGH (3.3V)** - pulled up via 10kΩ resistor
   - **When gesture detected**: Goes **LOW (0V)** for ~50-100µs
   - **Frequency**: Only when gestures detected (not periodic like sensor SPI)
   - **If always HIGH**: No gestures detected, or gesture detector not working
   - **If always LOW**: Missing pull-up resistor

4. **Probe `mcu_sclk` (P21)**:
   - **Expected idle**: **LOW (0V)** - CPOL=0 (Mode 0)
   - **During transaction**: 
     - **Frequency**: ~3MHz (period ~333ns per clock cycle)
     - **8 clock cycles** per byte transfer
     - **Total transaction**: ~2-3µs per byte
   - **Waveform**: Square wave, 50% duty cycle
   - **If no clock**: No gestures detected, or SPI not starting

5. **Probe `mcu_mosi` (P10)**:
   - **Expected idle**: **LOW (0V)**
   - **During transaction**: 
     - **Data format**: `0000XXXX` where XXXX is sound code (0-7)
     - **MSB first** (most significant bit first)
     - **8 bits per transfer**
     - **Data changes on falling edge of SCLK** (CPHA=0)
   - **Sound codes**:
     - `0000 0000` = 0 (Snare)
     - `0000 0001` = 1 (Hi-hat)
     - `0000 0010` = 2 (Kick)
     - `0000 0011` = 3 (High tom)
     - `0000 0100` = 4 (Mid tom)
     - `0000 0101` = 5 (Crash)
     - `0000 0110` = 6 (Ride)
     - `0000 0111` = 7 (Floor tom)

### Expected Waveforms

```
mcu_cs_n (P19):
    3.3V ────┐     ┌───────────────────
             │     │
    0V       └─────┘
             (active when gesture detected)
             ~50-100µs

mcu_sclk (P21):
    0V   ────┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌───
             │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │
    3.3V     └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─
             (8 clock cycles, CPOL=0, idle LOW)
             ~333ns per cycle (~3MHz)

mcu_mosi (P10):
    0V   ────┐     ┌───┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌───
             │     │   │ │ │ │ │ │ │ │ │ │
    3.3V     └─────┘   └─┘ └─┘ └─┘ └─┘ └─┘ └─
             (MSB first, 8 bits: 0000XXXX)
```

### Testing Gesture Detection

1. **Wave drumsticks** with sensors attached
2. **Observe `mcu_cs_n`**: Should pulse LOW when gesture detected
3. **Decode `mcu_mosi` data**: Should match expected sound code for gesture
4. **Verify timing**: CS should go LOW, then 8 clock cycles, then CS goes HIGH

### Timing Measurements

- **SPI Clock Frequency**: Should be ~3MHz (period = 333ns)
- **Transaction Duration**: ~50-100µs per transfer
- **Gesture Response Time**: Should be <100ms from gesture to SPI output

### Troubleshooting

| Problem | Possible Cause | Solution |
|---------|---------------|----------|
| No `mcu_cs_n` activity | No gestures detected | Wave sticks, check gesture detector |
| `mcu_cs_n` always LOW | Missing pull-up | Add 10kΩ pull-up to 3.3V |
| No `mcu_sclk` | SPI not starting | Check gesture detector output |
| Wrong `mcu_mosi` data | Gesture detection error | Check yaw zones, calibration |

---

## Test 6: Multi-Channel Analysis (Advanced)

### Purpose
Verify timing relationships between signals.

### Recommended Setup
- **4-channel oscilloscope** (or use multiple scopes)
- **Probe simultaneously**:
  - Channel 1: `cs_n1` (Sensor 1 chip select)
  - Channel 2: `sclk1` (Sensor 1 clock)
  - Channel 3: `mcu_cs_n` (MCU chip select)
  - Channel 4: `mcu_sclk` (MCU clock)

### What to Look For

1. **Sensor SPI independence**: 
   - Sensor 1 and Sensor 2 should operate independently
   - Both can communicate simultaneously

2. **MCU SPI timing**:
   - MCU SPI should only activate when gestures detected
   - Should not interfere with sensor SPI

3. **Clock synchronization**:
   - All SPI clocks should be ~3MHz
   - Clocks should be independent (not synchronized)

---

## Test 7: Kick Button (Optional)

### Purpose
Verify kick button input works (if implemented).

### Signals to Probe
1. **`kick_button`** (P2) - Kick button input

### Procedure
**Same as Test 4** (calibration button), but probe `kick_button` pin (P2).

### Expected Behavior
- **When pressed**: Should trigger sound code `2` (Kick drum) on MCU SPI
- **Observe `mcu_cs_n`**: Should pulse LOW when button pressed
- **Observe `mcu_mosi`**: Should show `0000 0010` (code 2)

---

## Quick Reference: Signal Summary

| Signal | Pin | Type | Idle State | Expected Activity |
|--------|-----|------|------------|-------------------|
| `rst_n` | P43 | Input | HIGH (3.3V) | Goes LOW when reset pressed |
| `sclk1` | P20 | Output | HIGH (3.3V) | ~3MHz clock during SPI |
| `cs_n1` | P18 | Output | HIGH (3.3V) | Goes LOW during SPI transactions |
| `mosi1` | P13 | Output | LOW (0V) | Data during SPI transactions |
| `miso1` | P12 | Input | Floating | Sensor data during SPI |
| `int1` | P9 | Input | HIGH (3.3V) | Goes LOW when sensor has data (active LOW) |
| `int2` | P3 | Input | HIGH (3.3V) | Goes LOW when sensor has data (active LOW) |
| `sclk2` | P4 | Output | HIGH (3.3V) | ~3MHz clock during SPI |
| `cs_n2` | P48 | Output | HIGH (3.3V) | Goes LOW during SPI transactions |
| `mosi2` | P47 | Output | LOW (0V) | Data during SPI transactions |
| `miso2` | P6 | Input | Floating | Sensor data during SPI |
| `calib_button` | P11 | Input | HIGH (3.3V) | Goes LOW when pressed |
| `kick_button` | P2 | Input | HIGH (3.3V) | Goes LOW when pressed |
| `mcu_sclk` | P21 | Output | LOW (0V) | ~3MHz clock during SPI |
| `mcu_cs_n` | P19 | Output | HIGH (3.3V) | Goes LOW when gesture detected |
| `mcu_mosi` | P10 | Output | LOW (0V) | Sound code data during SPI |
| `led_initialized` | P28 | Output | LOW (0V) | Goes HIGH when sensors ready |
| `led_error` | P38 | Output | LOW (0V) | Goes HIGH on error |

---

## Testing Checklist

### Basic Functionality
- [ ] FPGA powers on correctly
- [ ] Reset button works (`rst_n` goes LOW when pressed)
- [ ] `led_initialized` goes HIGH after sensor initialization
- [ ] `led_error` stays LOW (no errors)

### Sensor Communication
- [ ] Sensor 1 SPI signals active (`cs_n1`, `sclk1`, `mosi1`, `miso1`)
- [ ] Sensor 2 SPI signals active (`cs_n2`, `sclk2`, `mosi2`, `miso2`)
- [ ] SPI clock frequency ~3MHz
- [ ] Periodic transactions every ~20ms (50Hz)
- [ ] Both sensors initialize successfully

### User Interface
- [ ] Calibration button works (`calib_button` goes LOW when pressed)
- [ ] Kick button works (`kick_button` goes LOW when pressed, if implemented)

### MCU Communication
- [ ] MCU SPI signals active when gestures detected (`mcu_cs_n`, `mcu_sclk`, `mcu_mosi`)
- [ ] SPI clock frequency ~3MHz
- [ ] Sound codes transmitted correctly (0-7)
- [ ] Timing correct (CS LOW → 8 clock cycles → CS HIGH)

### Advanced
- [ ] Multi-channel timing analysis
- [ ] Gesture detection triggers MCU SPI
- [ ] All sound codes (0-7) transmitted correctly

---

## Common Issues and Solutions

### Issue: No SPI Activity
**Symptoms**: No signals on SPI pins, `led_initialized` stays LOW

**Solutions**:
1. Check sensor power (VIN and GND)
2. Verify SPI wiring (MOSI, MISO, SCLK, CS)
3. Check pull-up resistors on CS_N pins (10kΩ to 3.3V)
4. Verify sensor is in SPI mode (not I2C)
5. Check reset signal (`rst_n` should be HIGH)

### Issue: Wrong SPI Clock Frequency
**Symptoms**: SPI clock too fast or too slow

**Solutions**:
1. Check system clock frequency (should be ~3MHz from HSOSC)
2. Verify CLK_DIV parameter in `spi_master.sv` (should be 16)
3. Measure actual clock period and calculate frequency

### Issue: MCU SPI Not Working
**Symptoms**: No activity on `mcu_cs_n` when gestures detected

**Solutions**:
1. Check gesture detector is working (wave sticks)
2. Verify calibration (press calibration button)
3. Check `mcu_cs_n` pull-up resistor (10kΩ to 3.3V)
4. Verify gesture thresholds in `gesture_detector.sv`

### Issue: Button Not Working
**Symptoms**: Button always HIGH or always LOW

**Solutions**:
1. Check pull-up resistor (10kΩ to 3.3V)
2. Verify button wiring (one side to pin, other side to GND)
3. Check for short circuits or open connections

---

## Next Steps

After verifying all signals with oscilloscope:

1. **Connect MCU** and verify SPI communication
2. **Test gesture detection** with actual drumsticks
3. **Calibrate system** (press calibration button in zero position)
4. **Fine-tune thresholds** in `gesture_detector.sv` if needed
5. **Integrate audio playback** on MCU

Good luck with your testing! 🎯

