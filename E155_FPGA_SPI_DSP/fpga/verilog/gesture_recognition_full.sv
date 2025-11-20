// Full Gesture Recognition Module
// Implements complete logic matching src/main.c
// Detects drum sounds based on yaw ranges, pitch thresholds, and gyro triggers
// Author: E155 Final Project
// Date: 2024

module gesture_recognition_full (
    input  logic        clk,
    input  logic        rst_n,
    
    // IMU1 Data (Right Hand)
    input  logic [15:0] yaw1_normalized,      // Normalized yaw (0-360 degrees, Q8)
    input  logic signed [15:0] pitch1,        // Pitch angle (degrees, Q8)
    input  logic signed [15:0] gyro1_y,      // Gyroscope Y-axis
    input  logic signed [15:0] gyro1_z,      // Gyroscope Z-axis
    input  logic        data1_valid,
    
    // IMU2 Data (Left Hand)
    input  logic [15:0] yaw2_normalized,      // Normalized yaw (0-360 degrees, Q8)
    input  logic signed [15:0] pitch2,        // Pitch angle (degrees, Q8)
    input  logic signed [15:0] gyro2_y,      // Gyroscope Y-axis
    input  logic signed [15:0] gyro2_z,      // Gyroscope Z-axis
    input  logic        data2_valid,
    
    // Button Inputs
    input  logic        button1,              // Kick drum button (right hand)
    input  logic        button2,              // Calibration button (left hand)
    
    // Output
    output logic [7:0]  sound_id,             // Drum sound ID (0-7, 255 = no sound)
    output logic        sound_valid            // Sound ID valid
);

    // Sound IDs (matching C code)
    localparam SOUND_SNARE = 8'h00;
    localparam SOUND_HIHAT = 8'h01;
    localparam SOUND_KICK = 8'h02;
    localparam SOUND_HIGH_TOM = 8'h03;
    localparam SOUND_MID_TOM = 8'h04;
    localparam SOUND_CRASH = 8'h05;
    localparam SOUND_RIDE = 8'h06;
    localparam SOUND_FLOOR_TOM = 8'h07;
    localparam NO_SOUND = 8'hFF;
    
    // Thresholds (matching C code)
    // Q8 format: -2500 in raw = -2500, but we need to compare properly
    localparam signed [15:0] GYRO_THRESHOLD_Y = -16'd2500;
    localparam signed [15:0] GYRO_THRESHOLD_Z = -16'd2000;
    localparam [15:0] PITCH_THRESHOLD_HIGH = 16'd12800;  // 50 degrees * 256 (Q8)
    localparam [15:0] PITCH_THRESHOLD_LOW = 16'd7680;    // 30 degrees * 256 (Q8)
    
    // Yaw ranges (in Q8 format: degrees * 256)
    localparam [15:0] YAW_20 = 16'd5120;   // 20 * 256
    localparam [15:0] YAW_100 = 16'd25600; // 100 * 256
    localparam [15:0] YAW_120 = 16'd30720; // 120 * 256
    localparam [15:0] YAW_200 = 16'd51200; // 200 * 256
    localparam [15:0] YAW_300 = 16'd76800; // 300 * 256
    localparam [15:0] YAW_305 = 16'd78080; // 305 * 256
    localparam [15:0] YAW_325 = 16'd83200; // 325 * 256
    localparam [15:0] YAW_340 = 16'd87040; // 340 * 256
    localparam [15:0] YAW_350 = 16'd89600; // 350 * 256
    localparam [15:0] YAW_360 = 16'd92160; // 360 * 256
    
    // Debounce flags (matching C code)
    logic printedForGyro1y, printedForGyro2y;
    logic button1_prev, button1_debounced;
    logic [23:0] button1_debounce_counter;  // Fixed: 24-bit for 2,400,000 count
    
    // Sound detection logic
    logic [7:0] sound_id_comb;
    logic sound_valid_comb;
    
    // Pipeline registers for data_valid synchronization
    logic data1_valid_sync, data2_valid_sync;
    logic data1_valid_pipe, data2_valid_pipe;
    
    // Synchronize data_valid signals
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data1_valid_sync <= 1'b0;
            data2_valid_sync <= 1'b0;
            data1_valid_pipe <= 1'b0;
            data2_valid_pipe <= 1'b0;
        end else begin
            data1_valid_pipe <= data1_valid;
            data2_valid_pipe <= data2_valid;
            data1_valid_sync <= data1_valid_pipe;
            data2_valid_sync <= data2_valid_pipe;
        end
    end
    
    // Gyro debouncing (matching C code logic)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            printedForGyro1y <= 1'b0;
            printedForGyro2y <= 1'b0;
            button1_prev <= 1'b0;
            button1_debounced <= 1'b0;
            button1_debounce_counter <= '0;
        end else begin
            button1_prev <= button1;
            
            // Button1 debouncing (50ms = 2400000 cycles at 48MHz)
            if (button1 != button1_prev) begin
                button1_debounce_counter <= '0;
            end else if (button1_debounce_counter < 24'd2400000) begin
                button1_debounce_counter <= button1_debounce_counter + 1;
            end else begin
                button1_debounced <= button1;
            end
            
            // Gyro1_y debouncing (only update when data is valid)
            if (data1_valid_sync) begin
                if (gyro1_y < GYRO_THRESHOLD_Y && !printedForGyro1y) begin
                    printedForGyro1y <= 1'b1;
                end else if (gyro1_y >= GYRO_THRESHOLD_Y && printedForGyro1y) begin
                    printedForGyro1y <= 1'b0;
                end
            end
            
            // Gyro2_y debouncing (only update when data is valid)
            if (data2_valid_sync) begin
                if (gyro2_y < GYRO_THRESHOLD_Y && !printedForGyro2y) begin
                    printedForGyro2y <= 1'b1;
                end else if (gyro2_y >= GYRO_THRESHOLD_Y && printedForGyro2y) begin
                    printedForGyro2y <= 1'b0;
                end
            end
        end
    end
    
    // Right Hand Logic (IMU1) - matching C code exactly
    always_comb begin
        sound_id_comb = NO_SOUND;
        sound_valid_comb = 1'b0;
        
        // Button1: Kick drum (priority - checked first)
        if (button1_debounced) begin
            sound_id_comb = SOUND_KICK;
            sound_valid_comb = 1'b1;
        end
        // Only check gestures if button1 is not pressed and data is valid
        else if (data1_valid_sync) begin
            // Right hand yaw ranges
            if (yaw1_normalized >= YAW_20 && yaw1_normalized <= YAW_120) begin
                // Yaw 20-120: Snare drum
                if (gyro1_y < GYRO_THRESHOLD_Y && !printedForGyro1y) begin
                    sound_id_comb = SOUND_SNARE;
                    sound_valid_comb = 1'b1;
                end
            end
            else if ((yaw1_normalized >= YAW_340) || (yaw1_normalized <= YAW_20)) begin
                // Yaw 340-360 or 0-20: High tom or Crash
                if (gyro1_y < GYRO_THRESHOLD_Y && !printedForGyro1y) begin
                    if (pitch1 > PITCH_THRESHOLD_HIGH) begin
                        sound_id_comb = SOUND_CRASH;
                    end else begin
                        sound_id_comb = SOUND_HIGH_TOM;
                    end
                    sound_valid_comb = 1'b1;
                end
            end
            else if (yaw1_normalized >= YAW_305 && yaw1_normalized <= YAW_340) begin
                // Yaw 305-340: Mid tom or Ride
                if (gyro1_y < GYRO_THRESHOLD_Y && !printedForGyro1y) begin
                    if (pitch1 > PITCH_THRESHOLD_HIGH) begin
                        sound_id_comb = SOUND_RIDE;
                    end else begin
                        sound_id_comb = SOUND_MID_TOM;
                    end
                    sound_valid_comb = 1'b1;
                end
            end
            else if (yaw1_normalized >= YAW_200 && yaw1_normalized <= YAW_305) begin
                // Yaw 200-305: Floor tom or Ride
                if (gyro1_y < GYRO_THRESHOLD_Y && !printedForGyro1y) begin
                    if (pitch1 > PITCH_THRESHOLD_LOW) begin
                        sound_id_comb = SOUND_RIDE;
                    end else begin
                        sound_id_comb = SOUND_FLOOR_TOM;
                    end
                    sound_valid_comb = 1'b1;
                end
            end
        end
        
        // Left Hand Logic (IMU2) - matching C code exactly
        if (!sound_valid_comb && data2_valid_sync) begin
            if ((yaw2_normalized >= YAW_350) || (yaw2_normalized <= YAW_100)) begin
                // Yaw 350-360 or 0-100: Snare or Hi-hat
                if (gyro2_y < GYRO_THRESHOLD_Y && !printedForGyro2y) begin
                    if (pitch2 > PITCH_THRESHOLD_LOW && gyro2_z > GYRO_THRESHOLD_Z) begin
                        sound_id_comb = SOUND_HIHAT;
                    end else begin
                        sound_id_comb = SOUND_SNARE;
                    end
                    sound_valid_comb = 1'b1;
                end
            end
            else if (yaw2_normalized >= YAW_325 && yaw2_normalized <= YAW_350) begin
                // Yaw 325-350: High tom or Crash
                if (gyro2_y < GYRO_THRESHOLD_Y && !printedForGyro2y) begin
                    if (pitch2 > PITCH_THRESHOLD_HIGH) begin
                        sound_id_comb = SOUND_CRASH;
                    end else begin
                        sound_id_comb = SOUND_HIGH_TOM;
                    end
                    sound_valid_comb = 1'b1;
                end
            end
            else if (yaw2_normalized >= YAW_300 && yaw2_normalized <= YAW_325) begin
                // Yaw 300-325: Mid tom or Ride
                if (gyro2_y < GYRO_THRESHOLD_Y && !printedForGyro2y) begin
                    if (pitch2 > PITCH_THRESHOLD_HIGH) begin
                        sound_id_comb = SOUND_RIDE;
                    end else begin
                        sound_id_comb = SOUND_MID_TOM;
                    end
                    sound_valid_comb = 1'b1;
                end
            end
            else if (yaw2_normalized >= YAW_200 && yaw2_normalized <= YAW_300) begin
                // Yaw 200-300: Floor tom or Ride
                if (gyro2_y < GYRO_THRESHOLD_Y && !printedForGyro2y) begin
                    if (pitch2 > PITCH_THRESHOLD_LOW) begin
                        sound_id_comb = SOUND_RIDE;
                    end else begin
                        sound_id_comb = SOUND_FLOOR_TOM;
                    end
                    sound_valid_comb = 1'b1;
                end
            end
        end
    end
    
    // Output register
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sound_id <= NO_SOUND;
            sound_valid <= 1'b0;
        end else begin
            sound_id <= sound_id_comb;
            sound_valid <= sound_valid_comb;
        end
    end

endmodule

