# URGENT: I2C Port Name Mismatch - Final Fix

## 🚨 Problem

Radiant is using `i2c_block.v` from `E155_finalp/i2c_block/rtl/i2c_block.v` which has **different port names** than expected.

**Error:** `cannot find port i2c1_sda_io on this module`

## ✅ SOLUTION: Check Actual File Port Names

**You MUST check the actual Module Generator file to see what ports it has.**

### Step 1: Open the Module Generator File

1. Navigate to: `E155_finalp/i2c_block/rtl/i2c_block.v`
2. Open it in a text editor

### Step 2: Find the Module Declaration

Look for lines around line 10-25 that look like:

```verilog
module i2c_block (
    port1,
    port2,
    port3,
    ...
);
```

### Step 3: Identify I2C Port Names

Find the I2C-related ports. They might be named:
- `i2c1_scl_io`, `i2c1_sda_io` (what we expect)
- `i2c2_scl_io`, `i2c2_sda_io` (I2C2 ports)
- OR something completely different!

### Step 4: Tell Me the Port Names

**Copy the module declaration (first 20-30 lines) and share it.**

Then I can update `drum_system_top.sv` with the correct port names.

## Alternative: Replace the File

If you can't check the file, **replace it** with our repository's `i2c_block.v`:

1. **Backup** `E155_finalp/i2c_block/rtl/i2c_block.v` → `i2c_block.v.backup`
2. **Copy** `E155_FPGA_MCU_DrumSet/fpga/verilog/i2c_block.v` from this repository
3. **Paste** it to `E155_finalp/i2c_block/rtl/i2c_block.v` (overwrite)
4. **In Radiant**: Remove and re-add the file, then clean and re-synthesize

## Why This Happens

Module Generator creates files based on its configuration. If:
- Only I2C Left is enabled → ports might be different
- Only I2C Right is enabled → ports might be different  
- Both enabled but different settings → ports might be different

Our repository's `i2c_block.v` has both I2Cs enabled with standard port names, so replacing the Module Generator file should work.

