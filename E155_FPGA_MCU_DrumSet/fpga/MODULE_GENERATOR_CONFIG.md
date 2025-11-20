# Module Generator Configuration - Exact Settings for iCE40UP5K

## General Tab Settings

### Enable Hard IP Blocks
- ✅ **Enable hard user I2C left** - **CHECKED** (I2C1)
- ✅ **Enable hard user I2C right** - **CHECKED** (I2C2)
- ❌ **Enable hard user SPI left** - **UNCHECKED** (not needed)
- ❌ **Enable hard user SPI right** - **UNCHECKED** (not needed)

### System Bus Clock
- **System bus clock frequency (MHz)**: **48** (for HFOSC/HSOC)

## I2C Left (I2C1) Configuration

### Basic Settings
- **I2C Left: General call enable**: ❌ **UNCHECKED** (not needed for master mode)
- **I2C Left: Wakeup enable**: ❌ **UNCHECKED** (not needed for BNO055)
- **I2C Left: Desired frequency (kHz)**: **400**
- **I2C Left: Clock Pre-scale [10 - 1023]**: **Leave blank or auto-calculate** (Module Generator will calculate)
- **I2C Left: DIVIDER**: **Leave blank or auto-calculate** (Module Generator will calculate)
- **I2C Left: Actual frequency (kHz)**: **Should show ~400** (verify after calculation)
- **I2C Left: I2C Addressing Width**: **7-Bit Addressing**
- **I2C Left: I2C Addressing Prefix**: **Leave default** (not used in master mode, only for slave)

### Interrupts
- **I2C Left: Arbitration lost**: ⚠️ **Optional** (can enable for debugging, but not required)
- ✅ **I2C Left: TX/RX ready**: **CHECKED** (REQUIRED - needed for data transfer)
- ⚠️ **I2C Left: Overrun or NACK**: **Optional** (can enable for error handling)
- ❌ **I2C Left: General call**: **UNCHECKED** (not needed)

### I2C Timing Options
- ✅ **I2C Left: 50ns delay on SDA input**: **CHECKED** (recommended for reliable START/STOP detection)
- ✅ **I2C Left: 50ns delay on SDA output**: **CHECKED** (recommended for reliable signal generation)

## I2C Right (I2C2) Configuration

### Basic Settings
- **I2C Right: General call enable**: ❌ **UNCHECKED**
- **I2C Right: Wakeup enable**: ❌ **UNCHECKED**
- **I2C Right: Desired frequency (kHz)**: **400**
- **I2C Right: Clock Pre-scale**: **Leave blank or auto-calculate**
- **I2C Right: DIVIDER**: **Leave blank or auto-calculate**
- **I2C Right: Actual frequency (kHz)**: **Should show ~400** (verify after calculation)
- **I2C Right: I2C Addressing Width**: **7-Bit Addressing**
- **I2C Right: I2C Addressing Prefix**: **Leave default**

### Interrupts
- **I2C Right: Arbitration lost**: ⚠️ **Optional**
- ✅ **I2C Right: TX/RX ready**: **CHECKED** (REQUIRED)
- ⚠️ **I2C Right: Overrun or NACK**: **Optional**
- ❌ **I2C Right: General call**: **UNCHECKED**

### I2C Timing Options
- ✅ **I2C Right: 50ns delay on SDA input**: **CHECKED**
- ✅ **I2C Right: 50ns delay on SDA output**: **CHECKED**

## Summary of Required Settings

### Must Enable:
- ✅ Enable hard user I2C left
- ✅ Enable hard user I2C right
- ✅ System bus clock frequency: **48 MHz**
- ✅ I2C Left/Right: Desired frequency: **400 kHz**
- ✅ I2C Left/Right: TX/RX ready interrupt: **CHECKED**
- ✅ I2C Left/Right: 50ns delay on SDA input: **CHECKED**
- ✅ I2C Left/Right: 50ns delay on SDA output: **CHECKED**
- ✅ I2C Left/Right: I2C Addressing Width: **7-Bit Addressing**

### Can Leave Default/Unchecked:
- ❌ General call enable (both)
- ❌ Wakeup enable (both)
- ❌ General call interrupt (both)
- ⚠️ Arbitration lost (optional)
- ⚠️ Overrun or NACK (optional)
- I2C Addressing Prefix (leave default - not used in master mode)

### Auto-Calculated (Don't Manually Set):
- Clock Pre-scale (Module Generator calculates)
- DIVIDER (Module Generator calculates)
- Actual frequency (verify it's close to 400 kHz)

## Verification After Generation

After clicking Generate, verify:
1. **Actual frequency** shows ~400 kHz (may be slightly different, e.g., 400.9 kHz)
2. **Generated files** appear in your project directory
3. **Module name** is noted (e.g., `i2c_master_top`)

## Next Steps

After configuration:
1. Click **Generate** or **OK**
2. Save generated files to your project
3. Add generated files to Radiant project
4. Instantiate I2C IP wrappers in your top module
5. See `RADIANT_I2C_SETUP.md` for instantiation details

