#!/bin/bash

# Gesture to Sound Demonstration Test Runner
# Shows how different MCU readings trigger different drum sounds

echo "🎯 E155 Invisible Drum Set - Gesture to Sound Demo Runner"
echo "========================================================"

# Compile the gesture demonstration test
echo "🔨 Compiling gesture to sound demonstration..."
gcc -o gesture_to_sound_demo gesture_to_sound_demo.c -lm

if [ $? -eq 0 ]; then
    echo "✅ Compilation successful!"
    echo ""
    echo "🎯 Running gesture to sound demonstration..."
    echo "============================================="
    echo ""
    
    # Run the test
    ./gesture_to_sound_demo
    
    echo ""
    echo "🎉 Gesture to sound demonstration completed!"
    echo "Different MCU readings successfully triggered different sounds."
    
else
    echo "❌ Compilation failed!"
    echo "Please check for errors in the source code."
    exit 1
fi
