# Diagnostic: Frequency Analysis - Multiple Issues Detected

## Your Current Measurements

| Signal | Measured Frequency | Expected Frequency | Status |
|--------|-------------------|-------------------|--------|
| `sclk1` | **192 kHz** | ~3 MHz | ❌ **15.6x too slow** |
| `mosi1` | **23.2 kHz** | ~50 Hz (transaction rate) | ❌ **464x too fast** |
| `miso1` | **357 kHz / 1.1 MHz** (alternating) | Data during transactions only | ❌ **Unusual pattern** |
| `int1` | **286 kHz** | ~50 Hz (20 ms period) | ❌ **5,720x too fast** |

---

## Problem Analysis

### Issue 1: SPI Clock Too Slow (192 kHz vs 3 MHz)

**Expected:**
- System clock: 3 MHz (from HSOSC: 48 MHz / 16)
- SPI clock: ~3 MHz (CLK_DIV = 16, so 3 MHz / 2 = 1.5 MHz per edge, but actual SPI clock should be ~3 MHz)

**Actual:**
- SPI clock: 192 kHz (15.6x slower than expected)

**Possible causes:**
1. **Clock divider wrong** - CLK_DIV might be too large
2. **System clock wrong** - HSOSC might not be generating 3 MHz
3. **Clock gating issue** - Clock might be getting divided somewhere
4. **Measurement error** - Make sure you're measuring the actual SPI clock during transactions

**Check:**
- Measure system clock frequency (should be 3 MHz)
- Verify CLK_DIV parameter in `spi_master.sv` (should be 16)
- Check if `sclk1` is only active during `cs_n1` LOW pulses

---

### Issue 2: Transaction Rate Too Fast (23.2 kHz)

**Expected:**
- Transaction rate: ~50 Hz (one transaction every 20 ms)
- Transaction duration: ~50-100 µs per transaction

**Actual:**
- Transaction rate: 23.2 kHz (one transaction every 43 µs)
- This is **464x too fast**

**This means:**
- Controller is stuck in a loop
- Each transaction completes too quickly
- Immediately starts next transaction
- Sensor likely not responding properly

**Possible causes:**
1. **Sensor not responding** - No valid data on MISO
2. **State machine stuck** - Controller in error loop
3. **Initialization failed** - System never properly initialized
4. **MISO not connected** - Sensor can't send data back

---

### Issue 3: MISO Alternating Frequencies (357 kHz / 1.1 MHz)

**Expected:**
- MISO should only have data during `cs_n1` LOW pulses
- Data rate should match SPI clock (~3 MHz)
- Should show consistent data patterns

**Actual:**
- Alternating between 357 kHz and 1.1 MHz
- This is very unusual

**Possible causes:**
1. **Different packet sizes** - Sensor sending different length responses
2. **Noise/interference** - MISO picking up noise
3. **Wiring issue** - Loose connection or crosstalk
4. **Sensor error responses** - Sensor sending error packets
5. **Measurement artifact** - Measuring noise between transactions

**Check:**
- Is MISO only active during `cs_n1` LOW?
- Does MISO show actual data patterns or just noise?
- Is MISO wire properly connected and shielded?

---

### Issue 4: INT Pin Too Fast (286 kHz)

**Expected:**
- INT should pulse LOW every ~20 ms (50 Hz)
- INT should be HIGH most of the time
- INT goes LOW when sensor has data ready

**Actual:**
- INT: 286 kHz (period = 3.5 µs)
- This is **5,720x too fast**

**This is CRITICAL - INT should NOT be this fast!**

**Possible causes:**
1. **Wiring issue** - INT pin shorted or picking up noise
2. **Sensor error** - Sensor in error state, INT oscillating
3. **Crosstalk** - INT picking up SPI clock or other signals
4. **No pull-up resistor** - INT floating, picking up noise
5. **Sensor not powered** - INT pin floating

