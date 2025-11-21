# SPI Testing Guide

## Overview

This guide explains how to test the SPI-to-MCU functionality in simulation. The SPI module sends sound codes (0-7) from the FPGA to an MCU.

## SPI Protocol

- **Mode**: SPI Mode 0 (CPOL=0, CPHA=0)
  - Clock idle low
  - Data sampled on rising edge of SCLK
  - Data changed on falling edge of SCLK
- **Data Format**: 8-bit byte, MSB first
- **Format**: `0000XXXX` where XXXX is the sound code (0-7)

## Testing Strategy

### 1. Direct Signal Monitoring

The simplest way to test SPI is to directly monitor the SPI signals:
- **CS_N**: Should go low when transfer starts, high when complete
- **SCLK**: Should toggle 8 times during transfer
- **MOSI**: Should output the data bits MSB first

### 2. Manual Receiver

Create a simple receiver that samples MOSI on SCLK rising edges:

```systemverilog
logic [7:0] rx_shift;
logic [2:0] bit_cnt;

always_ff @(posedge clk) begin
    if (!mcu_cs_n && mcu_sclk && !sclk_prev) begin
        // SCLK rising edge during transfer
        rx_shift <= {rx_shift[6:0], mcu_mosi};
        bit_cnt <= bit_cnt + 1;
    end
    if (mcu_cs_n && !cs_prev) begin
        // CS rising edge - transfer complete
        rx_data <= rx_shift;
    end
end
```

### 3. Testbench Structure

A good testbench should:
1. **Reset**: Initialize all signals
2. **Wait for ready**: Ensure SPI master is in IDLE state
3. **Send data**: Assert `data_valid` with `sound_code`
4. **Monitor CS**: Wait for CS to go low (transfer start)
5. **Monitor SCLK**: Count 8 clock cycles
6. **Monitor CS**: Wait for CS to go high (transfer complete)
7. **Verify data**: Check that received data matches expected

## Common Issues

### Issue 1: Transfer Never Starts

**Symptoms**: CS never goes low, `busy` never asserts

**Causes**:
- `data_valid_edge` not detected properly
- State machine stuck in IDLE

**Fix**: Ensure `data_valid` has a proper rising edge:
```systemverilog
data_valid = 0;
#(CLK_PERIOD * 2);
data_valid = 1;
#(CLK_PERIOD);
data_valid = 0;
```

### Issue 2: Transfer Starts But Never Completes

**Symptoms**: CS goes low but never goes high, SCLK keeps toggling

**Causes**:
- Bit counter not incrementing
- State machine stuck in TX_DATA

**Fix**: Check that `clk_cnt` and `bit_cnt` are incrementing correctly

### Issue 3: Wrong Data Received

**Symptoms**: CS toggles correctly but wrong data on MOSI

**Causes**:
- Data not shifted correctly
- Wrong bit order (MSB vs LSB)

**Fix**: Verify `tx_shift` is shifting MSB first: `{tx_shift[6:0], 1'b0}`

## Testbench Example

```systemverilog
// Simple testbench that monitors signals directly
initial begin
    // Reset
    rst_n = 0;
    #(CLK_PERIOD * 10);
    rst_n = 1;
    #(CLK_PERIOD * 10);
    
    // Send sound code 0
    sound_code = 4'd0;
    data_valid = 0;
    #(CLK_PERIOD * 2);
    data_valid = 1;
    #(CLK_PERIOD);
    data_valid = 0;
    
    // Wait for CS to go low
    wait(!mcu_cs_n);
    $display("Transfer started");
    
    // Wait for CS to go high
    wait(mcu_cs_n);
    $display("Transfer complete");
    
    // Check received data (from manual receiver)
    if (rx_data == 8'h00) begin
        $display("PASS: Received 0x00");
    end else begin
        $display("FAIL: Received 0x%02X, expected 0x00", rx_data);
    end
end
```

## Verification Checklist

- [ ] CS goes low when `data_valid` is asserted
- [ ] SCLK toggles exactly 8 times during transfer
- [ ] MOSI outputs correct data bits (MSB first)
- [ ] CS goes high after 8 bits
- [ ] `busy` signal is high during transfer, low otherwise
- [ ] Multiple transfers work correctly (not just first one)
- [ ] Received data matches transmitted data

## Running Tests

```bash
# Compile
iverilog -g2012 -o tb_test spi_to_mcu.sv tb_spi_simple.sv

# Run
vvp tb_test

# Or with output
vvp tb_test | head -100
```

## Debugging Tips

1. **Add $display statements** to track state transitions
2. **Monitor all SPI signals** (CS, SCLK, MOSI)
3. **Check bit counter** - should count 0-7
4. **Check clock counter** - should count 0 to CLK_DIV-1
5. **Verify state machine** transitions correctly

## Expected Behavior

For a sound code of 5 (0x05):
1. `data_valid` goes high → state transitions to CS_ASSERT
2. CS goes low → state transitions to TX_DATA
3. SCLK toggles 8 times, MOSI outputs: `00000101` (MSB first)
4. After 8 bits → state transitions to CS_DEASSERT
5. CS goes high → state transitions to DONE
6. After delay → state returns to IDLE

The received byte should be `0x05` (or `0x05` in lower 4 bits if upper bits are set).


