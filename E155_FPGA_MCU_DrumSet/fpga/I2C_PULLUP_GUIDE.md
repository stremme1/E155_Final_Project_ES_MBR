# I2C Pull-Up Resistor Guide

## Can You Use Internal Pull-Ups for I2C?

**Short Answer**: It depends on your I2C speed and bus capacitance, but **external 10kΩ pull-ups are recommended** for reliable operation at 400kHz.

## Internal vs External Pull-Ups

### Internal Pull-Ups (FPGA)

**Availability**:
- iCE40 FPGAs support weak internal pull-up resistors on GPIO pins
- Typical resistance: **50kΩ to 100kΩ** (much weaker than I2C standard)
- Can be enabled via pin assignment constraints

**Limitations**:
- **Too weak for standard I2C**: I2C specification recommends 1kΩ to 10kΩ pull-ups
- **Slow rise time**: Weak pull-ups cause slow signal rise times
- **Limited current drive**: May not meet I2C timing requirements at higher speeds
- **Bus capacitance**: Internal pull-ups may not work well with longer wires or multiple devices

**When Internal Pull-Ups Might Work**:
- Very short I2C traces (< 10cm)
- Single device on bus (low capacitance)
- Low I2C speed (≤ 100kHz)
- Short wires, minimal capacitance

### External Pull-Ups (Recommended)

**Advantages**:
- **Proper resistance**: 10kΩ is standard for I2C
- **Fast rise time**: Meets I2C timing specifications
- **Reliable at 400kHz**: Works well at high I2C speeds
- **Handles bus capacitance**: Works with longer wires and multiple devices
- **Industry standard**: Recommended by I2C specification

**When External Pull-Ups Are Required**:
- I2C speed ≥ 400kHz (your case)
- Multiple devices on bus
- Longer wires/traces
- Reliable operation needed

## I2C Pull-Up Requirements

### I2C Specification

According to I2C specification:
- **Pull-up resistance**: 1kΩ to 10kΩ (typically 4.7kΩ or 10kΩ)
- **Rise time**: Must meet timing requirements based on bus capacitance
- **Voltage**: Pull-up to VCC (3.3V in your case)

### Calculation

For 400kHz I2C:
- **Maximum rise time**: ~300ns (for 400kHz Fast Mode)
- **Bus capacitance**: Depends on wire length and devices
- **Pull-up value**: Lower resistance = faster rise time, but more current

**Formula**:
```
R_pullup ≤ (t_rise) / (0.8473 × C_bus)
```

Where:
- `t_rise` = maximum rise time (300ns for 400kHz)
- `C_bus` = total bus capacitance (typically 100-400pF)

**Example**:
- If C_bus = 200pF: R_pullup ≤ 1.77kΩ
- If C_bus = 400pF: R_pullup ≤ 885Ω

**Standard practice**: Use **10kΩ** for most applications (works for bus capacitance up to ~400pF)

## For Your Application (BNO055 at 400kHz)

### Recommendation: **Use 10kΩ Pull-Ups (On-Board or External)**

**Best Option**: **On-Board 10kΩ Pull-Ups** (if available)
- ✅ **Perfect value**: 10kΩ is ideal for 400kHz I2C
- ✅ **Already installed**: No additional components needed
- ✅ **Properly placed**: Usually placed optimally on PCB
- ✅ **Verified**: Board manufacturer has tested them

**Alternative**: **External 10kΩ Pull-Ups** (if on-board not available)
- ✅ Works perfectly for 400kHz I2C
- Requires 4 resistors (2 for I2C1, 2 for I2C2)

### Internal Pull-Ups: **Not Recommended**

**Why Not**:
1. **Too Weak**: 50kΩ-100kΩ is 5-10x weaker than recommended
2. **Slow Rise Time**: May violate I2C timing at 400kHz
3. **Unreliable**: May cause communication errors or failures
4. **BNO055 Sensitivity**: BNO055 has tight I2C timing requirements

## How to Enable Internal Pull-Ups (If You Want to Try)

**Note**: This is **NOT recommended** for 400kHz I2C, but here's how if you want to experiment:

### In Pin Assignment File (.pdc)

```tcl
# I2C1 Pull-ups (NOT RECOMMENDED for 400kHz)
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to I2C1_SCL
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to I2C1_SDA

# I2C2 Pull-ups (NOT RECOMMENDED for 400kHz)
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to I2C2_SCL
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to I2C2_SDA
```

**Important**: 
- Internal pull-ups are **weak** (~50kΩ-100kΩ)
- May not work reliably at 400kHz
- Test thoroughly if you use them

## On-Board Pull-Ups (Best Option)

### If Your Board Has 10kΩ Pull-Ups

**Advantages**:
- ✅ **Perfect value**: 10kΩ is ideal for 400kHz I2C
- ✅ **No additional components**: Already installed on board
- ✅ **Properly placed**: Optimally located on PCB
- ✅ **Tested**: Board manufacturer has verified them

### How to Verify On-Board Pull-Ups

