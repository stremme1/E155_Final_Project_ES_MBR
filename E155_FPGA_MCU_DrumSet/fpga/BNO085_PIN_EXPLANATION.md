# BNO085 Pin Name Explanation

## Important: SDO is the BNO085 Pin Name, NOT Your FPGA Pin Name

### Understanding the Pin Names

**BNO085 Breakout Board** has these pins (from Adafruit datasheet):
- **DI** = Data In / MOSI (data FROM FPGA TO sensor)
- **SDA** = Data Out / MISO (data FROM sensor TO FPGA)
- **SCL** = SPI Clock (SCK)
- **CS** = Chip Select

**Your FPGA Board** has these pins:
- **P0, P1, P2, etc.** = GPIO pins
- **DI** = Data In pin
- **CS** = Chip Select pin
- etc.

### The Connection

```
BNO085 Breakout Board          Your FPGA Board
─────────────────────          ───────────────
SCL (pin on BNO085)    →      P20 (FPGA sclk1 output)
DI (pin on BNO085)     →      P13 (FPGA mosi1 output)
SDA (pin on BNO085)    →      P12 (FPGA miso1 input)
CS (pin on BNO085)     →      P18 (FPGA cs_n1 output)
```

### Key Point

- **DI** on BNO085 = **MOSI** (data FROM FPGA TO sensor)
- **SDA** on BNO085 = **MISO** (data FROM sensor TO FPGA)
- **DI** and **SDA** are **BNO085's pin names** (what's printed on the breakout board)
- **P13, P12, P20, P18** are your **FPGA's pin names** (what you assign in Radiant)
- You connect: BNO085 **DI** pin → FPGA **P13** (mosi1) pin
- You connect: BNO085 **SDA** pin → FPGA **P12** (miso1) pin

### Final Pin Assignments

**Sensor 1 (Right Hand):**
```
SCLK1:  P20    (BNO085 SCL → FPGA P20)
MOSI1:  P13    (BNO085 DI → FPGA P13)
MISO1:  P12    (BNO085 SDA → FPGA P12)
CS1:    P18    (BNO085 CS → FPGA P18)
```

**Sensor 2 (Left Hand):**
```
SCLK2:  P4     (BNO085 SCL → FPGA P4)
MOSI2:  P47    (BNO085 DI → FPGA P47)
MISO2:  P6     (BNO085 SDA → FPGA P6)
CS2:    P48    (BNO085 CS → FPGA P48)
```

## Summary

- **DI** on BNO085 = **MOSI** (data FROM FPGA TO sensor)
- **SDA** on BNO085 = **MISO** (data FROM sensor TO FPGA)
- **SCL** on BNO085 = **SCK** (SPI clock)
- **CS** on BNO085 = **Chip Select** (active low)

The names are different because:
- BNO085 uses "DI" (Data In from sensor's perspective) for MOSI
- BNO085 uses "SDA" (Serial Data) for MISO (data from sensor)
- FPGA uses "MOSI" (Master Out, Slave In) and "MISO" (Master In, Slave Out)
- They're the same signals, just different naming conventions!
