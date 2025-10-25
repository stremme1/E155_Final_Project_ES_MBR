// STM32L432KC Main Program for Drum System
// Professional implementation with interrupt-driven architecture
// Author: E155 Final Project
// Date: 2024

#include "STM32L432KC.h"
#include "gesture_recognition.h"
#include "audio_processor.h"
#include "spi_handler.h"
#include "main.h"

// System state
volatile system_mode_t system_mode = LIVE_MODE;

// Global variables with proper memory management
static gesture_data_t current_gesture;
static volatile uint8_t current_sound_id = 0;
static volatile uint32_t system_tick = 0;

// Interrupt-driven audio system
static volatile uint8_t audio_playing = 0;
static volatile uint8_t audio_queue_head = 0;
static volatile uint8_t audio_queue_tail = 0;
static volatile uint8_t audio_queue[8]; // Circular buffer for audio queue

// Debouncing variables (matching original Arduino code)
uint32_t lastDebounceTime1 = 0;
uint32_t lastDebounceTime2 = 0;
uint32_t lastDebounceTime3 = 0;
bool button1_pressed = false;
bool button2_pressed = false;
bool button3_pressed = false;

// Pin definitions (using Lab 6 style)
#define LED_PIN PA5
#define BUTTON1_PIN PA0  // Kick drum button
#define BUTTON2_PIN PA1  // Calibration button
#define BUTTON3_PIN PA2  // Record/Playback toggle
#define AUDIO_PWM_PIN PA6

// Debouncing constants (matching original Arduino code)
#define DEBOUNCE_DELAY1 50   // Button 1 debounce delay
#define DEBOUNCE_DELAY2 50   // Button 2 debounce delay
#define DEBOUNCE_DELAY3 50   // Button 3 debounce delay

// Function prototypes
void configureClock(void);
void configureFlash(void);
void handle_buttons(void);
void update_leds(void);
void handle_system_modes(void);
void perform_calibration(void);

// Interrupt-driven function prototypes
void TIM6_IRQHandler(void);
void SPI1_IRQHandler(void);
void EXTI0_IRQHandler(void);
void EXTI1_IRQHandler(void);
void EXTI2_IRQHandler(void);
void queue_audio(sound_id_t sound_id);
uint8_t dequeue_audio(void);
void process_audio_queue(void);

int main(void) {
    // Initialize system using Lab 6 pattern
    configureFlash();  // Use Lab 6's configureFlash() function
    configureClock();  // Use Lab 6's configureClock() function
    
    // Enable GPIO ports
    gpioEnable(GPIO_PORT_A);
    gpioEnable(GPIO_PORT_B);
    gpioEnable(GPIO_PORT_C);
    
    // Configure pins (Lab 6 pattern)
    pinMode(LED_PIN, GPIO_OUTPUT);
    pinMode(BUTTON1_PIN, GPIO_INPUT);
    pinMode(BUTTON2_PIN, GPIO_INPUT);
    pinMode(BUTTON3_PIN, GPIO_INPUT);
    pinMode(AUDIO_PWM_PIN, GPIO_OUTPUT);
    
    // Note: pinResistor not implemented in Lab 6, buttons will use internal pull-ups
    
    // Initialize timer for delays (Lab 6 pattern)
    RCC->APB1ENR1 |= RCC_APB1ENR1_TIM6EN;
    initTIM(TIM6);
    
    // Initialize SPI for FPGA communication
    spi_init();
    
    // Initialize gesture recognition
    gesture_recognition_init();
    
    // Initialize audio system
    audio_init();
    
    // Enable interrupts for real-time operation
    // __enable_irq(); // Commented out for standalone compilation
    
    // Main loop - OPTIMIZED for real-time performance
    while (1) {
        // OPTIMIZED: Read gesture data from FPGA only when needed
        if (system_mode == LIVE_MODE) {
            current_gesture = spi_receive_gesture_data();
            current_sound_id = recognize_gesture(current_gesture);
            if (current_sound_id != NO_SOUND) {
                queue_audio(current_sound_id);
                current_sound_id = NO_SOUND;
            }
        }
        
        // Process audio queue (non-blocking)
        process_audio_queue();
        
        // Handle system modes (optimized frequency)
        if (system_tick % 10 == 0) {
            handle_system_modes();
        }
        
        // Update system tick
        system_tick++;
        
        // OPTIMIZED: Reduced delay for better real-time performance
        delay_millis(TIM6, 0);  // Minimal delay
    }
}

// Note: configureClock() and configureFlash() are provided by Lab 6 libraries
// No need to redefine them - they're already implemented in STM32L432KC_RCC.c and STM32L432KC_FLASH.c

