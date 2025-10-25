/*
DS1722.c
Author: Emmett Stralka
Date: 12/19/2024
Description: DS1722 temperature sensor driver
*/
#include "DS1722.h"

// DS1722 pin definitions
#define DS1722_CS_PIN   PA11
#define DS1722_SCK_PIN  PB3
#define DS1722_MISO_PIN PB4
#define DS1722_MOSI_PIN PB5

// Global settings
static uint8_t current_resolution = 12;
static uint8_t spi_baud_rate = 100;

// Delay function for SPI timing
void spi_delay(void) {
    for(volatile int i = 0; i < spi_baud_rate; i++);
}

// SPI data transfer
uint8_t spi_transfer(uint8_t data) {
    uint8_t received = 0;
    
    for(int i = 7; i >= 0; i--) {
        digitalWrite(DS1722_MOSI_PIN, (data & (1 << i)) ? PIO_HIGH : PIO_LOW);
        spi_delay();
        
        digitalWrite(DS1722_SCK_PIN, PIO_HIGH);
        spi_delay();
        
        if (digitalRead(DS1722_MISO_PIN) == PIO_HIGH) {
            received |= (1 << i);
        }
        
        digitalWrite(DS1722_SCK_PIN, PIO_LOW);
        spi_delay();
    }
    
    return received;
}

// Initialize DS1722 sensor
void DS1722_init(void) {
    pinMode(DS1722_CS_PIN, GPIO_OUTPUT);
    digitalWrite(DS1722_CS_PIN, PIO_HIGH);
}

// Set resolution (8, 9, 10, 11, or 12 bits)
void DS1722_set_resolution(uint8_t resolution) {
    if (resolution < 8 || resolution > 12) return;
    current_resolution = resolution;
    
    uint8_t config = 0x60;
    if (resolution == 8) config = 0b11100000;
    else if (resolution == 9) config = 0b11100010;
    else if (resolution == 10) config = 0b11100100;
    else if (resolution == 11) config = 0b11100110;
    else if (resolution == 12) config = 0b11101000;
    
    digitalWrite(DS1722_CS_PIN, PIO_LOW);
    spiSendReceive(0x80);
    spiSendReceive(config);
    digitalWrite(DS1722_CS_PIN, PIO_HIGH);
}

// Read temperature
float DS1722_read_temperature(void) {
    uint8_t lsb, msb;
    
    digitalWrite(DS1722_CS_PIN, PIO_LOW);
    spiSendReceive(0x01);
    lsb = spiSendReceive(0x00);
    digitalWrite(DS1722_CS_PIN, PIO_HIGH);
    
    digitalWrite(DS1722_CS_PIN, PIO_LOW);
    spiSendReceive(0x02);
    msb = spiSendReceive(0x00);
    digitalWrite(DS1722_CS_PIN, PIO_HIGH);
    
    float temperature = (msb & 0b01111111);

    if ((msb >> 7) & 1) {temperature -= 128;} 

    float resolution = (float)((lsb >> 4) & 0x0F) * 0.0625;

    return temperature + resolution;
}

// Get current resolution
uint8_t DS1722_get_resolution(void) {
    return current_resolution;
}

// Set SPI baud rate (1-255, higher = slower)
void DS1722_set_baud_rate(uint8_t baud_rate) {
    if (baud_rate > 0 && baud_rate <= 255) {
        spi_baud_rate = baud_rate;
    }
}

// Get current SPI baud rate
uint8_t DS1722_get_baud_rate(void) {
    return spi_baud_rate;
}