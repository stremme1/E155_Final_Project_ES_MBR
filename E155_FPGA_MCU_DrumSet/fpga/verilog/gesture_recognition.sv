// Gesture Recognition Module - OPTIMIZED FOR iCE40UP5K
// Implements drum gesture recognition logic from C code
// Optimized to reduce LUT usage by simplifying comparisons
// Author: E155 Final Project
// Date: 2024

module gesture_recognition (
    input  logic        clk,
    input  logic        rst_n,
    
    // IMU 1 (Right Hand) Data
    input  logic signed [15:0] yaw1,      // Normalized yaw angle (0-360)
    input  logic signed [15:0] pitch1,     // Pitch angle
    input  logic signed [15:0] gyro1_y,   // Gyroscope Y axis
    
    // IMU 2 (Left Hand) Data
    input  logic signed [15:0] yaw2,      // Normalized yaw angle (0-360)
    input  logic signed [15:0] pitch2,     // Pitch angle
    input  logic signed [15:0] gyro2_y,   // Gyroscope Y axis
    input  logic signed [15:0] gyro2_z,   // Gyroscope Z axis
    
    // User Input
    input  logic        button1,          // Kick drum button
    
    // Output
    output logic [7:0]  sound_id          // Drum sound ID (0-7, 255 = no sound)
);

    // Sound IDs
    localparam NO_SOUND = 8'hFF;
    localparam SOUND_SNARE = 8'h00;
    localparam SOUND_HIHAT = 8'h01;
    localparam SOUND_KICK = 8'h02;
    localparam SOUND_HIGH_TOM = 8'h03;
    localparam SOUND_MID_TOM = 8'h04;
    localparam SOUND_CRASH = 8'h05;
    localparam SOUND_RIDE = 8'h06;
    localparam SOUND_FLOOR_TOM = 8'h07;
    
    // Thresholds (matching C code)
    localparam signed [15:0] GYRO_THRESHOLD_Y = -16'd2500;
    localparam signed [15:0] GYRO_THRESHOLD_Z = -16'd2000;
    localparam signed [15:0] PITCH_THRESHOLD_HIGH = 16'd5000;  // 50.00 degrees * 100
    localparam signed [15:0] PITCH_THRESHOLD_LOW = 16'd3000;   // 30.00 degrees * 100
    
    // OPTIMIZATION: Pre-compute normalized yaw and gyro conditions
    // This reduces combinational logic in the main always_comb block
    logic [15:0] yaw1_norm, yaw2_norm;
    logic gyro1_trigger, gyro2_trigger;
    logic right_hand_active, left_hand_active;
    
    // Normalize yaw to 0-36000 range (pipelined to reduce combinational logic)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            yaw1_norm <= 0;
            yaw2_norm <= 0;
        end else begin
            // Yaw1 normalization
            if (yaw1 < 0) begin
                yaw1_norm <= yaw1 + 16'd36000;
            end else if (yaw1 >= 16'd36000) begin
                yaw1_norm <= yaw1 - 16'd36000;
            end else begin
                yaw1_norm <= yaw1[15:0];
            end
            
            // Yaw2 normalization
            if (yaw2 < 0) begin
                yaw2_norm <= yaw2 + 16'd36000;
            end else if (yaw2 >= 16'd36000) begin
                yaw2_norm <= yaw2 - 16'd36000;
            end else begin
                yaw2_norm <= yaw2[15:0];
            end
        end
    end
    
    // Pre-compute gyro trigger conditions
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gyro1_trigger <= 0;
            gyro2_trigger <= 0;
        end else begin
            gyro1_trigger <= (gyro1_y < GYRO_THRESHOLD_Y);
            gyro2_trigger <= (gyro2_y < GYRO_THRESHOLD_Y);
        end
    end
    
    // Debouncing flags (matching C code behavior)
    logic printedForGyro1y, printedForGyro2y;
    logic gyro1_y_prev, gyro2_y_prev;
    
    // Track previous gyro values for debouncing
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gyro1_y_prev <= 0;
            gyro2_y_prev <= 0;
            printedForGyro1y <= 0;
            printedForGyro2y <= 0;
        end else begin
            gyro1_y_prev <= gyro1_y;
            gyro2_y_prev <= gyro2_y;
            
            // Reset debounce flags when gyro crosses threshold
            if (gyro1_y < GYRO_THRESHOLD_Y && gyro1_y_prev >= GYRO_THRESHOLD_Y) begin
                printedForGyro1y <= 0;
            end else if (gyro1_y >= GYRO_THRESHOLD_Y && printedForGyro1y) begin
                printedForGyro1y <= 0;
            end
            // Set debounce flag when right hand triggers (simplified condition)
            else if (gyro1_trigger && !printedForGyro1y && 
                     ((yaw1_norm <= 16'd12000) ||  // Snare range
                      (yaw1_norm >= 16'd34000) || // High tom range
                      (yaw1_norm <= 16'd2000) ||  // High tom wrap
                      ((yaw1_norm >= 16'd30500) && (yaw1_norm <= 16'd34000)) || // Mid tom
                      ((yaw1_norm >= 16'd20000) && (yaw1_norm <= 16'd30500)))) begin // Floor tom
                printedForGyro1y <= 1;
            end
            
            if (gyro2_y < GYRO_THRESHOLD_Y && gyro2_y_prev >= GYRO_THRESHOLD_Y) begin
                printedForGyro2y <= 0;
            end else if (gyro2_y >= GYRO_THRESHOLD_Y && printedForGyro2y) begin
                printedForGyro2y <= 0;
            end
            // Set debounce flag when left hand triggers (simplified condition)
            else if (gyro2_trigger && !printedForGyro2y &&
                     ((yaw2_norm >= 16'd35000) || (yaw2_norm <= 16'd10000) || // Snare range
                      ((yaw2_norm >= 16'd32500) && (yaw2_norm <= 16'd35000)) || // High tom
                      ((yaw2_norm >= 16'd30000) && (yaw2_norm <= 16'd32500)) || // Mid tom
                      ((yaw2_norm >= 16'd20000) && (yaw2_norm <= 16'd30000)))) begin // Floor tom
                printedForGyro2y <= 1;
            end
        end
    end
    
    // OPTIMIZATION: Simplified gesture recognition using pipelined values
    // Break into smaller always_comb blocks to reduce LUT depth
    logic [7:0] right_hand_sound, left_hand_sound;
    
    // Right hand logic (simplified)
    always_comb begin
        right_hand_sound = NO_SOUND;
        
        if (gyro1_trigger && !printedForGyro1y) begin
            if (yaw1_norm <= 16'd12000) begin  // Snare: 0-120
                right_hand_sound = SOUND_SNARE;
            end
            else if (yaw1_norm >= 16'd34000 || yaw1_norm <= 16'd2000) begin  // High tom: 340-360 or 0-20
                right_hand_sound = (pitch1 > PITCH_THRESHOLD_HIGH) ? SOUND_CRASH : SOUND_HIGH_TOM;
            end
            else if (yaw1_norm >= 16'd30500 && yaw1_norm <= 16'd34000) begin  // Mid tom: 305-340
                right_hand_sound = (pitch1 > PITCH_THRESHOLD_HIGH) ? SOUND_RIDE : SOUND_MID_TOM;
            end
            else if (yaw1_norm >= 16'd20000 && yaw1_norm <= 16'd30500) begin  // Floor tom: 200-305
                right_hand_sound = (pitch1 > PITCH_THRESHOLD_LOW) ? SOUND_RIDE : SOUND_FLOOR_TOM;
            end
        end
    end
    
    // Left hand logic (simplified)
    always_comb begin
        left_hand_sound = NO_SOUND;
        
        if (gyro2_trigger && !printedForGyro2y) begin
            if (yaw2_norm >= 16'd35000 || yaw2_norm <= 16'd10000) begin  // Snare: 350-100 (wrap)
                if (pitch2 > PITCH_THRESHOLD_LOW && gyro2_z > GYRO_THRESHOLD_Z) begin
                    left_hand_sound = SOUND_HIHAT;
                end else begin
                    left_hand_sound = SOUND_SNARE;
                end
            end
            else if (yaw2_norm >= 16'd32500 && yaw2_norm <= 16'd35000) begin  // High tom: 325-350
                left_hand_sound = (pitch2 > PITCH_THRESHOLD_HIGH) ? SOUND_CRASH : SOUND_HIGH_TOM;
            end
            else if (yaw2_norm >= 16'd30000 && yaw2_norm <= 16'd32500) begin  // Mid tom: 300-325
                left_hand_sound = (pitch2 > PITCH_THRESHOLD_HIGH) ? SOUND_RIDE : SOUND_MID_TOM;
            end
            else if (yaw2_norm >= 16'd20000 && yaw2_norm <= 16'd30000) begin  // Floor tom: 200-300
                left_hand_sound = (pitch2 > PITCH_THRESHOLD_LOW) ? SOUND_RIDE : SOUND_FLOOR_TOM;
            end
        end
    end
    
    // Final output selection (prioritize right hand, then left hand, then button)
    always_comb begin
        if (button1) begin
            sound_id = SOUND_KICK;
        end
        else if (right_hand_sound != NO_SOUND) begin
            sound_id = right_hand_sound;
        end
        else if (left_hand_sound != NO_SOUND) begin
            sound_id = left_hand_sound;
        end
        else begin
            sound_id = NO_SOUND;
        end
    end
    
endmodule
