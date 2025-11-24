# Diagnostic: CS_N Pulsing Too Fast (23.2 kHz)

## Problem Analysis

**Your observation:**
- `cs_n1` is pulsing at **23.2 kHz** (period = 43 µs)
- This is **WAY too fast** - expected is ~50 Hz (20 ms period)

**What this means:**
- The controller is **stuck in a loop**, repeatedly starting SPI transactions
- Each transaction completes too quickly (no valid data from sensor)
- Controller immediately starts another transaction
- This creates a rapid polling loop

**Expected vs Actual:**
- ✅ **Expected**: `cs_n1` pulses every ~20ms (50 Hz) for data reports
- ❌ **Actual**: `cs_n1` pulses every ~43 µs (23.2 kHz) - **464x too fast!**

---

## Root Cause Analysis

### Possible Causes

1. **Sensor Not Responding**
   - Sensor not powered or not connected
   - Sensor not in SPI mode (P0/P1 not HIGH)
   - Sensor stuck or not initialized

2. **SPI Communication Failure**
   - MISO not connected or not working
   - Sensor not sending data back
   - Controller keeps trying to read but gets no response

3. **State Machine Stuck in READ_HEADER Loop**
   - Controller in READ_HEADER state
   - Not receiving valid `spi_rx_valid` signals
   - Falls through to else clause, immediately starts new transaction
   - Creates rapid polling loop

4. **Initialization Never Completed**
   - System stuck in initialization sequence
   - Keeps trying to send commands but sensor not responding
   - Each command attempt completes quickly (no response)

---

## Diagnostic Steps

### Step 1: Check LED Status

**Probe `led_initialized` (P28):**
- ✅ **HIGH** = Initialization completed (but may be stuck in read loop)
- ❌ **LOW** = Still initializing or stuck in init sequence

**Probe `led_error` (P38):**
- ✅ **LOW** = No errors detected (but communication may still be failing)
- ❌ **HIGH** = Error detected

**What this tells you:**
- If `led_initialized` is LOW → System never completed initialization
- If `led_initialized` is HIGH → System thinks it's initialized, but sensor not responding

---

### Step 2: Check MISO Signal

**Probe `miso1` (P12) during `cs_n1` LOW pulses:**

**Expected behavior:**
```
miso1 (P12):
    3.3V ────┐     ┌───┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌───
             │     │   │ │ │ │ │ │ │ │ │ │
    0V       └─────┘   └─┘ └─┘ └─┘ └─┘ └─┘ └─
             (Sensor response data during cs_n1 LOW)
```

**What to check:**
- ✅ **Data changes** during `cs_n1` LOW → Sensor responding
- ❌ **No data / stuck LOW or HIGH** → Sensor not responding
- ❌ **Random noise / spikes** → Wiring issue or sensor not powered

**If MISO shows no data:**
- Sensor is not responding
- Controller keeps trying to read
- Each read completes quickly (no valid data)
- Immediately starts next read → 23.2 kHz loop

---

### Step 3: Check MOSI Signal

**Probe `mosi1` (P13) during `cs_n1` LOW pulses:**

**Expected behavior:**
```
mosi1 (P13):
    3.3V ────┐     ┌───┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌───
             │     │   │ │ │ │ │ │ │ │ │ │
    0V       └─────┘   └─┘ └─┘ └─┘ └─┘ └─┘ └─
             (Command/data to sensor)
```

**What to check:**
- ✅ **Data changes** during `cs_n1` LOW → Controller sending commands
- ❌ **No data / stuck LOW** → Controller not sending properly
- ❌ **Same pattern repeating** → Stuck sending same command

**If MOSI shows data:**
- Controller is trying to communicate
- But sensor not responding (check MISO)

---

### Step 4: Check INT Pin

**Probe `int1` (P9):**

**Expected behavior:**
```
int1 (P9):
    3.3V ────┐     ┌───────────────────┐     ┌───
             │     │                   │     │
    0V       └─────┘                   └─────┘
             (Pulses LOW when sensor has data)
             Period: ~20ms (50Hz)
```

**What to check:**
- ✅ **Pulsing LOW periodically** → Sensor working, has data ready
- ❌ **Stuck HIGH** → Sensor not generating interrupts
- ❌ **Stuck LOW** → Sensor error or wiring issue

**If INT is stuck HIGH:**
- Sensor may not be working properly
- Controller should still poll every 20ms via timeout
- But if sensor not responding, it may loop faster

---

### Step 5: Check Sensor Power and Mode

**Hardware checks:**

1. **Sensor Power:**
   - Measure VIN pin voltage (should be 3.3V or 5V)
   - Check GND connection (should be 0V)
   - Verify power supply is stable

2. **SPI Mode Selection:**
   - **P0 pin** must be HIGH (connected to 3.3V) for SPI mode
   - **P1 pin** must be HIGH (connected to 3.3V) for SPI mode
   - If P0/P1 are LOW or floating → Sensor in wrong mode (I2C/UART)

