# Radiant Pin Assignment Guide

## How to Assign Pins in Lattice Radiant

### Method 1: Using Constraints File (.pcf)

1. **Create or edit** `constraints.pcf` in your Radiant project
2. **Add pin assignments** using this syntax:
   ```
   set_io <signal_name> <pin_name>
   ```

### Method 2: Using Radiant GUI

1. **Open Radiant** → Your Project
2. **Go to**: File → New → Constraint File → Physical Constraints
3. **Or**: Right-click project → Add File → Constraint File
4. **In the constraints editor**, add pin assignments

---

## Pin Mapping for Your Board

Based on your available pins: `BT, P0, P1, Reset, DI, CS, VIN, 3BO, Ground, SCL, SDA, INT`

### Required Signals from `drum_set_top.sv`:

```
Inputs:
- clk (system clock)
- rst_n (reset)
- miso1, miso2 (from BNO085 sensors)
- calib_button (calibration button)
- kick_button (optional)

Outputs:
- sclk1, sclk2 (SPI clocks to BNO085)
- mosi1, mosi2 (SPI MOSI to BNO085)
- cs_n1, cs_n2 (chip selects to BNO085)
- mcu_sclk, mcu_mosi, mcu_cs_n (SPI to MCU)
- led_initialized, led_error (status LEDs)
```

---

## Suggested Pin Assignment for Your Board

Based on your available pins: `BT, P0, P1, Reset, DI, CS, VIN, 3BO, Ground, SCL, SDA, INT`

**Note**: VIN and Ground are power pins (not GPIO), so you have ~10 GPIO pins available.

### System Signals
```
# Note: Clock is generated internally by HSOSC - no clock pin needed
set_io rst_n   P43             # Reset button (active LOW - goes LOW to reset)
```

### BNO085 Sensor 1 (Right Hand) - 4 pins
```
set_io sclk1   P20             # SPI clock to Sensor 1
set_io mosi1   P13             # SPI MOSI to Sensor 1
set_io miso1   P12             # SPI MISO from Sensor 1
set_io cs_n1   P18             # Chip select to Sensor 1
```

### BNO085 Sensor 2 (Left Hand) - 4 pins
```
set_io sclk2   P4              # SPI clock to Sensor 2
set_io mosi2   P47             # SPI MOSI to Sensor 2
set_io miso2   P6              # SPI MISO from Sensor 2
set_io cs_n2   P48             # Chip select to Sensor 2
```

### User Interface - 2 pins
```
set_io calib_button  P11       # Calibration button (left button)
set_io kick_button    P2        # Kick button (right button)
```

### MCU SPI Communication - 3 pins
```
set_io mcu_sclk      P21       # SPI clock to MCU
set_io mcu_mosi      P10       # SPI MOSI to MCU
set_io mcu_cs_n      P19       # Chip select to MCU (needs 10kΩ pull-up)
```

### Status LEDs - 2 pins
```
set_io led_initialized P28  # LED when initialized (HIGH when both sensors ready)
set_io led_error       P38  # LED for errors (HIGH when sensor error detected)
```

### ⚠️ PIN SHORTAGE WARNING
You have ~10 GPIO pins but need ~14 pins minimum:
- System: 2 pins (clk, rst_n)
- Sensor 1: 4 pins
- Sensor 2: 4 pins  
- Calibration: 1 pin
- MCU SPI: 3 pins
- **Total: 14 pins needed**

**Solutions:**
1. Check your board documentation for additional GPIO pins (P2, P3, P4, etc.)
2. Verify if SCL/SDA/INT can be used as GPIO (not just I2C)
3. Consider using a board with more GPIO pins
4. Temporarily skip optional features (LEDs, kick button)

---

## Complete Example Constraints File

Create `constraints.pcf`:

```pcf
# System Reset
# Note: Clock is generated internally by HSOSC - no clock pin needed
set_io rst_n   P43                 # Reset button (active LOW - goes LOW to reset)

# BNO085 Sensor 1 (Right Hand)
set_io sclk1   P20                 # SPI clock
set_io mosi1   P13                  # SPI MOSI
set_io miso1   P12                  # SPI MISO
set_io cs_n1   P18                  # Chip select

# BNO085 Sensor 2 (Left Hand)
set_io sclk2   P4                   # SPI clock
set_io mosi2   P47                  # SPI MOSI
set_io miso2   P6                   # SPI MISO
set_io cs_n2   P48                  # Chip select

# User Interface
set_io calib_button  P11          # Calibration button (left button)
set_io kick_button    P2          # Kick button (right button)

# MCU SPI Communication
set_io mcu_sclk      P21          # SPI clock to MCU
set_io mcu_mosi      P10          # SPI MOSI to MCU
set_io mcu_cs_n      P19          # Chip select to MCU (needs 10kΩ pull-up)

# Status LEDs
set_io led_initialized P28          # LED when initialized
set_io led_error       P38          # LED for errors
```

