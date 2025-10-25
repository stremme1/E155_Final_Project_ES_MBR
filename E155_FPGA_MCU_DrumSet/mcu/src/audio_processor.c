// Audio Processor for MCU Audio Generation
// Based on Lab 6 timer implementation
// Author: E155 Final Project
// Date: 2024

#include "STM32L432KC.h"
#include "audio_processor.h"

// Audio configuration
#define AUDIO_FREQ_BASE    80000000  // 80MHz system clock (Lab 6 configuration)
#define AUDIO_PWM_FREQ     100000    // 100kHz PWM frequency
#define AUDIO_PWM_PIN      PA6       // Audio output pin

// Audio parameters for each drum sound
typedef struct {
    uint16_t frequency;
    uint16_t duration;
    uint8_t volume;
} audio_params_t;

// Audio parameters for each sound (matching original Python code)
static const audio_params_t audio_params[] = {
    {200,  100, 100},  // SOUND_SNARE (0): 200Hz, 100ms, full volume
    {8000, 50,  80},   // SOUND_HIHAT (1): 8kHz, 50ms, 80% volume
    {60,   200, 100},  // SOUND_KICK (2): 60Hz, 200ms, full volume
    {300,  150, 90},   // SOUND_HIGH_TOM (3): 300Hz, 150ms, 90% volume
    {250,  150, 90},   // SOUND_MID_TOM (4): 250Hz, 150ms, 90% volume
    {4000, 300, 95},   // SOUND_CRASH (5): 4kHz, 300ms, 95% volume
    {2000, 200, 85},   // SOUND_RIDE (6): 2kHz, 200ms, 85% volume
    {150,  200, 90}    // SOUND_FLOOR_TOM (7): 150Hz, 200ms, 90% volume
};

void audio_init(void) {
    // Configure audio output pin
    pinMode(AUDIO_PWM_PIN, GPIO_OUTPUT);
    digitalWrite(AUDIO_PWM_PIN, PIO_LOW);
    
    // Initialize timer for audio generation
    RCC->APB1ENR1 |= RCC_APB1ENR1_TIM6EN;
    initTIM(TIM6);
}

void play_audio(sound_id_t sound_id) {
    if (sound_id >= sizeof(audio_params) / sizeof(audio_params_t)) {
        return;  // Invalid sound ID
    }
    
    const audio_params_t *params = &audio_params[sound_id];
    
    // Generate audio tone using Lab 6 timer functions
    generate_audio_tone(params->frequency, params->duration, params->volume);
}

// Non-blocking audio generation using timer interrupts
static volatile uint32_t audio_cycles_remaining = 0;
static volatile uint32_t audio_period_counter = 0;
static volatile uint32_t audio_period_target = 0;

void generate_audio_tone(uint16_t frequency, uint16_t duration, uint8_t volume) {
    // Input validation
    if (frequency == 0 || duration == 0 || volume == 0) {
        return;
    }
    
    // Calculate period for desired frequency (non-blocking)
    audio_period_target = (AUDIO_FREQ_BASE / frequency) / 2; // Half period for square wave
    audio_cycles_remaining = (duration * 1000) / (1000000 / frequency);
    audio_period_counter = 0;
    
    // Configure timer for audio generation
    TIM6->ARR = audio_period_target;
    TIM6->CR1 |= TIM_CR1_CEN;  // Enable timer
    TIM6->DIER |= TIM_DIER_UIE;  // Enable update interrupt
}

// Timer interrupt handler for audio generation
void TIM6_IRQHandler(void) {
    if (TIM6->SR & TIM_SR_UIF) {
        TIM6->SR &= ~TIM_SR_UIF;
        
        if (audio_cycles_remaining > 0) {
            // Toggle audio pin for square wave
            digitalWrite(AUDIO_PWM_PIN, !digitalRead(AUDIO_PWM_PIN));
            audio_cycles_remaining--;
        } else {
            // Audio generation complete
            TIM6->CR1 &= ~TIM_CR1_CEN;  // Disable timer
            TIM6->DIER &= ~TIM_DIER_UIE;  // Disable interrupt
            digitalWrite(AUDIO_PWM_PIN, PIO_LOW);  // Ensure pin is low
        }
    }
}

// Alternative timer-based audio generation
void generate_audio_timer(uint16_t frequency, uint16_t duration, uint8_t volume) {
    // Use timer for more precise audio generation
    uint32_t period = (AUDIO_FREQ_BASE / frequency) - 1;
    uint32_t pulse = (period * volume) / 100;
    
    // Configure timer
    TIM6->ARR = period;
    TIM6->CCR1 = pulse;
    TIM6->CR1 |= TIM_CR1_CEN;  // Enable timer
    
    // Wait for duration
    delay_ms(duration);
    
    // Stop timer
    TIM6->CR1 &= ~TIM_CR1_CEN;
}

// Audio mixing for multiple sounds
void play_mixed_audio(sound_id_t sound1, sound_id_t sound2, uint8_t mix_ratio) {
    // Simple audio mixing implementation
    if (sound1 != NO_SOUND) {
        play_audio(sound1);
    }
    
    if (sound2 != NO_SOUND) {
        // Play second sound with reduced volume
        const audio_params_t *params = &audio_params[sound2];
        generate_audio_tone(params->frequency, params->duration, params->volume * mix_ratio / 100);
    }
}

// Audio effects
void apply_audio_effects(sound_id_t sound_id, uint8_t reverb_level, uint8_t echo_level) {
    const audio_params_t *params = &audio_params[sound_id];
    
    // Base sound
    generate_audio_tone(params->frequency, params->duration, params->volume);
    
    // Reverb effect
    if (reverb_level > 0) {
        generate_audio_tone(params->frequency, params->duration / 2, params->volume * reverb_level / 100);
    }
    
    // Echo effect
    if (echo_level > 0) {
        delay_ms(50);  // Echo delay
        generate_audio_tone(params->frequency, params->duration / 3, params->volume * echo_level / 100);
    }
}

// Volume control
void set_audio_volume(uint8_t volume) {
    // Global volume control (0-100)
    // This would be implemented with a global volume variable
    // that affects all audio generation
}

// Audio status
uint8_t audio_is_playing(void) {
    // Check if audio is currently playing
    return (TIM6->CR1 & TIM_CR1_CEN) ? 1 : 0;
}

// Stop audio
void stop_audio(void) {
    // Stop any currently playing audio
    TIM6->CR1 &= ~TIM_CR1_CEN;
    digitalWrite(AUDIO_PWM_PIN, PIO_LOW);
}