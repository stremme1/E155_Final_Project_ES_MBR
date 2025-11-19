# EXACT Resource Limits - iCE40UP5K

## HARD LIMITS (From Datasheet)

**iCE40UP5K**:
- **Logic Cells (LUTs)**: **5280** ⚠️ **ABSOLUTE MAXIMUM**
- **EBR Blocks**: 30 (120 kb)
- **SPRAM Blocks**: 4 (1024 kb)
- **DSP Blocks**: 8
- **User I/O**: 39 GPIO pins

## Critical Cuts Made

### 1. I2C Controller - DRASTICALLY REDUCED
**Before**: 25-state FSM = ~600-800 LUTs per controller
**After**: 8-state FSM with counter-based reading = ~200-300 LUTs per controller
**Savings**: **~800-1000 LUTs** (for both controllers)

**Changes**:
- Removed soft reset initialization (saves 3 states)
- Combined all read states into counter-based loop (saves 14 states)
- Simplified delay handling
- Removed individual state for each byte read

### 2. System Bus Master - SIMPLIFIED
**Before**: 6-state FSM = ~200-300 LUTs per master
**After**: 4-state FSM = ~100-150 LUTs per master
**Savings**: **~200-300 LUTs** (for both masters)

**Changes**:
- Combined write/read address states
- Combined write/read data states
- Simplified protocol handling

### 3. Quaternion Math - ALREADY OPTIMIZED
- 4-stage pipeline
- 16-bit arithmetic only
- No roll calculation
- **Current**: ~500 LUTs

### 4. Gesture Recognition - ALREADY MINIMAL
- Consolidated sequential logic
- Simplified comparisons
- **Current**: ~150 LUTs

## New Resource Estimate

### After Critical Cuts:
- I2C Controllers (2x): ~400-600 LUTs ⬇️ **-800 LUTs**
- System Bus Masters (2x): ~200-300 LUTs ⬇️ **-200 LUTs**
- Quaternion-to-Euler (shared): ~500 LUTs
- Gesture Recognition: ~150 LUTs
- Top-level logic: ~200 LUTs
- **Total: ~1450-1750 LUTs** ⬇️ **-1000 LUTs from previous**

### With Synthesis Overhead (20-30%):
- **Realistic Total: ~1800-2300 LUTs**
- **Margin: ~3000 LUTs (57% margin)**

## Summary

**Exact Limit**: **5280 LUTs** (hard maximum)
**Estimated Usage**: **~1800-2300 LUTs** (with overhead)
**Safety Margin**: **~3000 LUTs (57%)**

This should now fit comfortably within the 5280 LUT limit.

