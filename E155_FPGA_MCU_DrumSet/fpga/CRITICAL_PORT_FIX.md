# CRITICAL FIX: I2C Port Connection Error

## Problem

Radiant is finding `i2c_block.v` at:
```
E155_finalp/i2c_block/rtl/i2c_block.v
```

But it can't find port `i2c1_sda_io`, meaning the Module Generator file has different port names.

## Solution Applied

Changed to **positional connections** in `drum_system_top.sv` to work around port name mismatches.

## Port Order (from our i2c_block.v)

1. `i2c2_scl_io` (I2C2 Clock - unused)
2. `i2c2_sda_io` (I2C2 Data - unused)
3. `i2c1_scl_io` (I2C1 Clock - **USED**)
4. `i2c1_sda_io` (I2C1 Data - **USED**)
5. `rst_i` (Reset)
6. `ipload_i` (IP Load)
7. `ipdone_o` (IP Done)
8. `sb_clk_i` (System Bus Clock)
9. `sb_wr_i` (System Bus Write)
10. `sb_stb_i` (System Bus Strobe)
11. `sb_adr_i` (System Bus Address)
12. `sb_dat_i` (System Bus Data Input)
13. `sb_dat_o` (System Bus Data Output)
14. `sb_ack_o` (System Bus Acknowledge)
15. `i2c_pirq_o` (I2C Interrupt [1:0])
16. `i2c_pwkup_o` (I2C Wakeup [1:0])

## If Error Persists

**Check the actual Module Generator file** at:
```
E155_finalp/i2c_block/rtl/i2c_block.v
```

1. Open that file
2. Find the module declaration (around line 10-25)
3. Count the ports in order
4. If the order is different, update `drum_system_top.sv` to match

## Alternative: Use Named Connections

If you can determine the exact port names from the Module Generator file, you can switch back to named connections (`.port_name(signal)`), which is more readable and maintainable.

