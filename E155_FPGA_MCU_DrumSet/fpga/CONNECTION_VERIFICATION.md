# Connection Verification

## ✅ All Signals Are Properly Connected

### Calibration Button (`calib_button`)
- **Port Declaration**: `input logic calib_button` (line 23)
- **Connected To**: `gesture_detector` module (line 203)
- **Status**: ✅ CONNECTED
- **Usage**: Used for calibration functionality with debouncing

### BNO085 Interrupt Pins (`int1`, `int2`)
- **Port Declaration**: `input logic int1, int2` (lines 20-21)
- **Connected To**: `bno085_controller` modules (lines 150, 195)
- **Status**: ✅ CONNECTED
- **Usage**: Required for stable SPI operation per Adafruit documentation
- **Pin Assignments**: int1 → P9, int2 → P3

### MCU MISO (`mcu_miso`)
- **Port Declaration**: `input logic mcu_miso` (line 29)
- **Connected To**: `spi_to_mcu` module (line 265)
- **Status**: ✅ CONNECTED
- **Note**: This is optional - MCU may not send data back. Signal is connected but not actively used in current implementation (one-way communication from FPGA to MCU).

### MCU SPI Outputs (All Connected)
- **`mcu_sclk`**: Output → Connected to `spi_to_mcu` (line 263)
- **`mcu_mosi`**: Output → Connected to `spi_to_mcu` (line 264)
- **`mcu_cs_n`**: Output → Connected to `spi_to_mcu` (line 266)

## Signal Flow

```
FPGA Top-Level (drum_set_top.sv)
├── calib_button (input) → gesture_detector.calib_button ✅
├── int1 (input, P9) → bno085_controller.int_n ✅
├── int2 (input, P3) → bno085_controller.int_n ✅
├── mcu_miso (input) → spi_to_mcu.mcu_miso ✅
├── mcu_sclk (output) ← spi_to_mcu.mcu_sclk ✅
├── mcu_mosi (output) ← spi_to_mcu.mcu_mosi ✅
└── mcu_cs_n (output) ← spi_to_mcu.mcu_cs_n ✅
```

## If Synthesis Shows "Unconnected"

If your synthesis tool shows these as "unconnected", it may be because:

1. **`mcu_miso`**: This signal is connected but not actively used in the logic (MCU doesn't send data back). This is normal and expected. You can:
   - Leave it unconnected in hardware (tie to GND or leave floating)
   - Or remove it from the port list if you want (but it's fine to keep it)

2. **`calib_button`**: If this shows as unconnected, check:
   - Pin assignment in constraints file
   - Make sure the port is actually assigned to a physical pin
   - Verify the signal name matches exactly

## Pin Assignment Checklist

Make sure these are assigned in your constraints file:

```
set_io calib_button P11   # Calibration button (left button, with 10kΩ pull-up)
set_io kick_button   P2   # Kick button (right button, with 10kΩ pull-up)
set_io int1         P9    # Interrupt from Sensor 1 (REQUIRED, 10kΩ pull-up)
set_io int2         P3    # Interrupt from Sensor 2 (REQUIRED, 10kΩ pull-up)
set_io mcu_sclk     P21   # SPI clock to MCU
set_io mcu_mosi     P10   # SPI MOSI to MCU
set_io mcu_cs_n     P19   # Chip select to MCU (with 10kΩ pull-up)
set_io mcu_miso     16    # SPI MISO from MCU (optional, can be unconnected)
```

All signals are properly connected in the SystemVerilog code!
