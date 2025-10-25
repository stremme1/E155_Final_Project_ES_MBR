/*
STM32L432KC_SPI.h
Author: Emmett Stralka
Date: 12/19/2024
Description: SPI peripheral driver for STM32L432KC
*/

#ifndef STM32L4_SPI_H
#define STM32L4_SPI_H

#include <stdint.h>
// CMSIS include removed for standalone compilation

// Mock type definitions for standalone compilation
typedef struct {
    uint32_t CR1;
    uint32_t CR2;
    uint32_t SR;
    uint32_t DR;
    uint32_t CRCPR;
    uint32_t RXCRCR;
    uint32_t TXCRCR;
    uint32_t I2SCFGR;
    uint32_t I2SPR;
} SPI_TypeDef;

typedef struct {
    uint32_t IMR;
    uint32_t EMR;
    uint32_t RTSR;
    uint32_t FTSR;
    uint32_t SWIER;
    uint32_t PR;
} EXTI_TypeDef;

// Mock register definitions
#define SPI_SR_RXNE (1 << 0)
#define SPI_SR_TXE (1 << 1)
#define SPI_CR1_SPE (1 << 6)
#define EXTI_PR_PR0 (1 << 0)
#define EXTI_PR_PR1 (1 << 1)
#define EXTI_PR_PR2 (1 << 2)

// Mock peripheral definitions
extern SPI_TypeDef *SPI1;
extern EXTI_TypeDef *EXTI;

// SPI Pin Definitions
#define SPI_CE PA11
#define SPI_SCK PB3
#define SPI_MOSI PB5
#define SPI_MISO PB4

///////////////////////////////////////////////////////////////////////////////
// Function prototypes
///////////////////////////////////////////////////////////////////////////////

/* Initialize SPI peripheral with specified clock speed, polarity, and phase
 * br: clock divider (0b000 - 0b111)
 * cpol: clock polarity (0 = low when idle, 1 = high when idle)
 * cpha: clock phase (0 = sample on first edge, 1 = sample on second edge) */ 
void initSPI(int br, int cpol, int cpha);

/* Send and receive data over SPI
 * send: byte to transmit
 * return: byte received from slave */
char spiSendReceive(char send);

#endif