**Check:**
- Is INT pin properly connected?
- Does INT have pull-up resistor (10kΩ to 3.3V)?
- Is INT wire too close to SPI clock or other high-speed signals?
- Measure INT voltage: Should be HIGH (3.3V) when idle

---

## Root Cause Analysis

### Most Likely Scenario

Based on all the frequencies, here's what's probably happening:

1. **System clock is wrong or too slow**
   - SPI clock is 192 kHz instead of 3 MHz
   - This suggests system clock might be wrong

2. **Sensor not responding properly**
   - Transaction rate is 23.2 kHz (too fast)
   - MISO showing alternating frequencies (sensor confused or sending errors)
   - Controller stuck in loop trying to read

3. **INT pin has serious issue**
   - 286 kHz is way too fast
   - INT should be ~50 Hz
   - This suggests wiring problem or sensor error

4. **System in bad state**
   - Multiple issues suggest fundamental problems
   - Sensor may not be initialized
   - Communication protocol broken

---

## Diagnostic Steps

### Step 1: Check System Clock

**Measure the actual system clock frequency:**
- The HSOSC should generate 3 MHz (48 MHz / 16)
- If system clock is wrong, everything will be wrong

**How to check:**
- Look for a clock output pin (if available)
- Or measure SPI clock and work backwards
- If `sclk1` = 192 kHz with CLK_DIV=16, system clock might be ~3 MHz (192 kHz * 16 = 3.072 MHz) - actually this might be correct!

**Wait - let me recalculate:**
- If SPI clock is 192 kHz
- And CLK_DIV = 16
- Then SPI clock period = system clock period * 16 * 2 (for both edges)
- So system clock = 192 kHz * 16 * 2 = 6.144 MHz

**But expected system clock is 3 MHz...**

**Actually, the SPI clock generation divides by CLK_DIV for each half-cycle:**
- System clock: 3 MHz
- CLK_DIV: 16
- SPI clock frequency = 3 MHz / (16 * 2) = 93.75 kHz per edge
- But SPI clock period = 2 * (16 * system clock period) = 32 * system clock period
- So SPI clock = 3 MHz / 32 = 93.75 kHz

**Hmm, but you're seeing 192 kHz...**

Let me check the SPI master code more carefully. The clock divider logic might be different than I thought.

---

### Step 2: Verify Sensor Power and Mode

**Check:**
- Sensor VIN voltage (should be 3.3V or 5V)
- Sensor GND (should be 0V)
- **P0 pin** (must be HIGH/3.3V for SPI mode)
- **P1 pin** (must be HIGH/3.3V for SPI mode)
- RST pin (should be HIGH/3.3V)

**If P0 or P1 are LOW:**
- Sensor is in I2C or UART mode
- SPI communication will fail
- Sensor won't respond correctly

---

### Step 3: Check INT Pin Wiring

**INT pin at 286 kHz is CRITICAL - this is wrong!**

**Check:**
- Is `int1` (P9) connected to sensor INT pin?
- Does INT pin have **10kΩ pull-up resistor to 3.3V**?
- Is INT wire too close to SPI clock wire? (crosstalk)
- Measure INT voltage: Should be HIGH (3.3V) when idle

**If INT is oscillating at 286 kHz:**
- This suggests:
  - No pull-up resistor (floating)
  - Wire picking up noise from SPI clock
  - Sensor in error state
  - Wiring issue

**Fix:**
- Add 10kΩ pull-up resistor to 3.3V
- Keep INT wire away from SPI clock wire
- Verify sensor is powered and working

---

### Step 4: Check MISO Signal Quality

**MISO alternating between 357 kHz and 1.1 MHz is unusual**

**Check:**
- Is MISO only active during `cs_n1` LOW pulses?
- Or is MISO active all the time (noise)?
- Does MISO show actual data patterns or just noise?

**If MISO is noisy:**
- Check wiring (loose connection?)
- Check for crosstalk (wire too close to clock?)
- Verify sensor is powered
- Check MISO pull-up resistor (optional, but recommended)

---

### Step 5: Check Transaction Timing

