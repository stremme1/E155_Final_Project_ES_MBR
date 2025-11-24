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

## BNO085 Sensor 1 (Right Hand)

**Hardware Wiring:**
```
BNO085-1 Pin    →    FPGA Pin    →    FPGA Signal Name
─────────────────────────────────────────────────────
SCL (SCK)       →    P20          →    sclk1 (SPI clock)
DI (MOSI)       →    P13          →    mosi1 (FPGA sends data)
SDA (MISO)      →    P12          →    miso1 (sensor sends data)
CS              →    P18          →    cs_n1 (chip select, with 10kΩ pull-up)
INT             →    P9          →    int1 (REQUIRED for stable SPI - active LOW)
RST             →    3.3V         →    Reset (keep HIGH, active LOW)
P0              →    3.3V         →    Mode select (HIGH for SPI mode) - CRITICAL!
P1              →    3.3V         →    Mode select (HIGH for SPI mode) - CRITICAL!
VIN             →    3.3V or 5V   →    Power supply
GND             →    GND          →    Ground (common)
ADR             →    (unconnected) →  Not used (SPI mode)
```

**CRITICAL:** 
- **P0 and P1 MUST be HIGH (3.3V) for SPI mode** - Without this, sensor will be in I2C mode!
- **INT pin is REQUIRED** - Adafruit documentation states it's required for stable SPI operation

**Important Notes:**
- **DI** on BNO085 = **MOSI** (data FROM FPGA TO sensor)
- **SDA** on BNO085 = **MISO** (data FROM sensor TO FPGA)
- **DI** and **SDA** are BNO085 pin names, NOT FPGA pin names
- Your FPGA pin named "DI" can be used for MISO (sensor data input)

---

## BNO085 Sensor 2 (Left Hand)

**Hardware Wiring:**
```
BNO085-2 Pin    →    FPGA Pin    →    FPGA Signal Name
─────────────────────────────────────────────────────
SCL (SCK)       →    P4           →    sclk2 (SPI clock)
DI (MOSI)       →    P47          →    mosi2 (FPGA sends data)
SDA (MISO)      →    P6           →    miso2 (sensor sends data)
CS              →    P48          →    cs_n2 (chip select, with 10kΩ pull-up)
INT             →    P3          →    int2 (REQUIRED for stable SPI - active LOW)
RST             →    3.3V         →    Reset (keep HIGH, active LOW)
P0              →    3.3V         →    Mode select (HIGH for SPI mode) - CRITICAL!
P1              →    3.3V         →    Mode select (HIGH for SPI mode) - CRITICAL!
VIN             →    3.3V or 5V   →    Power supply
GND             →    GND          →    Ground (common)
ADR             →    (unconnected) →    Not used (SPI mode)
```

**CRITICAL:** 
- **P0 and P1 MUST be HIGH (3.3V) for SPI mode** - Without this, sensor will be in I2C mode!
- **INT pin is REQUIRED** - Adafruit documentation states it's required for stable SPI operation

**Important Notes:**
- **DI** on BNO085 = **MOSI** (data FROM FPGA TO sensor)
- **SDA** on BNO085 = **MISO** (data FROM sensor TO FPGA)
- **DI** and **SDA** are BNO085 pin names, NOT FPGA pin names
- Your FPGA pins (SDA, INT, etc.) are used for the MISO connection

