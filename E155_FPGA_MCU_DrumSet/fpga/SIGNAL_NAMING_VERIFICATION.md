# Signal Naming Verification Report

## Summary
✅ **All signal names are consistent across all modules**

## Detailed Verification

### 1. Top-Level Module (`drum_set_top.sv`)

#### Port Declarations:
- **Line 27**: `(* keep *) input  logic        calib_button,`
- **Line 28**: `input  logic        kick_button,`

**Status**: ✅ Both declared correctly as `input logic`

**Note**: `calib_button` has `(* keep *)` attribute, `kick_button` does not. Since `kick_button` works, this suggests the attribute may not be the issue.

#### Module Instantiation (gesture_detector):
- **Line 240**: `.calib_button(calib_button),`

**Status**: ✅ Connection syntax is correct - uses named port connection

#### Top-Level Usage:
- **Line 271**: `calib_button_prev_top <= calib_button;` (sequential)
- **Line 278**: `assign calib_button_edge_top = calib_button && !calib_button_prev_top;` (combinational)

**Status**: ✅ Signal is used in both sequential and combinational logic

### 2. Gesture Detector Module (`gesture_detector.sv`)

#### Port Declaration:
- **Line 30**: `input  logic        calib_button,`

**Status**: ✅ Port name matches exactly: `calib_button`

#### Internal Usage:
- **Line 86**: `calib_button_sync1 <= calib_button;`
- **Line 87**: `calib_button_sync2 <= calib_button_sync1;`
- **Line 116**: `if (calib_button_debounced && !calib_button_prev && data_valid_1 && data_valid_2)`

**Status**: ✅ Signal is actively used in the module

### 3. Testbenches

#### `tb_calibration.sv`:
- **Line 17**: `logic calib_button;`
- **Line 64**: `.calib_button(calib_button),`

**Status**: ✅ Signal name matches

#### `tb_system_with_sim_imu.sv`:
- **Line 23**: `logic calib_button, kick_button;`
- **Line 71**: `.calib_button(calib_button),`

**Status**: ✅ Signal name matches

### 4. Constraints File

#### `constraints_example.txt`:
- **Line 23**: `set_io calib_button  P11`

**Status**: ✅ Signal name matches exactly (case-sensitive: lowercase with underscore)

## Comparison: calib_button vs kick_button

| Aspect | calib_button | kick_button | Status |
|--------|--------------|-------------|--------|
| Port declaration | `input logic calib_button` | `input logic kick_button` | ✅ Both identical format |
| `(* keep *)` attribute | ✅ Has attribute | ❌ No attribute | ⚠️ Different |
| Connection to submodule | ✅ `.calib_button(calib_button)` | N/A (not connected to submodule) | ✅ Correct |
| Sequential usage | ✅ `calib_button_prev_top <= calib_button` | ✅ `kick_button_prev <= kick_button` | ✅ Both used |
| Combinational usage | ✅ `assign calib_button_edge_top = ...` | ✅ `assign kick_button_edge = ...` | ✅ Both used |
| Used in state machine | ❌ Not used in state machine | ✅ Used in state machine (line 311) | ⚠️ Different |
| Constraints file | ✅ `set_io calib_button P11` | ✅ `set_io kick_button P2` | ✅ Both listed |

## Key Differences Found

1. **`(* keep *)` attribute**: 
   - `calib_button` has it, `kick_button` doesn't
   - Since `kick_button` works without it, this may not be necessary

2. **State machine usage**:
   - `kick_button_edge` is used in state machine (line 311): `else if (kick_button_edge && !mcu_busy)`
   - `calib_button_edge_top` is NOT used in state machine
   - This is the **most significant difference**

## Recommendations

### Option 1: Remove `(* keep *)` attribute (match kick_button exactly)
Since `kick_button` works without `(* keep *)`, try removing it from `calib_button`:

```systemverilog
input  logic        calib_button,   // Remove (* keep *)
```

### Option 2: Use calib_button_edge_top in state machine (match kick_button pattern)
Add usage of `calib_button_edge_top` similar to how `kick_button_edge` is used:

```systemverilog
// In the MCU transmission state machine (around line 311)
else if (calib_button_edge_top && !mcu_busy) begin
    // Could send a calibration status code, or just acknowledge
    // This ensures the signal is used in state machine like kick_button
end
```

### Option 3: Add `(* keep *)` to kick_button (for consistency)
If the attribute helps, add it to `kick_button` too for consistency.

## Verification Checklist

- ✅ Port name is `calib_button` (not `calibration_button` or `calib_btn`)
- ✅ Case-sensitive: all lowercase with underscore
- ✅ Port declaration syntax matches `kick_button`
- ✅ Connection syntax matches pattern: `.calib_button(calib_button)`
- ✅ Signal is used in sequential logic
- ✅ Signal is used in combinational logic
- ✅ Signal is connected to submodule
- ✅ Constraints file has correct name: `set_io calib_button P11`
- ⚠️ Signal is NOT used in state machine (unlike `kick_button`)

## Conclusion

**Signal naming is 100% correct and consistent across all modules.**

The issue is likely:
1. **Radiant tool behavior** - may require state machine usage like `kick_button`
2. **Project configuration** - may need clean rebuild
3. **Synthesis optimization** - despite `(* keep *)`, may still optimize if not used in state machine

**Next step**: Try using `calib_button_edge_top` in the state machine to match the `kick_button` pattern exactly.

