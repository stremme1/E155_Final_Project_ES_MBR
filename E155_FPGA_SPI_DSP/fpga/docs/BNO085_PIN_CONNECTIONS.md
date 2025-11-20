# BNO085 Pin Connections and Wiring Guide

## ⚠️ CRITICAL: BNO085 Hardware Setup

### Protocol Selection Pins (PS0/PS1)

To enable **SPI mode** on BNO085, the protocol selection pins must be configured:

- **PS0 (P0)**: Connect to **HIGH (3.3V)** - Required for SPI mode
- **PS1 (P1)**: Connect to **HIGH (3.3V)** - Required for SPI mode

**⚠️ If PS0/PS1 are not set correctly, the BNO085 will NOT operate in SPI mode!**

---

## Pin Connections for Two BNO085 Sensors

### Shared SPI Bus (Both IMUs)

| FPGA Pin | BNO085 Pin | Description | Notes |
|----------|------------|-------------|-------|
| `spi_sclk` | SCL/SCK | SPI Clock | Shared between both IMUs |
| `spi_mosi` | DI/MOSI | Master Out Slave In | Shared between both IMUs |
| `spi_miso` | SDA/MISO | Master In Slave Out | Shared between both IMUs |

### BNO085 #1 (Right Hand IMU)

| FPGA Pin | BNO085 #1 Pin | Description | Notes |
|----------|---------------|-------------|-------|
| `spi_cs1_n` | CS | Chip Select | Active LOW, unique to IMU1 |
| `bno085_1_int_n` | INT | Interrupt | Active LOW, data ready signal |
| `bno085_1_rst_n` | RST | Reset | Active LOW, reset control |
| `GND` | GND | Ground | Common ground |
| `3.3V` | VIN | Power | 3.3V power supply |
| `3.3V` | PS0 | Protocol Select 0 | Must be HIGH for SPI |
| `3.3V` | PS1 | Protocol Select 1 | Must be HIGH for SPI |

### BNO085 #2 (Left Hand IMU)

| FPGA Pin | BNO085 #2 Pin | Description | Notes |
|----------|---------------|-------------|-------|
| `spi_cs2_n` | CS | Chip Select | Active LOW, unique to IMU2 |
| `bno085_2_int_n` | INT | Interrupt | Active LOW, data ready signal |
| `bno085_2_rst_n` | RST | Reset | Active LOW, reset control |
| `GND` | GND | Ground | Common ground |
| `3.3V` | VIN | Power | 3.3V power supply |
| `3.3V` | PS0 | Protocol Select 0 | Must be HIGH for SPI |
| `3.3V` | PS1 | Protocol Select 1 | Must be HIGH for SPI |

---

## SPI Configuration

### SPI Mode
- **Mode 3**: CPOL=1, CPHA=1
  - Clock idle **HIGH**
  - Data sampled on **falling edge**
  - Data changed on **rising edge**

### Clock Speed
- **1-10 MHz** (BNO085 supports up to 10 MHz)
- Recommended: **5 MHz** for reliable operation
- System clock: 48 MHz → Divide by 10 = 4.8 MHz SPI clock

### Bit Order
- **MSB first** (Most Significant Bit first)

---

## BNO085 Protocol: SHTP (Sensor Hub Transport Protocol)

### Key Differences from BNO055

**BNO055 (I2C)**: Register-based protocol
- Direct register reads/writes
- Register addresses (e.g., 0x14 for gyro X)

**BNO085 (SPI)**: SHTP protocol
- **Report-based** communication
- Request specific report types (quaternion, gyro, etc.)
- **16-bit length field** followed by data payload
- Header-based packet structure

### Required Reports

1. **Rotation Vector (Quaternion)**: Report ID `0x05`
   - 4x 16-bit values (w, x, y, z)
   - Used for Euler angle conversion

2. **Gyroscope**: Report ID `0x06`
   - 3x 16-bit values (x, y, z)
   - Used for hit detection

3. **Game Rotation Vector**: Report ID `0x08` (alternative)
   - Similar to Rotation Vector but without magnetometer

### SHTP Packet Structure

```
[Header Byte 0] [Header Byte 1] [Length LSB] [Length MSB] [Data...]
     |              |              |              |
  Continuation   Report ID      Packet Length (16-bit)
```

---

## Interrupt Handling

### INT Pin Behavior

- **Active LOW**: `int_n = 0` means data ready
- **Pulse**: INT goes LOW when new report is available
- **Polling**: Can poll INT pin or use edge detection

### Recommended Flow

1. Wait for `int_n` to go LOW (data ready)
2. Assert CS (LOW)
3. Read SHTP packet (header + length + data)
4. Deassert CS (HIGH)
5. Process report data

---

## Reset Sequence

### Power-On Reset

1. Assert `rst_n = LOW` (hold reset)
2. Wait **100 ms** minimum
3. Deassert `rst_n = HIGH` (release reset)
4. Wait **300 ms** for sensor initialization
5. Begin SHTP communication

### Software Reset

- Send SHTP reset command (Report ID `0x01`)
- Wait for sensor to respond
- Re-initialize reports

---

## Voltage Levels

- **BNO085**: 3.3V logic levels
- **iCE40UP5K**: 3.3V I/O banks
- **Compatibility**: ✅ Direct connection (no level shifters needed)

---

## Pull-up/Pull-down Requirements

- **CS pins**: No external pull-ups needed (FPGA drives them)
- **INT pins**: **10kΩ pull-up to 3.3V** (BNO085 has weak pull-up, but external recommended)
- **RST pins**: **10kΩ pull-up to 3.3V** (to prevent accidental reset)
- **PS0/PS1**: **10kΩ pull-up to 3.3V** (MUST be HIGH for SPI mode)

---

## Troubleshooting

### BNO085 Not Responding

1. ✅ Check PS0 and PS1 are HIGH (3.3V)
2. ✅ Verify CS is asserted (LOW) during transactions
3. ✅ Check SPI mode (Mode 3: CPOL=1, CPHA=1)
4. ✅ Verify clock speed (1-10 MHz)
5. ✅ Check INT pin connection (required for stable operation)
6. ✅ Verify RST pin is HIGH (not held in reset)

### Data Not Updating

1. ✅ Check INT pin is connected and working
2. ✅ Verify reports are enabled (send enable report commands)
3. ✅ Check report interval is set correctly
4. ✅ Verify CS timing (assert before transaction, deassert after)

---

## References

- [BNO085 Datasheet](https://cdn-learn.adafruit.com/downloads/pdf/adafruit-9-dof-orientation-imu-fusion-breakout-bno085.pdf)
- [Hillcrest SH-2 Reference Manual](https://github.com/hillcrestlabs/SensorHub-Sh2)
- [Adafruit BNO085 Guide](https://learn.adafruit.com/adafruit-9-dof-orientation-imu-fusion-breakout-bno085)

