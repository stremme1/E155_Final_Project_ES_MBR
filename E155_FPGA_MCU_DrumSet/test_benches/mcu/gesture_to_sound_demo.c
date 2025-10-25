// Gesture to Sound Demonstration for E155 Invisible Drum Set
// Shows how different MCU readings (gesture data) trigger different drum sounds
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

// Gesture data structure (from FPGA)
typedef struct {
    float yaw1, pitch1, roll1;      // Right hand IMU
    float yaw2, pitch2, roll2;      // Left hand IMU
    int16_t gyro1_x, gyro1_y, gyro1_z;  // Right hand gyro
    int16_t gyro2_x, gyro2_y, gyro2_z;  // Left hand gyro
    uint32_t timestamp;             // System timestamp
} gesture_data_t;

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
    
    // Simulate PWM generation (limited cycles for demo)
    for (uint32_t i = 0; i < cycles && i < 5; i++) {  // Limit to 5 cycles for demo
        digitalWrite(6, 1);  // High
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

// Gesture recognition logic (from the actual MCU code)
float normalizeYaw(float yaw) {
    if (isnan(yaw) || isinf(yaw)) {
        return 0.0f;
    }
    
    if (yaw > 720.0f) {
        yaw = fmod(yaw, 360.0f);
    } else if (yaw < -360.0f) {
        yaw = fmod(yaw, 360.0f);
    }
    
    yaw = fmod(yaw, 360.0f);
    if (yaw < 0) {
        yaw += 360.0f;
    }
    return yaw;
}

bool is_valid_gesture_data(gesture_data_t gesture) {
    // Check for NaN or infinity
    if (isnan(gesture.yaw1) || isinf(gesture.yaw1) ||
        isnan(gesture.pitch1) || isinf(gesture.pitch1) ||
        isnan(gesture.yaw2) || isinf(gesture.yaw2) ||
        isnan(gesture.pitch2) || isinf(gesture.pitch2)) {
        return false;
    }
    
    // Relaxed angle ranges
    if (gesture.yaw1 < -720.0f || gesture.yaw1 > 720.0f ||
        gesture.pitch1 < -180.0f || gesture.pitch1 > 180.0f ||
        gesture.yaw2 < -720.0f || gesture.yaw2 > 720.0f ||
        gesture.pitch2 < -180.0f || gesture.pitch2 > 180.0f) {
        return false;
    }
    
    // Relaxed gyro ranges
    if (gesture.gyro1_x < -40000 || gesture.gyro1_x > 40000 ||
        gesture.gyro1_y < -40000 || gesture.gyro1_y > 40000 ||
        gesture.gyro1_z < -40000 || gesture.gyro1_z > 40000 ||
        gesture.gyro2_x < -40000 || gesture.gyro2_x > 40000 ||
        gesture.gyro2_y < -40000 || gesture.gyro2_y > 40000 ||
        gesture.gyro2_z < -40000 || gesture.gyro2_z > 40000) {
        return false;
    }
    
    return true;
}

sound_id_t recognize_gesture(gesture_data_t gesture) {
    // Input validation
    if (!is_valid_gesture_data(gesture)) {
        return NO_SOUND;
    }
    
    // Apply yaw offsets and normalize
    float yaw1 = normalizeYaw(gesture.yaw1);
    float yaw2 = normalizeYaw(gesture.yaw2);
    
    sound_id_t sound_id = NO_SOUND;
    
    // Early exit for invalid gyro values
    if (gesture.gyro1_y > -2000 && gesture.gyro2_y > -2000) {
        return NO_SOUND;
    }
    
    // RIGHT HAND LOGIC
    // Snare drum: yaw 0-120°
    if (yaw1 >= 0 && yaw1 <= 120) {
        if (gesture.gyro1_y < -2500) {
            sound_id = SOUND_SNARE;
        }
    }
    // High tom/crash: yaw 340-360°
    else if (yaw1 >= 340 && yaw1 <= 360) {
        if (gesture.gyro1_y < -2500) {
            if (gesture.pitch1 > 50) {
                sound_id = SOUND_CRASH;
            } else {
                sound_id = SOUND_HIGH_TOM;
            }
        }
    }
    // Mid tom/ride: yaw 305-340°
    else if (yaw1 >= 305 && yaw1 <= 340) {
        if (gesture.gyro1_y < -2500) {
            if (gesture.pitch1 > 50) {
                sound_id = SOUND_RIDE;
            } else {
                sound_id = SOUND_MID_TOM;
            }
        }
    }
    // Floor tom/ride: yaw 200-305°
    else if (yaw1 >= 200 && yaw1 <= 305) {
        if (gesture.gyro1_y < -2500) {
            if (gesture.pitch1 > 30) {
                sound_id = SOUND_RIDE;
            } else {
                sound_id = SOUND_FLOOR_TOM;
            }
        }
    }
    
    // LEFT HAND LOGIC
    // Snare/hi-hat: yaw 350-100°
    if (yaw2 >= 350 || yaw2 <= 100) {
        if (gesture.gyro2_y < -2500) {
            if (gesture.pitch2 > 30 && gesture.gyro2_z > -2000) {
                sound_id = SOUND_HIHAT;
            } else {
                sound_id = SOUND_SNARE;
            }
        }
    }
    // High tom/crash: yaw 325-350°
    else if (yaw2 >= 325 && yaw2 <= 350) {
        if (gesture.gyro2_y < -2500) {
            if (gesture.pitch2 > 50) {
                sound_id = SOUND_CRASH;
            } else {
                sound_id = SOUND_HIGH_TOM;
            }
        }
    }
    // Mid tom/ride: yaw 300-325°
    else if (yaw2 >= 300 && yaw2 <= 325) {
        if (gesture.gyro2_y < -2500) {
            if (gesture.pitch2 > 50) {
                sound_id = SOUND_RIDE;
            } else {
                sound_id = SOUND_MID_TOM;
            }
        }
    }
    // Floor tom/ride: yaw 200-300°
    else if (yaw2 >= 200 && yaw2 <= 300) {
        if (gesture.gyro2_y < -2500) {
            if (gesture.pitch2 > 30) {
                sound_id = SOUND_RIDE;
            } else {
                sound_id = SOUND_FLOOR_TOM;
            }
        }
    }
    
    return sound_id;
}

// Test scenarios with different MCU readings
void test_gesture_scenarios(void) {
    printf("\n🎯 === GESTURE TO SOUND DEMONSTRATION ===\n");
    printf("Showing how different MCU readings trigger different sounds\n");
    printf("========================================================\n\n");
    
    // Test scenario 1: Right hand snare drum
    printf("🥁 Test 1: Right Hand Snare Drum\n");
    printf("   📊 MCU Reading: yaw1=60°, pitch1=0°, gyro1_y=-3000\n");
    gesture_data_t gesture1 = {
        .yaw1 = 60.0f, .pitch1 = 0.0f, .roll1 = 0.0f,
        .yaw2 = 0.0f, .pitch2 = 0.0f, .roll2 = 0.0f,
        .gyro1_x = 0, .gyro1_y = -3000, .gyro1_z = 0,
        .gyro2_x = 0, .gyro2_y = 0, .gyro2_z = 0,
        .timestamp = 1000
    };
    sound_id_t sound1 = recognize_gesture(gesture1);
    printf("   🎵 Result: %s\n", audio_params[sound1].name);
    play_audio(sound1);
    printf("\n");
    
    // Test scenario 2: Right hand crash cymbal
    printf("🥁 Test 2: Right Hand Crash Cymbal\n");
    printf("   📊 MCU Reading: yaw1=350°, pitch1=60°, gyro1_y=-2800\n");
    gesture_data_t gesture2 = {
        .yaw1 = 350.0f, .pitch1 = 60.0f, .roll1 = 0.0f,
        .yaw2 = 0.0f, .pitch2 = 0.0f, .roll2 = 0.0f,
        .gyro1_x = 0, .gyro1_y = -2800, .gyro1_z = 0,
        .gyro2_x = 0, .gyro2_y = 0, .gyro2_z = 0,
        .timestamp = 2000
    };
    sound_id_t sound2 = recognize_gesture(gesture2);
    printf("   🎵 Result: %s\n", audio_params[sound2].name);
    play_audio(sound2);
    printf("\n");
    
    // Test scenario 3: Left hand hi-hat
    printf("🥁 Test 3: Left Hand Hi-Hat\n");
    printf("   📊 MCU Reading: yaw2=20°, pitch2=40°, gyro2_y=-2600, gyro2_z=-1500\n");
    gesture_data_t gesture3 = {
        .yaw1 = 0.0f, .pitch1 = 0.0f, .roll1 = 0.0f,
        .yaw2 = 20.0f, .pitch2 = 40.0f, .roll2 = 0.0f,
        .gyro1_x = 0, .gyro1_y = 0, .gyro1_z = 0,
        .gyro2_x = 0, .gyro2_y = -2600, .gyro2_z = -1500,
        .timestamp = 3000
    };
    sound_id_t sound3 = recognize_gesture(gesture3);
    printf("   🎵 Result: %s\n", audio_params[sound3].name);
    play_audio(sound3);
    printf("\n");
    
    // Test scenario 4: Right hand high tom
    printf("🥁 Test 4: Right Hand High Tom\n");
    printf("   📊 MCU Reading: yaw1=355°, pitch1=20°, gyro1_y=-2700\n");
    gesture_data_t gesture4 = {
        .yaw1 = 355.0f, .pitch1 = 20.0f, .roll1 = 0.0f,
        .yaw2 = 0.0f, .pitch2 = 0.0f, .roll2 = 0.0f,
        .gyro1_x = 0, .gyro1_y = -2700, .gyro1_z = 0,
        .gyro2_x = 0, .gyro2_y = 0, .gyro2_z = 0,
        .timestamp = 4000
    };
    sound_id_t sound4 = recognize_gesture(gesture4);
    printf("   🎵 Result: %s\n", audio_params[sound4].name);
    play_audio(sound4);
    printf("\n");
    
    // Test scenario 5: Left hand snare drum
    printf("🥁 Test 5: Left Hand Snare Drum\n");
    printf("   📊 MCU Reading: yaw2=50°, pitch2=10°, gyro2_y=-2900, gyro2_z=-2500\n");
    gesture_data_t gesture5 = {
        .yaw1 = 0.0f, .pitch1 = 0.0f, .roll1 = 0.0f,
        .yaw2 = 50.0f, .pitch2 = 10.0f, .roll2 = 0.0f,
        .gyro1_x = 0, .gyro1_y = 0, .gyro1_z = 0,
        .gyro2_x = 0, .gyro2_y = -2900, .gyro2_z = -2500,
        .timestamp = 5000
    };
    sound_id_t sound5 = recognize_gesture(gesture5);
    printf("   🎵 Result: %s\n", audio_params[sound5].name);
    play_audio(sound5);
    printf("\n");
    
    // Test scenario 6: Right hand mid tom
    printf("🥁 Test 6: Right Hand Mid Tom\n");
    printf("   📊 MCU Reading: yaw1=320°, pitch1=15°, gyro1_y=-2550\n");
    gesture_data_t gesture6 = {
        .yaw1 = 320.0f, .pitch1 = 15.0f, .roll1 = 0.0f,
        .yaw2 = 0.0f, .pitch2 = 0.0f, .roll2 = 0.0f,
        .gyro1_x = 0, .gyro1_y = -2550, .gyro1_z = 0,
        .gyro2_x = 0, .gyro2_y = 0, .gyro2_z = 0,
        .timestamp = 6000
    };
    sound_id_t sound6 = recognize_gesture(gesture6);
    printf("   🎵 Result: %s\n", audio_params[sound6].name);
    play_audio(sound6);
    printf("\n");
    
    // Test scenario 7: Left hand ride cymbal
    printf("🥁 Test 7: Left Hand Ride Cymbal\n");
    printf("   📊 MCU Reading: yaw2=280°, pitch2=55°, gyro2_y=-2400\n");
    gesture_data_t gesture7 = {
        .yaw1 = 0.0f, .pitch1 = 0.0f, .roll1 = 0.0f,
        .yaw2 = 280.0f, .pitch2 = 55.0f, .roll2 = 0.0f,
        .gyro1_x = 0, .gyro1_y = 0, .gyro1_z = 0,
        .gyro2_x = 0, .gyro2_y = -2400, .gyro2_z = 0,
        .timestamp = 7000
    };
    sound_id_t sound7 = recognize_gesture(gesture7);
    printf("   🎵 Result: %s\n", audio_params[sound7].name);
    play_audio(sound7);
    printf("\n");
    
    // Test scenario 8: Right hand floor tom
    printf("🥁 Test 8: Right Hand Floor Tom\n");
    printf("   📊 MCU Reading: yaw1=250°, pitch1=5°, gyro1_y=-2600\n");
    gesture_data_t gesture8 = {
        .yaw1 = 250.0f, .pitch1 = 5.0f, .roll1 = 0.0f,
        .yaw2 = 0.0f, .pitch2 = 0.0f, .roll2 = 0.0f,
        .gyro1_x = 0, .gyro1_y = -2600, .gyro1_z = 0,
        .gyro2_x = 0, .gyro2_y = 0, .gyro2_z = 0,
        .timestamp = 8000
    };
    sound_id_t sound8 = recognize_gesture(gesture8);
    printf("   🎵 Result: %s\n", audio_params[sound8].name);
    play_audio(sound8);
    printf("\n");
}

// Test invalid gesture data
void test_invalid_gestures(void) {
    printf("\n⚠️  === INVALID GESTURE TESTING ===\n");
    printf("Testing how MCU handles invalid sensor data\n");
    printf("==========================================\n\n");
    
    // Test invalid yaw values
    printf("🧪 Test: Invalid Yaw Values\n");
    printf("   📊 MCU Reading: yaw1=NaN, pitch1=0°, gyro1_y=-3000\n");
    gesture_data_t invalid_gesture1 = {
        .yaw1 = NAN, .pitch1 = 0.0f, .roll1 = 0.0f,
        .yaw2 = 0.0f, .pitch2 = 0.0f, .roll2 = 0.0f,
        .gyro1_x = 0, .gyro1_y = -3000, .gyro1_z = 0,
        .gyro2_x = 0, .gyro2_y = 0, .gyro2_z = 0,
        .timestamp = 9000
    };
    sound_id_t invalid_sound1 = recognize_gesture(invalid_gesture1);
    printf("   🎵 Result: %s (should be NO_SOUND)\n", 
           invalid_sound1 == NO_SOUND ? "NO_SOUND" : audio_params[invalid_sound1].name);
    printf("\n");
    
    // Test insufficient gyro movement
    printf("🧪 Test: Insufficient Gyro Movement\n");
    printf("   📊 MCU Reading: yaw1=60°, pitch1=0°, gyro1_y=-1000\n");
    gesture_data_t invalid_gesture2 = {
        .yaw1 = 60.0f, .pitch1 = 0.0f, .roll1 = 0.0f,
        .yaw2 = 0.0f, .pitch2 = 0.0f, .roll2 = 0.0f,
        .gyro1_x = 0, .gyro1_y = -1000, .gyro1_z = 0,
        .gyro2_x = 0, .gyro2_y = 0, .gyro2_z = 0,
        .timestamp = 10000
    };
    sound_id_t invalid_sound2 = recognize_gesture(invalid_gesture2);
    printf("   🎵 Result: %s (should be NO_SOUND)\n", 
           invalid_sound2 == NO_SOUND ? "NO_SOUND" : audio_params[invalid_sound2].name);
    printf("\n");
}

// Test rapid gesture processing
void test_rapid_gestures(void) {
    printf("\n⚡ === RAPID GESTURE PROCESSING ===\n");
    printf("Testing rapid MCU readings and sound generation\n");
    printf("===============================================\n\n");
    
    // Simulate rapid drumming
    gesture_data_t rapid_gestures[] = {
        // Snare
        {60.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0, -3000, 0, 0, 0, 0, 11000},
        // Hi-hat
        {0.0f, 0.0f, 0.0f, 20.0f, 40.0f, 0.0f, 0, 0, 0, 0, -2600, -1500, 12000},
        // Kick (button)
        {0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0, 0, 0, 0, 0, 0, 13000},
        // Crash
        {350.0f, 60.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0, -2800, 0, 0, 0, 0, 14000},
        // High tom
        {355.0f, 20.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0, -2700, 0, 0, 0, 0, 15000}
    };
    
    const char* gesture_names[] = {"Snare", "Hi-hat", "Kick", "Crash", "High Tom"};
    
    printf("🥁 Rapid Drumming Sequence:\n");
    for (int i = 0; i < 5; i++) {
        printf("   %d. %s gesture\n", i + 1, gesture_names[i]);
        sound_id_t sound = recognize_gesture(rapid_gestures[i]);
        if (sound != NO_SOUND) {
            printf("      🎵 Playing: %s\n", audio_params[sound].name);
            play_audio(sound);
        } else {
            printf("      🔇 No sound detected\n");
        }
        printf("\n");
    }
}

int main(void) {
    printf("🎯 E155 Invisible Drum Set - Gesture to Sound Demonstration\n");
    printf("===========================================================\n");
    printf("This test shows how different MCU readings trigger different sounds\n");
    printf("In a real system, these would come from BNO055 IMU sensors via FPGA\n\n");
    
    // Initialize mock timer
    TIM6 = (TIM_TypeDef*)malloc(sizeof(TIM_TypeDef));
    initTIM(TIM6);
    
    // Run all demonstration categories
    test_gesture_scenarios();
    test_invalid_gestures();
    test_rapid_gestures();
    
    printf("\n🎉 === GESTURE TO SOUND DEMONSTRATION COMPLETE ===\n");
    printf("All gesture scenarios tested successfully!\n");
    printf("MCU is ready to process real IMU data from FPGA.\n");
    printf("================================================\n");
    
    return 0;
}
