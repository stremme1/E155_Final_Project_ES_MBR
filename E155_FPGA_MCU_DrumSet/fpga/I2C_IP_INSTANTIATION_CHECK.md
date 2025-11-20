# I2C IP Instantiation - Critical Checklist

## ✅ Verification Steps

### 1. I2C IP File Must Be in Project

**CRITICAL**: The generated I2C IP file (`i2c_block.v` or similar) **MUST** be added to your Lattice Radiant project as a source file.

**To add it:**
1. In Lattice Radiant, right-click on your project
2. Select **Add Source Files...**
3. Browse to the generated I2C IP file (usually in your project directory or IP output folder)
4. Select the `.v` or `.sv` file
5. Make sure it appears in your **Source Files** list

**If the file is not in the project, synthesis will fail with "module not found" errors!**

### 2. Verify Module Name Matches

The generated IP module name must match what you're instantiating in `drum_system_top.sv`.

**Check the generated file:**
```verilog
module i2c_block (  // <-- This name must match
```

**In your top module:**
```verilog
i2c_block i2c1_ip (  // <-- Must match exactly
```

### 3. Verify Port Names Match

**Generated IP ports (from ErrorCodes.txt):**
```verilog
module i2c_block (
    i2c2_scl_io,      // I2C2 Clock (unused)
    i2c2_sda_io,      // I2C2 Data (unused)
    i2c1_scl_io,      // I2C1 Clock ✅
    i2c1_sda_io,      // I2C1 Data ✅
    rst_i,            // Reset (active-high) ✅
    ipload_i,         // IP Load ✅
    ipdone_o,         // IP Done ✅
    sb_clk_i,         // System Bus Clock ✅
    sb_wr_i,          // System Bus Write ✅
    sb_stb_i,         // System Bus Strobe ✅
    sb_adr_i,         // System Bus Address ✅
    sb_dat_i,         // System Bus Data Input ✅
    sb_dat_o,         // System Bus Data Output ✅
    sb_ack_o,         // System Bus Acknowledge ✅
    i2c_pirq_o,       // I2C Interrupt [1:0] ✅
    i2c_pwkup_o       // I2C Wakeup [1:0] ✅
);
```

**Your top module connections:**
- ✅ All port names match
- ✅ I2C2 ports left unconnected (correct)
- ✅ Reset inverted: `!rst_n` → `rst_i` (correct, IP expects active-high)

### 4. Verify I2C2 is Disabled in IP

**Check the generated IP file for:**
```verilog
.i2c_left_enable(1),    // I2C1 - should be 1 ✅
.i2c_right_enable(0),  // I2C2 - should be 0 ✅
```

**If `i2c_right_enable(1)`, you need to regenerate the IP with I2C2 disabled!**

### 5. Common Issues

#### Issue: "Module i2c_block not found"
**Solution**: Add the generated I2C IP file to your Radiant project source files.

#### Issue: "Port mismatch" errors
**Solution**: Check that port names in instantiation match exactly (case-sensitive).

#### Issue: "Multiple drivers" for I2C pins
**Solution**: Make sure I2C physical pins are only connected to the IP block, not driven elsewhere.

#### Issue: Design still doesn't fit
**Solution**: 
1. Verify I2C2 is disabled (`i2c_right_enable(0)`)
2. Check synthesis report for actual LUT usage
3. Ensure I2C IP file is included (if missing, synthesis may be creating a stub)

## Current Status

✅ **I2C IP is instantiated** in `drum_system_top.sv`  
✅ **Port connections match** the generated IP  
⚠️ **Verify I2C IP file is in project** (most common issue!)

## Next Steps

1. **Check if I2C IP file is in Radiant project**
   - Look in Source Files list
   - If missing, add it

2. **Re-run synthesis**
   - Should now recognize the I2C IP block
   - Should properly use hardened I2C resources

3. **If still doesn't fit**
   - Get synthesis report with actual LUT counts
   - Verify I2C2 is disabled in generated IP

