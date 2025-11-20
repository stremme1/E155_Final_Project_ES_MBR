# Check Module Generator File Port Names

## Problem

Radiant is using `i2c_block.v` from Module Generator at:
`E155_finalp/i2c_block/rtl/i2c_block.v`

This file has **different port names** than what we're using in `drum_system_top.sv`.

## Solution: Check and Update drum_system_top.sv

### Step 1: Open Module Generator File

1. Navigate to: `E155_finalp/i2c_block/rtl/i2c_block.v`
2. Open it in a text editor

### Step 2: Find Port Names

Look at lines 10-25 for the module declaration:

```verilog
module i2c_block (
    port1,    // ← Check these names
    port2,    // ← Check these names
    port3,    // ← Check these names
    ...
);
```

### Step 3: Identify I2C Port Names

Find the I2C-related ports. They might be:
- `i2c1_scl_io`, `i2c1_sda_io` (what we expect)
- `i2c2_scl_io`, `i2c2_sda_io` (I2C2 ports)
- OR something completely different like `i2c_left_scl_io`, `i2c_right_scl_io`

### Step 4: Share Port Names

**Copy the first 20-30 lines of the module declaration and share them.**

Then I can update `drum_system_top.sv` to match the exact port names.

## Common Variations

If the Module Generator file was generated with only I2C Left enabled, ports might be:
- `i2c2_scl_io`, `i2c2_sda_io` (I2C Left = I2C2 in the naming)
- No `i2c1_*` ports at all

If generated with only I2C Right enabled, ports might be:
- `i2c1_scl_io`, `i2c1_sda_io` (I2C Right = I2C1 in the naming)
- No `i2c2_*` ports at all

## After Getting Port Names

Once you share the port names, I'll update `drum_system_top.sv` to match exactly.

