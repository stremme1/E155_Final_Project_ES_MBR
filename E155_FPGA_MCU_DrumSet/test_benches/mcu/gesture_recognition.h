// Gesture Recognition Header File
// Author: E155 Final Project
// Date: 2024

#ifndef GESTURE_RECOGNITION_H
#define GESTURE_RECOGNITION_H

#include "STM32L432KC.h"
#include <stdint.h>
#include <stdbool.h>

// Sound IDs (matching original Arduino code exactly)
typedef enum {
    NO_SOUND = 255,       // No sound to play
    SOUND_SNARE = 0,      // "0" - Snare drum
    SOUND_HIHAT = 1,      // "1" - Hi-hat
    SOUND_KICK = 2,       // "2" - Kick drum
    SOUND_HIGH_TOM = 3,   // "3" - High tom
    SOUND_MID_TOM = 4,    // "4" - Mid tom
    SOUND_CRASH = 5,      // "5" - Crash cymbal
    SOUND_RIDE = 6,       // "6" - Ride cymbal
    SOUND_FLOOR_TOM = 7   // "7" - Floor tom
} sound_id_t;

// Gesture data structure
typedef struct {
    float yaw1, pitch1, roll1;
    int16_t gyro1_x, gyro1_y, gyro1_z;
    float yaw2, pitch2, roll2;
    int16_t gyro2_x, gyro2_y, gyro2_z;
    uint32_t timestamp;
} gesture_data_t;

// Gesture recognition thresholds
#define GYRO_THRESHOLD_Y     -2500
#define GYRO_THRESHOLD_Z     -2000
#define PITCH_THRESHOLD_HIGH  50
#define PITCH_THRESHOLD_LOW   30

// Yaw angle ranges for drum positions
#define YAW_SNARE_MIN        20
#define YAW_SNARE_MAX        120
#define YAW_HIGH_TOM_MIN     340
#define YAW_HIGH_TOM_MAX     20
#define YAW_MID_TOM_MIN      305
#define YAW_MID_TOM_MAX      340
#define YAW_FLOOR_TOM_MIN    200
#define YAW_FLOOR_TOM_MAX    305

// Left hand yaw ranges
#define YAW_LEFT_SNARE_MIN   350
#define YAW_LEFT_SNARE_MAX   100
#define YAW_LEFT_HIGH_MIN    325
#define YAW_LEFT_HIGH_MAX    350
#define YAW_LEFT_MID_MIN     300
#define YAW_LEFT_MID_MAX     325
#define YAW_LEFT_FLOOR_MIN   200
#define YAW_LEFT_FLOOR_MAX   300

// Function prototypes
void gesture_recognition_init(void);
sound_id_t recognize_gesture(gesture_data_t gesture);
void perform_calibration(void);
sound_id_t handle_button1(void);
void handle_button2(gesture_data_t gesture);
float get_yaw_offset1(void);
float get_yaw_offset2(void);
void reset_debouncing_flags(void);
float normalizeYaw(float yaw);

#endif // GESTURE_RECOGNITION_H
