# Signal Requirements Summary

## ✅ Required Signals (Must Connect)

### Calibration Button
- **Signal**: `calib_button`
- **Type**: Input
- **Required**: **YES** - Needed for calibration functionality
- **Connection**: Connected to `gesture_detector` module
- **Hardware**: Connect button with 10kΩ pull-up resistor
- **Status**: ✅ Properly connected and used

### MCU SPI Outputs (Required for MCU Communication)
- **`mcu_sclk`**: Output - SPI clock to MCU ✅
- **`mcu_mosi`**: Output - SPI data to MCU ✅
- **`mcu_cs_n`**: Output - Chip select to MCU ✅
- **Required**: **YES** - All three needed for SPI communication
- **Hardware**: 
  - `mcu_cs_n` needs 10kΩ pull-up resistor
  - `mcu_sclk` and `mcu_mosi` are outputs (no pull-up needed)

## ❌ Removed Signals (Not Needed)

### BNO085 Interrupt Pins
- **`int1`**: Removed - Not used (polling mode instead of interrupt mode)
- **`int2`**: Removed - Not used (polling mode instead of interrupt mode)
- **Reason**: Current implementation polls sensors via SPI, doesn't use interrupts
- **Action**: Can leave BNO085 INT pins unconnected or tie to GND

### MCU MISO
- **`mcu_miso`**: Tied to 0 internally - Not used
- **Reason**: One-way communication (FPGA → MCU only)
- **Current Implementation**: FPGA only SENDS data to MCU, doesn't receive
- **Future**: If bidirectional communication needed, can add back

## Signal Status

| Signal | Type | Required | Connected | Used in Logic |
|--------|------|----------|-----------|---------------|
| `calib_button` | Input | ✅ YES | ✅ YES | ✅ YES |
| `mcu_sclk` | Output | ✅ YES | ✅ YES | ✅ YES |
| `mcu_mosi` | Output | ✅ YES | ✅ YES | ✅ YES |
| `mcu_cs_n` | Output | ✅ YES | ✅ YES | ✅ YES |
| `int1` | Input | ❌ NO | ❌ Removed | ❌ Not used |
| `int2` | Input | ❌ NO | ❌ Removed | ❌ Not used |
| `mcu_miso` | Input | ❌ NO | Tied to 0 | ❌ Not used |

## Pin Assignment (Updated)

```
# Required pins
set_io calib_button P11   # Calibration button (left button, with 10kΩ pull-up)
set_io kick_button   P2   # Kick button (right button, with 10kΩ pull-up)
set_io mcu_sclk     P21   # SPI clock to MCU
set_io mcu_mosi     P10   # SPI MOSI to MCU
set_io mcu_cs_n     P19   # Chip select to MCU (with 10kΩ pull-up)

# Removed pins (no longer needed)
# set_io int1        5    # REMOVED - Not used
# set_io int2        10   # REMOVED - Not used
# set_io mcu_miso    16   # REMOVED - Not used (one-way communication)
```

## About MCU MISO

**Question**: "I think I will surely need the mcu_miso too when connected over SPI to the MCU"

**Answer**: 
- For **standard SPI**, you typically need MISO for bidirectional communication
- However, **this implementation only sends data FROM FPGA TO MCU** (one-way)
- The MCU acts as a slave that **receives** data, not sends it back
- Therefore, `mcu_miso` is **not needed** for current functionality
- If you need the MCU to send data back to FPGA in the future, you can add it back

**Current SPI Configuration**:
- FPGA = SPI Master (sends data)
- MCU = SPI Slave (receives data)
- Communication: FPGA → MCU only (unidirectional)

## Summary

✅ **All required signals are properly connected**
- Calibration button: Connected and functional
- MCU SPI outputs: All connected and working
- No "unconnected" warnings should appear for required signals

❌ **Unused signals removed**
- `int1`, `int2`: Removed (not needed)
- `mcu_miso`: Tied to 0 (not used in one-way communication)

Your FPGA should now synthesize without "unconnected" warnings for these signals!

