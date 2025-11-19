# Button Configuration Guide

## Overview

The system has two buttons:
- **button1**: Kick drum trigger
- **button2**: Calibration (sets current yaw as zero offset)

## Button Implementation in Code

### Current Implementation (`drum_system_top.sv`)

**Button Inputs (lines 47-48):**
```systemverilog
input  logic        button1,      // Kick drum
input  logic        button2,      // Calibration
```

**Button Debouncing (lines 97-122):**
```systemverilog
// Debouncing
logic button1_db, button2_db;
logic [15:0] debounce_counter;

// Debounce buttons
localparam DEBOUNCE_COUNT = 16000;  // Adjust based on actual clock frequency

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        debounce_counter <= 0;
        button1_db <= 0;
        button2_db <= 0;
    end else begin
        if (debounce_counter < DEBOUNCE_COUNT) begin
            debounce_counter <= debounce_counter + 1;
        end else begin
            debounce_counter <= 0;
            button1_db <= button1;  // Sample button every DEBOUNCE_COUNT cycles
            button2_db <= button2;
        end
    end
end
```

**Button Usage:**
- `button1_db` → Connected to gesture recognition (line 289)
- `button2_db` → Used for calibration (line 129) and LED2 (line 295)

## Button Logic

### Active State
- **Active Low**: Buttons are active when pulled LOW (0)
- **Pull-up resistors**: Keep buttons HIGH (1) when not pressed
- **When pressed**: Button goes LOW (0), triggering action

### Debouncing
- Samples button state every `DEBOUNCE_COUNT` clock cycles
- For 48MHz: `DEBOUNCE_COUNT = 48000` = ~1ms debounce
- For 16MHz: `DEBOUNCE_COUNT = 16000` = ~1ms debounce
- Prevents false triggers from mechanical bounce

## Pin Assignment

### Step 1: Choose GPIO Pins

Select any available GPIO pins on your iCE40 device. Example for iCE40UP5K:

```
button1 → GPIO_0 (or any GPIO pin)
button2 → GPIO_1 (or any GPIO pin)
```

### Step 2: Create Pin Assignment File (.pdc)

In Lattice Diamond/Radiant, create or edit your `.pdc` file:

```tcl
# Button Pin Assignments

# Button 1 (Kick Drum)
set_location_assignment PIN_XX -to button1
set_io_standard "3.3-V LVCMOS" -current
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to button1

# Button 2 (Calibration)
set_location_assignment PIN_YY -to button2
set_io_standard "3.3-V LVCMOS" -current
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to button2
```

**Replace:**
- `PIN_XX` with actual pin number for button1
- `PIN_YY` with actual pin number for button2

### Step 3: Hardware Connection

**Button Circuit:**
```
VCC (3.3V)
  |
  |  [10kΩ Pull-up Resistor] (Internal or External)
  |
  +---[Button]---+
                  |
                 GND
                  |
              GPIO Pin
```

**Connection:**
1. Connect one side of button to GPIO pin
2. Connect other side of button to GND
3. Enable internal pull-up resistor (via pin assignment)
   - OR use external 10kΩ pull-up resistor to 3.3V

**When button is NOT pressed:**
- Pull-up resistor keeps GPIO pin HIGH (1)
- `button1 = 1`, `button2 = 1`

**When button IS pressed:**
- Button connects GPIO pin to GND
- GPIO pin goes LOW (0)
- `button1 = 0`, `button2 = 0`

## Modifying Button Behavior

### Change Debounce Time

Edit `DEBOUNCE_COUNT` in `drum_system_top.sv` (line 106):

```systemverilog
// For 48MHz clock: 48000 = 1ms, 480000 = 10ms
localparam DEBOUNCE_COUNT = 48000;  // 1ms debounce at 48MHz
```

### Change Button Polarity (Active High)

If you want buttons to be active HIGH instead of LOW:

**Option 1: Invert in pin assignment (recommended)**
- Keep hardware as-is (pull-down instead of pull-up)
- Invert signal in code:

```systemverilog
// Invert button signals
assign button1_inverted = ~button1;
assign button2_inverted = ~button2;

// Use inverted signals for debouncing
always_ff @(posedge clk or negedge rst_n) begin
    // ... debounce logic using button1_inverted, button2_inverted
end
```

