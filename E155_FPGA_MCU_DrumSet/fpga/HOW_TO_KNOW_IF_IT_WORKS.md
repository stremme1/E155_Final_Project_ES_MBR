# How to Know If Your FPGA Code Is Working
## Visual Indicators on FPGA, Oscilloscope, and Logic Analyzer

This guide shows you **exactly what to look for** to determine if your system is working correctly.

---

## 🟢 Quick Health Check (30 seconds)

### On the FPGA Board (Visual Inspection)

1. **`led_initialized` (P28)** - Should be **ON (lit)** after ~2-5 seconds
   - ✅ **Working**: LED turns ON and stays ON
   - ❌ **Not working**: LED stays OFF (sensors not initializing)

2. **`led_error` (P38)** - Should be **OFF (dark)**
   - ✅ **Working**: LED stays OFF
   - ❌ **Not working**: LED is ON (sensor communication error)

### If LEDs are correct → System is **80% working!**

---

## 🔍 Detailed Signal Analysis

### Test 1: Power-On Sequence (First 10 seconds)

#### What to Probe
- **`rst_n`** (P43) - Reset signal
- **`led_initialized`** (P28) - Initialization LED
- **`led_error`** (P38) - Error LED

#### Expected Behavior

```
Time:  0s    1s    2s    3s    4s    5s
rst_n: ────────────────────────────────── (HIGH)
led_init: ───┐
            │
            └──────────────────────────── (HIGH after init)
led_error: ───────────────────────────── (LOW, stays LOW)
```

**What this tells you:**
- ✅ **`rst_n` HIGH**: System is not in reset
- ✅ **`led_initialized` goes HIGH**: Both sensors initialized successfully
- ✅ **`led_error` stays LOW**: No communication errors

**If `led_initialized` never goes HIGH:**
- Sensors not powered
- SPI wiring incorrect
- Sensors not responding

---

### Test 2: Sensor SPI Communication (Sensor 1)

#### What to Probe (4 signals)
- **`cs_n1`** (P18) - Chip select
- **`sclk1`** (P20) - SPI clock
- **`mosi1`** (P13) - Data to sensor
- **`miso1`** (P12) - Data from sensor
- **`int1`** (P9) - Interrupt pin

#### Expected Waveforms (Oscilloscope/Logic Analyzer)

```
cs_n1 (P18):
    3.3V ────┐     ┌───────────────────┐     ┌───
             │     │                   │     │
    0V       └─────┘                   └─────┘
             ~50µs                     ~50µs
             every 20ms                every 20ms
             (50Hz data reports)

sclk1 (P20):
    3.3V ────┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌───
             │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │
    0V       └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─
             (8 clock cycles per byte)
             Period: ~333ns (3MHz)

mosi1 (P13):
    3.3V ────┐     ┌───┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌───
             │     │   │ │ │ │ │ │ │ │ │ │
    0V       └─────┘   └─┘ └─┘ └─┘ └─┘ └─┘ └─
             (Command/data to sensor)

miso1 (P12):
    3.3V ────┐     ┌───┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌───
             │     │   │ │ │ │ │ │ │ │ │ │
    0V       └─────┘   └─┘ └─┘ └─┘ └─┘ └─┘ └─
             (Response from sensor)

int1 (P9):
    3.3V ────┐     ┌───────────────────┐     ┌───
             │     │                   │     │
    0V       └─────┘                   └─────┘
             (Pulses LOW when data ready)
```

#### Key Measurements

| Signal | What to Measure | Expected Value | What It Means |
|--------|----------------|----------------|---------------|
| `cs_n1` | Pulse frequency | ~20ms between pulses | ✅ Sensors sending data at 50Hz |
| `sclk1` | Clock frequency | ~3MHz (333ns period) | ✅ SPI clock correct |
| `cs_n1` | Pulse width | ~50-100µs | ✅ Normal transaction time |
| `miso1` | Activity during `cs_n1` LOW | Data changes | ✅ Sensor responding |
| `int1` | Pulse frequency | ~20ms between pulses | ✅ Sensor indicating data ready |

#### What This Tells You

✅ **Working correctly:**
- `cs_n1` pulses every ~20ms (50Hz)
- `sclk1` shows ~3MHz clock during transactions
- `miso1` shows data during transactions
- `int1` pulses LOW periodically

❌ **Not working:**
- `cs_n1` always HIGH → No SPI communication
- `cs_n1` always LOW → Missing pull-up resistor
- No `sclk1` activity → SPI master not starting
- No `miso1` response → Sensor not powered or not responding
- `int1` stuck LOW → Sensor error or wiring issue

