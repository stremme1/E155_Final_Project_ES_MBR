// SPI Handler for FPGA Communication
// Based on Lab 6 working SPI implementation
// Author: E155 Final Project
// Date: 2024

#include "STM32L432KC.h"
#include "gesture_recognition.h"

// SPI configuration for FPGA communication
#define FPGA_CS_PIN PA11  // Chip select for FPGA
#define SPI_CLOCK_DIV 0b111  // Slowest clock for reliable communication
#define SPI_CPOL 0  // Clock polarity
#define SPI_CPHA 1  // Clock phase

// Data buffers
static uint8_t tx_buffer[64];
static uint8_t rx_buffer[64];
static uint16_t tx_count = 0;
static uint16_t rx_count = 0;

// Gesture data structure
gesture_data_t received_gesture;

void spi_init(void) {
    // Initialize SPI using Lab 6 implementation
    initSPI(SPI_CLOCK_DIV, SPI_CPOL, SPI_CPHA);
    
    // Configure FPGA CS pin
    pinMode(FPGA_CS_PIN, GPIO_OUTPUT);
    digitalWrite(FPGA_CS_PIN, PIO_HIGH);  // CS high when idle
    
    // Initialize buffers
    tx_count = 0;
    rx_count = 0;
}

// SPI error handling and validation
static uint32_t spi_error_count = 0;
static uint32_t spi_timeout_count = 0;
#define SPI_MAX_ERRORS 10
#define SPI_TIMEOUT_MS 100

gesture_data_t spi_receive_gesture_data(void) {
    // Receive gesture data from FPGA with comprehensive error handling
    uint8_t data[16];  // 16 bytes for gesture data
    gesture_data_t result = {0};  // Initialize to safe values
    
    // Input validation
    if (spi_error_count >= SPI_MAX_ERRORS) {
        // Too many errors, return safe default
        return result;
    }
    
    // Select FPGA with timeout protection
    digitalWrite(FPGA_CS_PIN, PIO_LOW);
    uint32_t start_time = system_tick;
    
    // Receive gesture data with error checking
    for (int i = 0; i < 16; i++) {
        // Check for timeout
        if ((system_tick - start_time) > SPI_TIMEOUT_MS) {
            spi_timeout_count++;
            digitalWrite(FPGA_CS_PIN, PIO_HIGH);
            return result;  // Return safe default on timeout
        }
        
        data[i] = spiSendReceive(0x00);
        
        // Validate received data
        if (data[i] == 0xFF || data[i] == 0x00) {
            // Potential communication error
            spi_error_count++;
        }
    }
    
    // Deselect FPGA
    digitalWrite(FPGA_CS_PIN, PIO_HIGH);
    
    // Parse received data with bounds checking
    result.yaw1 = validate_angle((data[0] << 8) | data[1]);
    result.pitch1 = validate_angle((data[2] << 8) | data[3]);
    result.roll1 = validate_angle((data[4] << 8) | data[5]);
    result.gyro1_x = validate_gyro((data[6] << 8) | data[7]);
    result.gyro1_y = validate_gyro((data[8] << 8) | data[9]);
    result.gyro1_z = validate_gyro((data[10] << 8) | data[11]);
    result.yaw2 = validate_angle((data[12] << 8) | data[13]);
    result.pitch2 = validate_angle((data[14] << 8) | data[15]);
    result.roll2 = 0;  // Not used in original code
    result.gyro2_x = 0;  // Not used in original code
    result.gyro2_y = 0;  // Not used in original code
    result.gyro2_z = 0;  // Not used in original code
    result.timestamp = system_tick;  // Set current timestamp
    
    return result;
}

// Input validation functions
float validate_angle(int16_t raw_angle) {
    // Validate angle is within reasonable range
    if (raw_angle < -180 || raw_angle > 180) {
        return 0.0f;  // Return safe default
    }
    return (float)raw_angle;
}

