// Gesture Recognition - Full Logic Matching Original C/Python Code
// Implements complete gesture recognition with two IMUs
// Matches logic from src/main.c and gesture_recognition.c exactly
// Author: E155 Final Project
// Date: 2024

module gesture_recognition_full (
    input  logic        clk,
    input  logic        rst_n,
    
    // IMU1 (Right Hand) Data
    input  logic signed [15:0] yaw1, pitch1,        // Euler angles (degrees)
    input  logic signed [15:0] gyro1_x, gyro1_y, gyro1_z,
    
    // IMU2 (Left Hand) Data
    input  logic signed [15:0] yaw2, pitch2,       // Euler angles (degrees)
    input  logic signed [15:0] gyro2_x, gyro2_y, gyro2_z,
    
    // User Input
    input  logic        button1,          // Kick drum button
    input  logic        button2,          // Calibration button
    
    // Calibration
    input  logic        calibrate,        // Calibration trigger
    output logic        calibration_done,  // Calibration complete
    
    // Output
    output logic [7:0]  sound_id          // Drum sound ID (0-7, 255 = no sound)
);

    // Sound IDs (matching original code)
    localparam NO_SOUND = 8'hFF;
    localparam SOUND_SNARE = 8'h00;
    localparam SOUND_HIHAT = 8'h01;
    localparam SOUND_KICK = 8'h02;
    localparam SOUND_HIGH_TOM = 8'h03;
    localparam SOUND_MID_TOM = 8'h04;
    localparam SOUND_CRASH = 8'h05;
    localparam SOUND_RIDE = 8'h06;
    localparam SOUND_FLOOR_TOM = 8'h07;
    
    // Thresholds (matching original code)
    localparam signed [15:0] GYRO_THRESHOLD_Y = -16'd2500;
    localparam signed [15:0] GYRO_THRESHOLD_Z = -16'd2000;
    localparam [7:0] PITCH_THRESHOLD_HIGH = 8'd50;
    localparam [7:0] PITCH_THRESHOLD_LOW = 8'd30;
    
    // Yaw normalization and offsets
    logic signed [15:0] yaw1_normalized, yaw2_normalized;
    logic signed [15:0] yaw_offset1, yaw_offset2;
    
    // Debouncing flags
    logic printedForGyro1y, printedForGyro2y;
    logic gyro1_y_prev, gyro2_y_prev;
    
    // Button debouncing
    logic button1_db, button2_db;
    logic [15:0] debounce_counter1, debounce_counter2;
    localparam DEBOUNCE_COUNT = 3000; // ~50ms at 48MHz
    
    // Yaw Normalization (0-360 range)
    function logic signed [15:0] normalize_yaw(input logic signed [15:0] yaw_in, input logic signed [15:0] offset);
        logic signed [15:0] yaw_temp;
        yaw_temp = yaw_in - offset;
        // Normalize to 0-360
        if (yaw_temp < 0) yaw_temp = yaw_temp + 16'd360;
        if (yaw_temp >= 16'd360) yaw_temp = yaw_temp - 16'd360;
        return yaw_temp;
    endfunction
    
    // Calibration
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            yaw_offset1 <= 0;
            yaw_offset2 <= 0;
            calibration_done <= 0;
        end else begin
            if (calibrate) begin
                yaw_offset1 <= yaw1;
                yaw_offset2 <= yaw2;
                calibration_done <= 1;
            end else begin
                calibration_done <= 0;
            end
        end
    end
    
    // Normalize yaw values
    assign yaw1_normalized = normalize_yaw(yaw1, yaw_offset1);
    assign yaw2_normalized = normalize_yaw(yaw2, yaw_offset2);
    
    // Button debouncing
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            debounce_counter1 <= 0;
            debounce_counter2 <= 0;
            button1_db <= 0;
            button2_db <= 0;
        end else begin
            if (debounce_counter1 < DEBOUNCE_COUNT) begin
                debounce_counter1 <= debounce_counter1 + 16'd1;
            end else begin
                debounce_counter1 <= 0;
                button1_db <= button1;
            end
            
            if (debounce_counter2 < DEBOUNCE_COUNT) begin
                debounce_counter2 <= debounce_counter2 + 16'd1;
            end else begin
                debounce_counter2 <= 0;
                button2_db <= button2;
            end
        end
    end
    
    // Gyro trigger debouncing (matching original code)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            printedForGyro1y <= 0;
            printedForGyro2y <= 0;
            gyro1_y_prev <= 0;
            gyro2_y_prev <= 0;
        end else begin
            gyro1_y_prev <= gyro1_y;
            gyro2_y_prev <= gyro2_y;
            
            // IMU1 debouncing
            if (gyro1_y < GYRO_THRESHOLD_Y && gyro1_y_prev >= GYRO_THRESHOLD_Y) begin
                printedForGyro1y <= 0;  // Falling edge - reset
            end else if (gyro1_y >= GYRO_THRESHOLD_Y) begin
                printedForGyro1y <= 0;  // Above threshold - reset
            end else if (gyro1_y < GYRO_THRESHOLD_Y && !printedForGyro1y) begin
                printedForGyro1y <= 1;  // Triggered
            end
            
            // IMU2 debouncing
            if (gyro2_y < GYRO_THRESHOLD_Y && gyro2_y_prev >= GYRO_THRESHOLD_Y) begin
                printedForGyro2y <= 0;
            end else if (gyro2_y >= GYRO_THRESHOLD_Y) begin
                printedForGyro2y <= 0;
            end else if (gyro2_y < GYRO_THRESHOLD_Y && !printedForGyro2y) begin
                printedForGyro2y <= 1;
            end
        end
    end
    
    // Gesture Recognition Logic (matching original C code exactly)
    always_comb begin
        sound_id = NO_SOUND;
        
        // Button 1: Kick drum
        if (button1_db) begin
            sound_id = SOUND_KICK;
        end
        // RIGHT HAND LOGIC (IMU1)
        else if (gyro1_y < GYRO_THRESHOLD_Y && !printedForGyro1y) begin
            // Yaw 20-120: Snare
            if (yaw1_normalized >= 16'd20 && yaw1_normalized <= 16'd120) begin
                sound_id = SOUND_SNARE;
            end
            // Yaw 340-360 or 0-20: High tom or Crash
            else if ((yaw1_normalized >= 16'd340 && yaw1_normalized <= 16'd360) ||
                     (yaw1_normalized >= 16'd0 && yaw1_normalized <= 16'd20)) begin
                if (pitch1 > PITCH_THRESHOLD_HIGH) begin
                    sound_id = SOUND_CRASH;
                end else begin
                    sound_id = SOUND_HIGH_TOM;
                end
            end
            // Yaw 305-340: Mid tom or Ride
            else if (yaw1_normalized >= 16'd305 && yaw1_normalized <= 16'd340) begin
                if (pitch1 > PITCH_THRESHOLD_HIGH) begin
                    sound_id = SOUND_RIDE;
                end else begin
                    sound_id = SOUND_MID_TOM;
                end
            end
            // Yaw 200-305: Floor tom or Ride
            else if (yaw1_normalized >= 16'd200 && yaw1_normalized <= 16'd305) begin
                if (pitch1 > PITCH_THRESHOLD_LOW) begin
                    sound_id = SOUND_RIDE;
                end else begin
                    sound_id = SOUND_FLOOR_TOM;
                end
            end
        end
        // LEFT HAND LOGIC (IMU2)
        else if (gyro2_y < GYRO_THRESHOLD_Y && !printedForGyro2y) begin
            // Yaw 350-360 or 0-100: Snare or Hi-hat
            if ((yaw2_normalized >= 16'd350 && yaw2_normalized <= 16'd360) ||
                (yaw2_normalized >= 16'd0 && yaw2_normalized <= 16'd100)) begin
                if (pitch2 > PITCH_THRESHOLD_LOW && gyro2_z > GYRO_THRESHOLD_Z) begin
                    sound_id = SOUND_HIHAT;
                end else begin
                    sound_id = SOUND_SNARE;
                end
            end
            // Yaw 325-350: High tom or Crash
            else if (yaw2_normalized >= 16'd325 && yaw2_normalized <= 16'd350) begin
                if (pitch2 > PITCH_THRESHOLD_HIGH) begin
                    sound_id = SOUND_CRASH;
                end else begin
                    sound_id = SOUND_HIGH_TOM;
                end
            end
            // Yaw 300-325: Mid tom or Ride
            else if (yaw2_normalized >= 16'd300 && yaw2_normalized <= 16'd325) begin
                if (pitch2 > PITCH_THRESHOLD_HIGH) begin
                    sound_id = SOUND_RIDE;
                end else begin
                    sound_id = SOUND_MID_TOM;
                end
            end
            // Yaw 200-300: Floor tom or Ride
            else if (yaw2_normalized >= 16'd200 && yaw2_normalized <= 16'd300) begin
                if (pitch2 > PITCH_THRESHOLD_LOW) begin
                    sound_id = SOUND_RIDE;
                end else begin
                    sound_id = SOUND_FLOOR_TOM;
                end
            end
        end
    end

endmodule

