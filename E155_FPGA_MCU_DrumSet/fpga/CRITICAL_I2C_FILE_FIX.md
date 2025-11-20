# CRITICAL FIX: I2C Block File Mismatch

## Problem

Radiant is using a different `i2c_block.v` file than the one in this repository, causing port name mismatches.

**Error:** `cannot find port i2c1_sda_io on this module`

**Radiant is finding:** `E155_finalp/i2c_block/rtl/i2c_block.v`  
**We need:** The `i2c_block.v` from this repository

## Solution: Replace Module Generator File

### Step 1: Locate Module Generator File

1. In Lattice Radiant, find the file path:
   - Look in **Project Navigator** → **Source Files**
   - Find `i2c_block.v` or check the error message path
   - Path is likely: `E155_finalp/i2c_block/rtl/i2c_block.v`

### Step 2: Replace with Repository File

1. **Copy** `i2c_block.v` from this repository:
   ```
   E155_FPGA_MCU_DrumSet/fpga/verilog/i2c_block.v
   ```

2. **Replace** the Module Generator file:
   - Navigate to: `E155_finalp/i2c_block/rtl/`
   - **Backup** the existing `i2c_block.v` (rename to `i2c_block.v.backup`)
   - **Copy** our `i2c_block.v` to that location
   - **Overwrite** the existing file

### Step 3: Verify in Radiant

1. In Radiant, **remove** `i2c_block.v` from Source Files (if it's there)
2. **Re-add** the file from the correct location
3. **Clean** the project: **Process → Clean**
4. **Re-run synthesis**

## Alternative: Add Repository File to Project

If you can't replace the Module Generator file:

1. In Radiant, **remove** the Module Generator `i2c_block.v` from Source Files
2. **Add** `i2c_block.v` from this repository:
   - Right-click **Source Files** → **Add Source Files...**
   - Browse to: `E155_FPGA_MCU_DrumSet/fpga/verilog/i2c_block.v`
   - Add it to the project
3. **Clean** and **re-synthesize**

## Why This Happens

Module Generator creates files in its own directory structure. If you regenerate the IP or the file gets out of sync, Radiant may use an older or differently configured version.

## Verification

After replacing the file, check that:
- ✅ Port names match: `i2c1_scl_io`, `i2c1_sda_io`, `i2c2_scl_io`, `i2c2_sda_io`
- ✅ Module name is `i2c_block`
- ✅ Both I2C controllers are enabled: `.i2c_left_enable(1)`, `.i2c_right_enable(1)`