1. **Check board schematic**: Look for 10kΩ resistors on I2C lines
2. **Check board documentation**: Many development boards list pull-ups
3. **Measure resistance** (with power OFF):
   - Measure between I2C_SCL pin and 3.3V (should read ~10kΩ)
   - Measure between I2C_SDA pin and 3.3V (should read ~10kΩ)
4. **Test I2C communication**: If I2C works without external pull-ups, they're likely on-board

### If On-Board Pull-Ups Are Present

- ✅ **No action needed** - you're all set!
- ✅ **Just connect BNO055 sensors** to I2C pins
- ✅ **Verify connections** match your pin assignments

## External Pull-Up Implementation (If Needed)

### Standard Configuration

**For each I2C bus** (I2C1 and I2C2):

```
3.3V
  |
  |
10kΩ Resistor
  |
  |
I2C_SCL (or I2C_SDA)
  |
  |
BNO055 SCL (or SDA)
```

### Component Values

- **Resistance**: 10kΩ (standard) or 4.7kΩ (stronger, faster)
- **Power Rating**: 1/16W or 1/8W is sufficient
- **Type**: Standard through-hole or surface-mount resistor

### Placement

- **Close to FPGA**: Place pull-ups near FPGA I2C pins
- **One per line**: One 10kΩ resistor per SCL, one per SDA
- **Total needed**: 4 resistors (2 for I2C1, 2 for I2C2)

### Example Circuit

```
I2C1 Bus:
  3.3V ──[10kΩ]── I2C1_SCL ── BNO055_1_SCL
  3.3V ──[10kΩ]── I2C1_SDA ── BNO055_1_SDA

I2C2 Bus:
  3.3V ──[10kΩ]── I2C2_SCL ── BNO055_2_SCL
  3.3V ──[10kΩ]── I2C2_SDA ── BNO055_2_SDA
```

## Testing Pull-Up Configuration

### If Using Internal Pull-Ups

1. **Test at lower speed first**: Try 100kHz to see if it works
2. **Monitor I2C signals**: Use oscilloscope to check rise times
3. **Check for errors**: Monitor for I2C communication errors
4. **Verify timing**: Ensure signals meet I2C timing requirements

### If Using External Pull-Ups

1. **Verify resistance**: Measure pull-up resistor values (should be ~10kΩ)
2. **Check connections**: Ensure pull-ups connect to 3.3V and I2C lines
3. **Test communication**: Verify I2C transactions complete successfully
4. **Monitor signals**: Use oscilloscope to verify proper I2C waveforms

## Troubleshooting

### I2C Communication Fails

**Possible Causes**:
1. **No pull-ups**: Signals float, can't drive high
2. **Weak pull-ups**: Internal pull-ups too weak for 400kHz
3. **Wrong value**: Pull-up resistance too high or too low
4. **Missing connection**: Pull-up not connected to 3.3V

**Solutions**:
1. Add external 10kΩ pull-ups
2. Verify pull-ups are connected to 3.3V
3. Check I2C signal integrity with oscilloscope
4. Reduce I2C speed to 100kHz if using internal pull-ups

### Slow I2C Operation

**Possible Causes**:
1. **Weak pull-ups**: Internal pull-ups causing slow rise time
2. **High bus capacitance**: Long wires or multiple devices
3. **Insufficient pull-up strength**: Need stronger pull-ups

**Solutions**:
1. Use external 10kΩ pull-ups (or 4.7kΩ for faster)
2. Reduce wire length
3. Check bus capacitance

## Summary

| Configuration | Pull-Up Type | Resistance | Works at 400kHz? | Recommendation |
|---------------|--------------|------------|------------------|----------------|
| Internal (FPGA) | Weak | ~50kΩ-100kΩ | ❌ No | Not recommended |
| **On-Board** | **Standard** | **10kΩ** | ✅ **Yes** | **✅ BEST OPTION** |
| External | Standard | 10kΩ | ✅ Yes | Recommended if no on-board |
| External | Strong | 4.7kΩ | ✅ Yes | Alternative option |

## Final Recommendation

**For your BNO055 application at 400kHz**:

### If You Have On-Board 10kΩ Pull-Ups (Your Case):
- ✅ **Use on-board 10kΩ pull-ups** - Perfect for 400kHz I2C
- ✅ **No additional components needed**
- ✅ **Verify they're connected** to I2C1 and I2C2 pins
- ✅ **Check board schematic** to confirm pull-up locations

### If You Don't Have On-Board Pull-Ups:
- ✅ **Use external 10kΩ pull-up resistors**
- ❌ **Do NOT rely on internal FPGA pull-ups**
- ✅ **Place pull-ups close to FPGA I2C pins**
- ✅ **One pull-up per SCL and SDA line** (4 total: 2 for I2C1, 2 for I2C2)

### How to Verify On-Board Pull-Ups:

1. **Check board schematic**: Look for 10kΩ resistors on I2C lines
2. **Measure resistance**: With power off, measure between I2C pin and 3.3V
3. **Check board documentation**: Many development boards include pull-ups
4. **Test I2C communication**: If I2C works without external pull-ups, they're likely on-board

This ensures reliable I2C communication and meets I2C timing specifications.

