/*
STM32L432KC_SPI.c
Author: Emmett Stralka
Date: 12/19/2024
Description: SPI peripheral implementation for STM32L432KC
*/

#include "STM32L432KC.h"
#include "STM32L432KC_SPI.h"
#include "STM32L432KC_GPIO.h"
#include "STM32L432KC_RCC.h"

/* Initialize SPI peripheral with clock speed, polarity, and phase settings */ 
void initSPI(int br, int cpol, int cpha) {
    // Enable GPIO and SPI clocks
    RCC->AHB2ENR |= (RCC_AHB2ENR_GPIOAEN | RCC_AHB2ENR_GPIOBEN);
    RCC->APB2ENR |= RCC_APB2ENR_SPI1EN;

    // Configure SPI pins
    pinMode(SPI_SCK, GPIO_ALT);
    pinMode(SPI_MISO, GPIO_ALT);
    pinMode(SPI_MOSI, GPIO_ALT);
    pinMode(SPI_CE, GPIO_OUTPUT);

    // Set high speed for SCK
    GPIOB->OSPEEDR |= (GPIO_OSPEEDR_OSPEED3);

    // Configure alternate functions for SPI
    GPIOB->AFR[0] |= _VAL2FLD(GPIO_AFRL_AFSEL3, 5);
    GPIOB->AFR[0] |= _VAL2FLD(GPIO_AFRL_AFSEL4, 5);
    GPIOB->AFR[0] |= _VAL2FLD(GPIO_AFRL_AFSEL5, 5);
    
    // Configure SPI control registers
    SPI1->CR1 |= _VAL2FLD(SPI_CR1_BR, br);
    SPI1->CR1 |= (SPI_CR1_MSTR);
    SPI1->CR1 &= ~(SPI_CR1_CPOL | SPI_CR1_CPHA | SPI_CR1_LSBFIRST | SPI_CR1_SSM);
    SPI1->CR1 |= _VAL2FLD(SPI_CR1_CPHA, cpha);
    SPI1->CR1 |= _VAL2FLD(SPI_CR1_CPOL, cpol);
    SPI1->CR2 |= _VAL2FLD(SPI_CR2_DS, 0b0111);
    SPI1->CR2 |= (SPI_CR2_FRXTH | SPI_CR2_SSOE);

    SPI1->CR1 |= (SPI_CR1_SPE);
}

/* Send and receive data over SPI */
char spiSendReceive(char send) {
    while(!(SPI1->SR & SPI_SR_TXE));
    *(volatile char *) (&SPI1->DR) = send;
    while(!(SPI1->SR & SPI_SR_RXNE));
    char rec = (volatile char) SPI1->DR;
    return rec;
}