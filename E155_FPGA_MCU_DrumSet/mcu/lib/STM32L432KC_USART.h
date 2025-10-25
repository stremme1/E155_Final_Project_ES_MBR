// STM32L432KC_USART.h
// Header for USART functions

#ifndef STM32L432KC_USART_H
#define STM32L432KC_USART_H

#include <stdint.h>
// CMSIS include removed for standalone compilation

// Mock type definitions for standalone compilation
typedef struct {
    uint32_t CR1;
    uint32_t CR2;
    uint32_t CR3;
    uint32_t BRR;
    uint32_t GTPR;
    uint32_t RTOR;
    uint32_t RQR;
    uint32_t ISR;
    uint32_t ICR;
    uint32_t RDR;
    uint32_t TDR;
} USART_TypeDef;

// Defines for USART case statements
#define USART1_ID   1
#define USART2_ID   2

///////////////////////////////////////////////////////////////////////////////
// Function prototypes
///////////////////////////////////////////////////////////////////////////////

USART_TypeDef * id2Port(int USART_ID);
USART_TypeDef * initUSART(int USART_ID, int baud_rate);
void sendChar(USART_TypeDef * USART, char data);
char readChar(USART_TypeDef * USART);
void sendString(USART_TypeDef * USART, char * charArray);
void readString(USART_TypeDef * USART, char * charArray);

#endif