int16_t validate_gyro(int16_t raw_gyro) {
    // Validate gyro is within reasonable range
    if (raw_gyro < -32768 || raw_gyro > 32767) {
        return 0;  // Return safe default
    }
    return raw_gyro;
}

void spi_send_record_command(uint8_t sound_id, gesture_data_t gesture) {
    // Send record command to FPGA using Lab 6 SPI pattern
    digitalWrite(FPGA_CS_PIN, PIO_LOW);
    
    // Send record command (similar to DS1722 configuration)
    spiSendReceive(0x01);  // Record command
    spiSendReceive(sound_id);
    spiSendReceive((gesture.timestamp >> 8) & 0xFF);
    spiSendReceive(gesture.timestamp & 0xFF);
    spiSendReceive((gesture.yaw1 >> 8) & 0xFF);
    spiSendReceive(gesture.yaw1 & 0xFF);
    spiSendReceive((gesture.pitch1 >> 8) & 0xFF);
    spiSendReceive(gesture.pitch1 & 0xFF);
    
    digitalWrite(FPGA_CS_PIN, PIO_HIGH);
}

void spi_send_playback_command(void) {
    // Send playback command to FPGA
    digitalWrite(FPGA_CS_PIN, PIO_LOW);
    
    spiSendReceive(0x02);  // Playback command
    spiSendReceive(0x00);  // Start playback
    
    digitalWrite(FPGA_CS_PIN, PIO_HIGH);
}

void spi_send_calibration_command(void) {
    // Send calibration command to FPGA
    digitalWrite(FPGA_CS_PIN, PIO_LOW);
    
    spiSendReceive(0x03);  // Calibration command
    spiSendReceive(0x00);  // Reset offsets
    
    digitalWrite(FPGA_CS_PIN, PIO_HIGH);
}

// Enhanced SPI functions for better communication
void spi_send_gesture_data(gesture_data_t gesture) {
    // Send gesture data to FPGA for recording
    digitalWrite(FPGA_CS_PIN, PIO_LOW);
    
    // Send gesture data
    spiSendReceive(0x04);  // Gesture data command
    spiSendReceive((gesture.yaw1 >> 8) & 0xFF);
    spiSendReceive(gesture.yaw1 & 0xFF);
    spiSendReceive((gesture.pitch1 >> 8) & 0xFF);
    spiSendReceive(gesture.pitch1 & 0xFF);
    spiSendReceive((gesture.gyro1_y >> 8) & 0xFF);
    spiSendReceive(gesture.gyro1_y & 0xFF);
    spiSendReceive((gesture.yaw2 >> 8) & 0xFF);
    spiSendReceive(gesture.yaw2 & 0xFF);
    spiSendReceive((gesture.pitch2 >> 8) & 0xFF);
    spiSendReceive(gesture.pitch2 & 0xFF);
    spiSendReceive((gesture.gyro2_y >> 8) & 0xFF);
    spiSendReceive(gesture.gyro2_y & 0xFF);
    spiSendReceive((gesture.gyro2_z >> 8) & 0xFF);
    spiSendReceive(gesture.gyro2_z & 0xFF);
    
    digitalWrite(FPGA_CS_PIN, PIO_HIGH);
}

uint8_t spi_receive_sound_id(void) {
    // Receive sound ID from FPGA
    uint8_t sound_id = 0;
    
    digitalWrite(FPGA_CS_PIN, PIO_LOW);
    
    sound_id = spiSendReceive(0x05);  // Request sound ID
    
    digitalWrite(FPGA_CS_PIN, PIO_HIGH);
    
    return sound_id;
}

// SPI communication status
uint8_t spi_is_ready(void) {
    // Check if SPI is ready for communication
    return (SPI1->SR & SPI_SR_TXE) && (SPI1->SR & SPI_SR_RXNE);
}

// SPI error handling
void spi_reset(void) {
    // Reset SPI in case of communication errors
    SPI1->CR1 &= ~SPI_CR1_SPE;  // Disable SPI
    delay_ms(10);
    SPI1->CR1 |= SPI_CR1_SPE;   // Re-enable SPI
}