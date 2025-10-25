// Debug Actual Test - Check what's really happening
#include <stdio.h>
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

// Gesture recognition function (EXACT COPY from optimized_audit_test.c)
sound_id_t recognize_gesture(gesture_data_t gesture) {
    // Input validation and sanitization
    if (!is_valid_gesture_data(gesture)) {
        return NO_SOUND;
    }
    
    // Apply yaw offsets and normalize
    float yaw1 = normalizeYaw(gesture.yaw1);
    float yaw2 = normalizeYaw(gesture.yaw2);
    
    sound_id_t sound_id = NO_SOUND;
    
    // Early exit for invalid gyro values to improve performance
    if (gesture.gyro1_y > -2000 && gesture.gyro2_y > -2000) {
        return NO_SOUND;  // No significant movement detected
    }
    
    // Right hand logic (FIXED - matching original Arduino code exactly)
    if (yaw1 >= 0 && yaw1 <= 120) {
        if (gesture.gyro1_y < -2500) {
            sound_id = SOUND_SNARE; // "0"
        }
    }
    else if (yaw1 >= 340 && yaw1 <= 360) {
        if (gesture.gyro1_y < -2500) {
            if (gesture.pitch1 > 50) {
                sound_id = SOUND_CRASH; // "5"
            } else {
                sound_id = SOUND_HIGH_TOM; // "3"
            }
        }
    }
    
    // Left hand logic (matching original Arduino code exactly)
    if (yaw2 >= 350 || yaw2 <= 100) {
        if (gesture.gyro2_y < -2500) {
            if (gesture.pitch2 > 30 && gesture.gyro2_z > -2000) {
                sound_id = SOUND_HIHAT; // "1"
            } else {
                sound_id = SOUND_SNARE; // "0"
            }
        }
    }
    
    return sound_id;
}

int main() {
    printf("=== DEBUG ACTUAL TEST ===\n");
    
    int failures = 0;
    for (int i = 0; i < 10; i++) {
        gesture_data_t gesture;
        gesture.yaw1 = (i % 360);
        gesture.pitch1 = (i % 90);
        gesture.gyro1_x = (i % 100) - 50;  // -50 to 49
        gesture.gyro1_y = -3000 + (i % 1000);  // -3000 to -2001
        gesture.gyro1_z = (i % 100) - 50;  // -50 to 49
        gesture.yaw2 = ((i + 180) % 360);
        gesture.pitch2 = ((i + 45) % 90);
        gesture.gyro2_x = (i % 100) - 50;  // -50 to 49
        gesture.gyro2_y = -2500 + (i % 500);  // -2500 to -2001
        gesture.gyro2_z = -1000 + (i % 200);  // -1000 to -801
        gesture.roll1 = 0.0f;
        gesture.roll2 = 0.0f;
        gesture.timestamp = i;
        
        sound_id_t result = recognize_gesture(gesture);
        printf("Test %d: yaw1=%.1f, gyro1_y=%d, result=%d", i, gesture.yaw1, gesture.gyro1_y, result);
        
        // Check if result is valid
        if (result != NO_SOUND && (result < 0 || result > 7)) {
            printf(" ❌ INVALID");
            failures++;
        } else {
            printf(" ✅ VALID");
        }
        printf("\n");
    }
    
    printf("\nFailures: %d out of 10 tests\n", failures);
    return failures;
}
