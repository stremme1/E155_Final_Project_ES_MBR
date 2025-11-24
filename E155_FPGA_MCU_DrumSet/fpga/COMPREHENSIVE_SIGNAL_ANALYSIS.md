# Comprehensive Signal Analysis - calib_button vs kick_button

## Critical Difference Found

### kick_button Usage (WORKS in Radiant):
```systemverilog
// Line 285-286: Declarations
logic kick_button_prev;
logic kick_button_edge;

// Line 288-293: Sequential usage
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        kick_button_prev <= 1'b0;
    end else begin
        kick_button_prev <= kick_button;  // ✅ Direct use
    end
end

// Line 296: Combinational usage
assign kick_button_edge = kick_button && !kick_button_prev;  // ✅ Direct use

// Line 311: State machine usage - AFFECTS OUTPUTS
else if (kick_button_edge && !mcu_busy) begin
    mcu_sound_code <= 4'd2;  // ✅ Sets output
    mcu_data_valid <= 1'b1;  // ✅ Sets output (meaningful)
end
```

### calib_button Usage (DOESN'T WORK in Radiant):
```systemverilog
// Line 262-264: Declarations
logic calib_button_prev_top;
logic calib_button_edge_top;
logic calib_button_monitor;  // ⚠️ Declared but never used

// Line 266-275: Sequential usage
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        calib_button_prev_top <= 1'b0;
        calib_button_monitor <= 1'b0;  // ⚠️ Unused signal
    end else begin
        calib_button_prev_top <= calib_button;  // ✅ Direct use
        calib_button_monitor <= calib_button_edge_top;  // ⚠️ Unused signal
    end
end

// Line 278: Combinational usage
assign calib_button_edge_top = calib_button && !calib_button_prev_top;  // ✅ Direct use

// Line 318: State machine usage - DOESN'T AFFECT OUTPUTS MEANINGFULLY
else if (calib_button_edge_top && !mcu_busy) begin
    mcu_sound_code <= 4'd0;  // ⚠️ Placeholder value
    mcu_data_valid <= 1'b0;   // ⚠️ Sets to 0 (no effect, already 0)
end
```

## Problems Identified

### Problem 1: Unused Signal
- `calib_button_monitor` is declared and assigned but **never read**
- Synthesis tools may optimize this away, potentially breaking the signal chain
- `kick_button` doesn't have this unused signal

### Problem 2: Meaningless State Machine Usage
- `calib_button_edge_top` is used in state machine, but:
  - `mcu_data_valid <= 1'b0` has no effect (it's already 0 from line 303)
  - `mcu_sound_code <= 4'd0` is a placeholder
  - Synthesis tool may optimize this entire branch away because it doesn't affect outputs
- `kick_button_edge` actually sets `mcu_data_valid <= 1'b1` which **affects outputs**

### Problem 3: Signal Chain Dependency
If `calib_button_monitor` is optimized away:
- `calib_button_edge_top` might be optimized (only drives unused signal)
- `calib_button_prev_top` might be optimized (only used to compute unused signal)
- `calib_button` might be optimized (only used to compute unused signal)

## Solution

Remove `calib_button_monitor` and make `calib_button_edge_top` actually affect an output, similar to `kick_button_edge`.

