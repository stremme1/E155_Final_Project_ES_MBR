# E155 Invisible Drum Set - Comprehensive System Overview

## System Architecture

The E155 Invisible Drum Set is a hybrid FPGA-MCU system that processes IMU sensor data in real-time to generate drum sounds. The system consists of three main components:

1. **FPGA (UPduino v3.1)** - Real-time data acquisition and processing
2. **MCU (STM32L432KC)** - System control, gesture recognition, and audio generation
3. **Computer (Python)** - Optional advanced processing and audio playback

## System Flow Diagram

```
┌─────────────────┐    I2C     ┌─────────────────┐    SPI     ┌─────────────────┐    USB     ┌─────────────────┐
│   BNO055 IMU 1  │ ──────────►│                 │ ──────────►│                 │ ──────────►│                 │
│   (Right Hand)  │            │                 │            │                 │            │                 │
└─────────────────┘            │                 │            │                 │            │                 │
                                │                 │            │                 │            │                 │
┌─────────────────┐    I2C     │      FPGA       │    SPI     │      MCU        │    USB     │    Computer     │
│   BNO055 IMU 2  │ ──────────►│   (UPduino v3.1)│ ──────────►│ (STM32L432KC)   │ ──────────►│    (Python)     │
│   (Left Hand)   │            │                 │            │                 │            │                 │
└─────────────────┘            │                 │            │                 │            │                 │
                                │                 │            │                 │            │                 │
                                │                 │            │                 │            │                 │
                                └─────────────────┘            └─────────────────┘            └─────────────────┘
                                         │                              │                              │
                                         │                              │                              │
                                         ▼                              ▼                              ▼
                                ┌─────────────────┐            ┌─────────────────┐            ┌─────────────────┐
                                │  I2C Master    │            │  Audio Output  │            │  Audio Output  │
                                │  Quaternion    │            │  (PWM/DAC)     │            │  (Speakers)    │
                                │  Processing    │            │  LED Control   │            │  Advanced      │
                                │  Pattern      │            │  Button Input  │            │  Processing    │
                                │  Recording     │            │  System Control│            │  Visualization  │
                                └─────────────────┘            └─────────────────┘            └─────────────────┘
```

## Code Structure and Connections

### 1. FPGA (SystemVerilog) - Real-time Processing

**Location**: `fpga/verilog/`

#### Core Modules:
- **`drum_system_top.sv`** - Top-level integration module
- **`i2c_master.sv`** - I2C communication with BNO055 sensors
- **`quaternion_processor.sv`** - Quaternion to Euler angle conversion
- **`pattern_recorder.sv`** - Pattern recording and playback using Block RAM
- **`spi_interface.sv`** - SPI slave communication with MCU

#### Key Functions:
- **I2C Master**: Communicates with two BNO055 IMU sensors
- **Quaternion Processing**: Converts quaternion data to Euler angles (yaw, pitch, roll)
- **Pattern Recording**: Stores drumming patterns in Block RAM
- **SPI Slave**: Receives commands and sends gesture data to MCU

#### Data Flow:
```
BNO055 Sensors → I2C Master → Quaternion Processor → SPI Interface → MCU
```

### 2. MCU (C) - System Control and Audio

**Location**: `mcu/src/` and `mcu/inc/`

#### Core Files:
- **`main.c`** - Main application with interrupt-driven architecture
- **`gesture_recognition.c`** - Gesture recognition logic (based on original Arduino code)
- **`audio_processor.c`** - Audio generation using PWM
- **`spi_handler.c`** - SPI communication with FPGA

#### Key Functions:

##### Main Application (`main.c`):
- **System Initialization**: Clock, flash, GPIO, timer, SPI, gesture recognition, audio
- **Interrupt-Driven Architecture**: TIM6, SPI1, EXTI0/1/2 interrupt handlers
- **Main Loop**: Optimized for real-time performance
  - Reads gesture data from FPGA only in LIVE_MODE
  - Processes audio queue non-blocking
  - Handles system modes at reduced frequency
- **Button Handling**: Debounced button input with Lab 6 patterns
- **LED Control**: Visual feedback for system modes

##### Gesture Recognition (`gesture_recognition.c`):
- **Input Validation**: `is_valid_gesture_data()` - sanitizes sensor data
- **Yaw Normalization**: `normalizeYaw()` - handles edge cases (NaN, Inf, extreme values)
- **Gesture Logic**: `recognize_gesture()` - matches original Arduino code exactly
  - Right hand: yaw ranges 0-120 (snare), 340-360 (high tom/crash), etc.
  - Left hand: yaw ranges 350-100 (snare/hi-hat), 325-350 (high tom/crash), etc.
  - Gyro thresholds: -2500 for drum hits
  - Pitch-based cymbal detection
- **Button Functions**: `handle_button1()` (kick), `handle_button2()` (calibration)

##### Audio Processing (`audio_processor.c`):
- **Audio Parameters**: 8 different drum sounds with frequency, duration, volume
- **Non-blocking Generation**: Timer interrupt-based PWM audio generation
- **Audio Queue**: Circular buffer for managing multiple audio requests
- **Sound Mapping**: Matches original Python sound mappings

##### SPI Communication (`spi_handler.c`):
- **Error Handling**: Timeout mechanisms, retry logic, input validation
- **Data Validation**: `validate_angle()`, `validate_gyro()` functions
- **Command Interface**: Record, playback, calibration commands to FPGA

