# Fix: "cannot find port i2c1_sda_io" Error

## Problem

Radiant is finding `i2c_block.v` at:
```
E155_finalp/i2c_block/rtl/i2c_block.v
```

But it can't find port `i2c1_sda_io`. This means the Module Generator file might have different port names.

## Solution: Check the Actual Module Generator File

1. **Open the Module Generator file** at:
   `E155_finalp/i2c_block/rtl/i2c_block.v`

2. **Find the module declaration** (around line 10-25)

3. **Check the port names** - Look for lines like:
   ```verilog
   module i2c_block (
       i2c2_scl_io,
       i2c2_sda_io,
       i2c1_scl_io,    // ← Check this name
       i2c1_sda_io,    // ← Check this name
       ...
   );
   ```

4. **If port names are different**, update `drum_system_top.sv` to match

## Possible Port Name Variations

The Module Generator might use:
- `i2c1_scl_io` / `i2c1_sda_io` (what we expect)
- `i2c_scl_io` / `i2c_sda_io` (if only one I2C enabled)
- `i2c_left_scl_io` / `i2c_left_sda_io` (alternative naming)
- `i2c_right_scl_io` / `i2c_right_sda_io` (if I2C1 is "right")

## Quick Fix: Use Positional Connection (Temporary)

If you need a quick workaround, you can use positional connection:

```verilog
i2c_block i2c1_ip (
    ,              // i2c2_scl_io (unused)
    ,              // i2c2_sda_io (unused)
    i2c1_scl,      // i2c1_scl_io (position 2)
    i2c1_sda,      // i2c1_sda_io (position 3)
    !rst_n,        // rst_i
    i2c1_ipload,   // ipload_i
    i2c1_ipdone,   // ipdone_o
    i2c1_sb_clk,   // sb_clk_i
    i2c1_sb_wr,    // sb_wr_i
    i2c1_sb_stb,   // sb_stb_i
    i2c1_sb_addr,  // sb_adr_i
    i2c1_sb_data_i, // sb_dat_i
    i2c1_sb_data_o, // sb_dat_o
    i2c1_sb_ack,   // sb_ack_o
    i2c_pirq_o,    // i2c_pirq_o
    i2c_pwkup_o    // i2c_pwkup_o
);
```

**But this is fragile - better to check the actual file!**

