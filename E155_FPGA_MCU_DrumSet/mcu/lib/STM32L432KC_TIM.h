// STM32L432KC_TIM.h
// Header for TIM functions

#ifndef STM32L432KC_TIM_H
#define STM32L432KC_TIM_H

#include <stdint.h> // Include stdint header
// CMSIS include removed for standalone compilation  // CMSIS device library include
#include "STM32L432KC_GPIO.h"

// Mock type definitions for standalone compilation
typedef struct {
    uint32_t CR1;
    uint32_t CR2;
    uint32_t SMCR;
    uint32_t DIER;
    uint32_t SR;
    uint32_t EGR;
    uint32_t CCMR1;
    uint32_t CCMR2;
    uint32_t CCER;
    uint32_t CNT;
    uint32_t PSC;
    uint32_t ARR;
    uint32_t RCR;
    uint32_t CCR1;
    uint32_t CCR2;
    uint32_t CCR3;
    uint32_t CCR4;
    uint32_t BDTR;
    uint32_t DCR;
    uint32_t DMAR;
} TIM_TypeDef;

// Mock register definitions
#define TIM_SR_UIF (1 << 0)
#define TIM_CR1_CEN (1 << 0)
#define TIM_DIER_UIE (1 << 0)

// Mock peripheral definitions
extern TIM_TypeDef *TIM6;

///////////////////////////////////////////////////////////////////////////////
// Function prototypes
///////////////////////////////////////////////////////////////////////////////

void initTIM(TIM_TypeDef * TIMx);
void delay_millis(TIM_TypeDef * TIMx, uint32_t ms);

#endif