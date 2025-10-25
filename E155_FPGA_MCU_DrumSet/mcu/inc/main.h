// Main Header File for STM32L432KC
// Based on Lab 6 implementation
// Author: E155 Final Project
// Date: 2024

#ifndef MAIN_H
#define MAIN_H

#include "STM32L432KC.h"
#include "gesture_recognition.h"
#include "audio_processor.h"
#include "spi_handler.h"

// System configuration
#define SYSTEM_CLOCK_FREQ 80000000  // 80MHz
#define SPI_CLOCK_FREQ 1000000      // 1MHz SPI
#define AUDIO_SAMPLE_RATE 8000      // 8kHz audio

// Pin definitions (Lab 6 style)
#define LED_PIN PA5
#define BUTTON1_PIN PA0
#define BUTTON2_PIN PA1
#define BUTTON3_PIN PA2
#define AUDIO_PWM_PIN PA6

// SPI pin definitions (Lab 6 style)
#define FPGA_CS_PIN PA11
#define SPI_SCK_PIN PB3
#define SPI_MISO_PIN PB4
#define SPI_MOSI_PIN PB5

// System mode definitions
typedef enum {
    LIVE_MODE,
    RECORD_MODE,
    PLAYBACK_MODE,
    CALIBRATION_MODE
} system_mode_t;

// Function prototypes
void handle_buttons(void);
void update_leds(void);
void handle_system_modes(void);
void perform_calibration(void);

// Note: configureClock() and configureFlash() are provided by Lab 6 libraries

#endif // MAIN_H