---

## Important Notes

### 1. Pin Availability
You listed these pins: `BT, P0, P1, Reset, DI, CS, VIN, 3BO, Ground, SCL, SDA, INT`

**You may not have enough pins** for all signals. Priority:

**Critical (Must Have):**
- `clk`, `rst_n` - System signals
- `sclk1`, `mosi1`, `miso1`, `cs_n1` - Sensor 1 (4 pins)
- `sclk2`, `mosi2`, `miso2`, `cs_n2` - Sensor 2 (4 pins)
- `calib_button` - Calibration button (P11)
- `kick_button` - Kick button (P2)
- `mcu_sclk`, `mcu_mosi`, `mcu_cs_n` - MCU SPI (3 pins)

**Total: ~15 pins needed**

### 2. Pin Reuse
- `SCL`, `SDA`, `INT` are typically I2C/interrupt pins
- If your board supports it, you can use them as GPIO for SPI
- Check your board documentation to confirm

### 3. Missing Pins
If you don't have enough pins, you may need to:
- Use a different FPGA board with more GPIO
- Use a pin expansion board
- Check if your board has more pins not listed

### 4. VIN and Ground
- `VIN` - Power input (not a GPIO pin)
- `Ground` - Ground connection (not a GPIO pin)
- These are for power, not signal routing

---

## Step-by-Step in Radiant

### 1. Create Constraints File
1. In Radiant: **File** → **New** → **Constraint File** → **Physical Constraints**
2. Name it: `constraints.pcf`
3. Click **OK**

### 2. Add Pin Assignments
1. Open the constraints file
2. Add lines like: `set_io signal_name pin_name`
3. Save the file

### 3. Verify Pin Assignments
1. **Run Synthesis**
2. Check **Pin Assignment Report** (should show all signals assigned)
3. If warnings appear, fix pin assignments

### 4. Check Pin Types
Make sure pin types match:
- **Input signals** → Input-capable pins
- **Output signals** → Output-capable pins
- **Clock signals** → Clock-capable pins (for `clk`)

---

## Alternative: Check Your Board Documentation

Your board might have:
- More GPIO pins (P2, P3, etc.)
- Dedicated SPI pins
- Pin expansion headers

**Check your FPGA board's pinout diagram** for all available pins!

---

## Quick Reference: Signal Types

| Signal | Type | Direction | Notes |
|--------|------|-----------|-------|
| `clk` | Internal | - | Generated by HSOSC (no pin needed) |
| `rst_n` | Input | → FPGA | Reset (P43, active LOW - goes LOW to reset) |
| `sclk1`, `sclk2` | Output | FPGA → | SPI clocks |
| `mosi1`, `mosi2` | Output | FPGA → | SPI MOSI |
| `miso1`, `miso2` | Input | → FPGA | SPI MISO |
| `cs_n1`, `cs_n2` | Output | FPGA → | Chip selects (need pull-ups) |
| `calib_button` | Input | → FPGA | Button (needs pull-up, P11) |
| `kick_button` | Input | → FPGA | Button (needs pull-up, P2) |
| `mcu_sclk` | Output | FPGA → | MCU SPI clock (P21) |
| `mcu_mosi` | Output | FPGA → | MCU SPI MOSI (P10) |
| `mcu_cs_n` | Output | FPGA → | MCU chip select (P19, needs pull-up) |
| `led_initialized` | Output | FPGA → | Status LED (P28) |
| `led_error` | Output | FPGA → | Error LED (P38) |

---

## Need More Pins?

If you're short on pins, consider:
1. **Check board documentation** for additional GPIO pins
2. **Use pin expansion** (if available)
3. **Prioritize signals**:
   - Must have: Sensors, MCU SPI, Calibration button
   - Optional: LEDs, Kick button

Good luck with your pin assignment! 🎯

