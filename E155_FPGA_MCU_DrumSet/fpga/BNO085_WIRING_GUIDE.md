# BNO085 Sensor Wiring Guide

## BNO085 Pinout (from Datasheet)

```
BNO085 Breakout Board Pinout:
┌─────────────────┐
│  VIN  GND  RST  │
│  INT   CS  SDA  │
│  DI   SCL  ADR  │
└─────────────────┘

SPI Pin Functions (from Adafruit BNO085 Datasheet):
- VIN:  Power (3.3V or 5V) - Power input with onboard regulator
- GND:  Ground - Common ground
- SCL:  SPI Clock (SCK) - Input to chip, clock signal
- DI:   Data In / MOSI - Data FROM processor TO sensor (FPGA sends data)
- SDA:  Data Out / MISO - Data FROM sensor TO processor (FPGA receives data)
- CS:   Chip Select - Input to chip, pull LOW to start SPI transaction
- INT:  Interrupt - Active Low, indicates sensor needs attention (REQUIRED for stable SPI)
- RST:  Reset - Active Low, pull LOW to GND to reset (REQUIRED for stable SPI)
- ADR:  I2C Address pin (not used in SPI mode)
```

## Wiring Format

### BNO085 Sensor 1 (Right Hand)

| BNO085 Pin | Function | FPGA Signal | FPGA Pin Options | Notes |
|------------|----------|-------------|------------------|-------|
| **SCL** | SPI Clock (SCK) | `sclk1` | P0, P20 | Output: FPGA → Sensor |
| **DI** | Data In / MOSI | `mosi1` | P1, P12 | Output: FPGA → Sensor |
| **SDA** | Data Out / MISO | `miso1` | DI, P13 | Input: Sensor → FPGA |
| **CS** | Chip Select | `cs_n1` | CS, P18 | Output: FPGA → Sensor (needs 10kΩ pull-up) |
| **INT** | Interrupt | - | (unconnected) | Active Low, not used in polling mode |
| **RST** | Reset | - | 3.3V or GND | Active Low, tie to 3.3V (not low) |

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
─────────────────────────────────────────────────────
SCL (SCK)       →    P0 or P20   →    sclk1 (SPI clock)
DI (MOSI)       →    P1 or P12   →    mosi1 (FPGA sends data)
SDA (MISO)      →    DI or P13   →    miso1 (sensor sends data)
CS              →    CS or P18   →    cs_n1 (chip select, with 10kΩ pull-up)
INT             →    (unconnected) →  Not used (polling mode)
RST             →    3.3V        →    Reset (keep HIGH, active LOW)
VIN             →    3.3V or 5V  →    Power supply
GND             →    GND         →    Ground (common)
ADR             →    (unconnected) →  Not used (SPI mode)
```

**Important Notes:**
- **DI** on BNO085 = **MOSI** (data FROM FPGA TO sensor)
- **SDA** on BNO085 = **MISO** (data FROM sensor TO FPGA)
- **DI** and **SDA** are BNO085 pin names, NOT FPGA pin names
- Your FPGA pin named "DI" can be used for MISO (sensor data input)

---

### BNO085 Sensor 2 (Left Hand)

| BNO085 Pin | Function | FPGA Signal | FPGA Pin Options | Notes |
|------------|----------|-------------|------------------|-------|
| **SCL** | SPI Clock (SCK) | `sclk2` | SCL, P2, P21 | Output: FPGA → Sensor |
| **DI** | Data In / MOSI | `mosi2` | SDA, P3, P14 | Output: FPGA → Sensor |
| **SDA** | Data Out / MISO | `miso2` | INT, P4, P15 | Input: Sensor → FPGA |
| **CS** | Chip Select | `cs_n2` | 3BO, P5, P19 | Output: FPGA → Sensor (needs 10kΩ pull-up) |
| **INT** | Interrupt | - | (unconnected) | Active Low, not used in polling mode |
| **RST** | Reset | - | 3.3V or GND | Active Low, tie to 3.3V (not low) |
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
BNO085-2 Pin    →    FPGA Pin    →    FPGA Signal Name
─────────────────────────────────────────────────────
SCL (SCK)       →    SCL or P2 or P21   →    sclk2 (SPI clock)
DI (MOSI)       →    SDA or P3 or P14   →    mosi2 (FPGA sends data)
SDA (MISO)      →    INT or P4 or P15   →    miso2 (sensor sends data)
CS              →    3BO or P5 or P19   →    cs_n2 (chip select, with 10kΩ pull-up)
INT             →    (unconnected)      →    Not used (polling mode)
RST             →    3.3V               →    Reset (keep HIGH, active LOW)
VIN             →    3.3V or 5V         →    Power supply
GND             →    GND                →    Ground (common)
ADR             →    (unconnected)      →    Not used (SPI mode)
```

