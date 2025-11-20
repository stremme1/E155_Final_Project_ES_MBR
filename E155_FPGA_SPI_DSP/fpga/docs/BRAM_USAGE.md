# BRAM Usage Guide

## iCE40UP5K BRAM

- **120 kb EBR** (Embedded Block RAM) available
- **30 EBR blocks** (4 kb each)
- **Fast access** - single cycle read/write
- **Configurable** as RAM, ROM, or FIFO

## Usage in This Design

### 1. Gyro Data Buffer
- **Purpose**: Store recent gyro samples for filtering/analysis
- **Size**: 256-512 samples (16-bit each) = 512-1024 bytes
- **Type**: Single-port RAM
- **Usage**: Circular buffer for moving average filter

### 2. Filter Coefficients
- **Purpose**: Store filter coefficients for DSP operations
- **Size**: ~64-128 bytes
- **Type**: ROM (read-only, initialized at synthesis)
- **Usage**: Lookup table for filter coefficients

### 3. Gesture Thresholds
- **Purpose**: Store gesture recognition thresholds
- **Size**: ~32-64 bytes
- **Type**: ROM
- **Usage**: Threshold values for different gestures

## BRAM Instantiation

```systemverilog
// Example: 256x16 Single-port RAM
SB_RAM256x16 #(
    .INIT_0(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_1(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_2(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_3(256'h0000000000000000000000000000000000000000000000000000000000000000)
) gyro_buffer (
    .RDATA(gyro_data_out),
    .RADDR(buffer_addr),
    .RCLK(clk),
    .RCLKE(1'b1),
    .RE(1'b1),
    .WADDR(buffer_addr),
    .WCLK(clk),
    .WCLKE(1'b1),
    .WDATA(gyro_data_in),
    .WE(write_enable)
);
```

## Resource Savings

Using BRAM instead of LUTs for storage:
- **Saves ~1000+ LUTs** for large buffers
- **Faster access** than distributed RAM
- **More efficient** for sequential data

## Memory Map

- **0x000-0x1FF**: Gyro data buffer (512 samples)
- **0x200-0x23F**: Filter coefficients (64 bytes)
- **0x240-0x27F**: Gesture thresholds (64 bytes)
- **Remaining**: Available for future use

