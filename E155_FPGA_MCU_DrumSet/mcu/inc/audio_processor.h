// Audio Processor Header File
// Author: E155 Final Project
// Date: 2024

#ifndef AUDIO_PROCESSOR_H
#define AUDIO_PROCESSOR_H

#include "STM32L432KC.h"
#include "gesture_recognition.h"

// Function prototypes
void audio_init(void);
void play_audio(sound_id_t sound_id);
void generate_audio_tone(uint16_t frequency, uint16_t duration, uint8_t volume);
void generate_audio_timer(uint16_t frequency, uint16_t duration, uint8_t volume);
void play_mixed_audio(sound_id_t sound1, sound_id_t sound2, uint8_t mix_ratio);
void apply_audio_effects(sound_id_t sound_id, uint8_t reverb_level, uint8_t echo_level);
void set_audio_volume(uint8_t volume);
uint8_t audio_is_playing(void);
void stop_audio(void);

#endif // AUDIO_PROCESSOR_H