**Important Notes:**
- **DI** on BNO085 = **MOSI** (data FROM FPGA TO sensor)
- **SDA** on BNO085 = **MISO** (data FROM sensor TO FPGA)
- **DI** and **SDA** are BNO085 pin names, NOT FPGA pin names
- Your FPGA pins (SDA, INT, etc.) are used for the MISO connection

---

## Complete Pin Assignment Summary

### Sensor 1 (Right Hand) - Your Format:
```
SCLK1:  P0,  P20          # BNO085 SCL → FPGA sclk1
MOSI1:  P1,  P12          # BNO085 DI → FPGA mosi1
MISO1:  DI,  P13          # BNO085 SDA → FPGA miso1
CS1:    CS,  P18          # BNO085 CS → FPGA cs_n1
```

### Sensor 2 (Left Hand) - Recommended:
```
SCLK2:  SCL, P2,  P21     # BNO085 SCL → FPGA sclk2
MOSI2:  SDA, P3,  P14     # BNO085 DI → FPGA mosi2
MISO2:  INT, P4,  P15     # BNO085 SDA → FPGA miso2
CS2:    3BO, P5,  P19     # BNO085 CS → FPGA cs_n2
```

**Key Mapping:**
- BNO085 **SCL** → FPGA **SCLK** (clock)
- BNO085 **DI** → FPGA **MOSI** (FPGA sends data)
- BNO085 **SDA** → FPGA **MISO** (sensor sends data)
- BNO085 **CS** → FPGA **CS_N** (chip select)

---

## Important Wiring Notes

### 1. Power Connections
- **VIN**: Connect to **3.3V** (or 5V if sensor supports it)
- **GND**: Connect to **Ground** (common ground with FPGA)
- **RST**: Tie to **3.3V** or leave floating (with pull-up)

### 2. Pull-Up Resistors Required
- **CS pins** (`cs_n1`, `cs_n2`): **10kΩ pull-up to 3.3V** (critical!)
- Without pull-ups, CS may float LOW and accidentally select sensors

### 3. SPI Signal Routing (BNO085 Pin Names)
- **SCL** (on BNO085) → **SCLK** (on FPGA): Clock signal (output from FPGA)
- **DI** (on BNO085) → **MOSI** (on FPGA): Master Out, Slave In (output from FPGA)
- **SDA** (on BNO085) → **MISO** (on FPGA): Master In, Slave Out (input to FPGA)
- **CS** (on BNO085) → **CS_N** (on FPGA): Chip Select (output from FPGA, active LOW)

**Important**: 
- BNO085 uses **DI** for MOSI (not SDA!)
- BNO085 uses **SDA** for MISO (data from sensor)
- Your FPGA pin named "DI" can be used for MISO input (sensor data)

### 4. Unused Pins
- **INT**: Leave unconnected (not used in polling mode, but datasheet says "required for stable SPI" - you may want to connect it)
- **RST**: Tie to 3.3V (keep HIGH, active LOW - datasheet says "required for stable SPI")
- **ADR**: Leave unconnected (not used in SPI mode)

**Note from Datasheet**: INT and RST are marked as "required for stable SPI operation" but our implementation uses polling mode, so INT is optional. RST should be tied HIGH (3.3V) to keep sensor out of reset.

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

- [ ] VIN → 3.3V (or 5V) power supply
- [ ] GND → Ground (common with FPGA)
- [ ] SCL → FPGA pin (sclk1 or sclk2) - SPI clock
- [ ] DI → FPGA pin (mosi1 or mosi2) - FPGA sends data (MOSI)
- [ ] SDA → FPGA pin (miso1 or miso2) - Sensor sends data (MISO)
- [ ] CS → FPGA pin (cs_n1 or cs_n2) **+ 10kΩ pull-up to 3.3V**
- [ ] RST → 3.3V (keep HIGH, active LOW - required for stable SPI)
- [ ] INT → (unconnected, optional - datasheet says required but we use polling)
- [ ] ADR → (unconnected, not used in SPI mode)

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

