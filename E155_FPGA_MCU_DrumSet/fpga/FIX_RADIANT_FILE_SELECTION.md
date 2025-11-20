# FIX: Make Radiant Use Repository's i2c_block.v

## ✅ Good News!

Your repository's `i2c_block.v` has the **correct port names**:
- `i2c1_scl_io` ✅
- `i2c1_sda_io` ✅
- All other ports match ✅

## 🚨 Problem

Radiant is using a **different file** from Module Generator:
- **Radiant is using:** `E155_finalp/i2c_block/rtl/i2c_block.v` (wrong file)
- **We need:** `E155_FPGA_MCU_DrumSet/fpga/verilog/i2c_block.v` (correct file)

## ✅ Solution: Force Radiant to Use Repository File

### Step 1: Remove Module Generator File from Project

1. In Lattice Radiant, open **Project Navigator**
2. Find `i2c_block.v` in the **Source Files** list
3. **Right-click** on it → **Remove from Project**
   - This removes it from the project but doesn't delete the file

### Step 2: Add Repository File to Project

1. In **Project Navigator**, right-click on **Source Files**
2. Select **Add Source Files...**
3. Navigate to: `E155_FPGA_MCU_DrumSet/fpga/verilog/`
4. Select `i2c_block.v` from the repository
5. Click **OK**
6. **Verify** it appears in Source Files list

### Step 3: Verify File Path

1. In **Project Navigator**, check the file path shown for `i2c_block.v`
2. It should show: `E155_FPGA_MCU_DrumSet/fpga/verilog/i2c_block.v`
3. If it shows `E155_finalp/i2c_block/rtl/i2c_block.v`, you added the wrong file!

### Step 4: Clean and Re-synthesize

1. **Process → Clean** (removes old build artifacts)
2. **Process → Run Synthesis**

## Alternative: Replace Module Generator File

If you can't remove the Module Generator file from the project:

1. Navigate to: `E155_finalp/i2c_block/rtl/i2c_block.v`
2. **Backup** it: Rename to `i2c_block.v.backup`
3. **Copy** `E155_FPGA_MCU_DrumSet/fpga/verilog/i2c_block.v` from repository
4. **Paste** it to `E155_finalp/i2c_block/rtl/i2c_block.v` (overwrite)
5. In Radiant: **Process → Clean** then **Process → Run Synthesis**

## Verification

After fixing, the error should disappear. The ports match:
- Repository file: `i2c1_scl_io`, `i2c1_sda_io` ✅
- Our code: `.i2c1_scl_io(i2c1_scl)`, `.i2c1_sda_io(i2c1_sda)` ✅

