# Diagnostic: CS_N Stuck HIGH - No SPI Transactions

## Your Current Observations
- ✅ `sclk1` - Looks like a clock (good!)
- ❌ `mosi1` - Looks like nothing (should show data)
- ❓ `miso1` - Looks like spikes/data (could be noise or actual data)
- ❌ `cs_n1` - **STUCK HIGH** (should pulse LOW periodically)
- ❓ `int1` - Square wave (could be good if pulsing)

## Problem Analysis

**`cs_n1` stuck HIGH means:**
- The SPI master is **not starting transactions**
- The BNO085 controller is **not requesting SPI transfers**
- The system may be stuck in initialization or waiting state

---

## Step-by-Step Diagnosis

### Step 1: Check System State

**Probe these signals to understand where the system is stuck:**

1. **`led_initialized` (P28)**
   - ✅ **HIGH** = Sensors initialized, system in WAIT_DATA state
   - ❌ **LOW** = Still initializing or stuck in init

2. **`led_error` (P38)**
   - ✅ **LOW** = No errors
   - ❌ **HIGH** = Communication error

**What this tells you:**
- If `led_initialized` is LOW → System is still in initialization (waiting 100ms, or stuck in init sequence)
- If `led_initialized` is HIGH → System should be polling, but not starting transactions

---

### Step 2: Check INT Pin Behavior

**Probe `int1` (P9) with oscilloscope:**

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
- **Is `int1` pulsing LOW periodically?**
  - ✅ **YES** (pulses every ~20ms) → INT is working, sensor has data ready
  - ❌ **NO** (stuck HIGH) → Sensor not generating interrupts
  - ❌ **Stuck LOW** → Sensor error or wiring issue

**If `int1` is stuck HIGH:**
- The controller waits for INT to go LOW OR a 20ms timeout
- If INT never goes LOW, it should still poll every 20ms (60,000 cycles at 3MHz)
- **Check if 20ms has passed** since initialization

---

### Step 3: Check SPI Master State

**The SPI master should be idle when not in use:**

**Expected idle state:**
- `cs_n1` = HIGH (inactive)
- `sclk1` = HIGH (CPOL=1, Mode 3)
- `mosi1` = LOW (driven low when idle)

**What you're seeing:**
- `sclk1` = Clock signal (this is unusual - should be HIGH when idle)
- `mosi1` = Nothing (correct for idle, but should show data during transactions)
- `cs_n1` = HIGH (correct for idle, but should pulse LOW)

**Question: Is `sclk1` continuously running, or only during transactions?**

- **If `sclk1` is continuously running:**
  - This suggests the SPI master might be stuck in a transaction
  - Or there's a synthesis issue
  - **Check `spi_busy` signal** (if you can probe it)

- **If `sclk1` is HIGH (idle):**
  - SPI master is idle (correct)
  - Problem is controller not starting transactions

---

### Step 4: Check Initialization Sequence

**The BNO085 controller goes through these states:**

1. **INIT_WAIT** (100ms delay after reset)
2. **INIT_PRODUCT_ID** (Send product ID request)
3. **INIT_ENABLE_ROTATION** (Enable rotation vector report)
4. **INIT_ENABLE_GYRO** (Enable gyroscope report)
5. **WAIT_DATA** (Poll for data)

**If `led_initialized` is LOW:**
- System is stuck in initialization
- **Wait at least 5 seconds** after power-on
- Check if `cs_n1` ever pulses during initialization

**If `led_initialized` is HIGH:**
- System completed initialization
- Should be in WAIT_DATA state
- Should poll every 20ms (even if INT is HIGH)

---

## Possible Causes and Solutions

### Cause 1: System Still Initializing

**Symptoms:**
- `led_initialized` is LOW
- `cs_n1` never pulses
- Less than 5 seconds since power-on

**Solution:**
- **Wait longer** (initialization takes 2-5 seconds)
- Watch for `cs_n1` to start pulsing after initialization completes

---

### Cause 2: INT Pin Not Connected or Wrong State

**Symptoms:**
- `int1` is stuck HIGH (never pulses LOW)
- `led_initialized` is HIGH
- `cs_n1` never pulses

**The code should still poll every 20ms even if INT is HIGH:**
```systemverilog
if (!int_n_sync || (init_counter > 32'd60_000)) begin  // ~20ms at 3MHz
```

**Check:**
- Is `int1` (P9) connected to sensor INT pin?
- Does sensor INT pin have pull-up resistor? (should be HIGH when idle)
- Has 20ms passed since initialization? (check with oscilloscope timebase)

**Solution:**
- Verify INT pin wiring
- Wait 20ms and check if `cs_n1` pulses
- If still no pulses, check `spi_busy` and `spi_tx_ready` signals

---

### Cause 3: SPI Master Stuck or Not Ready

**Symptoms:**
- `led_initialized` is HIGH
- `int1` is pulsing LOW
- `cs_n1` never pulses

**The controller checks:**
```systemverilog
if (!spi_busy && spi_tx_ready) begin
```

**Possible issues:**
- `spi_busy` stuck HIGH (SPI master stuck in transaction)
- `spi_tx_ready` stuck LOW (SPI master not ready)

