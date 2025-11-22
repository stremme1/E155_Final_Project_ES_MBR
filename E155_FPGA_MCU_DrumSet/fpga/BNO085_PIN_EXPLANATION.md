# BNO085 Pin Name Explanation

## Important: SDO is the BNO085 Pin Name, NOT Your FPGA Pin Name

### Understanding the Pin Names

**BNO085 Breakout Board** has these pins:
- **SDO** = Serial Data Out (from BNO085's perspective)
- **SDA** = Serial Data (MOSI from FPGA's perspective)  
- **SCL** = Serial Clock
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
SDO (pin on BNO085)    →      DI or P13 (FPGA MISO input)
SDA (pin on BNO085)    →      P1 or P12 (FPGA MOSI output)
SCL (pin on BNO085)    →      P0 or P20 (FPGA SCLK output)
CS (pin on BNO085)     →      CS or P18 (FPGA CS output)
```

### Key Point

- **SDO** is the **BNO085's pin name** (what's printed on the breakout board)
- **DI** or **P13** is your **FPGA's pin name** (what you assign in Radiant)
- You connect: BNO085 **SDO** pin → FPGA **DI** (or P13) pin

### In Your Format

**Sensor 1:**
```
SCLK1:  P0,  P20    (BNO085 SCL → FPGA P0 or P20)
MOSI1:  P1,  P12    (BNO085 SDA → FPGA P1 or P12)
MISO1:  DI,  P13    (BNO085 SDO → FPGA DI or P13) ← This is the connection!
CS1:    CS,  P18    (BNO085 CS → FPGA CS or P18)
```

**Sensor 2:**
```
SCLK2:  SCL, P2,  P21    (BNO085 SCL → FPGA SCL or P2 or P21)
MOSI2:  SDA, P3,  P14    (BNO085 SDA → FPGA SDA or P3 or P14)
MISO2:  INT, P4,  P15    (BNO085 SDO → FPGA INT or P4 or P15) ← This is the connection!
CS2:    3BO, P5,  P19    (BNO085 CS → FPGA 3BO or P5 or P19)
```

## Summary

- **SDO** on BNO085 = Data **OUT** from sensor (sensor sends data)
- **MISO** on FPGA = Master **IN**, Slave **OUT** (FPGA receives data)
- **Connection**: BNO085 SDO pin → FPGA MISO input pin (DI, P13, INT, P4, P15, etc.)

The names are different because:
- BNO085 uses "SDO" (Serial Data Out from sensor's perspective)
- FPGA uses "MISO" (Master In, Slave Out from master's perspective)
- They're the same signal, just different naming conventions!