**Set oscilloscope to show:**
- `cs_n1` (trigger)
- `sclk1`
- `mosi1`
- `miso1`
- `int1`

**Look for:**
- Does `cs_n1` go LOW for each transaction?
- How long is `cs_n1` LOW? (should be ~50-100 µs)
- Does `sclk1` only run during `cs_n1` LOW?
- Does `miso1` show data during `cs_n1` LOW?
- Is `int1` oscillating continuously or only during transactions?

---

## Immediate Fixes to Try

### Fix 1: Add INT Pull-Up Resistor

**CRITICAL - INT pin needs pull-up!**

```
INT pin (P9) → 10kΩ resistor → 3.3V
```

**This should fix the 286 kHz oscillation**

---

### Fix 2: Verify P0 and P1 are HIGH

**REQUIRED for SPI mode:**

```
P0 pin → 3.3V (HIGH)
P1 pin → 3.3V (HIGH)
```

**If these are LOW, sensor is in wrong mode!**

---

### Fix 3: Check SPI Clock Calculation

**Verify CLK_DIV parameter:**
- In `spi_master.sv`, CLK_DIV should be 16
- This gives SPI clock = system_clock / (CLK_DIV * 2)
- With 3 MHz system clock: SPI = 3 MHz / 32 = 93.75 kHz

**But you're seeing 192 kHz...**

**Possible explanations:**
1. System clock is actually 6.144 MHz (not 3 MHz)
2. CLK_DIV is actually 8 (not 16)
3. Measurement is of something else (not actual SPI clock)

**Check:**
- What is the actual system clock frequency?
- What is CLK_DIV set to in code?

---

### Fix 4: Reset Everything

**Try complete reset:**
1. Power off FPGA and sensors
2. Wait 10 seconds
3. Verify all wiring (especially INT pull-up, P0/P1 HIGH)
4. Power on sensors first
5. Wait 2 seconds
6. Power on FPGA
7. Wait 10 seconds for initialization
8. Measure frequencies again

---

## Expected Frequencies After Fix

| Signal | Expected Frequency | Expected Period |
|--------|-------------------|----------------|
| `sclk1` | ~93.75 kHz (during transactions) | ~10.67 µs |
| `cs_n1` | ~50 Hz (transaction rate) | ~20 ms |
| `mosi1` | ~50 Hz (transaction rate) | ~20 ms |
| `miso1` | Data during transactions only | N/A |
| `int1` | ~50 Hz (pulse rate) | ~20 ms |

**Note:** SPI clock frequency depends on CLK_DIV and system clock. If system clock is 3 MHz and CLK_DIV=16, SPI clock should be ~93.75 kHz, not 3 MHz. The 3 MHz I mentioned earlier was incorrect - that would be the system clock, not the SPI clock.

---

## Key Questions to Answer

1. **What is the actual system clock frequency?** (should be 3 MHz from HSOSC)
2. **What is CLK_DIV set to?** (should be 16)
3. **Does INT have pull-up resistor?** (must have 10kΩ to 3.3V)
4. **Are P0 and P1 HIGH?** (must be HIGH for SPI mode)
5. **Is MISO only active during cs_n1 LOW?** (should be)
6. **What does led_initialized show?** (HIGH or LOW?)

---

## Most Critical Issues

1. **INT pin at 286 kHz** - This is completely wrong, must fix first
2. **Transaction rate at 23.2 kHz** - Way too fast, suggests sensor not responding
3. **MISO alternating frequencies** - Suggests communication problems

**Priority fixes:**
1. Add INT pull-up resistor (10kΩ to 3.3V)
2. Verify P0 and P1 are HIGH (3.3V)
3. Check sensor power and wiring
4. Verify system clock frequency

---

Report back with:
- INT voltage when idle (should be 3.3V)
- P0 and P1 states (should be HIGH/3.3V)
- System clock frequency (if you can measure it)
- Whether INT has pull-up resistor
- `led_initialized` state

This will help identify the root cause! 🔍