---

### Test 3: Sensor SPI Communication (Sensor 2)

**Same as Test 2**, but probe:
- `cs_n2` (P48)
- `sclk2` (P4)
- `mosi2` (P47)
- `miso2` (P6)
- `int2` (P3)

**Expected:** Identical behavior to Sensor 1, but **independent timing** (can overlap)

---

### Test 4: MCU SPI Output (Gesture Detection)

#### What to Probe
- **`mcu_cs_n`** (P19) - Chip select to MCU
- **`mcu_sclk`** (P21) - SPI clock to MCU
- **`mcu_mosi`** (P10) - Data to MCU

#### Expected Behavior

**When NO gestures detected:**
```
mcu_cs_n: ────────────────────────────────── (HIGH, idle)
mcu_sclk: ────────────────────────────────── (LOW, idle)
mcu_mosi: ────────────────────────────────── (LOW, idle)
```

**When gesture detected (e.g., strike detected):**
```
mcu_cs_n:
    3.3V ────┐     ┌───────────────────
             │     │
    0V       └─────┘
             ~50-100µs
             (pulses when gesture detected)

mcu_sclk:
    0V   ────┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌───
             │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │
    3.3V     └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─
             (8 clock cycles, ~3MHz)

mcu_mosi:
    0V   ────┐     ┌───┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌───
             │     │   │ │ │ │ │ │ │ │ │ │
    3.3V     └─────┘   └─┘ └─┘ └─┘ └─┘ └─┘ └─
             (Sound code: 0000XXXX)
```

#### Decoding `mcu_mosi` Data

The 8-bit data format is: `0000XXXX` where XXXX is the sound code (0-7)

| Binary Pattern | Decimal | Sound |
|----------------|---------|-------|
| `0000 0000` | 0 | Snare |
| `0000 0001` | 1 | Hi-hat |
| `0000 0010` | 2 | Kick |
| `0000 0011` | 3 | High tom |
| `0000 0100` | 4 | Mid tom |
| `0000 0101` | 5 | Crash |
| `0000 0110` | 6 | Ride |
| `0000 0111` | 7 | Floor tom |

**How to decode on oscilloscope:**
1. Trigger on falling edge of `mcu_cs_n`
2. Look at `mcu_mosi` during the 8 clock cycles
3. Read MSB first (left to right)
4. Lower 4 bits = sound code

#### What This Tells You

✅ **Working correctly:**
- `mcu_cs_n` pulses LOW when you wave sticks (gesture detected)
- `mcu_sclk` shows ~3MHz clock during pulses
- `mcu_mosi` shows valid data patterns (0000XXXX)
- Different gestures produce different codes

❌ **Not working:**
- `mcu_cs_n` never pulses → Gesture detector not working
- `mcu_cs_n` always LOW → Missing pull-up resistor
- No `mcu_sclk` → SPI not starting
- Wrong `mcu_mosi` data → Gesture detection logic error

---

### Test 5: Interrupt Pins (INT1 and INT2)

#### What to Probe
- **`int1`** (P9) - Sensor 1 interrupt
- **`int2`** (P3) - Sensor 2 interrupt

#### Expected Behavior

```
int1 (P9):
    3.3V ────┐     ┌───────────────────┐     ┌───
             │     │                   │     │
    0V       └─────┘                   └─────┘
             (Pulses LOW when sensor has data ready)
             Frequency: ~20ms (50Hz)
             Width: ~1-5ms (sensor-dependent)

int2 (P3):
    3.3V ────┐     ┌───────────────────┐     ┌───
             │     │                   │     │
    0V       └─────┘                   └─────┘
             (Same behavior as int1, independent timing)
```

#### What This Tells You

✅ **Working correctly:**
- `int1` and `int2` pulse LOW periodically (~20ms)
- Pulses align with `cs_n1`/`cs_n2` activity
- Pins are HIGH most of the time (idle)

❌ **Not working:**
- `int1`/`int2` stuck LOW → Sensor error or wiring issue
- `int1`/`int2` always HIGH → Sensor not generating interrupts (may still work in polling mode)
- No pulses → Sensor not powered or not configured

**Note:** Even if INT pins don't pulse, the system may still work in polling mode (check SPI activity instead)

---

### Test 6: Button Inputs

#### What to Probe
- **`calib_button`** (P11) - Calibration button
- **`kick_button`** (P2) - Kick button

#### Expected Behavior

