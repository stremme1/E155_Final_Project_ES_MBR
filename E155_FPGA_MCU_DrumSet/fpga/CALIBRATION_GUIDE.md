# Calibration Button Guide

## What the Calibration Button Does

The calibration button sets the **"zero position"** (north/reference direction) for both drumsticks. When you press the button:

1. **Captures current yaw angles** from both sensors (right and left hand)
2. **Stores these as offset values** (`yaw_offset1` and `yaw_offset2`)
3. **All future yaw measurements are relative to this position**

### Why This is Important

- **Personalized Setup**: Each drummer holds sticks differently
- **Flexible Positioning**: You can sit/stand in any orientation
- **Consistent Zones**: Drum zones (snare, toms, cymbals) are relative to YOUR zero position

## How It Works

### Step-by-Step Process:

1. **Hold drumsticks in your desired "zero" position**
   - This is your natural resting position
   - Typically: sticks pointing forward/north
   - Both hands should be in comfortable position

2. **Press and release the calibration button**
   - Button press is detected on rising edge (LOW → HIGH)
   - Current yaw values from both sensors are captured
   - These become the new zero offsets

3. **System uses offsets for all gesture detection**
   - All yaw measurements are now: `yaw_normalized = yaw_raw - yaw_offset`
   - Zone detection uses normalized yaw values
   - Zones remain consistent relative to your zero position

### Example:

```
Before Calibration:
- Right stick pointing at 45° (raw yaw = 45°)
- Left stick pointing at 315° (raw yaw = 315°)
- Zones are calculated from raw values

After Calibration (button pressed at 45°/315°):
- yaw_offset1 = 45°
- yaw_offset2 = 315°
- Right stick at 45° → normalized = 45° - 45° = 0° (Zone 1)
- Right stick at 165° → normalized = 165° - 45° = 120° (Zone 1)
- Left stick at 315° → normalized = 315° - 315° = 0° (Zone 1)
```

## Hardware Configuration

### Button Wiring:

```
Calibration Button:
┌─────────────┐
│   Button    │
└──────┬──────┘
       │
       ├──→ 10kΩ resistor → 3.3V (pull-up)
       │
       └──→ GPIO Pin (calib_button) → FPGA
            │
            └──→ GND (when button pressed)
```

### Pin Assignment:

In your constraints file (`.pcf`, `.xdc`, or `.qsf`):
```
set_io calib_button BT    # Calibration button pin
```

### Button Type:

- **Momentary push button** (normally open)
- **Active HIGH** when pressed (pulls to 3.3V via pull-up)
- **Active LOW** when released (pulled to 3.3V via resistor)

## Software Implementation

### Current Implementation:

The calibration logic is in `gesture_detector.sv` with **button debouncing**:

```systemverilog
// Button synchronization and debouncing (50ms debounce period)
// Double synchronize asynchronous button signal
calib_button_sync1 <= calib_button;
calib_button_sync2 <= calib_button_sync1;

// Debounce logic - waits 50ms before accepting button state change
if (calib_button_sync2 != calib_button_debounced) begin
    debounce_counter <= debounce_counter + 1;
    if (debounce_counter >= DEBOUNCE_COUNT) begin
        calib_button_debounced <= calib_button_sync2;
    end
end

// Calibration: capture current yaw values when button pressed
if (calib_button_debounced && !calib_button_prev && data_valid_1 && data_valid_2) begin
    yaw_offset1_reg <= yaw1;
    yaw_offset2_reg <= yaw2;
    calib_active <= 1'b1;
end
```

### Requirements:

- **Both sensors must have valid data** (`data_valid_1 && data_valid_2`)
- **Button press detected on rising edge** (LOW → HIGH transition)
- **50ms debounce period** prevents false triggers from button bounce
- **Double synchronization** prevents metastability from asynchronous button signal
- **Yaw offsets are captured** when debounced button press is detected

### Status Signal:

- `calib_active` goes HIGH when calibration is triggered
- Can be used to drive an LED to indicate calibration is active
- Returns to LOW when button is released

## Usage Instructions

### Initial Setup:

1. **Power on the system**
2. **Wait for sensors to initialize** (LED_initialized should turn on)
3. **Hold drumsticks in your natural playing position**
4. **Press calibration button** (hold for ~1 second)
5. **Release button**
6. **System is now calibrated** - zones are relative to this position

### Recalibration:

- **Press button again** at any time to recalibrate
- Useful if you change position or want to adjust zones
- No need to power cycle

### Troubleshooting:

**Button doesn't work:**
- Check wiring (pull-up resistor, button connections)
- Verify pin assignment in constraints file
- Ensure both sensors have valid data (check LED_initialized)

**Calibration seems wrong:**
- Make sure you're holding sticks in desired zero position when pressing
- Try recalibrating with sticks in different position
- Check that sensors are properly initialized

**Zones don't match expectations:**
- Recalibrate with sticks pointing in your desired "north" direction
- Remember: zones are relative to YOUR zero position, not absolute

## Technical Details

### Yaw Offset Storage:

- Offsets are stored in registers: `yaw_offset1_reg` and `yaw_offset2_reg`
- These are applied in real-time to normalize yaw values
- Offsets persist until next calibration or system reset

### Normalization:

After calibration, all yaw values are normalized:
```systemverilog
yaw1_norm = normalize_yaw(yaw1 - yaw_offset1_reg);
yaw2_norm = normalize_yaw(yaw2 - yaw_offset2_reg);
```

The `normalize_yaw` function ensures values stay in 0-360° range.

### Zone Detection:

All zone detection uses normalized yaw values:
- **Right Hand Zone 1**: 20°-120° (normalized)
- **Right Hand Zone 2**: 340°-20° (normalized)
- **Right Hand Zone 3**: 305°-340° (normalized)
- **Right Hand Zone 4**: 200°-305° (normalized)
- **Left Hand Zone 1**: 350°-100° (normalized)
- **Left Hand Zone 2**: 325°-350° (normalized)
- **Left Hand Zone 3**: 300°-325° (normalized)
- **Left Hand Zone 4**: 200°-300° (normalized)

## Integration with Top-Level

The calibration button is connected in `drum_set_top.sv`:

```systemverilog
gesture_detector gesture_det (
    ...
    .yaw_offset1(yaw_offset1),
    .yaw_offset2(yaw_offset2),
    .calib_button(calib_button),
    ...
    .calib_active(calib_active)
);

// Capture yaw offsets during calibration
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        yaw_offset1 <= 16'd0;
        yaw_offset2 <= 16'd0;
    end else if (calib_active && euler1_valid && euler2_valid) begin
        yaw_offset1 <= yaw1;
        yaw_offset2 <= yaw2;
    end
end
```

The offsets are captured in the top-level module and passed back to the gesture detector.

