# System Block Diagram

```mermaid
graph TD
    subgraph "Hardware Layer"
        IMU1[BNO055 IMU 1<br/>Drumstick 1]
        IMU2[BNO055 IMU 2<br/>Drumstick 2]
        BUTTONS[Push Buttons<br/>Calibration]
    end
    
    subgraph "FPGA Layer (UPduino v3.1)"
        I2C[I2C Master<br/>400kHz]
        QUAT[Quaternion<br/>Processor]
        BUFFER[Data Buffer<br/>FIFO 64 samples]
        SPI_OUT[SPI Interface<br/>1MHz]
    end
    
    subgraph "MCU Layer (STM32L432KC)"
        SPI_IN[SPI Slave<br/>Interface]
        GESTURE[Gesture<br/>Recognition]
        WIFI_MGR[WiFi Manager<br/>ESP8266]
    end
    
    subgraph "Computer Layer"
        WIFI_RX[WiFi Receiver<br/>Python]
        AUDIO_PROC[Audio Processor<br/>Python]
        SOUND[Audio Output<br/>Speakers]
    end
    
    IMU1 -->|I2C| I2C
    IMU2 -->|I2C| I2C
    BUTTONS -->|Digital I/O| I2C
    
    I2C --> QUAT
    QUAT --> BUFFER
    BUFFER --> SPI_OUT
    
    SPI_OUT -->|SPI| SPI_IN
    SPI_IN --> GESTURE
    GESTURE --> WIFI_MGR
    
    WIFI_MGR -->|WiFi| WIFI_RX
    WIFI_RX --> AUDIO_PROC
    AUDIO_PROC --> SOUND
```

## Data Flow:
1. **IMU Sensors** → I2C → **FPGA** → SPI → **MCU** → WiFi → **Computer** → Audio
2. **Buttons** → Digital I/O → **FPGA** → SPI → **MCU** → WiFi → **Computer** (Calibration)
