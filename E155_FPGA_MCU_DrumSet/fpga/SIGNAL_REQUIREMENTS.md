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

## ✅ Required Signals (BNO085 INT Pins)

### BNO085 Interrupt Pins
- **`int1`**: Input - REQUIRED for stable SPI operation (P9)
- **`int2`**: Input - REQUIRED for stable SPI operation (P3)
- **Reason**: Adafruit documentation states INT pins are "Required for stable SPI operation"
- **Action**: Must connect BNO085 INT pins to FPGA (P9 for sensor 1, P3 for sensor 2)
- **Hardware**: Connect with 10kΩ pull-up resistor (INT is active LOW)

### MCU MISO
- **`mcu_miso`**: Tied to 0 internally - Not used
- **Reason**: One-way communication (FPGA → MCU only)
- **Current Implementation**: FPGA only SENDS data to MCU, doesn't receive
- **Future**: If bidirectional communication needed, can add back

## Signal Status

| Signal | Type | Required | Connected | Used in Logic |
|--------|------|----------|-----------|---------------|
| `calib_button` | Input | ✅ YES | ✅ YES | ✅ YES |
| `int1` | Input | ✅ YES | ✅ YES | ✅ YES (monitored) |
| `int2` | Input | ✅ YES | ✅ YES | ✅ YES (monitored) |
| `mcu_sclk` | Output | ✅ YES | ✅ YES | ✅ YES |
| `mcu_mosi` | Output | ✅ YES | ✅ YES | ✅ YES |
| `mcu_cs_n` | Output | ✅ YES | ✅ YES | ✅ YES |
| `mcu_miso` | Input | ❌ NO | Tied to 0 | ❌ Not used |

## Pin Assignment (Updated)

```
# Required pins
set_io calib_button P11   # Calibration button (left button, with 10kΩ pull-up)
set_io kick_button   P2   # Kick button (right button, with 10kΩ pull-up)
set_io int1         P9    # Interrupt from Sensor 1 (REQUIRED for stable SPI, 10kΩ pull-up)
set_io int2         P3    # Interrupt from Sensor 2 (REQUIRED for stable SPI, 10kΩ pull-up)
set_io mcu_sclk     P21   # SPI clock to MCU
set_io mcu_mosi     P10   # SPI MOSI to MCU
set_io mcu_cs_n     P19   # Chip select to MCU (with 10kΩ pull-up)

# Not used
# set_io mcu_miso    16   # Not used (one-way communication: FPGA→MCU only)
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

✅ **INT pins are required**
- `int1` (P9), `int2` (P3): Required for stable SPI operation per Adafruit documentation
- Must be connected with 10kΩ pull-up resistors (INT is active LOW)

❌ **Unused signals**
- `mcu_miso`: Tied to 0 (not used in one-way communication)

Your FPGA should now synthesize without "unconnected" warnings for these signals!

