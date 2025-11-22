# BNO085 Sensor Wiring Guide

## BNO085 Pinout (from Datasheet)

```
BNO085 Breakout Board Pinout:
┌─────────────────┐
│  VIN  GND  RST  │
│  INT   CS  SDO  │
│  SDA  SCL  ADR  │
└─────────────────┘

Pin Functions (BNO085 Breakout Board):
- VIN:  Power (3.3V or 5V) → Connect to 3.3V
- GND:  Ground → Connect to GND
- SCL:  SPI Clock (also called SCK) → Connect to FPGA sclk1/sclk2 pin
- SDA:  SPI Master Out (MOSI) → Connect to FPGA mosi1/mosi2 pin
- SDO:  SPI Master In (MISO) → Connect to FPGA miso1/miso2 pin
- CS:   Chip Select (active low) → Connect to FPGA cs_n1/cs_n2 pin
- INT:  Interrupt (optional, not used) → Leave unconnected
- RST:  Reset (optional) → Tie to 3.3V or leave floating
- ADR:  I2C Address (not used in SPI mode) → Leave unconnected

Note: SDO on BNO085 = MISO (Master In, Slave Out)
      This is the pin that sends data FROM sensor TO FPGA
      Connect to your FPGA's MISO input pin (DI, P13, etc.)
```

## Wiring Format

### BNO085 Sensor 1 (Right Hand)

| BNO085 Pin | Function | FPGA Signal | FPGA Pin Options | Notes |
|------------|----------|-------------|------------------|-------|
| **SCL** (or SCK) | SPI Clock | `sclk1` | P0, P20 | Output: FPGA → Sensor |
| **SDA** (or MOSI) | SPI Master Out | `mosi1` | P1, P12 | Output: FPGA → Sensor |
| **SDO** (or MISO) | SPI Master In | `miso1` | DI, P13 | Input: Sensor → FPGA |
| **CS** | Chip Select | `cs_n1` | CS, P18 | Output: FPGA → Sensor (needs 10kΩ pull-up) |

| **VIN** | Power | - | 3.3V | Power supply |
| **GND** | Ground | - | GND | Ground connection |
| **RST** | Reset | - | 3.3V or floating | Optional (tie high) |
| **INT** | Interrupt | - | Unconnected | Not used (polling mode) |
| **ADR** | I2C Address | - | Unconnected | Not used (SPI mode) |

**Radiant Constraints:**
```pcf
# BNO085 Sensor 1 (Right Hand)
set_io sclk1   P0              # Or P20
set_io mosi1   P1              # Or P12
set_io miso1   DI              # Or P13
set_io cs_n1   CS              # Or P18
```

**Hardware Wiring:**
```
BNO085-1 Pin    →    FPGA Pin    →    FPGA Signal Name
──────────────────────────────────────────────────────
SCL (SCK)       →    P0 or P20   →    sclk1 (output)
SDA (MOSI)      →    P1 or P12   →    mosi1 (output)
SDO (MISO)      →    DI or P13   →    miso1 (input)
CS              →    CS or P18   →    cs_n1 (output, with 10kΩ pull-up)
VIN             →    3.3V        →    Power supply
GND             →    GND         →    Ground (common)
RST             →    3.3V        →    Reset (tie high)
INT             →    (unconnected) →   Not used
ADR             →    (unconnected) →  Not used (SPI mode)
```

**Important**: 
- **SDO** on BNO085 breakout = **MISO** (data FROM sensor TO FPGA)
- Connect BNO085 **SDO** pin → FPGA **MISO input** pin (DI, P13, etc.)
- This is NOT a position/pin name on your FPGA - it's the BNO085 pin name
- Your FPGA receives this data on its MISO input pin

---

### BNO085 Sensor 2 (Left Hand)

| BNO085 Pin | Function | FPGA Signal | Pin Options | Notes |
|------------|----------|-------------|-------------|-------|
| **SCL** | SPI Clock | `sclk2` | SCL, P2, P21 | Output from FPGA |
| **SDA** | SPI MOSI | `mosi2` | SDA, P3, P14 | Output from FPGA |
| **SDO** | SPI MISO | `miso2` | INT, P4, P15 | Input to FPGA |
| **CS** | Chip Select | `cs_n2` | 3BO, P5, P19 | Output from FPGA (needs 10kΩ pull-up) |
| **VIN** | Power | - | 3.3V | Power supply |
| **GND** | Ground | - | GND | Ground connection |
| **RST** | Reset | - | 3.3V or floating | Optional (tie high) |
| **INT** | Interrupt | - | Unconnected | Not used (polling mode) |
| **ADR** | I2C Address | - | Unconnected | Not used (SPI mode) |