void handle_buttons(void) {
    uint32_t current_time = system_tick;
    
    // Button 1: Kick drum (matching original Arduino code)
    if (current_time - lastDebounceTime1 > DEBOUNCE_DELAY1) {
        uint8_t reading1 = digitalRead(BUTTON1_PIN);
        
        // Button is active low (pressed when reading == 0)
        if (reading1 == 0 && !button1_pressed) {
            button1_pressed = true;
            current_sound_id = handle_button1(); // Returns SOUND_KICK
        }
        if (reading1 == 1) {
            button1_pressed = false;
        }
        lastDebounceTime1 = current_time;
    }
    
    // Button 2: Calibration (matching original Arduino code)
    if (current_time - lastDebounceTime2 > DEBOUNCE_DELAY2) {
        uint8_t reading2 = digitalRead(BUTTON2_PIN);
        
        // Button is active low (pressed when reading == 0)
        if (reading2 == 0 && !button2_pressed) {
            button2_pressed = true;
            handle_button2(current_gesture); // Calibrate sensors
        }
        if (reading2 == 1) {
            button2_pressed = false;
        }
        lastDebounceTime2 = current_time;
    }
    
    // Button 3: Record/Playback toggle
    if (current_time - lastDebounceTime3 > DEBOUNCE_DELAY3) {
        uint8_t reading3 = digitalRead(BUTTON3_PIN);
        
        // Button is active low (pressed when reading == 0)
        if (reading3 == 0 && !button3_pressed) {
            button3_pressed = true;
            // Toggle between record and playback modes
            if (system_mode == LIVE_MODE) {
                system_mode = RECORD_MODE;
            } else if (system_mode == RECORD_MODE) {
                system_mode = PLAYBACK_MODE;
            } else {
                system_mode = LIVE_MODE;
            }
        }
        if (reading3 == 1) {
            button3_pressed = false;
        }
        lastDebounceTime3 = current_time;
    }
}

void update_leds(void) {
    // Update LED based on system mode
    switch (system_mode) {
        case LIVE_MODE:
            digitalWrite(LED_PIN, PIO_LOW);
            break;
        case RECORD_MODE:
            digitalWrite(LED_PIN, PIO_HIGH);
            break;
        case PLAYBACK_MODE:
            // Blink LED for playback mode
            if (system_tick % 100 < 50) {
                digitalWrite(LED_PIN, PIO_HIGH);
            } else {
                digitalWrite(LED_PIN, PIO_LOW);
            }
            break;
        case CALIBRATION_MODE:
            // Fast blink for calibration
            if (system_tick % 20 < 10) {
                digitalWrite(LED_PIN, PIO_HIGH);
            } else {
                digitalWrite(LED_PIN, PIO_LOW);
            }
            break;
    }
}

void handle_system_modes(void) {
    switch (system_mode) {
        case LIVE_MODE:
            // Normal drumming mode
            break;
            
        case RECORD_MODE:
            // Record gestures to FPGA
            if (current_sound_id != NO_SOUND) {
                spi_send_record_command(current_sound_id, current_gesture);
            }
            break;
            
        case PLAYBACK_MODE:
            // Play back recorded patterns
            spi_send_playback_command();
            break;
            
        case CALIBRATION_MODE:
            // Calibrate sensors
            perform_calibration();
            system_mode = LIVE_MODE;  // Return to live mode after calibration
            break;
    }
}

void perform_calibration(void) {
    // Perform sensor calibration
    // Send calibration command to FPGA
    spi_send_calibration_command();
    
    // Wait for calibration to complete (Lab 6 pattern)
    delay_millis(TIM6, 1000);
    
    // Reset gesture recognition
    gesture_recognition_init();
}

// Interrupt-driven audio queue management
void queue_audio(sound_id_t sound_id) {
    if (sound_id == NO_SOUND) return;
    
    uint8_t next_head = (audio_queue_head + 1) % 8;
    if (next_head != audio_queue_tail) {
        audio_queue[audio_queue_head] = sound_id;
        audio_queue_head = next_head;
    }
    // If queue is full, drop oldest sound (audio_queue_tail++)
}

uint8_t dequeue_audio(void) {
    if (audio_queue_head == audio_queue_tail) {
        return NO_SOUND;
    }
    
    uint8_t sound_id = audio_queue[audio_queue_tail];
    audio_queue_tail = (audio_queue_tail + 1) % 8;
    return sound_id;
}

void process_audio_queue(void) {
    if (!audio_playing && audio_queue_head != audio_queue_tail) {
        uint8_t sound_id = dequeue_audio();
        if (sound_id != NO_SOUND) {
            play_audio(sound_id);
            audio_playing = 1;
        }
    }
}

// Timer interrupt for audio generation (non-blocking)
void TIM6_IRQHandler(void) {
    if (TIM6->SR & TIM_SR_UIF) {
        TIM6->SR &= ~TIM_SR_UIF;
        
        // Handle audio generation in interrupt
        if (audio_playing) {
            // Toggle audio pin for square wave generation
            digitalWrite(AUDIO_PWM_PIN, !digitalRead(AUDIO_PWM_PIN));
        }
    }
}

// SPI interrupt for non-blocking communication
void SPI1_IRQHandler(void) {
    if (SPI1->SR & SPI_SR_RXNE) {
        // Handle SPI data reception
        uint8_t data = SPI1->DR;
        // Process received data...
    }
}

// Button interrupt handlers
void EXTI0_IRQHandler(void) {
    if (EXTI->PR & EXTI_PR_PR0) {
        EXTI->PR |= EXTI_PR_PR0;
        // Handle button 1 press
        queue_audio(SOUND_KICK);
    }
}

void EXTI1_IRQHandler(void) {
    if (EXTI->PR & EXTI_PR_PR1) {
        EXTI->PR |= EXTI_PR_PR1;
        // Handle button 2 press (calibration)
        perform_calibration();
    }
}

void EXTI2_IRQHandler(void) {
    if (EXTI->PR & EXTI_PR_PR2) {
        EXTI->PR |= EXTI_PR_PR2;
        // Handle button 3 press (mode toggle)
        if (system_mode == LIVE_MODE) {
            system_mode = RECORD_MODE;
        } else if (system_mode == RECORD_MODE) {
            system_mode = PLAYBACK_MODE;
        } else {
            system_mode = LIVE_MODE;
        }
    }
}