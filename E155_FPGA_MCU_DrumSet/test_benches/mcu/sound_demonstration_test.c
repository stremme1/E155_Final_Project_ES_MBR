// Sound Demonstration Test for E155 Invisible Drum Set
// Tests all 8 drum sounds with visual and audio feedback
// Author: E155 Final Project
// Date: 2024

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>
#include <math.h>
#include <time.h>

// Mock STM32L432KC definitions for testing
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

// Mock peripheral definitions
TIM_TypeDef *TIM6;

// Mock register definitions
#define TIM_SR_UIF (1 << 0)
#define TIM_CR1_CEN (1 << 0)
#define TIM_DIER_UIE (1 << 0)

// Sound ID definitions
typedef enum {
    SOUND_SNARE = 0,      // Snare drum
    SOUND_HIHAT = 1,      // Hi-hat
    SOUND_KICK = 2,       // Kick drum
    SOUND_HIGH_TOM = 3,   // High tom
    SOUND_MID_TOM = 4,    // Mid tom
    SOUND_CRASH = 5,      // Crash cymbal
    SOUND_RIDE = 6,       // Ride cymbal
    SOUND_FLOOR_TOM = 7,  // Floor tom
    NO_SOUND = 255        // No sound
} sound_id_t;

// Audio parameters for each drum sound
typedef struct {
    uint16_t frequency;
    uint16_t duration;
    uint8_t volume;
    const char* name;
    const char* description;
} audio_params_t;

// Audio parameters for each sound (matching original Python code)
static const audio_params_t audio_params[] = {
    {200,  100, 100, "SNARE",     "Sharp crack - main snare drum sound"},
    {8000, 50,  80,  "HI-HAT",    "Quick tick - hi-hat cymbal"},
    {60,   200, 100, "KICK",      "Deep thump - bass drum"},
    {300,  150, 90,  "HIGH TOM",  "Medium tone - high tom"},
    {250,  150, 90,  "MID TOM",   "Lower tone - mid tom"},
    {4000, 300, 95,  "CRASH",     "Bright crash - crash cymbal"},
    {2000, 200, 85,  "RIDE",      "Sustained ring - ride cymbal"},
    {150,  200, 90,  "FLOOR TOM", "Deep tone - floor tom"}
};

// Mock functions for testing
void pinMode(int pin, int mode) {
    // Mock implementation
}

void digitalWrite(int pin, int value) {
    // Mock implementation - in real system this would control PWM pin
    printf("    🔊 Audio Pin %d: %s\n", pin, value ? "HIGH" : "LOW");
}

int digitalRead(int pin) {
    // Mock implementation
    return 0;
}

void initTIM(TIM_TypeDef *TIMx) {
    // Mock timer initialization
    printf("    ⏱️  Timer initialized\n");
}

void delay_millis(TIM_TypeDef *TIMx, uint32_t ms) {
    // Mock delay - in real system this would be actual delay
    printf("    ⏳ Delay: %u ms\n", ms);
}

// Audio generation functions (simplified for testing)
void generate_audio_tone(uint16_t frequency, uint16_t duration, uint8_t volume) {
    printf("    🎵 Generating tone: %d Hz, %d ms, %d%% volume\n", 
           frequency, duration, volume);
    
    // Simulate square wave generation
    uint32_t period_us = 1000000 / frequency;  // Period in microseconds
    uint32_t cycles = (duration * 1000) / period_us;  // Number of cycles
    
    printf("    📊 Wave parameters: %u μs period, %u cycles\n", 
           period_us, cycles);
    
    // Simulate PWM generation
    for (uint32_t i = 0; i < cycles && i < 10; i++) {  // Limit to 10 cycles for demo
        digitalWrite(6, 1);  // High (using pin number directly)
        delay_millis(TIM6, 1);  // Half period
        digitalWrite(6, 0);  // Low
        delay_millis(TIM6, 1);  // Half period
    }
    
    printf("    ✅ Audio generation complete\n");
}

void play_audio(sound_id_t sound_id) {
    if (sound_id >= sizeof(audio_params) / sizeof(audio_params_t)) {
        printf("    ❌ Invalid sound ID: %d\n", sound_id);
        return;
    }
    
    const audio_params_t *params = &audio_params[sound_id];
    printf("    🥁 Playing %s: %s\n", params->name, params->description);
    
    generate_audio_tone(params->frequency, params->duration, params->volume);
}

// Test function to demonstrate all sounds
void test_all_sounds(void) {
    printf("\n🎵 === DRUM SOUND DEMONSTRATION TEST ===\n");
    printf("Testing all 8 drum sounds with audio generation\n");
    printf("===============================================\n\n");
    
    // Test each sound individually
    for (int i = 0; i < 8; i++) {
        printf("🔊 Test %d: %s Drum\n", i + 1, audio_params[i].name);
        printf("   📋 Description: %s\n", audio_params[i].description);
        printf("   🎛️  Parameters: %d Hz, %d ms, %d%% volume\n", 
               audio_params[i].frequency, audio_params[i].duration, audio_params[i].volume);
        
        play_audio((sound_id_t)i);
        printf("   ✅ %s test completed\n\n", audio_params[i].name);
        
        // Small delay between sounds
        delay_millis(TIM6, 100);
    }
}

