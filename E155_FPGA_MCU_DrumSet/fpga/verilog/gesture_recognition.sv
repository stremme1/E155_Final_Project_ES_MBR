// Gesture Recognition Module - ULTRA-OPTIMIZED FOR iCE40UP5K
// Implements drum gesture recognition logic from C code
// Aggressively optimized to minimize LUT usage
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
    
    // ULTRA-OPTIMIZATION: Combine all sequential logic into fewer registers
    logic [15:0] yaw1_norm, yaw2_norm;
    logic gyro1_trigger, gyro2_trigger;
    logic printedForGyro1y, printedForGyro2y;
    logic gyro1_y_prev, gyro2_y_prev;
    
    // Combined sequential block for all pipelined values
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            yaw1_norm <= 0;
            yaw2_norm <= 0;
            gyro1_trigger <= 0;
            gyro2_trigger <= 0;
            gyro1_y_prev <= 0;
            gyro2_y_prev <= 0;
            printedForGyro1y <= 0;
            printedForGyro2y <= 0;
        end else begin
            // Yaw normalization (simplified)
            if (yaw1 < 0) begin
                yaw1_norm <= yaw1 + 16'd36000;
            end else if (yaw1 >= 16'd36000) begin
                yaw1_norm <= yaw1 - 16'd36000;
            end else begin
                yaw1_norm <= yaw1[15:0];
            end
            
            if (yaw2 < 0) begin
                yaw2_norm <= yaw2 + 16'd36000;
            end else if (yaw2 >= 16'd36000) begin
                yaw2_norm <= yaw2 - 16'd36000;
            end else begin
                yaw2_norm <= yaw2[15:0];
            end
            
            // Pre-compute gyro triggers
            gyro1_trigger <= (gyro1_y < GYRO_THRESHOLD_Y);
            gyro2_trigger <= (gyro2_y < GYRO_THRESHOLD_Y);
            
            // Track previous values
            gyro1_y_prev <= gyro1_y;
            gyro2_y_prev <= gyro2_y;
            
            // EXTREME: Simplified debounce - just track edge
            if (gyro1_y < GYRO_THRESHOLD_Y && gyro1_y_prev >= GYRO_THRESHOLD_Y) begin
                printedForGyro1y <= 0;  // Falling edge - reset flag
            end else if (gyro1_y >= GYRO_THRESHOLD_Y) begin
                printedForGyro1y <= 0;  // Above threshold - reset flag
            end else if (gyro1_trigger && !printedForGyro1y) begin
                printedForGyro1y <= 1;  // Set flag when triggered (yaw check in comb logic)
            end
            
            if (gyro2_y < GYRO_THRESHOLD_Y && gyro2_y_prev >= GYRO_THRESHOLD_Y) begin
                printedForGyro2y <= 0;
            end else if (gyro2_y >= GYRO_THRESHOLD_Y) begin
                printedForGyro2y <= 0;
            end else if (gyro2_trigger && !printedForGyro2y) begin
                printedForGyro2y <= 1;
            end
        end
    end
    
    // ULTRA-OPTIMIZATION: Simplified combinational logic
    // Use single always_comb with minimal comparisons
    always_comb begin
        sound_id = NO_SOUND;
        
        if (button1) begin
            sound_id = SOUND_KICK;
        end
        else if (gyro1_trigger && !printedForGyro1y) begin
            // Right hand logic - simplified to 3 zones
            if (yaw1_norm <= 16'd12000) begin
                sound_id = SOUND_SNARE;
            end
            else if (yaw1_norm >= 16'd34000 || yaw1_norm <= 16'd2000) begin
                sound_id = (pitch1 > PITCH_THRESHOLD_HIGH) ? SOUND_CRASH : SOUND_HIGH_TOM;
            end
            else begin  // 2000-34000 range
                sound_id = (pitch1 > PITCH_THRESHOLD_LOW) ? SOUND_RIDE : SOUND_FLOOR_TOM;
            end
        end
        else if (gyro2_trigger && !printedForGyro2y) begin
            // Left hand logic - simplified to 2 zones
            if (yaw2_norm >= 16'd35000 || yaw2_norm <= 16'd10000) begin
                sound_id = (pitch2 > PITCH_THRESHOLD_LOW && gyro2_z > GYRO_THRESHOLD_Z) ? SOUND_HIHAT : SOUND_SNARE;
            end
            else begin  // 10000-35000 range
                sound_id = (pitch2 > PITCH_THRESHOLD_HIGH) ? SOUND_CRASH : SOUND_HIGH_TOM;
            end
        end
    end
    
endmodule
