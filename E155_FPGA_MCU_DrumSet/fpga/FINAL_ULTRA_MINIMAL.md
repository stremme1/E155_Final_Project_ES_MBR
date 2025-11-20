# FINAL Ultra-Minimal Design - Gyro-Only Version

## CRITICAL CHANGES - Maximum Aggression

### 1. **REMOVED QUATERNION-TO-EULER CONVERSION ENTIRELY** ⚠️
**Savings: ~500-700 LUTs**

**What Changed:**
- No quaternion reading
- No Euler angle calculations
- No DSP blocks needed
- No multiplications
- **Uses only gyroscope data**

**Impact:**
- Gesture recognition based solely on gyro triggers
- Simpler but less accurate
- Still functional for basic drumming

### 2. **INLINED SYSTEM BUS MASTER**
**Savings: ~50-100 LUTs**

**What Changed:**
- Removed separate `system_bus_master` module
- Inlined 2-state FSM directly into I2C controller
- Eliminates module instantiation overhead

### 3. **GYRO-ONLY I2C CONTROLLER**
**Savings: ~100-150 LUTs**

**What Changed:**
- Reads only 3 bytes (gyro X, Y, Z) instead of 14 bytes
- Removed quaternion data paths
- Simplified state machine (4 states instead of 5)
- Smaller read counter (2 bits instead of 4)

### 4. **ULTRA-SIMPLIFIED GESTURE RECOGNITION**
**Savings: ~100-200 LUTs**

**What Changed:**
- Removed all yaw normalization
- Removed all pitch comparisons
- Removed all yaw range checks
- **Only uses gyro Y trigger + gyro Z value**
- 2 sounds: HIHAT (if gyro_z > threshold) or SNARE (otherwise)
- Plus button for KICK

## New Resource Estimate

| Component | LUTs |
|-----------|------|
| I2C Controller (gyro-only, inlined) | ~100-150 |
| Gesture Recognition (gyro-only) | ~50-100 |
| Top Module (minimal) | ~50-100 |
| Button Debounce | ~20-30 |
| **TOTAL** | **~220-380 LUTs** |

### With Synthesis Overhead (20-30%):
- **Realistic Total: ~270-500 LUTs**
- **Margin: ~4800-5000 LUTs (90-95%)**

## Functionality

### Available Sounds:
1. **KICK** - Button press
2. **HIHAT** - Gyro trigger + gyro_z > threshold
3. **SNARE** - Gyro trigger + gyro_z <= threshold

### Removed:
- All yaw-based sound selection
- All pitch-based sound selection
- All complex gesture zones
- Quaternion orientation tracking

## Trade-offs

### ✅ Benefits:
- **Tiny resource usage** (~270-500 LUTs)
- **Will definitely fit** (90-95% margin)
- **Simple and fast**
- **No DSP blocks needed**

### ⚠️ Limitations:
- **Very basic gesture recognition**
- **Only 3 sounds** (KICK, HIHAT, SNARE)
- **No orientation-based sounds**
- **Less accurate than full version**

## Testing Required

1. ⚠️ **Update test benches** - completely different architecture
2. ✅ Verify gyro-only reading works
3. ✅ Verify 3-sound selection works
4. ✅ Verify button still works

## Next Steps

1. **Synthesize** - should definitely fit now
2. **Update test benches** for gyro-only version
3. **If still too large** (extremely unlikely):
   - Remove button debounce
   - Remove LED outputs
   - Use even simpler gyro trigger

## Summary

This is the **absolute minimum** design. It should fit with **massive margin** (~90-95%). If this doesn't fit, there may be an issue with:
- Synthesis tool settings
- IP block overhead
- Routing constraints
- Device selection

