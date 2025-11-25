# BNO085 SPI Communication Protocol & Initialization Reference

This document details the specific SPI protocol and initialization sequence for the BNO085 sensor, derived from the BNO08X datasheet and SHTP (Sensor Hub Transport Protocol) specifications. This implementation is critical for reliable operation on the FPGA.

## 1. SPI Physical Layer

- **Mode**: SPI Mode 3 (CPOL=1, CPHA=1)
  - Clock (SCLK) idles HIGH.
  - Data is captured on the rising edge of SCLK.
- **Frequency**: Max 3MHz.
- **Bit Order**: MSB First.
- **Pins**:
  - `SCLK`: Clock
  - `MOSI`: Master Out Slave In (DI on breakout)
  - `MISO`: Master In Slave Out (SDA on breakout)
  - `CS_N`: Chip Select (Active Low)
  - `INT_N`: Interrupt (Active Low) - **CRITICAL for flow control**
  - `RST_N`: Reset (Active Low)
  - `P0/P1`: Protocol Select (Both MUST be High/3.3V for SPI)

---

## 2. SHTP Protocol Structure

The BNO085 uses the Sensor Hub Transport Protocol (SHTP). Every transaction (read or write) begins with a 4-byte header.

### Packet Structure
```
| Byte 0 | Byte 1 | Byte 2  | Byte 3 | Byte 4...N |
|--------|--------|---------|--------|------------|
| Len LSB| Len MSB| Channel | Seq Num| Payload    |
```

- **Length (Bytes 0-1)**: Total length of the packet **including the header**.
  - `Length = {Byte1, Byte0} & 0x7FFF` (Bit 15 is a continuation flag, usually 0).
- **Channel (Byte 2)**:
  - `0`: Command Channel (Advertisements, Product ID)
  - `1`: Executable Channel (Reset, On/Off)
  - `2`: Control Channel (Feature Requests/Responses)
  - `3`: Sensor Reports (Input Reports)
  - `4`: Wake Reports
  - `5`: Gyro Rotation Vector (Low latency channel)
- **Sequence Number (Byte 3)**: Increments per packet.

---

## 3. Critical Handshake (The "Missing MISO" Fix)

The BNO085 is an interrupt-driven device. You **cannot** simply pull CS low and clock out data whenever you want. You must follow this strict handshake:

1.  **Master Asserts CS**: Pull `CS_N` LOW. This acts as a "Wake" signal to the sensor.
2.  **Master Waits for INT**: The FPGA **MUST** wait for the `INT_N` pin to go LOW.
    - If `INT_N` is HIGH, the sensor is sleeping or preparing data. **Do not clock SCLK yet.**
    - Clocking SCLK before `INT_N` goes LOW will result in reading all 0s or 0xFFs (no MISO data).
3.  **Master Clocks Data**: Once `INT_N` is LOW, start generating `SCLK` to read/write the header and payload.
4.  **Master Deasserts CS**: After the transaction is complete (based on the Length field), pull `CS_N` HIGH.

**Implementation Note**: In the FPGA state machine, we enter a `WAIT_INT` state after asserting CS, and we stay there indefinitely until `INT_N` is detected LOW. This fixed the issue where the FPGA was reading data too early.

---

## 4. Initialization Sequence

To get Quaternion and Gyroscope data, the following sequence must be performed after Reset:

### Step 1: Wait for Advertisement
After Reset, the BNO085 asserts `INT_N` to indicate it has reset. It sends an "SHTP Advertisement" packet (Channel 0).
- Action: Read the packet to clear the interrupt.

### Step 2: Request Product ID (Optional but recommended)
Confirms the device is alive.
- **Channel**: 2 (Control)
- **Report ID**: `0xF9` (Product ID Request)
- **Payload**: Empty (just the Report ID)
- **FPGA Sends**: `04 00 02 00 F9` (Len=4, Ch=2, Seq=0, Cmd=F9)

### Step 3: Enable Rotation Vector
Configures the sensor to stream Quaternion data.
- **Channel**: 2 (Control)
- **Report ID**: `0xFD` (Set Feature Command)
- **Feature ID**: `0x05` (Rotation Vector)
- **Flags**: `0x00`
- **Change Sensitivity**: `0x0000`
- **Report Interval**: `0x0000C350` (50,000 microseconds = 20Hz) - Example value
- **Batch Interval**: `0x00000000`
- **Sensor Specific**: `0x00000000`

**Packet Construction (17 Bytes):**
`11 00 02 01 FD 05 00 00 00 50 C3 00 00 00 00 00 00`
*(Note: Sequence number increments)*

### Step 4: Enable Gyroscope
Configures the sensor to stream Calibrated Gyroscope data (for strike detection).
- **Channel**: 2 (Control)
- **Report ID**: `0xFD` (Set Feature Command)
- **Feature ID**: `0x01` (Calibrated Gyroscope)
- **Report Interval**: `0x0000C350` (50,000 microseconds = 20Hz)

**Packet Construction (17 Bytes):**
`11 00 02 02 FD 01 00 00 00 50 C3 00 00 00 00 00 00`

---

## 5. Parsing Data Reports

Once enabled, the BNO085 will asynchronously assert `INT_N` whenever it has data. The FPGA must read these packets.

### Rotation Vector Report (ID 0x05)
Located in Channel 5 (or 3 depending on config).
- **Header**: 4 Bytes
- **Report ID**: `0x05` (Byte 4)
- **Sequence**: Byte 5
- **Status**: Byte 6
- **Delay**: Byte 7
- **i (X)**: Bytes 8-9 (Int16, Q14 format)
- **j (Y)**: Bytes 10-11 (Int16, Q14 format)
- **k (Z)**: Bytes 12-13 (Int16, Q14 format)
- **Real (W)**: Bytes 14-15 (Int16, Q14 format)
- **Accuracy**: Bytes 16-17

**Q14 Format**: To get float, divide by 2^14 (16384).
Example: Raw `16384` = `1.0`.

### Gyroscope Report (ID 0x01)
Located in Channel 5 (or 3).
- **Header**: 4 Bytes
- **Report ID**: `0x01` (Byte 4)
- **X**: Bytes 8-9 (Int16, scaled)
- **Y**: Bytes 10-11
- **Z**: Bytes 12-13

---

## 6. State Machine Implementation

The `bno085_controller.sv` implements this logic:

1.  **INIT_WAIT**: Wait 300ms for sensor boot.
2.  **INIT_PRODUCT_ID**: Send Product ID Request.
3.  **INIT_ENABLE_ROTATION**: Send Set Feature (Rotation Vector).
4.  **INIT_ENABLE_GYRO**: Send Set Feature (Gyroscope).
5.  **WAIT_DATA**: Assert `CS`, **wait for `INT` LOW**.
6.  **READ_HEADER**: Read first 4 bytes to get Length.
7.  **READ_PAYLOAD**: Read remaining `Length - 4` bytes.
    - While reading, parse bytes on-the-fly.
    - If Report ID = 0x05, capture Quaternion X, Y, Z, W.
    - If Report ID = 0x01, capture Gyro X, Y, Z.
8.  **PARSE_REPORT**: Valid pulse out if data found.
9.  **Loop** back to `WAIT_DATA`.

