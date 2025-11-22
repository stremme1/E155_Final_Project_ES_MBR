# Radiant Pin Assignment Troubleshooting

## Issue: calib_button Shows as "Unconnected"

If Radiant is reporting `calib_button` as "unconnected" and you cannot assign a pin to it, try these solutions:

### Solution 1: Verify Signal Name in Constraints File

Make sure the signal name in your constraints file **exactly matches** the port name in `drum_set_top.sv`:

```pcf
# Correct - exact match
set_io calib_button  P11

# Wrong - these won't work:
# set_io calibration_button  P11
# set_io calib_btn  P11
# set_io CALIB_BUTTON  P11
```

### Solution 2: Check Port Declaration

The signal is declared in `drum_set_top.sv` as:
```systemverilog
input  logic        calib_button,   // Calibration button (P11)
```

Make sure:
- It's in the module port list (line 27)
- It's connected to `gesture_detector` (line 240)
- No typos in the signal name

### Solution 3: Force Pin Assignment in Radiant GUI

1. **Open Radiant** → Your Project
2. **Go to**: Tools → Pin Planner (or Physical Constraints)
3. **Manually add** the pin assignment:
   - Signal: `calib_button`
   - Pin: `P11`
   - Direction: Input
4. **Save** the constraints file

### Solution 4: Check Synthesis Report

1. **Run Synthesis** in Radiant
2. **Check the synthesis report** for warnings about `calib_button`
3. **Look for** "unconnected port" or "unused signal" warnings
4. If it says "unused", the signal might be getting optimized away

### Solution 5: Verify Signal is Actually Used

The signal **IS used** in the code:
- Connected to `gesture_detector.calib_button` (line 240)
- Used in debounce logic in `gesture_detector.sv`
- Used to trigger calibration

If Radiant still says it's unused, try:

1. **Add explicit use** (temporary, for debugging):
```systemverilog
// At end of drum_set_top.sv, before endmodule
logic calib_button_debug;
assign calib_button_debug = calib_button;  // Force use
```

2. **Or use it in an assign statement**:
```systemverilog
// This ensures it's never optimized away
assign led_initialized = bno1_initialized && bno2_initialized && (calib_button || !calib_button);
```

### Solution 6: Check Module Hierarchy

Make sure you're assigning pins to the **correct top-level module**:

- **Top-level module**: `drum_set_top`
- **Not**: `gesture_detector` (this is a submodule)

### Solution 7: Re-synthesize After Adding Pin

1. **Add pin assignment** to constraints file:
   ```pcf
   set_io calib_button  P11
   ```
2. **Save** constraints file
3. **Re-run synthesis**
4. **Check** if pin assignment appears in synthesis report

### Solution 8: Verify Constraints File is Loaded

1. **Check** that your constraints file (`.pcf`) is added to the project
2. **Verify** it's being used in synthesis settings
3. **Check** file path is correct

### Common Issues:

1. **Signal name mismatch**: `calib_button` vs `calibration_button`
2. **Constraints file not loaded**: File not added to project
3. **Synthesis optimization**: Signal optimized away (shouldn't happen - it's used)
4. **Wrong module**: Assigning to submodule instead of top-level

### Verification Steps:

1. ✅ Signal declared in port list: `input logic calib_button`
2. ✅ Signal connected: `.calib_button(calib_button)` in gesture_detector instantiation
3. ✅ Signal used: In gesture_detector debounce and calibration logic
4. ✅ Pin assignment in constraints: `set_io calib_button P11`
5. ✅ Constraints file loaded in Radiant project

### If Still Not Working:

1. **Check Radiant version** - Some versions have bugs with pin assignment
2. **Try manual pin assignment** via GUI instead of constraints file
3. **Check for syntax errors** in constraints file
4. **Verify pin P11 exists** on your FPGA board
5. **Try a different pin** to see if it's a pin-specific issue

### Expected Behavior:

After correct pin assignment:
- `calib_button` should appear in pin assignment report
- Synthesis should complete without "unconnected" warnings
- Pin P11 should be assigned to `calib_button`

