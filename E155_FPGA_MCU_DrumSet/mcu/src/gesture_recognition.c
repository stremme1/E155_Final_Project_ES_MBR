// Gesture Recognition for Drum System
// Based on original Arduino code logic
// Author: E155 Final Project
// Date: 2024

#include "STM32L432KC.h"
#include "gesture_recognition.h"
#include <math.h>

// Global variables for debouncing (matching original Arduino code)
static bool printedForGyro1y = false;
static bool printedForGyro2y = false;
static float yawOffset1 = 0.0f;
static float yawOffset2 = 0.0f;

// Function to normalize yaw values to 0-360 range (OPTIMIZED for rapid processing)
float normalizeYaw(float yaw) {
    // OPTIMIZED: Handle edge cases for rapid processing
    if (isnan(yaw) || isinf(yaw)) {
        return 0.0f;  // Safe default
    }
    
    // Handle extreme values efficiently
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

void gesture_recognition_init(void) {
    // Initialize gesture recognition system
    printedForGyro1y = false;
    printedForGyro2y = false;
    yawOffset1 = 0.0f;
    yawOffset2 = 0.0f;
}

void perform_calibration(void) {
    // Calibrate sensors by setting current yaw as zero
    // This matches the original Arduino button 2 functionality
    yawOffset1 = 0.0f;  // Will be set by current sensor reading
    yawOffset2 = 0.0f;  // Will be set by current sensor reading
}

sound_id_t recognize_gesture(gesture_data_t gesture) {
    // Input validation and sanitization (OPTIMIZED for rapid processing)
    if (!is_valid_gesture_data(gesture)) {
        return NO_SOUND;
    }
    
    // Apply yaw offsets and normalize (matching original Arduino code)
    float yaw1 = normalizeYaw(gesture.yaw1 - yawOffset1);
    float yaw2 = normalizeYaw(gesture.yaw2 - yawOffset2);
    
    sound_id_t sound_id = NO_SOUND;
    
    // OPTIMIZED: Early exit for invalid gyro values to improve performance
    if (gesture.gyro1_y > -2000 && gesture.gyro2_y > -2000) {
        return NO_SOUND;  // No significant movement detected
    }
    
    // RIGHT HAND LOGIC (FIXED - matching original Arduino code exactly)
    // if yaw in the range of 0-120 then play snare drum (FIXED RANGE)
    if (yaw1 >= 0 && yaw1 <= 120) {
        if (gesture.gyro1_y < -2500 && !printedForGyro1y) {
            sound_id = SOUND_SNARE; // "0" - snare drum
            printedForGyro1y = true;
        } else if (gesture.gyro1_y >= -2500 && printedForGyro1y) {
            printedForGyro1y = false;
        }
    }
    // if yaw in the range of 340-360 then play high tom or crash (FIXED RANGE)
    else if (yaw1 >= 340 && yaw1 <= 360) {
        if (gesture.gyro1_y < -2500 && !printedForGyro1y) {
            if (gesture.pitch1 > 50) {
                sound_id = SOUND_CRASH; // "5" - crash cymbal
            } else {
                sound_id = SOUND_HIGH_TOM; // "3" - high tom
            }
            printedForGyro1y = true;
        } else if (gesture.gyro1_y >= -2500 && printedForGyro1y) {
            printedForGyro1y = false;
        }
    }
    // if yaw in the range of 305-340 then play mid tom or ride
    else if (yaw1 >= 305 && yaw1 <= 340) {
        if (gesture.gyro1_y < -2500 && !printedForGyro1y) {
            if (gesture.pitch1 > 50) {
                sound_id = SOUND_RIDE; // "6" - ride cymbal
            } else {
                sound_id = SOUND_MID_TOM; // "4" - mid tom
            }
            printedForGyro1y = true;
        } else if (gesture.gyro1_y >= -2500 && printedForGyro1y) {
            printedForGyro1y = false;
        }
    }
    // if yaw in the range of 200-305 then play floor tom or ride
    else if (yaw1 >= 200 && yaw1 <= 305) {
        if (gesture.gyro1_y < -2500 && !printedForGyro1y) {
            if (gesture.pitch1 > 30) {
                sound_id = SOUND_RIDE; // "6" - ride cymbal
            } else {
                sound_id = SOUND_FLOOR_TOM; // "7" - floor tom
            }
            printedForGyro1y = true;
        } else if (gesture.gyro1_y >= -2500 && printedForGyro1y) {
            printedForGyro1y = false;
        }
    }
    
    // LEFT HAND LOGIC (matching original Arduino code exactly)
    // if yaw in the range of 350-100 then play snare or hi-hat
    if (yaw2 >= 350 || yaw2 <= 100) {
        if (gesture.gyro2_y < -2500 && !printedForGyro2y) {
            // if facing up and not rotating fast around z axis
            if (gesture.pitch2 > 30 && gesture.gyro2_z > -2000) {
                sound_id = SOUND_HIHAT; // "1" - hi-hat
            } else {
                sound_id = SOUND_SNARE; // "0" - snare drum
            }
            printedForGyro2y = true;
        } else if (gesture.gyro2_y >= -2500 && printedForGyro2y) {
            printedForGyro2y = false;
        }
    }
    // if yaw in the range of 325-350 then play high tom or crash
    else if (yaw2 >= 325 && yaw2 <= 350) {
        if (gesture.gyro2_y < -2500 && !printedForGyro2y) {
            if (gesture.pitch2 > 50) {
                sound_id = SOUND_CRASH; // "5" - crash cymbal
            } else {
                sound_id = SOUND_HIGH_TOM; // "3" - high tom
            }
            printedForGyro2y = true;
        } else if (gesture.gyro2_y >= -2500 && printedForGyro2y) {
            printedForGyro2y = false;
        }
    }
    // if yaw in the range of 300-325 then play mid tom or ride
    else if (yaw2 >= 300 && yaw2 <= 325) {
        if (gesture.gyro2_y < -2500 && !printedForGyro2y) {
            if (gesture.pitch2 > 50) {
                sound_id = SOUND_RIDE; // "6" - ride cymbal
            } else {
                sound_id = SOUND_MID_TOM; // "4" - mid tom
            }
            printedForGyro2y = true;
        } else if (gesture.gyro2_y >= -2500 && printedForGyro2y) {
            printedForGyro2y = false;
        }
    }
    // if yaw in the range of 200-300 then play floor tom or ride
    else if (yaw2 >= 200 && yaw2 <= 300) {
        if (gesture.gyro2_y < -2500 && !printedForGyro2y) {
            if (gesture.pitch2 > 30) {
                sound_id = SOUND_RIDE; // "6" - ride cymbal
            } else {
                sound_id = SOUND_FLOOR_TOM; // "7" - floor tom
            }
            printedForGyro2y = true;
        } else if (gesture.gyro2_y >= -2500 && printedForGyro2y) {
            printedForGyro2y = false;
        }
    }
    
    return sound_id;
}

// Button functions (matching original Arduino code)
sound_id_t handle_button1(void) {
    // Button 1: Kick drum (matching original Arduino code)
    return SOUND_KICK; // "2" - kick drum
}

void handle_button2(gesture_data_t gesture) {
    // Button 2: Calibration (matching original Arduino code)
    // Set current yaw values as new zero (north)
    yawOffset1 = gesture.yaw1;
    yawOffset2 = gesture.yaw2;
}

// Get current yaw offsets (for debugging)
float get_yaw_offset1(void) {
    return yawOffset1;
}

float get_yaw_offset2(void) {
    return yawOffset2;
}

// Reset debouncing flags
void reset_debouncing_flags(void) {
    printedForGyro1y = false;
    printedForGyro2y = false;
}

// Input validation for gesture data (OPTIMIZED for rapid processing)
bool is_valid_gesture_data(gesture_data_t gesture) {
    // Check for NaN or infinity (critical for safety)
    if (isnan(gesture.yaw1) || isinf(gesture.yaw1) ||
        isnan(gesture.pitch1) || isinf(gesture.pitch1) ||
        isnan(gesture.yaw2) || isinf(gesture.yaw2) ||
        isnan(gesture.pitch2) || isinf(gesture.pitch2)) {
        return false;
    }
    
    // Relaxed angle ranges for rapid processing (allow wrap-around)
    if (gesture.yaw1 < -720.0f || gesture.yaw1 > 720.0f ||
        gesture.pitch1 < -180.0f || gesture.pitch1 > 180.0f ||
        gesture.yaw2 < -720.0f || gesture.yaw2 > 720.0f ||
        gesture.pitch2 < -180.0f || gesture.pitch2 > 180.0f) {
        return false;
    }
    
    // Relaxed gyro ranges for rapid processing (ALL gyro fields)
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