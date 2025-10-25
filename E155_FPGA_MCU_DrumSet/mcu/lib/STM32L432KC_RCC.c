// STM32L432KC_RCC.c
// Source code for RCC functions

#include "STM32L432KC_RCC.h"

void configurePLL() {
   // Set clock to 80 MHz according to STM32L432KC manual
   // Output freq = (src_clk) * (N/M) / R
   // (4 MHz) * (80/2) / 2 = 80 MHz
   // M=2, N=80, R=2
   // Use MSI as PLLSRC (4 MHz)

   RCC->CR &= ~RCC_CR_PLLON; // Turn off PLL
   while (RCC->CR & RCC_CR_PLLRDY); // Wait till PLL is unlocked (e.g., off)

   // Load configuration according to STM32L432KC manual
   RCC->PLLCFGR &= ~RCC_PLLCFGR_PLLSRC; // Clear PLLSRC
   RCC->PLLCFGR |= RCC_PLLCFGR_PLLSRC_MSI; // Set MSI as PLL source
   
   // Configure PLLM (M = 2) - bits [5:0]
   RCC->PLLCFGR &= ~RCC_PLLCFGR_PLLM; // Clear PLLM
   RCC->PLLCFGR |= (2 << RCC_PLLCFGR_PLLM_Pos); // M = 2
   
   // Configure PLLN (N = 80) - bits [14:8]  
   RCC->PLLCFGR &= ~RCC_PLLCFGR_PLLN; // Clear PLLN
   RCC->PLLCFGR |= (80 << RCC_PLLCFGR_PLLN_Pos); // N = 80
   
   // Configure PLLR (R = 2) - bits [29:28]
   RCC->PLLCFGR &= ~RCC_PLLCFGR_PLLR; // Clear PLLR
   RCC->PLLCFGR |= (0 << RCC_PLLCFGR_PLLR_Pos); // R = 2 (value 0 = divide by 2)
   RCC->PLLCFGR |= RCC_PLLCFGR_PLLREN; // Enable PLLCLK output

   // Enable PLL and wait until it's locked
   RCC->CR |= RCC_CR_PLLON;
   while(!(RCC->CR & RCC_CR_PLLRDY));
}

void configureClock(){
  // Configure and turn on PLL
  configurePLL();

  // Select PLL as clock source
  RCC->CFGR = RCC_CFGR_SW_PLL | (RCC->CFGR & ~RCC_CFGR_SW);
  while((RCC->CFGR & RCC_CFGR_SWS) != RCC_CFGR_SWS_PLL);

  SystemCoreClockUpdate();
}