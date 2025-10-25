// STM32L432KC_RCC.h
// Header for RCC functions

#ifndef STM32L432KC_RCC_H
#define STM32L432KC_RCC_H

#include <stdint.h>
// CMSIS include removed for standalone compilation
#include "STM32L432KC_TIM.h"

// Mock type definitions for standalone compilation
typedef struct {
    uint32_t CR;
    uint32_t ICSCR;
    uint32_t CFGR;
    uint32_t PLLCFGR;
    uint32_t PLLSAI1CFGR;
    uint32_t PLLSAI2CFGR;
    uint32_t CIER;
    uint32_t CIFR;
    uint32_t CICR;
    uint32_t IOPRSTR;
    uint32_t AHBRSTR;
    uint32_t APBRSTR1;
    uint32_t APBRSTR2;
    uint32_t IOPENR;
    uint32_t AHBENR;
    uint32_t APBENR1;
    uint32_t APBENR2;
    uint32_t APB1ENR1;
    uint32_t IOPSMENR;
    uint32_t AHBSMENR;
    uint32_t APBSMENR1;
    uint32_t APBSMENR2;
    uint32_t CCIPR;
    uint32_t CSR;
} RCC_TypeDef;

// Forward declaration - remove this to avoid conflict

// Mock peripheral definitions
extern RCC_TypeDef *RCC;
extern TIM_TypeDef *TIM6;

// Mock register definitions
#define RCC_APB1ENR1_TIM6EN (1 << 4)

///////////////////////////////////////////////////////////////////////////////
// Function prototypes
///////////////////////////////////////////////////////////////////////////////

void configurePLL();
void configureClock();

#endif