# MCU SPI Communication Protocol

## Overview

The FPGA sends sound codes to the MCU via SPI. The FPGA acts as **SPI Master**, and the MCU acts as **SPI Slave**.

## SPI Configuration

- **Mode**: Mode 0 (CPOL=0, CPHA=0)
  - Clock idle: LOW
  - Data sampled: Rising edge of SCLK
  - Data changed: Falling edge of SCLK
- **Bit Order**: MSB first
- **Data Width**: 8 bits
- **Clock Speed**: Configurable via CLK_DIV parameter (default: ~3MHz for 50MHz system clock)

## Signal Connections

```
FPGA (Master)          MCU (Slave)
─────────────────────────────────
mcu_sclk      →       SCLK
mcu_mosi      →       MOSI
mcu_miso      ←       MISO (optional, not used)
mcu_cs_n      →       CS/SS (chip select, active low)
GND           →       GND
```

## Protocol

### Transfer Format

When a gesture is detected (or kick button pressed), the FPGA:

1. **Asserts CS** (drives `mcu_cs_n` LOW)
2. **Sends 8-bit data**:
   - Format: `0000XXXX` (4 MSBs are 0, 4 LSBs are sound code)
   - Sound codes: 0-7 (see mapping below)
3. **Deasserts CS** (drives `mcu_cs_n` HIGH)
4. **Waits** before next transfer (prevents back-to-back transfers)

### Timing Diagram

```
CS (mcu_cs_n):
    ─────┐                    ┌─────
         └────────────────────┘
         ↑                    ↑
      Assert              Deassert

SCLK (mcu_sclk):
         ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐
    ─────┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─
         ↑   ↑   ↑   ↑   ↑   ↑   ↑   ↑
         Bit 7  6   5   4   3   2   1   0

MOSI (mcu_mosi):
         MSB                    LSB
         ┌─────────────────────────┐
    ─────┘                         └─────
         0  0  0  0  X  X  X  X
                      ↑  ↑  ↑  ↑
                   Sound Code (0-7)
```

## Sound Code Mapping

| Code | Sound        | Description                    |
|------|--------------|--------------------------------|
| 0    | Snare drum   | Right hand Zone 1, Left hand Zone 1 (low pitch) |
| 1    | Hi-hat       | Left hand Zone 1 (high pitch + rotation) |
| 2    | Kick drum    | Kick button pressed            |
| 3    | High tom     | Right/Left hand Zone 2 (low pitch) |
| 4    | Mid tom      | Right/Left hand Zone 3 (low pitch) |
| 5    | Crash cymbal | Right/Left hand Zone 2 (high pitch) |
| 6    | Ride cymbal  | Right/Left hand Zone 3/4 (high pitch) |
| 7    | Floor tom    | Right/Left hand Zone 4 (low pitch) |

## MCU Implementation Example

### Arduino/ESP32 Example

```cpp
#include <SPI.h>

#define CS_PIN 10  // Chip select pin

void setup() {
    Serial.begin(115200);
    
    // Configure SPI as slave
    pinMode(CS_PIN, INPUT);
    pinMode(MISO, OUTPUT);  // Not used but required
    
    // Enable SPI in slave mode
    SPCR |= bit(SPE);  // Enable SPI
    SPCR &= ~bit(MSTR); // Slave mode
    
    Serial.println("SPI Slave ready");
}

void loop() {
    // Wait for CS to go low (FPGA wants to send data)
    if (digitalRead(CS_PIN) == LOW) {
        // Read data from SPI
        byte sound_code = SPI.transfer(0);
        
        // Extract sound code (lower 4 bits)
        sound_code = sound_code & 0x0F;
        
        Serial.print("Received sound code: ");
        Serial.println(sound_code);
        
        // Trigger audio playback based on sound code
        playSound(sound_code);
        
        // Wait for CS to go high
        while (digitalRead(CS_PIN) == LOW) {
            delayMicroseconds(10);
        }
    }
}

void playSound(byte code) {
    // Your audio playback code here
    switch(code) {
        case 0: // Snare
            // Play snare sound
            break;
        case 1: // Hi-hat
            // Play hi-hat sound
            break;
        case 2: // Kick
            // Play kick sound
            break;
        // ... etc
    }
}
```

### STM32 Example

```c
#include "stm32f4xx.h"

void SPI2_Init_Slave(void) {
    // Enable SPI2 clock
    RCC->APB1ENR |= RCC_APB1ENR_SPI2EN;
    
    // Configure SPI2 as slave
    SPI2->CR1 |= SPI_CR1_SPE;  // Enable SPI
    SPI2->CR1 &= ~SPI_CR1_MSTR; // Slave mode
    SPI2->CR1 &= ~SPI_CR1_CPOL; // CPOL = 0
    SPI2->CR1 &= ~SPI_CR1_CPHA; // CPHA = 0
    SPI2->CR1 |= SPI_CR1_SSM;   // Software SS management
    SPI2->CR1 |= SPI_CR1_SSI;
}

void main(void) {
    SPI2_Init_Slave();
    
    while(1) {
        // Wait for data ready
        if (SPI2->SR & SPI_SR_RXNE) {
            uint8_t sound_code = SPI2->DR;
            sound_code &= 0x0F;  // Extract lower 4 bits
            
            // Trigger audio playback
            playSound(sound_code);
        }
    }
}
```

## Important Notes

1. **CS Polarity**: Chip select is **active LOW** (`mcu_cs_n`)
2. **Data Format**: Only lower 4 bits contain the sound code (0-7)
3. **Transfer Rate**: One byte per gesture detection
4. **No Acknowledgment**: FPGA doesn't wait for MCU response (one-way communication)
5. **Clock Speed**: Adjust `CLK_DIV` in `spi_to_mcu.sv` if MCU can't handle default speed

## Troubleshooting

### MCU Not Receiving Data

- Check CS pin is configured correctly (input with pull-up)
- Verify SPI mode matches (Mode 0)
- Check clock speed isn't too fast for MCU
- Use oscilloscope/logic analyzer to verify signals

### Wrong Data Received

- Verify bit order (MSB first)
- Check data extraction (lower 4 bits only)
- Ensure SPI is reading on correct clock edge

### Timing Issues

- Increase delay between transfers in FPGA if needed
- Check MCU SPI interrupt handling
- Verify CS deassert timing


