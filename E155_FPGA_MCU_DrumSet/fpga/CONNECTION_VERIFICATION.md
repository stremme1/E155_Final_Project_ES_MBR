# Connection Verification

## ✅ All Signals Are Properly Connected

### Calibration Button (`calib_button`)
- **Port Declaration**: `input logic calib_button` (line 23)
- **Connected To**: `gesture_detector` module (line 203)
- **Status**: ✅ CONNECTED
- **Usage**: Used for calibration functionality with debouncing

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
set_io calib_button 12    # Calibration button (with 10kΩ pull-up)
set_io mcu_sclk     14    # SPI clock to MCU
set_io mcu_mosi     15    # SPI MOSI to MCU
set_io mcu_cs_n     17    # Chip select to MCU (with 10kΩ pull-up)
set_io mcu_miso     16    # SPI MISO from MCU (optional, can be unconnected)
```

All signals are properly connected in the SystemVerilog code!
