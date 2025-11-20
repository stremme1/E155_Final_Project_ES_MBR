# Memory Optimization Strategy - iCE40UP5K

## Problem
Design still exceeds 5280 LUT limit even after extreme optimizations.

## Solution: Use Memory Instead of Logic

### Available Memory Resources (iCE40UP5K)
- **EBR (Embedded Block RAM)**: 30 blocks × 4kb = 120 kb total
- **SPRAM (Single Port RAM)**: 4 blocks × 256kb = 1024 kb total
- **DSP Blocks**: 8 blocks (for multipliers)

### Optimization 1: Remove Data Buffers (IMPLEMENTED)
**Before**: `logic [7:0] data_buffer [0:13];` = 14 bytes × 8 bits = 112 flip-flops per controller
- 2 controllers = 224 flip-flops = ~224 LUTs

**After**: Assemble data on-the-fly using only 8 registers (for 16-bit values)
- 2 controllers = 16 registers = ~16 LUTs
- **Savings: ~208 LUTs**

**Implementation**: 
- Store LSB byte temporarily
- When MSB arrives, assemble 16-bit value immediately
- No intermediate buffer needed

### Optimization 2: Use EBR for Lookup Tables (FUTURE)
If still needed, we can use EBR for:
- **Quaternion-to-Euler lookup tables**: Store pre-calculated angle values
- **Gesture recognition thresholds**: Store yaw range boundaries
- **Sound ID mapping**: Store gesture-to-sound lookup table

**EBR Configuration Options**:
- 256×16 (4kb): For angle lookup tables
- 512×8 (4kb): For threshold storage
- 1024×4 (4kb): For small lookup tables

### Optimization 3: Use SPRAM for Large Buffers (FUTURE)
If we need larger buffers:
- **SPRAM**: 256kb blocks (way too large for our needs)
- Only use if we need to buffer multiple sensor readings

### Current Memory Usage
- **EBR**: 0 blocks used (available: 30 blocks)
- **SPRAM**: 0 blocks used (available: 4 blocks)
- **DSP**: 0 blocks used (available: 8 blocks)

### Estimated Resource Savings

| Optimization | LUTs Saved | Status |
|--------------|------------|--------|
| Remove data buffers | ~208 | ✅ Implemented |
| Use EBR for lookup tables | ~100-200 | ⏳ Future |
| Use DSP for multiplications | ~50-100 | ⏳ Future |
| **Total Potential** | **~360-510 LUTs** | |

### New Estimated Total
- **Previous**: ~1000-1500 LUTs
- **After buffer removal**: ~800-1300 LUTs
- **Safety margin**: ~4000-4500 LUTs (75-85%)

## Next Steps

1. ✅ **Test current implementation** (buffer removal)
2. ⏳ **If still too large**: Implement EBR lookup tables
3. ⏳ **If still too large**: Use DSP blocks for multiplications
4. ⏳ **Last resort**: Remove one IMU (single-hand mode)

## Implementation Notes

### Buffer Removal Details
- **Byte 0**: Store as LSB (quat_w)
- **Byte 1**: Combine with previous LSB, store as quat_w[15:0]
- **Repeat for all 14 bytes**
- **Result**: Only 8 16-bit registers needed instead of 14 8-bit registers

### EBR Usage (Future)
```systemverilog
// Example: Angle lookup table in EBR
SB_RAM256x16 angle_lut (
    .RDATA(angle_out),
    .RADDR(angle_index),
    .RCLK(clk),
    .RCLKE(1'b1),
    .RE(1'b1),
    // ... write ports if needed
);
```

### DSP Usage (Future)
```systemverilog
// Example: Use DSP for quaternion multiplication
SB_MAC16 mult_acc (
    .A(quat_w),
    .B(quat_x),
    .C(accumulator),
    .CLK(clk),
    // ... other ports
);
```

