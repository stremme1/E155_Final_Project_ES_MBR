# I2C IP Regeneration Guide - CRITICAL FIX

## 🚨 CRITICAL ISSUE FOUND

Your current I2C IP block has **BOTH I2C controllers enabled**, wasting ~500-1000 LUTs!

**Current (WRONG):**
```verilog
.i2c_left_enable(1),    // I2C1 - enabled ✅
.i2c_right_enable(1),  // I2C2 - enabled ❌ WASTING RESOURCES!
```

**Should be:**
```verilog
.i2c_left_enable(1),    // I2C1 - enabled ✅
.i2c_right_enable(0),  // I2C2 - DISABLED ✅
```

## Step-by-Step: Regenerate I2C IP

### 1. Open Module Generator in Lattice Radiant

1. In Lattice Radiant, go to **Tools → Module Generator**
2. Select **iCE40UP5K** as target device
3. Click **Next**

### 2. Configure I2C Settings

**General Tab:**
- ✅ **Enable hard user I2C left** - **CHECKED** (I2C1)
- ❌ **Enable hard user I2C right** - **UNCHECKED** ⚠️ **CRITICAL - MUST BE OFF**
- ❌ **Enable hard user SPI left** - **UNCHECKED**
- ❌ **Enable hard user SPI right** - **UNCHECKED**
- **System bus clock frequency (MHz)**: **48**

**I2C Left Tab (I2C1):**
- ❌ General call enable: **UNCHECKED**
- ❌ Wakeup enable: **UNCHECKED**
- **Desired frequency (kHz)**: **400**
- **I2C Addressing Width**: **7-Bit Addressing**
- ✅ **TX/RX ready**: **CHECKED**
- ✅ **50ns delay on SDA input**: **CHECKED**
- ✅ **50ns delay on SDA output**: **CHECKED**
- ❌ Arbitration lost: **UNCHECKED** (optional)
- ❌ Overrun or NACK: **UNCHECKED** (optional)
- ❌ General call: **UNCHECKED**

**I2C Right Tab:**
- ⚠️ **IGNORE THIS TAB** - I2C2 is disabled, so settings don't matter

### 3. Generate IP

1. Click **Generate** or **OK**
2. Save the generated files to your project directory
3. **Add generated files to your Radiant project**

### 4. Verify Generated IP

Open the generated file (usually `i2c_block.v` or similar) and check:

```verilog
i2c_block_ipgen_lscc_spi_i2c #(
    .i2c_left_enable(1),    // ✅ Should be 1
    .i2c_right_enable(0),  // ✅ Should be 0 (not 1!)
    .spi_left_enable(0),
    .spi_right_enable(0),
    // ... rest of parameters
)
```

**If `i2c_right_enable` is still 1, you didn't disable it correctly!**

### 5. Update Your Top Module

Your `drum_system_top.sv` now includes the I2C IP instantiation. Make sure:

1. The module name matches your generated IP (check the generated file)
2. Port names match (they may vary slightly)
3. Physical I2C pins are connected

### 6. Re-synthesize

After regenerating IP with only I2C1 enabled:
- **Expected LUT reduction**: ~500-1000 LUTs
- **Design should now fit** within 5280 LUT limit

## Common Issues

### Issue: "Module i2c_block not found"
**Solution**: Add the generated IP files to your Radiant project:
1. Right-click project → **Add Source Files**
2. Select the generated `.v` or `.sv` file
3. Make sure it's in the source files list

### Issue: Port name mismatch
**Solution**: Check the generated IP file for exact port names:
- Generated IP may use `i2c1_scl_io` instead of `i2c1_scl`
- Generated IP may use `rst_i` (active-high) instead of `rst_n` (active-low)
- Adjust your top module connections accordingly

### Issue: Still doesn't fit after fix
**Solution**: 
1. Verify `i2c_right_enable(0)` in generated IP
2. Check synthesis report for actual resource usage
3. Ensure no other large modules are instantiated

## Expected Results

**Before (both I2Cs enabled):**
- I2C IP: ~1000-1500 LUTs
- Your logic: ~500-800 LUTs
- **Total: ~1500-2300 LUTs** (may not fit)

**After (only I2C1 enabled):**
- I2C IP: ~500-750 LUTs
- Your logic: ~500-800 LUTs
- **Total: ~1000-1550 LUTs** (should fit easily!)

## Verification Checklist

- [ ] Module Generator shows I2C2 as **disabled**
- [ ] Generated IP file shows `i2c_right_enable(0)`
- [ ] Top module instantiates I2C IP wrapper
- [ ] Physical I2C pins connected
- [ ] Synthesis completes without "doesn't fit" error
- [ ] Resource usage shows ~50% reduction in I2C-related LUTs

