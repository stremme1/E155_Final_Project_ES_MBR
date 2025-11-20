# DSP Block Usage Guide

## iCE40UP5K DSP Blocks

- **8 DSP blocks** available
- **16-bit x 16-bit multiplier** with 32-bit accumulator
- **Perfect for** gyro data processing and gesture calculations

## Usage in This Design

### 1. Gyro Data Filtering
- **Purpose**: Low-pass filter gyro data to reduce noise
- **Operation**: Multiply gyro value by filter coefficient
- **DSP Blocks**: 1-2 blocks (one per axis if needed)
- **Example**: `filtered = (gyro * alpha) + (prev_filtered * (1-alpha))`

### 2. Gesture Recognition Calculations
- **Purpose**: Calculate gesture thresholds and comparisons
- **Operation**: Multiply gyro values, accumulate for velocity
- **DSP Blocks**: 1-2 blocks
- **Example**: `velocity = velocity + (gyro * dt)`

### 3. Threshold Comparisons
- **Purpose**: Compare filtered gyro data to thresholds
- **Operation**: Multiply by scaling factors
- **DSP Blocks**: Can use DSP for scaling, then compare

## DSP Block Instantiation

```systemverilog
// Example: 16-bit x 16-bit multiply with accumulator
SB_MAC16 #(
    .NEG_TRIGGER(1'b0),
    .C_REG(1'b0),
    .A_REG(1'b1),
    .B_REG(1'b1),
    .D_REG(1'b0),
    .TOP_8x8_MULT_REG(1'b0),
    .BOT_8x8_MULT_REG(1'b0),
    .PIPELINE_16x16_MULT_REG1(1'b0),
    .PIPELINE_16x16_MULT_REG2(1'b0),
    .TOPOUTPUT_SELECT(2'b00),
    .TOPADDSUB_LOWERINPUT(2'b00),
    .TOPADDSUB_UPPERINPUT(1'b0),
    .TOPADDSUB_CARRYSELECT(2'b00),
    .BOTOUTPUT_SELECT(2'b00),
    .BOTADDSUB_LOWERINPUT(2'b00),
    .BOTADDSUB_UPPERINPUT(1'b0),
    .BOTADDSUB_CARRYSELECT(2'b00),
    .MODE_8x8(1'b0),
    .A_SIGNED(1'b1),
    .B_SIGNED(1'b1)
) dsp_inst (
    .CLK(clk),
    .CE(1'b1),
    .A(gyro_data),
    .B(filter_coeff),
    .C(32'h0),
    .D(16'h0),
    .AHOLD(1'b0),
    .BHOLD(1'b0),
    .CHOLD(1'b0),
    .DHOLD(1'b0),
    .IRSTTOP(1'b0),
    .IRSTBOT(1'b0),
    .ORSTTOP(1'b0),
    .ORSTBOT(1'b0),
    .OLOADTOP(1'b0),
    .OLOADBOT(1'b0),
    .ADDSUBTOP(1'b0),
    .ADDSUBBOT(1'b0),
    .OHOLDTOP(1'b0),
    .OHOLDBOT(1'b0),
    .CI(1'b0),
    .ACCUMCI(1'b0),
    .SIGNEXTIN(1'b0),
    .O(mult_result)
);
```

## Resource Savings

Using DSP blocks instead of LUTs for multiplication:
- **Saves ~100-200 LUTs per multiplier**
- **Faster operation** (dedicated hardware)
- **More efficient** for 16-bit operations