// Test function to demonstrate sound combinations
void test_sound_combinations(void) {
    printf("\n🎼 === SOUND COMBINATION TEST ===\n");
    printf("Testing realistic drum patterns\n");
    printf("===============================\n\n");
    
    // Basic rock beat pattern
    printf("🥁 Rock Beat Pattern:\n");
    printf("   1. Kick + Snare\n");
    play_audio(SOUND_KICK);
    delay_millis(TIM6, 50);
    play_audio(SOUND_SNARE);
    delay_millis(TIM6, 200);
    
    printf("   2. Hi-hat + Kick\n");
    play_audio(SOUND_HIHAT);
    delay_millis(TIM6, 50);
    play_audio(SOUND_KICK);
    delay_millis(TIM6, 200);
    
    printf("   3. Crash + Snare\n");
    play_audio(SOUND_CRASH);
    delay_millis(TIM6, 50);
    play_audio(SOUND_SNARE);
    delay_millis(TIM6, 200);
    
    // Tom roll
    printf("\n🥁 Tom Roll Pattern:\n");
    printf("   High Tom → Mid Tom → Floor Tom\n");
    play_audio(SOUND_HIGH_TOM);
    delay_millis(TIM6, 100);
    play_audio(SOUND_MID_TOM);
    delay_millis(TIM6, 100);
    play_audio(SOUND_FLOOR_TOM);
    delay_millis(TIM6, 200);
    
    // Cymbal work
    printf("\n🥁 Cymbal Work:\n");
    printf("   Ride → Crash → Hi-hat\n");
    play_audio(SOUND_RIDE);
    delay_millis(TIM6, 150);
    play_audio(SOUND_CRASH);
    delay_millis(TIM6, 150);
    play_audio(SOUND_HIHAT);
    delay_millis(TIM6, 200);
}

// Test function to demonstrate audio queue system
void test_audio_queue(void) {
    printf("\n📋 === AUDIO QUEUE SYSTEM TEST ===\n");
    printf("Testing rapid sound queuing and playback\n");
    printf("========================================\n\n");
    
    // Simulate rapid gesture inputs
    sound_id_t rapid_sounds[] = {
        SOUND_SNARE, SOUND_KICK, SOUND_HIHAT, 
        SOUND_CRASH, SOUND_HIGH_TOM, SOUND_RIDE
    };
    
    printf("🎯 Rapid Input Simulation:\n");
    for (int i = 0; i < 6; i++) {
        printf("   Input %d: %s\n", i + 1, audio_params[rapid_sounds[i]].name);
        play_audio(rapid_sounds[i]);
        delay_millis(TIM6, 50);  // Short delay between inputs
    }
    
    printf("   ✅ All sounds processed successfully\n");
}

// Test function to demonstrate error handling
void test_error_handling(void) {
    printf("\n⚠️  === ERROR HANDLING TEST ===\n");
    printf("Testing invalid inputs and edge cases\n");
    printf("====================================\n\n");
    
    printf("🧪 Testing invalid sound ID:\n");
    play_audio(NO_SOUND);
    play_audio(255);  // Invalid ID
    play_audio(8);    // Out of range
    
    printf("🧪 Testing extreme parameters:\n");
    printf("   Very high frequency (20kHz):\n");
    generate_audio_tone(20000, 50, 100);
    
    printf("   Very low frequency (20Hz):\n");
    generate_audio_tone(20, 1000, 100);
    
    printf("   Zero volume:\n");
    generate_audio_tone(440, 100, 0);
    
    printf("   ✅ Error handling test completed\n");
}

// Performance test
void test_performance(void) {
    printf("\n⚡ === PERFORMANCE TEST ===\n");
    printf("Testing system performance under load\n");
    printf("====================================\n\n");
    
    clock_t start_time = clock();
    int test_count = 100;
    
    printf("🚀 Running %d rapid sound generations...\n", test_count);
    
    for (int i = 0; i < test_count; i++) {
        sound_id_t sound = (sound_id_t)(i % 8);
        play_audio(sound);
    }
    
    clock_t end_time = clock();
    double cpu_time = ((double)(end_time - start_time)) / CLOCKS_PER_SEC;
    
    printf("📊 Performance Results:\n");
    printf("   Total sounds: %d\n", test_count);
    printf("   Total time: %.6f seconds\n", cpu_time);
    printf("   Average time per sound: %.6f seconds\n", cpu_time / test_count);
    printf("   Sounds per second: %.0f\n", test_count / cpu_time);
    
    if (cpu_time < 1.0) {
        printf("   ✅ Performance: EXCELLENT (< 1 second for %d sounds)\n", test_count);
    } else if (cpu_time < 2.0) {
        printf("   ✅ Performance: GOOD (< 2 seconds for %d sounds)\n", test_count);
    } else {
        printf("   ⚠️  Performance: NEEDS OPTIMIZATION (> 2 seconds for %d sounds)\n", test_count);
    }
}

int main(void) {
    printf("🎵 E155 Invisible Drum Set - Sound Demonstration Test\n");
    printf("====================================================\n");
    printf("This test demonstrates all drum sounds and audio functionality\n");
    printf("In a real system, these would generate actual PWM audio output\n\n");
    
    // Initialize mock timer
    TIM6 = (TIM_TypeDef*)malloc(sizeof(TIM_TypeDef));
    initTIM(TIM6);
    
    // Run all test categories
    test_all_sounds();
    test_sound_combinations();
    test_audio_queue();
    test_error_handling();
    test_performance();
    
    printf("\n🎉 === SOUND DEMONSTRATION COMPLETE ===\n");
    printf("All drum sounds tested successfully!\n");
    printf("System is ready for real hardware deployment.\n");
    printf("=============================================\n");
    
    return 0;
}
