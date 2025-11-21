# Logic Comparison: C Code vs SystemVerilog

## Comparison Results

### ✅ **Right Hand Logic - MATCHES**

| Zone | C Code | SystemVerilog | Status |
|------|--------|---------------|--------|
| Zone 1 | `yaw1 >= 20 && yaw1 <= 120` → Snare (0) | `yaw1_norm >= 20 && yaw1_norm <= 120` → Snare (0) | ✅ Match |
| Zone 2 | `yaw1 >= 340 \|\| yaw1 <= 20` → High tom (3) or Crash (5) if `pitch1 > 50` | `yaw1_norm >= 340 \|\| yaw1_norm <= 20` → High tom (3) or Crash (5) if `pitch1 > 50` | ✅ Match |
| Zone 3 | `yaw1 >= 305 && yaw1 <= 340` → Mid tom (4) or Ride (6) if `pitch1 > 50` | `yaw1_norm >= 305 && yaw1_norm <= 340` → Mid tom (4) or Ride (6) if `pitch1 > 50` | ✅ Match |
| Zone 4 | `yaw1 >= 200 && yaw1 <= 305` → Floor tom (7) or Ride (6) if `pitch1 > 30` | `yaw1_norm >= 200 && yaw1_norm <= 305` → Floor tom (7) or Ride (6) if `pitch1 > 30` | ✅ Match |

### ⚠️ **Left Hand Zone 1 - DISCREPANCY FOUND**

**C Code (line 151):**
```c
if (yaw2 >= 350 || yaw2 <= 100) {
```

**SystemVerilog (line 167):**
```systemverilog
if ((yaw2_norm >= 16'd350) || (yaw2_norm <= 16'd100)) begin
```

**Comment in C Code (line 150):**
```c
// if yaw in the range of 350-60 then play snare drum or hi-hat
```

**Issue:** The comment says "350-60" but the code uses `<= 100`. The SystemVerilog uses `<= 100` to match the actual C code implementation.

**Resolution:** The SystemVerilog correctly matches the C code implementation (not the comment). The comment appears to be incorrect.

### ✅ **Left Hand Zones 2-4 - MATCHES**

| Zone | C Code | SystemVerilog | Status |
|------|--------|---------------|--------|
| Zone 2 | `yaw2 >= 325 && yaw2 <= 350` → High tom (3) or Crash (5) if `pitch2 > 50` | `yaw2_norm >= 325 && yaw2_norm <= 350` → High tom (3) or Crash (5) if `pitch2 > 50` | ✅ Match |
| Zone 3 | `yaw2 >= 300 && yaw2 <= 325` → Mid tom (4) or Ride (6) if `pitch2 > 50` | `yaw2_norm >= 300 && yaw2_norm <= 325` → Mid tom (4) or Ride (6) if `pitch2 > 50` | ✅ Match |
| Zone 4 | `yaw2 >= 200 && yaw2 <= 300` → Floor tom (7) or Ride (6) if `pitch2 > 30` | `yaw2_norm >= 200 && yaw2_norm <= 300` → Floor tom (7) or Ride (6) if `pitch2 > 30` | ✅ Match |

### ✅ **Thresholds - MATCHES**

| Threshold | C Code | SystemVerilog | Status |
|-----------|--------|---------------|--------|
| Gyro Y | `gyro1_y < -2500` | `gyro1_y < GYRO_Y_THRESHOLD` (-2500) | ✅ Match |
| Gyro Z (Hi-hat) | `gyro2_z > -2000` | `gyro2_z > GYRO_Z_THRESHOLD` (-2000) | ✅ Match |
| Pitch Crash | `pitch1 > 50` | `pitch1 > PITCH_CRASH` (50) | ✅ Match |
| Pitch Ride | `pitch1 > 30` | `pitch1 > PITCH_RIDE` (30) | ✅ Match |

### ✅ **Sound Codes - MATCHES**

| Code | Sound | C Code | SystemVerilog | Status |
|------|-------|--------|---------------|--------|
| 0 | Snare | `"0"` | `4'd0` | ✅ Match |
| 1 | Hi-hat | `"1"` | `4'd1` | ✅ Match |
| 3 | High tom | `"3"` | `4'd3` | ✅ Match |
| 4 | Mid tom | `"4"` | `4'd4` | ✅ Match |
| 5 | Crash | `"5"` | `4'd5` | ✅ Match |
| 6 | Ride | `"6"` | `4'd6` | ✅ Match |
| 7 | Floor tom | `"7"` | `4'd7` | ✅ Match |

### ✅ **Yaw Normalization - MATCHES**

**C Code:**
```c
float normalizeYaw(float yaw) {
    yaw = fmod(yaw, 360.0);
    if (yaw < 0) {
        yaw += 360.0;
    }
    return yaw;
}
```

**SystemVerilog:**
```systemverilog
function logic signed [15:0] normalize_yaw(logic signed [15:0] yaw_in);
    logic signed [15:0] yaw_temp;
    logic signed [15:0] yaw_abs;
    if (yaw_in < 0) begin
        yaw_abs = -yaw_in;
        yaw_temp = 16'd360 - (yaw_abs % 16'd360);
        if (yaw_temp == 16'd360) yaw_temp = 16'd0;
    end else begin
        yaw_temp = yaw_in % 16'd360;
    end
    return yaw_temp;
endfunction
```

**Status:** ✅ Logic matches (handles negative values and wraps to 0-360 range)

### ✅ **Debouncing Logic - MATCHES (Conceptually)**

**C Code:**
- Uses `printedForGyro1y` flag
- Sets to `true` when `gyro1_y < -2500 && !printedForGyro1y`
- Resets to `false` when `gyro1_y >= -2500 && printedForGyro1y`
- Prints immediately when flag is set

**SystemVerilog:**
- Uses `printed_gyro1_y` flag
- Sets to `1` when `gyro1_y < GYRO_Y_THRESHOLD && !printed_gyro1_y`
- Resets to `0` when `gyro1_y >= GYRO_Y_THRESHOLD && printed_gyro1_y`
- Triggers `sound_valid` on rising edge of flag

**Status:** ✅ Logic matches (SystemVerilog uses rising edge detection which is equivalent)

### ✅ **Calibration - MATCHES (Conceptually)**

**C Code:**
- Captures yaw values when button2 is pressed
- Stores in `yawOffset1` and `yawOffset2`
- Applies: `yaw1 = normalizeYaw(yaw1 - yawOffset1)`

**SystemVerilog:**
- Captures yaw values when `calib_button` is pressed (rising edge)
- Stores in `yaw_offset1_reg` and `yaw_offset2_reg`
- Applies: `yaw1_norm <= normalize_yaw(yaw1 - yaw_offset1_reg)`

**Status:** ✅ Logic matches

## Summary

### ✅ **All Logic Matches Except:**

1. **Left Hand Zone 1 Comment Discrepancy:**
   - C code comment says "350-60" but code uses `<= 100`
   - SystemVerilog correctly matches the C code implementation (`<= 100`)
   - **Recommendation:** The C code comment should be updated to say "350-100" to match the implementation

### ✅ **Verified Matches:**

- ✅ All zone boundaries
- ✅ All thresholds
- ✅ All sound codes
- ✅ Yaw normalization
- ✅ Debouncing logic
- ✅ Calibration logic
- ✅ Pitch-based cymbal detection
- ✅ Hi-hat detection (pitch + gyro_z)

## Conclusion

**The SystemVerilog implementation correctly matches the C code logic.** The only discrepancy is a comment in the C code that doesn't match the actual implementation. The SystemVerilog follows the actual C code behavior, not the comment.


