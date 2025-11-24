# CRITICAL BNO085 Wiring Fixes

## Issues Found from Adafruit Documentation

According to the Adafruit BNO085 documentation, we are missing **CRITICAL** connections:

### 1. INT Pin - REQUIRED for Stable SPI Operation

**Documentation says:**
> "INT - Interrupt- Active Low. Indicates that the BNO085 needs the host's attention. **Required for stable SPI operation**"

**Current Status:** ❌ INT pins are unconnected (marked as "not used in polling mode")

**Fix Required:** 
- Connect INT pins to FPGA inputs
- Add INT signals to top-level module
- Monitor INT pins (even if polling, they're required for stable operation)

### 2. P0 and P1 Pins - MUST be HIGH for SPI Mode

**Documentation shows mode selection table:**
```
PS1  PS0  Mode
Low  Low  I2C
Low  High UART-RVC
High Low  UART
High High SPI  ← WE NEED THIS!
```

**Current Status:** ❌ P0 and P1 pins are not mentioned in wiring guide

**Fix Required:**
- **Both P0 and P1 must be connected to 3.3V (HIGH) for SPI mode**
- This is a hardware wiring requirement, not a code change

### 3. RST Pin - Already Correct

**Current Status:** ✅ RST is tied to 3.3V (kept HIGH) - this is correct

## Required Changes

### Hardware Wiring Changes:

**For BNO085 Sensor 1:**
```
BNO085-1 Pin    →    Connection
─────────────────────────────────
INT             →    FPGA P9 (REQUIRED for stable SPI)
P0              →    3.3V (REQUIRED for SPI mode)
P1              →    3.3V (REQUIRED for SPI mode)
RST             →    3.3V (Already correct)
```

**For BNO085 Sensor 2:**
```
BNO085-2 Pin    →    Connection
─────────────────────────────────
INT             →    FPGA P3 (REQUIRED for stable SPI)
P0              →    3.3V (REQUIRED for SPI mode)
P1              →    3.3V (REQUIRED for SPI mode)
RST             →    3.3V (Already correct)
```

### Code Changes Required:

1. **INT pins added to top-level module:**
   ```systemverilog
   input  logic        int1,          // Interrupt from Sensor 1 (P9, REQUIRED for SPI)
   input  logic        int2,          // Interrupt from Sensor 2 (P3, REQUIRED for SPI)
   ```

2. **INT pins are synchronized and monitored** in top-level module to prevent optimization

## Why Sensors Aren't Initializing

The sensors likely aren't initializing because:
1. **P0 and P1 aren't set HIGH** → Sensor is in wrong mode (probably I2C instead of SPI)
2. **INT pins aren't connected** → SPI communication is unstable
3. **Initialization counter was wrong** → Fixed in previous commit (300,000 cycles for 3MHz)

## Immediate Action Items

1. **Hardware:** Connect P0 and P1 to 3.3V on both sensors (CRITICAL!)
2. **Hardware:** Connect INT pins to FPGA:
   - Sensor 1 INT → FPGA P9
   - Sensor 2 INT → FPGA P3
3. **Code:** ✅ INT signals added to top-level module
4. **Code:** ✅ INT signals synchronized and monitored

## Priority

**HIGHEST PRIORITY:** Connect P0 and P1 to 3.3V - without this, sensors won't be in SPI mode!

**HIGH PRIORITY:** Connect INT pins - required for stable SPI operation