**Option 2: Change hardware**
- Use pull-down resistors instead of pull-up
- Button connects to 3.3V when pressed
- GPIO pin goes HIGH (1) when pressed

### Add More Buttons

To add additional buttons:

1. **Add input port** in `drum_system_top.sv`:
```systemverilog
input  logic        button3,      // New button
```

2. **Add debouncing logic**:
```systemverilog
logic button3_db;
// Add to debounce always_ff block
button3_db <= button3;
```

3. **Use in your logic**:
```systemverilog
// Example: Use button3 for something
if (button3_db) begin
    // Do something
end
```

4. **Assign pin** in `.pdc` file:
```tcl
set_location_assignment PIN_ZZ -to button3
set_io_standard "3.3-V LVCMOS" -current
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to button3
```

## Testing Buttons

### In Test Bench

The test bench shows how buttons work:

```systemverilog
// Press button1
button1 = 1;  // Actually 0 in hardware (active low)
#1000;
button1 = 0;  // Release (goes back to 1 in hardware)

// Press button2
button2 = 1;  // Actually 0 in hardware (active low)
#1000;
button2 = 0;  // Release
```

**Note:** In test bench, `button1 = 1` means button is pressed (active low logic).

### In Hardware

1. **Test with multimeter:**
   - Measure GPIO pin voltage
   - Should be ~3.3V when button not pressed
   - Should be ~0V when button pressed

2. **Test with LED:**
   - Connect LED to GPIO pin (with current limiting resistor)
   - LED should be OFF when button not pressed
   - LED should be ON when button pressed (if active low)

3. **Monitor in system:**
   - Check `led2` output (connected to `button2_db`)
   - LED2 should light when button2 is pressed
   - Check `sound_id` output when button1 is pressed

## Common Issues

### Buttons Not Working

1. **Check pull-up resistors:**
   - Verify internal pull-up is enabled in pin assignment
   - OR verify external pull-up resistor is connected

2. **Check pin assignment:**
   - Verify correct pin numbers in `.pdc` file
   - Verify pins are actually GPIO (not dedicated function pins)

3. **Check debounce timing:**
   - If buttons are too sensitive, increase `DEBOUNCE_COUNT`
   - If buttons are unresponsive, decrease `DEBOUNCE_COUNT`

4. **Check button polarity:**
   - Verify button logic matches hardware (active low vs active high)

### Buttons Triggering Randomly

1. **Increase debounce time:**
   ```systemverilog
   localparam DEBOUNCE_COUNT = 96000;  // 2ms at 48MHz
   ```

2. **Add hardware debouncing:**
   - Add capacitor (0.1µF) between button and GPIO pin
   - Or use Schmitt trigger input buffer

3. **Check for noise:**
   - Use shorter wires
   - Add ground plane
   - Use shielded cables if needed

## Example: Complete Button Setup

### Hardware Setup
```
Button 1:
  GPIO_0 ──[10kΩ]── 3.3V
           |
        [Button]
           |
          GND

Button 2:
  GPIO_1 ──[10kΩ]── 3.3V
           |
        [Button]
           |
          GND
```

### Pin Assignment File (.pdc)
```tcl
# Button 1 - Kick Drum
set_location_assignment PIN_15 -to button1
set_io_standard "3.3-V LVCMOS" -current
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to button1

# Button 2 - Calibration
set_location_assignment PIN_16 -to button2
set_io_standard "3.3-V LVCMOS" -current
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to button2
```

### Code (Already Implemented)
- Button inputs defined in `drum_system_top.sv`
- Debouncing implemented
- Button1 → gesture recognition
- Button2 → calibration

## Summary

1. **Buttons are active LOW** (pressed = 0, not pressed = 1)
2. **Use pull-up resistors** (internal or external)
3. **Debouncing is implemented** in code (1ms default)
4. **Assign to any GPIO pin** via `.pdc` file
5. **Enable pull-up** in pin assignment settings

The buttons are already fully implemented in the code - you just need to:
1. Assign them to physical pins in your `.pdc` file
2. Connect hardware buttons to those pins
3. Adjust debounce timing if needed

