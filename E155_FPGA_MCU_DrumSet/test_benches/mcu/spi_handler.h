// SPI Handler Header File
// Author: E155 Final Project
// Date: 2024

#ifndef SPI_HANDLER_H
#define SPI_HANDLER_H

#include "STM32L432KC.h"
#include "gesture_recognition.h"

// Function prototypes
void spi_init(void);
gesture_data_t spi_receive_gesture_data(void);
void spi_send_record_command(uint8_t sound_id, gesture_data_t gesture);
void spi_send_playback_command(void);
void spi_send_calibration_command(void);
void spi_send_gesture_data(gesture_data_t gesture);
uint8_t spi_receive_sound_id(void);
uint8_t spi_is_ready(void);
void spi_reset(void);

#endif // SPI_HANDLER_H
