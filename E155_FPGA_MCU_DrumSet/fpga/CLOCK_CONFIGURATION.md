# Clock Configuration Guide

## Overview

The system uses **HSOSC (High Speed Oscillator)** for hardware implementation, which cannot be simulated in testbenches. HSOSC is integrated directly into `drum_set_top.sv`:

- **Hardware**: HSOSC section active (uncommented) - generates clock internally
- **Simulation**: Comment out HSOSC, uncomment simulation clock section

## Hardware Clock (HSOSC)

### Configuration

The `drum_set_top.sv` module uses HSOSC to generate the system clock:

```systemverilog
// HSOSC configuration: CLKHF_DIV(2'b11) = divide by 16
// 48MHz / 16 = 3MHz system clock
HSOSC #(.CLKHF_DIV(2'b11)) hf_osc (
    .CLKHFPU(1'b1),   // Power up
    .CLKHFEN(1'b1),   // Enable
    .CLKHF(clk)       // Output clock (3MHz)
);
```

### HSOSC Divider Options

| CLKHF_DIV | Divide By | Output Frequency (from 48MHz) |
|-----------|-----------|-------------------------------|
| `2'b00`   | 2         | 24MHz                         |
| `2'b01`   | 4         | 12MHz                         |
| `2'b10`   | 8         | 6MHz                          |
| `2'b11`   | 16        | 3MHz (current setting)        |

**Current Setting**: `2'b11` (divide by 16) = **3MHz** system clock

This 3MHz clock is suitable for:
- SPI communication (BNO085 max 3MHz)
- MCU SPI communication (typically 1-10MHz)
- All internal logic

### Using HSOSC for Hardware

1. **Set top-level module** to `drum_set_top` in your FPGA project
2. **HSOSC is automatically instantiated** (uncommented by default) and generates the clock
3. **No external clock pin needed** - clock is generated internally
4. **Do not assign `clk` to a pin** - it's an internal signal, not an I/O pin

## Simulation Clock

### Why HSOSC Can't Be Simulated

HSOSC is a hardware primitive that cannot be simulated in standard Verilog/SystemVerilog simulators (Icarus Verilog, Questa, etc.). Therefore, testbenches must generate their own clock.

### Testbench Clock Generation

All testbenches generate a clock signal:

```systemverilog
// Example from tb_calibration.sv
localparam CLK_PERIOD = 20;  // 50MHz clock (20ns period)

initial begin
    clk = 0;
    forever #(CLK_PERIOD/2) clk = ~clk;
end
```

### Using drum_set_top for Simulation

1. **Comment out HSOSC section** in `drum_set_top.sv` (lines 89-93)
2. **Uncomment simulation clock section** in `drum_set_top.sv` (lines 97-101)
3. **Clock is generated internally** - no need to connect from testbench

Example:
```systemverilog
// Clock generation in testbench
logic clk;
initial begin
    clk = 0;
    forever #(CLK_PERIOD/2) clk = ~clk;
end

// Instantiate DUT
drum_set_top dut (
    .clk(clk),  // Clock from testbench
    .rst_n(rst_n),
    // ... other signals
);
```

## Switching Between Hardware and Simulation

### For Hardware Implementation:

1. **Use `drum_set_top.sv`** as top-level
2. **HSOSC section is active** (uncommented, lines 89-93)
3. **Simulation clock section is commented out** (lines 97-101)

```systemverilog
// HARDWARE: Active
HSOSC #(.CLKHF_DIV(2'b11)) hf_osc (
    .CLKHFPU(1'b1),
    .CLKHFEN(1'b1),
    .CLKHF(clk)
);

// SIMULATION: Commented out
/*
initial begin
    clk = 0;
    forever #10000 clk = ~clk;
end
*/
```

### For Simulation:

1. **Use `drum_set_top.sv`** as top-level
2. **Comment out HSOSC section** (lines 89-93)
3. **Uncomment simulation clock section** (lines 97-101)
4. **HSOSC is not used** (cannot be simulated)

## Pin Assignment

### With HSOSC (Hardware):

**DO NOT assign `clk` to a pin** - it's generated internally by HSOSC.

Your constraints file should NOT include:
```pcf
# set_io clk <pin>  # DO NOT include this - clock is internal!
```

### Without HSOSC (if using external clock):

If you need to use an external clock pin instead of HSOSC:

1. Use `drum_set_top.sv` directly (not wrapper)
2. Assign clock pin in constraints:
```pcf
set_io clk <clock_pin>  # External clock pin
```

## Clock Frequency Considerations

### Current Configuration (3MHz from HSOSC):

- **System Clock**: 3MHz
- **SPI Clock Divider**: CLK_DIV = 16
- **SPI Clock Frequency**: 3MHz / 16 = 187.5kHz

**Note**: This is slower than typical SPI speeds. If you need faster SPI:

1. **Change HSOSC divider** to get higher system clock:
   - `2'b10` (divide by 8) = 6MHz system clock
   - `2'b01` (divide by 4) = 12MHz system clock
   - `2'b00` (divide by 2) = 24MHz system clock

2. **Adjust CLK_DIV in SPI modules** to maintain desired SPI frequency:
   ```systemverilog
   // For 3MHz SPI from 6MHz system clock:
   parameter CLK_DIV = 2;  // 6MHz / 2 = 3MHz SPI
   ```

## Troubleshooting

### Clock Not Working in Hardware:

1. **Check HSOSC instantiation** - Make sure it's uncommented in wrapper
2. **Verify CLKHFPU and CLKHFEN** - Both should be `1'b1`
3. **Check CLKHF_DIV setting** - Current: `2'b11` (divide by 16)
4. **Verify top-level module** - Should be `drum_set_top_wrapper`

### Clock Issues in Simulation:

1. **Make sure you're using `drum_set_top`** (not wrapper)
2. **Check clock generation in testbench** - Should toggle every CLK_PERIOD/2
3. **Verify clock is connected** - `dut.clk` should be driven by testbench

### SPI Too Slow:

- **Increase system clock** by changing HSOSC divider
- **Decrease CLK_DIV** in SPI modules to maintain SPI frequency

## Summary

| Mode | Top Module | Clock Source | Notes |
|------|------------|--------------|-------|
| **Hardware** | `drum_set_top` | HSOSC (internal) | 3MHz from 48MHz/16, uncomment HSOSC section |
| **Simulation** | `drum_set_top` | Simulation clock | Comment out HSOSC, uncomment simulation clock |

**Remember**: 
- HSOSC cannot be simulated - comment it out and use simulation clock section
- HSOSC is integrated directly in `drum_set_top.sv` - no wrapper needed
- No external clock pin needed when using HSOSC
- Reset pin: P43 (active LOW - goes LOW to reset)

