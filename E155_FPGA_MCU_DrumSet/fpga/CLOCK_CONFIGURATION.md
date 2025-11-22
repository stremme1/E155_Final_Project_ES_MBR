# Clock Configuration Guide

## Overview

The system uses **HSOSC (High Speed Oscillator)** for hardware implementation, which cannot be simulated in testbenches. Therefore, we use a wrapper module approach:

- **Hardware**: `drum_set_top_wrapper.sv` - Includes HSOSC clock generation
- **Simulation**: `drum_set_top.sv` - Clock generated in testbench

## Hardware Clock (HSOSC)

### Configuration

The `drum_set_top_wrapper.sv` module uses HSOSC to generate the system clock:

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

### Using the Wrapper for Hardware

1. **Set top-level module** to `drum_set_top_wrapper` in your FPGA project
2. **HSOSC is automatically instantiated** and generates the clock
3. **No external clock pin needed** - clock is generated internally
4. **Remove `clk` from pin assignments** - it's not an I/O pin anymore

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

1. **Instantiate `drum_set_top` directly** (not the wrapper)
2. **Generate clock in testbench** (see examples above)
3. **Connect clock to `drum_set_top.clk` input**

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

1. **Use `drum_set_top_wrapper.sv`** as top-level
2. **HSOSC section is active** (uncommented)
3. **Simulation clock section is commented out**

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

1. **Use `drum_set_top.sv`** directly (not wrapper)
2. **Generate clock in testbench**
3. **HSOSC is not used** (cannot be simulated)

## Pin Assignment

### With HSOSC (Hardware - using wrapper):

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
| **Hardware** | `drum_set_top_wrapper` | HSOSC (internal) | 3MHz from 48MHz/16 |
| **Simulation** | `drum_set_top` | Testbench | Generate in testbench |

**Remember**: 
- HSOSC cannot be simulated - use testbench clock for simulation
- Wrapper module automatically handles clock for hardware
- No external clock pin needed when using HSOSC