```
calib_button (P11):
    3.3V ────┐     ┌────────────────────
             │     │
    0V       └─────┘
             (Goes LOW when pressed)
             May have brief bounces (normal)

kick_button (P2):
    3.3V ────┐     ┌────────────────────
             │     │
    0V       └─────┘
             (Goes LOW when pressed)
```

**When `kick_button` pressed:**
- `mcu_cs_n` should pulse LOW
- `mcu_mosi` should show `0000 0010` (code 2 = Kick)

#### What This Tells You

✅ **Working correctly:**
- Buttons go LOW when pressed
- Buttons return to HIGH when released
- `kick_button` triggers MCU SPI output

❌ **Not working:**
- Button always LOW → Stuck button or short circuit
- Button always HIGH → Missing pull-up resistor
- No response → Button not connected or wiring issue

---

## 📊 Multi-Channel Analysis (Logic Analyzer)

### Recommended Setup (4+ channels)

**Channel 1:** `cs_n1` (Sensor 1 chip select)  
**Channel 2:** `cs_n2` (Sensor 2 chip select)  
**Channel 3:** `mcu_cs_n` (MCU chip select)  
**Channel 4:** `led_initialized` (Status LED)

### Expected Pattern

```
Time:  0ms    20ms   40ms   60ms   80ms   100ms
cs_n1: ──┐ ┌───┐ ┌───┐ ┌───┐ ┌───┐ ┌───
         └─┘   └─┘   └─┘   └─┘   └─┘

cs_n2: ──┐ ┌───┐ ┌───┐ ┌───┐ ┌───┐ ┌───
         └─┘   └─┘   └─┘   └─┘   └─┘
         (Independent timing, can overlap)

mcu_cs_n: ────────────────────┐ ┌───────────
                              └─┘
                              (Only when gesture detected)

led_init: ───┐
             └───────────────────────────────
             (Goes HIGH after initialization)
```

**What this tells you:**
- ✅ Both sensors communicating independently
- ✅ MCU SPI only activates on gestures
- ✅ System initialized successfully

---

## 🎯 Quick Diagnostic Flowchart

```
Start: Power on FPGA
  │
  ├─> Check `led_initialized` (P28)
  │   │
  │   ├─> ON? → ✅ Sensors initialized
  │   │         │
  │   │         ├─> Check `led_error` (P38)
  │   │         │   │
  │   │         │   ├─> OFF? → ✅ No errors
  │   │         │   │         │
  │   │         │   │         ├─> Probe `cs_n1` (P18)
  │   │         │   │         │   │
  │   │         │   │         │   ├─> Pulses every 20ms? → ✅ Sensor 1 working
  │   │         │   │         │   │
  │   │         │   │         │   └─> No pulses? → ❌ Check sensor power/wiring
  │   │         │   │         │
  │   │         │   │         └─> Probe `mcu_cs_n` (P19)
  │   │         │   │             │
  │   │         │   │             ├─> Pulses when waving sticks? → ✅ Gesture detection working
  │   │         │   │             │
  │   │         │   │             └─> No pulses? → ❌ Check gesture detector or calibration
  │   │         │   │
  │   │         │   └─> ON? → ❌ Sensor communication error
  │   │         │         │
  │   │         │         └─> Check SPI signals (`cs_n1`, `sclk1`, `miso1`)
  │   │         │
  │   └─> OFF? → ❌ Sensors not initializing
  │         │
  │         └─> Check sensor power, SPI wiring, pull-up resistors
```

---

## ✅ Success Criteria Checklist

### Basic Functionality (Must Pass)
- [ ] `led_initialized` (P28) goes HIGH after power-on
- [ ] `led_error` (P38) stays LOW
- [ ] `rst_n` (P43) is HIGH (not in reset)

### Sensor Communication (Must Pass)
- [ ] `cs_n1` (P18) pulses every ~20ms
- [ ] `cs_n2` (P48) pulses every ~20ms
- [ ] `sclk1` (P20) shows ~3MHz clock during transactions
- [ ] `sclk2` (P4) shows ~3MHz clock during transactions
- [ ] `miso1` (P12) shows data during transactions
- [ ] `miso2` (P6) shows data during transactions

### Gesture Detection (Must Pass)
- [ ] `mcu_cs_n` (P19) pulses when waving sticks
- [ ] `mcu_sclk` (P21) shows ~3MHz clock during pulses
- [ ] `mcu_mosi` (P10) shows valid data (0000XXXX format)
- [ ] Different gestures produce different sound codes

