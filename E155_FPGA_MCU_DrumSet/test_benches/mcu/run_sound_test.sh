#!/bin/bash

# Sound Demonstration Test Runner
# Compiles and runs the sound demonstration test

echo "🎵 E155 Invisible Drum Set - Sound Test Runner"
echo "=============================================="

# Compile the sound demonstration test
echo "🔨 Compiling sound demonstration test..."
gcc -o sound_demonstration_test sound_demonstration_test.c -lm

if [ $? -eq 0 ]; then
    echo "✅ Compilation successful!"
    echo ""
    echo "🎵 Running sound demonstration test..."
    echo "====================================="
    echo ""
    
    # Run the test
    ./sound_demonstration_test
    
    echo ""
    echo "🎉 Sound demonstration test completed!"
    echo "All drum sounds have been tested and demonstrated."
    
else
    echo "❌ Compilation failed!"
    echo "Please check for errors in the source code."
    exit 1
fi