3. **RST Pin:**
   - Should be HIGH (3.3V) - tied to 3.3V
   - If LOW → Sensor in reset state

4. **INT Pin:**
   - Should have pull-up resistor (10kΩ to 3.3V)
   - Should be HIGH when idle
   - Goes LOW when sensor has data

---

## Solutions

### Solution 1: Verify Sensor Power and Mode

**Check:**
- Sensor VIN = 3.3V or 5V?
- Sensor GND = 0V?
- P0 pin = HIGH (3.3V)?
- P1 pin = HIGH (3.3V)?
- RST pin = HIGH (3.3V)?

**Fix:**
- Connect P0 and P1 to 3.3V (REQUIRED for SPI mode)
- Verify power supply connections
- Check for loose connections

---

### Solution 2: Verify SPI Wiring

**Check connections:**
- FPGA `mosi1` (P13) → Sensor DI (Data In)
- FPGA `miso1` (P12) → Sensor SDA (Data Out)
- FPGA `sclk1` (P20) → Sensor SCL (Clock)
- FPGA `cs_n1` (P18) → Sensor CS (with 10kΩ pull-up to 3.3V)
- FPGA `int1` (P9) → Sensor INT (with 10kΩ pull-up to 3.3V)

**Fix:**
- Verify all connections are correct
- Check for loose wires or cold solder joints
- Verify pull-up resistors are installed

---

### Solution 3: Check MISO Response

**If MISO shows no data:**
- Sensor is not responding
- Possible causes:
  - Sensor not powered
  - Sensor in wrong mode (I2C instead of SPI)
  - Sensor not initialized
  - MISO wire disconnected or broken

**Fix:**
- Verify sensor power
- Check P0/P1 are HIGH (SPI mode)
- Try resetting sensor (pull RST LOW then HIGH)
- Check MISO wiring

---

### Solution 4: Reset and Reinitialize

**Try resetting the system:**
1. **Power off** FPGA and sensors
2. **Wait 5 seconds**
3. **Power on** sensors first
4. **Wait 1 second**
5. **Power on** FPGA
6. **Wait 5 seconds** for initialization
7. **Check** if `cs_n1` frequency changes

**Expected after reset:**
- Initialization sequence (slower, irregular pulses)
- Then steady 50 Hz polling (if sensor responds)

---

### Solution 5: Check State Machine

**The controller may be stuck in READ_HEADER state:**
- Not receiving valid `spi_rx_valid` signals
- Immediately starts next transaction
- Creates rapid loop

**This suggests:**
- Sensor not responding on MISO
- SPI master completing transactions but no valid data
- Controller keeps trying to read

**Fix:**
- Verify sensor is responding (check MISO)
- Check sensor initialization
- Verify sensor is in SPI mode

---

## Expected Behavior After Fix

**Once working correctly, you should see:**

```
cs_n1 (P18):
    3.3V ────┐     ┌───────────────────┐     ┌───
             │     │                   │     │
    0V       └─────┘                   └─────┘
             ~50-100µs                 ~50-100µs
             Period: ~20ms (50 Hz)     Period: ~20ms
             (NOT 43 µs / 23.2 kHz!)
```

**Key differences:**
- ✅ **Period**: ~20ms (50 Hz), NOT 43 µs (23.2 kHz)
- ✅ **Frequency**: ~50 Hz, NOT 23.2 kHz
- ✅ **MISO shows data** during transactions
- ✅ **INT pulses** periodically

---

## Quick Diagnostic Checklist

- [ ] `led_initialized` state (HIGH/LOW)?
- [ ] `led_error` state (HIGH/LOW)?
- [ ] `miso1` shows data during `cs_n1` LOW?
- [ ] `mosi1` shows data during `cs_n1` LOW?
- [ ] `int1` pulsing or stuck?
- [ ] Sensor VIN voltage correct?
- [ ] P0 pin HIGH (3.3V)?
- [ ] P1 pin HIGH (3.3V)?
- [ ] RST pin HIGH (3.3V)?
- [ ] All SPI wires connected correctly?

---

## Most Likely Issue

Based on 23.2 kHz frequency, the **most likely cause** is:

**Sensor not responding on MISO**

The controller:
1. Starts SPI transaction
2. Sends command on MOSI
3. Waits for response on MISO
4. Gets no valid data (sensor not responding)
5. Transaction completes quickly
6. Immediately starts next transaction
7. Creates 23.2 kHz loop

**Check:**
- Is sensor powered?
- Are P0/P1 HIGH (SPI mode)?
- Is MISO wire connected?
- Does MISO show any data?

---

## Next Steps

1. **Check sensor power** (VIN, GND)
2. **Verify P0 and P1 are HIGH** (SPI mode selection)
3. **Check MISO signal** - does it show data?
4. **Verify all SPI wiring** connections
5. **Try resetting** the system

Report back with:
- `led_initialized` state
- `miso1` behavior (data/no data/stuck)
- Sensor power voltage
- P0/P1 pin states (HIGH/LOW)

This will help identify the exact issue! 🔍