**Solution:**
- Check SPI master state machine
- Verify clock is running (3MHz from HSOSC)
- Check for synthesis warnings about unconnected signals

---

### Cause 4: Sensor Not Responding During Initialization

**Symptoms:**
- `led_initialized` stays LOW
- `cs_n1` pulses during initialization but then stops
- `miso1` shows no response

**Solution:**
- Check sensor power (VIN and GND)
- Verify SPI wiring (MOSI, MISO, SCLK, CS)
- Check sensor RST pin (should be HIGH, tied to 3.3V)
- Verify sensor is in SPI mode (not I2C)

---

### Cause 5: Clock Issue

**Symptoms:**
- `sclk1` shows continuous clock (unusual)
- No transactions starting

**Check:**
- Is system clock (3MHz from HSOSC) running?
- Is SPI clock divider correct? (CLK_DIV=16)
- Check for clock domain issues

---

## Diagnostic Test Procedure

### Test 1: Check Initialization Status

1. **Power on FPGA**
2. **Wait 5 seconds**
3. **Check `led_initialized` (P28)**
   - ✅ HIGH → Go to Test 2
   - ❌ LOW → System stuck in initialization (check sensor power/wiring)

### Test 2: Check INT Pin

1. **Probe `int1` (P9)**
2. **Set oscilloscope**: 10ms/div, trigger on falling edge
3. **Wait 50ms** (should see 2-3 pulses if working)
4. **Check:**
   - ✅ Pulses LOW every ~20ms → INT working
   - ❌ Stuck HIGH → Check INT pin wiring
   - ❌ Stuck LOW → Sensor error

### Test 3: Wait for Timeout Polling

1. **If `int1` is stuck HIGH**, the controller should still poll every 20ms
2. **Set oscilloscope**: 20ms/div, trigger on falling edge of `cs_n1`
3. **Wait 50ms** (should see at least 2 pulses)
4. **Check:**
   - ✅ `cs_n1` pulses every ~20ms → System working!
   - ❌ No pulses → Controller stuck (check `spi_busy`, `spi_tx_ready`)

### Test 4: Check During Initialization

1. **Power on FPGA**
2. **Probe `cs_n1` (P18)**
3. **Set oscilloscope**: 100ms/div, trigger on falling edge
4. **Watch for pulses during first 5 seconds**
5. **Check:**
   - ✅ Pulses during initialization → Sensor responding
   - ❌ No pulses at all → Sensor not responding or not powered

---

## Quick Fixes to Try

### Fix 1: Verify INT Pin Connection

**Check:**
- `int1` (P9) connected to sensor INT pin?
- Sensor INT pin has pull-up resistor? (10kΩ to 3.3V)
- INT pin voltage: Should be HIGH (3.3V) when idle

### Fix 2: Reset the System

1. **Press reset button** (pull `rst_n` LOW)
2. **Release reset** (let `rst_n` go HIGH)
3. **Wait 5 seconds**
4. **Check if `cs_n1` starts pulsing**

### Fix 3: Check Sensor Power

**Measure:**
- Sensor VIN voltage (should be 3.3V or 5V)
- Sensor GND connection (should be 0V)
- Sensor RST pin (should be HIGH, 3.3V)

### Fix 4: Verify SPI Wiring

**Check connections:**
- FPGA `mosi1` (P13) → Sensor DI (Data In)
- FPGA `miso1` (P12) → Sensor SDA (Data Out)
- FPGA `sclk1` (P20) → Sensor SCL (Clock)
- FPGA `cs_n1` (P18) → Sensor CS (with 10kΩ pull-up to 3.3V)
- FPGA `int1` (P9) → Sensor INT (with 10kΩ pull-up to 3.3V)

---

## Expected Behavior After Fix

**Once working, you should see:**

```
cs_n1 (P18):
    3.3V ────┐     ┌───────────────────┐     ┌───
             │     │                   │     │
    0V       └─────┘                   └─────┘
             ~50-100µs                 ~50-100µs
             every 20ms                every 20ms

sclk1 (P20):
    3.3V ────┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌───
             │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │
    0V       └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─
             (Only during cs_n1 LOW pulses)
             ~3MHz clock

mosi1 (P13):
    3.3V ────┐     ┌───┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌───
             │     │   │ │ │ │ │ │ │ │ │ │
    0V       └─────┘   └─┘ └─┘ └─┘ └─┘ └─┘ └─
             (Data during cs_n1 LOW pulses)

miso1 (P12):
    3.3V ────┐     ┌───┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌───
             │     │   │ │ │ │ │ │ │ │ │ │
    0V       └─────┘   └─┘ └─┘ └─┘ └─┘ └─┘ └─
             (Sensor response data)
```

---

## Next Steps

1. **Check `led_initialized`** - Is it HIGH or LOW?
2. **Check `int1`** - Is it pulsing or stuck?
3. **Wait 20ms** - Does `cs_n1` pulse after timeout?
4. **Check sensor power** - Is sensor powered correctly?
5. **Verify wiring** - Are all SPI and INT pins connected?

Report back with:
- `led_initialized` state (HIGH/LOW)
- `int1` behavior (pulsing/stuck HIGH/stuck LOW)
- How long since power-on
- Whether you see any `cs_n1` pulses at all

This will help narrow down the exact issue! 🔍

