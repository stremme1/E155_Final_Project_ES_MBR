# Calibration Button Verification

## ✅ CONFIRMED: calib_button IS Properly Connected

### Port Declaration
- **File**: `drum_set_top.sv`
- **Line 23**: `input logic calib_button,   // Calibration button`
- **Type**: ✅ INPUT (correctly declared)

### Connection
- **Line 204**: `.calib_button(calib_button),`
- **Connected To**: `gesture_detector` module
- **Status**: ✅ CONNECTED

### Usage in Logic
- **File**: `gesture_detector.sv`
- **Used for**: 
  - Button debouncing (50ms debounce period)
  - Yaw offset capture during calibration
  - Calibration active status
- **Status**: ✅ ACTIVELY USED

## Why Synthesis Might Show "Unconnected"

If your synthesis tool shows `calib_button` as "unconnected", it's likely because:

1. **Pin Not Assigned**: The signal isn't assigned to a physical pin in your constraints file
   - **Solution**: Add `set_io calib_button <pin_number>` to your constraints file

2. **Signal Name Mismatch**: The pin name in constraints doesn't match the signal name
   - **Solution**: Ensure exact match: `calib_button` (not `calibration_button` or `calib_btn`)

3. **Synthesis Tool Warning**: Some tools warn about inputs that aren't assigned to pins
   - **This is normal** - just assign it to a pin

## Required Pin Assignment

Add this to your constraints file (`.pcf`, `.xdc`, or `.qsf`):

```
set_io calib_button 12    # Replace 12 with your actual pin number
```

## Hardware Connection

```
Calibration Button:
┌─────────────┐
│   Button    │
└──────┬──────┘
       │
       ├──→ 10kΩ resistor → 3.3V (pull-up)
       │
       └──→ GPIO Pin (calib_button) → FPGA
            │
            └──→ GND (when button pressed)
```

## Summary

✅ **calib_button is:**
- Properly declared as `input logic`
- Connected to `gesture_detector` module
- Actively used in the logic (debouncing + calibration)
- **REQUIRED** for calibration functionality

⚠️ **If showing as "unconnected":**
- Assign it to a physical pin in your constraints file
- Connect hardware button with 10kΩ pull-up resistor
- Verify pin number matches your FPGA board

The signal is correctly implemented - just needs to be assigned to a physical pin!
