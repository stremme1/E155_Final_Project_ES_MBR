# LED Status Indicators

## LED Signals

The system has two optional status LED outputs:

### 1. `led_initialized`
- **Function**: Indicates when both BNO085 sensors are successfully initialized
- **Logic**: `led_initialized = bno1_initialized && bno2_initialized`
- **Behavior**:
  - **LOW (OFF)**: One or both sensors not initialized
  - **HIGH (ON)**: Both sensors initialized and ready

### 2. `led_error`
- **Function**: Indicates when either sensor has an error
- **Logic**: `led_error = bno1_error || bno2_error`
- **Behavior**:
  - **LOW (OFF)**: No errors detected
  - **HIGH (ON)**: Error detected in one or both sensors

## Hardware Connection

### LED Wiring
```
FPGA Pin → Current Limiting Resistor (220Ω-1kΩ) → LED Anode → LED Cathode → GND
```

**Example:**
```
FPGA led_initialized → 220Ω resistor → LED+ → LED- → GND
FPGA led_error       → 220Ω resistor → LED+ → LED- → GND
```

### Pin Assignment

In your constraints file (`.pcf`, `.xdc`, or `.qsf`):
```
# Status LEDs
set_io led_initialized P28  # LED when initialized
set_io led_error       P38  # LED for errors
```

**Pin Assignments:**
- `led_initialized` → **P28**
- `led_error` → **P38**

## Usage

### During Startup:
1. Power on system
2. `led_initialized` should turn ON when both sensors initialize (typically within 1-2 seconds)
3. If `led_error` turns ON, check sensor connections and power

### During Operation:
- `led_initialized`: Should remain ON during normal operation
- `led_error`: Should remain OFF during normal operation
  - If it turns ON, check:
    - Sensor SPI connections
    - Power supply to sensors
    - Sensor initialization sequence

## Implementation Details

The LED signals are assigned in `drum_set_top.sv`:

```systemverilog
assign led_initialized = bno1_initialized && bno2_initialized;
assign led_error = bno1_error || bno2_error;
```

These signals come from the `bno085_controller` modules, which set:
- `initialized = 1'b1` when sensor successfully initializes and starts sending reports
- `error = 1'b1` when communication errors or initialization failures occur

## Optional: Leave Unconnected

If you don't have available GPIO pins for LEDs, you can:
1. Leave the LED pins unassigned in your constraints file
2. The signals will still be generated internally but won't be routed to physical pins
3. You can monitor sensor status through other means (MCU serial output, etc.)

