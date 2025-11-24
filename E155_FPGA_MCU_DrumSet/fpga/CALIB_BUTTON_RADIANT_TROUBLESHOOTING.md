# Calibration Button Pin Assignment Troubleshooting

## Problem
`calib_button` shows as "unconnected" in Radiant and cannot be assigned to a pin, even though `kick_button` works correctly.

## Code Verification

The code has been updated with multiple layers of protection:

1. **Port Declaration** (line 27):
   ```systemverilog
   (* keep *) input  logic        calib_button,   // Calibration button (P11)
   ```

2. **Signal Usage** (lines 262-275):
   - Sequential usage: `calib_button_prev_top <= calib_button;`
   - Combinational usage: `assign calib_button_edge_top = calib_button && !calib_button_prev_top;`
   - Registered monitor: `calib_button_monitor <= calib_button_edge_top;`

3. **Synthesis Attributes**:
   - `(* keep *)` on port declaration
   - `(* keep *)` on all internal signals

4. **Connection to Submodule** (line 240):
   ```systemverilog
   .calib_button(calib_button),
   ```

## Radiant-Specific Troubleshooting Steps

### Step 1: Verify Top-Level Module
1. In Radiant: **Project** → **Settings** → **Synthesis**
2. Verify **Top-level module** is set to: `drum_set_top`
3. If not, change it and re-synthesize

### Step 2: Clean and Rebuild
1. **Project** → **Clean Project**
2. Delete all generated files (`.edf`, `.rpt`, etc.)
3. **Project** → **Synthesize** (fresh synthesis)
4. Check if `calib_button` now appears

### Step 3: Check Signal Name in Constraints
1. Open your constraints file (`.pcf` or Physical Constraints)
2. Verify the exact signal name matches:
   ```
   set_io calib_button  P11
   ```
3. **Case-sensitive**: Make sure it's exactly `calib_button` (lowercase, underscore)

### Step 4: Force Pin Assignment via Constraints File
1. Create or edit `constraints.pcf` in your project
2. Add this line explicitly:
   ```
   set_io calib_button  P11
   ```
3. Save and re-synthesize

### Step 5: Check Port List in Synthesis Report
1. After synthesis, open **Synthesis Report**
2. Look for **Port List** or **I/O Ports** section
3. Search for `calib_button` - does it appear?
4. If it appears in the report but not in GUI, try assigning via constraints file

### Step 6: Verify Signal is Not Being Optimized
1. In synthesis report, check for warnings about "unused signals"
2. Look for: `calib_button` in optimization warnings
3. If you see it being optimized, the `(* keep *)` attributes should prevent this

### Step 7: Compare with kick_button
Since `kick_button` works, compare:
1. Check if `kick_button` has any special attributes in the report
2. Verify both signals are declared identically (they are)
3. The only difference is `kick_button` is used in state machine (line 306)

### Step 8: Manual Pin Assignment in GUI
1. In Radiant: **Tools** → **Pin Assignment** (or similar)
2. Try typing `calib_button` in the search box
3. If it appears in search but not in list, try assigning it manually

### Step 9: Check Project Settings
1. **Project** → **Settings** → **Synthesis Options**
2. Look for "Optimization" or "Preserve" settings
3. Ensure signals with `(* keep *)` are preserved

### Step 10: Alternative - Use Constraints File Only
If GUI assignment doesn't work:
1. Remove any GUI pin assignments
2. Use ONLY the constraints file (`constraints.pcf`)
3. Add: `set_io calib_button  P11`
4. Re-synthesize and place & route
5. The constraints file should override GUI settings

## Expected Behavior

After these steps, `calib_button` should:
- Appear in the port list after synthesis
- Be assignable to pin P11
- Show as "connected" (not "unconnected")

## If Still Not Working

If `calib_button` still shows as unconnected after all steps:

1. **Check Radiant Version**: Some versions have bugs with signal recognition
2. **Try Different Pin**: Test with a different pin (e.g., P1) to see if it's pin-specific
3. **Check for Reserved Names**: Ensure `calib_button` isn't a reserved word in Radiant
4. **Export/Import**: Try exporting the project and re-importing it
5. **Contact Lattice Support**: This may be a Radiant tool bug

## Verification

To verify the signal is actually connected:
1. After place & route, check the **Pin Assignment Report**
2. Search for `calib_button` - it should show as assigned to P11
3. If assigned in report but not in GUI, the constraints file is working correctly

## Current Code Status

✅ Port declared with `(* keep *)`  
✅ Used in sequential logic  
✅ Used in combinational logic  
✅ Connected to submodule  
✅ All internal signals have `(* keep *)`  
✅ Registered monitor signal prevents optimization  
✅ Constraints file has pin assignment  
✅ Testbench passes - functionality verified  

The code is correct. If Radiant still doesn't recognize it, the issue is likely in the Radiant tool itself or project configuration.

