// Test Headers for MCU Test Benches
// Mock headers for testing without STM32 hardware
// Author: E155 Final Project
// Date: 2024

#ifndef TEST_HEADERS_H
#define TEST_HEADERS_H

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>
#include <math.h>
#include <string.h>
#include <assert.h>

// Mock STM32L432KC definitions
#define GPIO_PORT_A 0
#define GPIO_PORT_B 1
#define GPIO_PORT_C 2

#define GPIO_INPUT 0
#define GPIO_OUTPUT 1
#define GPIO_ALT 2
#define GPIO_ANALOG 3

#define PIO_LOW 0
#define PIO_HIGH 1

#define GPIO_PULL_UP 0
#define GPIO_PULL_DOWN 1
#define GPIO_FLOATING 2

// Mock pin definitions
#define PA0 0
#define PA1 1
#define PA2 2
#define PA3 3
#define PA4 4
#define PA5 5
#define PA6 6
#define PA7 7
#define PA8 8
#define PA9 9
#define PA10 10
#define PA11 11
#define PA12 12
#define PA13 13
#define PA14 14
#define PA15 15

#define PB0 16
#define PB1 17
#define PB2 18
#define PB3 19
#define PB4 20
#define PB5 21
#define PB6 22
#define PB7 23
#define PB8 24
#define PB9 25
#define PB10 26
#define PB11 27
#define PB12 28
#define PB13 29
#define PB14 30
#define PB15 31

#define PC0 32
#define PC1 33
#define PC2 34
#define PC3 35
#define PC4 36
#define PC5 37
#define PC6 38
#define PC7 39
#define PC8 40
#define PC9 41
#define PC10 42
#define PC11 43
#define PC12 44
#define PC13 45
#define PC14 46
#define PC15 47

// Mock timer definitions
typedef struct {
    uint32_t ARR;
    uint32_t CCR1;
    uint32_t CR1;
    uint32_t SR;
} TIM_TypeDef;

#define TIM6 ((TIM_TypeDef *)0x40001000)

// Mock SPI definitions
typedef struct {
    uint32_t SR;
    uint32_t DR;
    uint32_t CR1;
    uint32_t CR2;
} SPI_TypeDef;

#define SPI1 ((SPI_TypeDef *)0x40013000)

#define SPI_SR_TXE (1 << 1)
#define SPI_SR_RXNE (1 << 0)

// Mock RCC definitions
typedef struct {
    uint32_t AHB2ENR;
    uint32_t APB1ENR1;
    uint32_t APB2ENR;
    uint32_t CR;
    uint32_t CFGR;
    uint32_t PLLCFGR;
} RCC_TypeDef;

#define RCC ((RCC_TypeDef *)0x40021000)

#define RCC_AHB2ENR_GPIOAEN (1 << 0)
#define RCC_AHB2ENR_GPIOBEN (1 << 1)
#define RCC_AHB2ENR_GPIOCEN (1 << 2)
#define RCC_APB1ENR1_TIM6EN (1 << 4)
#define RCC_APB2ENR_SPI1EN (1 << 12)

// Mock FLASH definitions
typedef struct {
    uint32_t ACR;
} FLASH_TypeDef;

#define FLASH ((FLASH_TypeDef *)0x40022000)

#define FLASH_ACR_LATENCY_4WS (4 << 0)
#define FLASH_ACR_PRFTEN (1 << 8)

// Mock GPIO definitions
typedef struct {
    uint32_t MODER;
    uint32_t OTYPER;
    uint32_t OSPEEDR;
    uint32_t PUPDR;
    uint32_t IDR;
    uint32_t ODR;
    uint32_t BSRR;
    uint32_t LCKR;
    uint32_t AFR[2];
} GPIO_TypeDef;

#define GPIOA ((GPIO_TypeDef *)0x50000000)
#define GPIOB ((GPIO_TypeDef *)0x50000400)
#define GPIOC ((GPIO_TypeDef *)0x50000800)

// Mock system clock
extern uint32_t SystemCoreClock;

// Mock function declarations
void gpioEnable(int port_id);
void pinMode(int gpio_pin, int function);
int digitalRead(int gpio_pin);
void digitalWrite(int gpio_pin, int val);
void pinResistor(int pin, int setting);
void initTIM(TIM_TypeDef * TIMx);
void delay_millis(TIM_TypeDef * TIMx, uint32_t ms);
void initSPI(int br, int cpol, int cpha);
char spiSendReceive(char send);
void configureFlash(void);
void configureClock(void);
void configurePLL(void);
void SystemCoreClockUpdate(void);

// Global system clock
uint32_t SystemCoreClock = 80000000; // 80MHz

#endif // TEST_HEADERS_H
