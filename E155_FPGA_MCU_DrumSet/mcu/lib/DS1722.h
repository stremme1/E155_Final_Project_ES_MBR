#ifndef DS1722_H
#define DS1722_H

#include "STM32L432KC.h"

/*
DS1722.h
Author: Emmett Stralka
Date: 12/19/2024
Description: DS1722 temperature sensor header
*/

// DS1722 pin definitions
#define DS1722_CS_PIN   PA11
#define DS1722_SCK_PIN  PB3
#define DS1722_MISO_PIN PB4
#define DS1722_MOSI_PIN PB5

// Function prototypes
void DS1722_init(void);
float DS1722_read_temperature(void);
void DS1722_set_resolution(uint8_t resolution);
uint8_t DS1722_get_resolution(void);
void DS1722_set_baud_rate(uint8_t baud_rate);
uint8_t DS1722_get_baud_rate(void);

// SPI helper functions
void spi_delay(void);
uint8_t spi_transfer(uint8_t data);

#endif // DS1722_H