# I2C IP Instantiation Verification Checklist

## ✅ Step 1: Generate I2C IP with Module Generator

1. Open **Lattice Radiant**
2. Go to **Tools → Module Generator**
3. Configure I2C with **MINIMAL settings** (see `MODULE_GENERATOR_CONFIG.md`):
   - ✅ Enable Left I2C
   - ❌ Disable Right I2C (we only need one)
   - ✅ Master mode
   - ✅ 400 kHz
   - ✅ 7-bit addressing
   - ✅ TX/RX Ready interrupt only
   - ❌ Disable ALL other interrupts
   - ❌ Disable FIFO mode
   - ❌ Disable General Call
   - ❌ Disable Wake-up
4. Click **Generate**
5. **Note the file location** where IP was generated

## ✅ Step 2: Find Generated IP Module Name

1. Open the generated IP file (usually `.v` or `.sv` file)
2. Look for the module declaration:
   ```systemverilog
   module i2c_master_top (  // <-- This is the module name
   ```
3. **Write down the exact module name** (e.g., `i2c_master_top`, `i2c1_wrapper`, etc.)

## ✅ Step 3: Check Port Names

In the generated IP file, find the port declarations:
```systemverilog
module i2c_master_top (
    input  SBCLKi,      // System Bus Clock
    input  SBWRi,       // System Bus Write
    input  SBSTBi,      // System Bus Strobe
    input  [7:0] SBADRi, // System Bus Address
    // ... etc
);
```

**Note the exact port names** - they may differ from examples!

## ✅ Step 4: Add Generated IP to Project

1. In Radiant Project Navigator:
   - Right-click project → **Add Source Files**
   - Navigate to generated IP location
   - Select the generated IP file (`.v` or `.sv`)
   - Click **Add**
2. Verify file appears in project

## ✅ Step 5: Update Top Module

1. Open `drum_system_top.sv`
2. Find the I2C IP instantiation section (around line 87)
3. **Uncomment** the `i2c_master_top` instantiation
4. **Replace** `i2c_master_top` with your actual module name
5. **Verify** all port names match your generated IP
6. **Add** `define USE_I2C_IP` to your project defines, OR
7. **Remove** the `ifdef USE_I2C_IP` and just uncomment the instantiation

## ✅ Step 6: Remove Temporary Assignments

1. Find the `else` block with temporary assignments (around line 119)
2. **Delete** or **comment out** this entire block:
   ```systemverilog
   // REMOVE THIS:
   assign i2c1_sb_wr = 0;
   assign i2c1_sb_stb = 0;
   // ... etc
   ```

## ✅ Step 7: Verify Connections

Check that System Bus signals are connected correctly:

**I2C Controller → I2C IP Wrapper:**
- `i2c1_sb_wr` - Controller drives, IP receives
- `i2c1_sb_stb` - Controller drives, IP receives
- `i2c1_sb_addr` - Controller drives, IP receives
- `i2c1_sb_data_i` - Controller drives, IP receives
- `i2c1_sb_data_o` - IP drives, Controller receives
- `i2c1_sb_ack` - IP drives, Controller receives
- `i2c1_sb_clk` - Top module drives both

**I2C IP Wrapper → Physical Pins:**
- `i2c1_scl` - IP drives/receives, connects to BNO055
- `i2c1_sda` - IP drives/receives, connects to BNO055

## ✅ Step 8: Assign I2C Physical Pins

1. In Radiant: **Tools → Pin Assignment Editor**
2. Assign `i2c1_scl` to **I2C1 SCL dedicated pin** (check datasheet)
3. Assign `i2c1_sda` to **I2C1 SDA dedicated pin** (check datasheet)
4. Save pin constraints

## ✅ Step 9: Synthesize and Check

1. **Synthesize** the design
2. **Check Design Summary**:
   - Look for I2C IP module in hierarchy
   - Check LUT usage
   - Verify it's less than 5280 LUTs
3. **Check for errors**:
   - Module not found → IP file not added to project
   - Port not found → Port name mismatch
   - Multiple drivers → Signal connected incorrectly

## Common Issues and Fixes

### Issue: "Module i2c_master_top not found"
**Fix**: 
- Add generated IP file to project
- Check module name is correct
- Verify file is in project source list

### Issue: "Port SBWRi not found"
**Fix**:
- Check generated IP file for exact port name
- May be `SBWR` instead of `SBWRi`
- Update port name in instantiation

### Issue: "I2C1_SCL port not found"
**Fix**:
- Some generated IPs handle pins internally
- Check if I2C pins are exposed as ports
- May need to remove I2C pin connections if handled internally

### Issue: "Design still doesn't fit"
**Fix**:
- Check I2C IP resource usage in Design Summary
- Verify Module Generator settings are minimal
- Regenerate IP with fewer features
- Consider that I2C IP might inherently be 2000-3000 LUTs

## Expected Results

After proper instantiation:
- ✅ No "module not found" errors
- ✅ No "port not found" errors
- ✅ I2C IP appears in design hierarchy
- ✅ System Bus signals properly connected
- ✅ Design fits (or at least closer to fitting)

## Next Steps After Verification

1. If design fits: ✅ **Ready to program FPGA**
2. If still too large:
   - Check I2C IP resource usage
   - Regenerate with even fewer features
   - Consider alternative approaches