### Optional (Nice to Have)
- [ ] `int1` (P9) pulses LOW periodically
- [ ] `int2` (P3) pulses LOW periodically
- [ ] `calib_button` (P11) goes LOW when pressed
- [ ] `kick_button` (P2) triggers MCU SPI output

---

## 🚨 Common Problems and Solutions

### Problem: `led_initialized` Never Goes HIGH

**Symptoms:**
- LED stays OFF after power-on
- No SPI activity on `cs_n1` or `cs_n2`

**Check:**
1. Sensor power (VIN and GND connected?)
2. SPI wiring (MOSI, MISO, SCLK, CS connected correctly?)
3. Pull-up resistors on CS_N pins (10kΩ to 3.3V)
4. Sensor RST pin (should be HIGH, tied to 3.3V)
5. INT pins connected (P9 and P3)

**Fix:**
- Verify all connections
- Check sensor datasheet for correct pinout
- Measure sensor power supply voltage

---

### Problem: `led_error` Goes HIGH

**Symptoms:**
- Error LED turns ON
- SPI communication fails

**Check:**
1. SPI clock frequency (should be ~3MHz)
2. INT pins stuck LOW (check `int1` and `int2`)
3. Sensor response on MISO

**Fix:**
- Check INT pin wiring
- Verify SPI mode (Mode 3 for BNO085)
- Check sensor initialization sequence

---

### Problem: No MCU SPI Output

**Symptoms:**
- `mcu_cs_n` never pulses
- No gesture detection

**Check:**
1. Calibration (press `calib_button` in zero position)
2. Gesture thresholds (may need adjustment)
3. Sensor data valid (`euler1_valid`, `euler2_valid`)

**Fix:**
- Recalibrate system
- Wave sticks more vigorously
- Check gesture detector thresholds in code

---

### Problem: Wrong Sound Codes

**Symptoms:**
- MCU SPI outputs wrong codes
- Gestures don't match expected sounds

**Check:**
1. Yaw zones (calibration may be off)
2. Pitch thresholds (for cymbal detection)
3. Gyro thresholds (for strike detection)

**Fix:**
- Recalibrate in correct zero position
- Adjust thresholds in `gesture_detector.sv`
- Verify sensor orientation

---

## 📈 Performance Metrics

### Expected Timing

| Event | Expected Time | Measurement |
|-------|---------------|-------------|
| Power-on to initialization | 2-5 seconds | Time from power-on to `led_initialized` HIGH |
| Sensor data rate | 50Hz (20ms) | Time between `cs_n1`/`cs_n2` pulses |
| SPI transaction | 50-100µs | Width of `cs_n1`/`cs_n2` LOW pulse |
| SPI clock frequency | ~3MHz | Period of `sclk1`/`sclk2` |
| Gesture response | <100ms | Time from gesture to `mcu_cs_n` pulse |

### System Health Indicators

**Healthy System:**
- ✅ `led_initialized` = HIGH
- ✅ `led_error` = LOW
- ✅ Regular SPI activity (50Hz)
- ✅ MCU SPI pulses on gestures

**Unhealthy System:**
- ❌ `led_initialized` = LOW (sensors not working)
- ❌ `led_error` = HIGH (communication error)
- ❌ No SPI activity (sensors not responding)
- ❌ No MCU SPI output (gesture detection not working)

---

## 🎓 Understanding the Signals

### Why These Signals Matter

1. **`led_initialized`**: Tells you if sensors are communicating
   - HIGH = Both sensors initialized and ready
   - LOW = Sensors not responding or not powered

2. **`led_error`**: Indicates communication problems
   - LOW = Everything OK
   - HIGH = SPI error or sensor problem

3. **`cs_n1`/`cs_n2`**: Shows sensor communication activity
   - Regular pulses = Sensors sending data
   - No pulses = Sensors not communicating

4. **`mcu_cs_n`**: Shows gesture detection activity
   - Pulses = Gestures detected
   - No pulses = No gestures or detector not working

5. **`int1`/`int2`**: Sensor data ready indicators
   - Pulses LOW = Sensor has data ready
   - Stuck LOW = Sensor error
   - Always HIGH = Sensor not generating interrupts (may still work)

---

## 🔧 Quick Test Procedure

### 5-Minute Test

1. **Power on FPGA** → Wait 5 seconds
2. **Check `led_initialized`** → Should be ON
3. **Check `led_error`** → Should be OFF
4. **Probe `cs_n1`** → Should see pulses every 20ms
5. **Wave sticks** → `mcu_cs_n` should pulse

**If all pass → System is working! ✅**

---

Good luck with your testing! 🎯

