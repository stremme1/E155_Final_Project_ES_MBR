// Debug Test - Simple gesture recognition test
#include <stdio.h>
#include <assert.h>
#include <math.h>
#include <stdint.h>
#include <stdbool.h>

// Sound IDs
typedef enum {
    NO_SOUND = 255,
    SOUND_SNARE = 0,
    SOUND_HIHAT = 1,
    SOUND_KICK = 2,
    SOUND_HIGH_TOM = 3,
    SOUND_MID_TOM = 4,
    SOUND_CRASH = 5,
    SOUND_RIDE = 6,
    SOUND_FLOOR_TOM = 7
} sound_id_t;

// Gesture data structure
typedef struct {
    float yaw1, pitch1, roll1;
    int16_t gyro1_x, gyro1_y, gyro1_z;
    float yaw2, pitch2, roll2;
    int16_t gyro2_x, gyro2_y, gyro2_z;
    uint32_t timestamp;
} gesture_data_t;

// Function to normalize yaw values to 0-360 range
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

// Input validation for gesture data
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

// Gesture recognition function
sound_id_t recognize_gesture(gesture_data_t gesture) {
    // Input validation
    if (!is_valid_gesture_data(gesture)) {
        printf("DEBUG: Invalid gesture data\n");
        return NO_SOUND;
    }
    
    // Apply yaw offsets and normalize
    float yaw1 = normalizeYaw(gesture.yaw1);
    float yaw2 = normalizeYaw(gesture.yaw2);
    
    sound_id_t sound_id = NO_SOUND;
    
    // Early exit for invalid gyro values
    if (gesture.gyro1_y > -2000 && gesture.gyro2_y > -2000) {
        printf("DEBUG: Early exit - no significant movement\n");
        return NO_SOUND;
    }
    
    printf("DEBUG: Processing gesture - yaw1=%.1f, yaw2=%.1f, gyro1_y=%d, gyro2_y=%d\n", 
           yaw1, yaw2, gesture.gyro1_y, gesture.gyro2_y);
    
    // Right hand logic (FIXED)
    if (yaw1 >= 0 && yaw1 <= 120) {
        if (gesture.gyro1_y < -2500) {
            sound_id = SOUND_SNARE;
            printf("DEBUG: Right hand snare detected\n");
        }
    }
    else if (yaw1 >= 340 && yaw1 <= 360) {
        if (gesture.gyro1_y < -2500) {
            if (gesture.pitch1 > 50) {
                sound_id = SOUND_CRASH;
                printf("DEBUG: Right hand crash detected\n");
            } else {
                sound_id = SOUND_HIGH_TOM;
                printf("DEBUG: Right hand high tom detected\n");
            }
        }
    }
    
    // Left hand logic
    if (yaw2 >= 350 || yaw2 <= 100) {
        if (gesture.gyro2_y < -2500) {
            if (gesture.pitch2 > 30 && gesture.gyro2_z > -2000) {
                sound_id = SOUND_HIHAT;
                printf("DEBUG: Left hand hi-hat detected\n");
            } else {
                sound_id = SOUND_SNARE;
                printf("DEBUG: Left hand snare detected\n");
            }
        }
    }
    
    printf("DEBUG: Final sound_id = %d\n", sound_id);
    return sound_id;
}

int main() {
    printf("=== DEBUG TEST ===\n");
    
    // Test 1: Simple valid gesture
    gesture_data_t gesture;
    gesture.yaw1 = 60.0f;
    gesture.pitch1 = 30.0f;
    gesture.gyro1_x = 0;
    gesture.gyro1_y = -3000;
    gesture.gyro1_z = 0;
    gesture.yaw2 = 120.0f;
    gesture.pitch2 = 45.0f;
    gesture.gyro2_x = 0;
    gesture.gyro2_y = -2500;
    gesture.gyro2_z = -1000;
    gesture.roll1 = 0.0f;
    gesture.roll2 = 0.0f;
    gesture.timestamp = 0;
    
    printf("Test 1: Simple valid gesture\n");
    sound_id_t result = recognize_gesture(gesture);
    printf("Result: %d (expected: %d)\n", result, SOUND_SNARE);
    
    // Test 2: Rapid processing test case
    printf("\nTest 2: Rapid processing test case\n");
    gesture.yaw1 = 0;  // i=0 case
    gesture.pitch1 = 0;
    gesture.gyro1_x = -50;  // (0 % 100) - 50
    gesture.gyro1_y = -3000;  // -3000 + (0 % 1000)
    gesture.gyro1_z = -50;  // (0 % 100) - 50
    gesture.yaw2 = 180;  // (0 + 180) % 360
    gesture.pitch2 = 45;  // (0 + 45) % 90
    gesture.gyro2_x = -50;  // (0 % 100) - 50
    gesture.gyro2_y = -2500;  // -2500 + (0 % 500)
    gesture.gyro2_z = -1000;  // -1000 + (0 % 200)
    
    result = recognize_gesture(gesture);
    printf("Result: %d (expected: %d)\n", result, SOUND_SNARE);
    
    return 0;
}