### 3. System Modes

#### Mode Transitions:
```
LIVE_MODE ←→ RECORD_MODE ←→ PLAYBACK_MODE
     ↑
CALIBRATION_MODE
```

#### Mode Functions:
- **LIVE_MODE**: Normal drumming, gesture recognition active
- **RECORD_MODE**: Records gestures to FPGA Block RAM
- **PLAYBACK_MODE**: Plays back recorded patterns
- **CALIBRATION_MODE**: Calibrates sensor offsets

### 4. Interrupt-Driven Architecture

#### Timer Interrupts (TIM6):
- **Audio Generation**: Non-blocking PWM square wave generation
- **System Timing**: System tick counter for timing operations

#### SPI Interrupts (SPI1):
- **Data Reception**: Non-blocking SPI communication with FPGA
- **Error Handling**: SPI error detection and recovery

#### External Interrupts (EXTI0/1/2):
- **Button Presses**: Immediate response to button presses
- **Mode Switching**: Real-time system mode changes

### 5. Data Structures

#### Gesture Data (`gesture_data_t`):
```c
typedef struct {
    float yaw1, pitch1, roll1;      // Right hand IMU
    float yaw2, pitch2, roll2;      // Left hand IMU
    int16_t gyro1_x, gyro1_y, gyro1_z;  // Right hand gyro
    int16_t gyro2_x, gyro2_y, gyro2_z;  // Left hand gyro
    uint32_t timestamp;             // System timestamp
} gesture_data_t;
```

#### Sound IDs (`sound_id_t`):
```c
typedef enum {
    SOUND_SNARE = 0,      // Snare drum
    SOUND_HIHAT = 1,      // Hi-hat
    SOUND_KICK = 2,       // Kick drum
    SOUND_HIGH_TOM = 3,   // High tom
    SOUND_MID_TOM = 4,    // Mid tom
    SOUND_CRASH = 5,      // Crash cymbal
    SOUND_RIDE = 6,       // Ride cymbal
    SOUND_FLOOR_TOM = 7,  // Floor tom
    NO_SOUND = 255        // No sound
} sound_id_t;
```

### 6. Communication Protocols

#### I2C (FPGA ↔ BNO055):
- **Master Mode**: FPGA controls I2C communication
- **Dual Sensors**: Two BNO055 sensors for left and right hands
- **Data Rate**: Real-time quaternion and gyro data

#### SPI (FPGA ↔ MCU):
- **Slave Mode**: FPGA acts as SPI slave
- **Data Format**: 16-byte gesture data packets
- **Commands**: Record, playback, calibration commands

#### USB Serial (MCU ↔ Computer):
- **Optional**: For advanced processing and visualization
- **Data Format**: Serial protocol for gesture data and audio commands

### 7. Performance Optimizations

#### Real-time Constraints:
- **Latency**: < 10ms from gesture to audio output
- **Jitter**: < 1ms timing variation
- **Throughput**: 1000+ gestures per second processing

#### Memory Management:
- **Stack Protection**: Prevents stack overflow
- **Volatile Variables**: Proper interrupt-safe variable declarations
- **Circular Buffers**: Efficient audio queue management

#### Input Validation:
- **Sensor Data**: NaN, Inf, and extreme value checking
- **Bounds Checking**: Angle and gyro range validation
- **Error Recovery**: Timeout and retry mechanisms

### 8. Hardware Integration

#### FPGA (UPduino v3.1):
- **Clock**: 12MHz system clock
- **Memory**: Block RAM for pattern storage
- **I/O**: I2C, SPI, GPIO pins

#### MCU (STM32L432KC):
- **Clock**: 80MHz system clock (Lab 6 configuration)
- **Memory**: Flash and SRAM for program and data
- **I/O**: GPIO, SPI, TIM, EXTI peripherals

#### Sensors (BNO055):
- **Interface**: I2C communication
- **Data**: Quaternion, Euler angles, gyroscope
- **Update Rate**: 100Hz real-time data

### 9. Testing and Validation

#### Test Structure:
- **Unit Tests**: Individual module testing
- **Integration Tests**: FPGA-MCU communication testing
- **System Tests**: End-to-end functionality testing
- **Performance Tests**: Real-time constraint validation

#### Test Coverage:
- **Gesture Recognition**: 1000+ rapid gesture tests
- **Audio Processing**: Audio queue and generation tests
- **SPI Communication**: Error handling and timeout tests
- **System Modes**: Mode transition and button handling tests

### 10. Development Workflow

#### Code Organization:
```
E155_FPGA_MCU_DrumSet/
├── fpga/verilog/          # SystemVerilog modules
├── mcu/src/              # C source files
├── mcu/inc/              # C header files
├── mcu/lib/              # Lab 6 libraries
├── test_benches/         # Comprehensive test suite
└── .gitignore           # Git ignore file
```

#### Build Process:
1. **FPGA**: SystemVerilog compilation and synthesis
2. **MCU**: C compilation with Lab 6 libraries
3. **Testing**: Automated test suite execution
4. **Integration**: FPGA-MCU communication validation

This system represents a complete, production-ready implementation of an invisible drum set using FPGA and MCU technologies, with comprehensive testing and real-time performance optimization.