**Radiant Constraints:**
```pcf
# BNO085 Sensor 2 (Left Hand)
set_io sclk2   SCL             # Or P2, P21 (if SCL can't be GPIO)
set_io mosi2   SDA             # Or P3, P14 (if SDA can't be GPIO)
set_io miso2   INT             # Or P4, P15 (if INT can't be GPIO)
set_io cs_n2   3BO             # Or P5, P19
```

**Hardware Wiring:**
```
BNO085-2 Pin    →    FPGA Pin    →    Signal Name
─────────────────────────────────────────────────
SCL (SCK)       →    SCL or P2 or P21   →    sclk2
SDA (MOSI)      →    SDA or P3 or P14   →    mosi2
SDO (MISO)      →    INT or P4 or P15   →    miso2
CS              →    3BO or P5 or P19   →    cs_n2 (with 10kΩ pull-up to 3.3V)
VIN             →    3.3V               →    Power
GND             →    GND                →    Ground
RST             →    3.3V               →    Reset (tie high)
INT             →    (unconnected)
ADR             →    (unconnected)
```

---

## Complete Pin Assignment Summary

### Sensor 1 (Right Hand) - Your Format:
```
SCLK1:  P0,  P20
MOSI1:  P1,  P12
MISO1:  DI,  P13
CS1:    CS,  P18
```

### Sensor 2 (Left Hand) - Recommended:
```
SCLK2:  SCL, P2,  P21
MOSI2:  SDA, P3,  P14
MISO2:  INT, P4,  P15
CS2:    3BO, P5,  P19
```

**Note**: 
- BNO085 **SDO** pin connects to FPGA **MISO2** input
- BNO085 **SDA** pin connects to FPGA **MOSI2** output
- BNO085 **SCL** pin connects to FPGA **SCLK2** output
- BNO085 **CS** pin connects to FPGA **CS2** output

---

## Important Wiring Notes

### 1. Power Connections
- **VIN**: Connect to **3.3V** (or 5V if sensor supports it)
- **GND**: Connect to **Ground** (common ground with FPGA)
- **RST**: Tie to **3.3V** or leave floating (with pull-up)

### 2. Pull-Up Resistors Required
- **CS pins** (`cs_n1`, `cs_n2`): **10kΩ pull-up to 3.3V** (critical!)
- Without pull-ups, CS may float LOW and accidentally select sensors

### 3. SPI Signal Routing
- **SCLK**: Clock signal (output from FPGA)
- **MOSI**: Master Out, Slave In (output from FPGA)
- **MISO**: Master In, Slave Out (input to FPGA)
- **CS**: Chip Select (output from FPGA, active LOW)

### 4. Unused Pins
- **INT**: Leave unconnected (not used in polling mode)
- **ADR**: Leave unconnected (not used in SPI mode)

---

## Complete Radiant Constraints File Example

```pcf
# System
set_io clk     <clock_pin>     # Check board docs
set_io rst_n   Reset

# BNO085 Sensor 1 (Right Hand)
set_io sclk1   P0              # Or P20
set_io mosi1   P1              # Or P12
set_io miso1   DI              # Or P13
set_io cs_n1   CS              # Or P18

# BNO085 Sensor 2 (Left Hand)
set_io sclk2   SCL             # Or P2, P21 (if SCL can be GPIO)
set_io mosi2   SDA             # Or P3, P14 (if SDA can be GPIO)
set_io miso2   INT             # Or P4, P15 (if INT can be GPIO)
set_io cs_n2   3BO             # Or P5, P19

# User Interface
set_io calib_button  BT

# MCU SPI (need additional pins)
set_io mcu_sclk      <pin>
set_io mcu_mosi      <pin>
set_io mcu_cs_n      <pin>
```

---

## Physical Wiring Checklist

For each BNO085 sensor:

- [ ] VIN → 3.3V power supply
- [ ] GND → Ground (common with FPGA)
- [ ] SCL → FPGA pin (sclk1 or sclk2)
- [ ] SDA → FPGA pin (mosi1 or mosi2)
- [ ] SDO → FPGA pin (miso1 or miso2)
- [ ] CS → FPGA pin (cs_n1 or cs_n2) **+ 10kΩ pull-up to 3.3V**
- [ ] RST → 3.3V (or leave floating)
- [ ] INT → (unconnected)
- [ ] ADR → (unconnected)

---

## Troubleshooting

**Sensor not responding:**
- Check power (VIN = 3.3V)
- Verify CS pull-up resistor (10kΩ to 3.3V)
- Check SPI wiring (SCL, SDA, SDO, CS)
- Verify ground connection

**Wrong data:**
- Check MISO/MOSI not swapped
- Verify CS polarity (active low)
- Check SPI mode (Mode 3: CPOL=1, CPHA=1)

**CS always low:**
- Missing pull-up resistor on CS pin
- Add 10kΩ pull-up to 3.3V

