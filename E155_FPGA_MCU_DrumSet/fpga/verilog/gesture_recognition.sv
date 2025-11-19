// Gesture Recognition Module
// Implements drum gesture recognition logic from C code
// Determines which drum sound to play based on IMU data
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
    
    // Yaw ranges (in degrees * 100)
    localparam signed [15:0] YAW_SNARE_MIN = 16'd0;
    localparam signed [15:0] YAW_SNARE_MAX = 16'd12000;      // 120.00 degrees
    localparam signed [15:0] YAW_HIGH_TOM_MIN = 16'd34000;    // 340.00 degrees
    localparam signed [15:0] YAW_HIGH_TOM_MAX = 16'd36000;    // 360.00 degrees
    localparam signed [15:0] YAW_MID_TOM_MIN = 16'd30500;    // 305.00 degrees
    localparam signed [15:0] YAW_MID_TOM_MAX = 16'd34000;     // 340.00 degrees
    localparam signed [15:0] YAW_FLOOR_TOM_MIN = 16'd20000;   // 200.00 degrees
    localparam signed [15:0] YAW_FLOOR_TOM_MAX = 16'd30500;   // 305.00 degrees
    
    // Left hand yaw ranges
    localparam signed [15:0] YAW_LEFT_SNARE_MIN = 16'd35000;  // 350.00 degrees
    localparam signed [15:0] YAW_LEFT_SNARE_MAX = 16'd10000;  // 100.00 degrees (wraps around)
    localparam signed [15:0] YAW_LEFT_HIGH_MIN = 16'd32500;  // 325.00 degrees
    localparam signed [15:0] YAW_LEFT_HIGH_MAX = 16'd35000;   // 350.00 degrees
    localparam signed [15:0] YAW_LEFT_MID_MIN = 16'd30000;   // 300.00 degrees
    localparam signed [15:0] YAW_LEFT_MID_MAX = 16'd32500;   // 325.00 degrees
    localparam signed [15:0] YAW_LEFT_FLOOR_MIN = 16'd20000;  // 200.00 degrees
    localparam signed [15:0] YAW_LEFT_FLOOR_MAX = 16'd30000; // 300.00 degrees
    
    // Debouncing flags (matching C code behavior)
    logic printedForGyro1y, printedForGyro2y;
    logic gyro1_y_prev, gyro2_y_prev;
    
    // Normalize yaw to 0-36000 range (degrees * 100)
    logic signed [15:0] yaw1_norm, yaw2_norm;
    
    // Normalize yaw1 (0-36000)
    always_comb begin
        if (yaw1 < 0) begin
            yaw1_norm = yaw1 + 16'd36000;
        end else if (yaw1 >= 16'd36000) begin
            yaw1_norm = yaw1 - 16'd36000;
        end else begin
            yaw1_norm = yaw1;
        end
    end
    
    // Normalize yaw2 (0-36000)
    always_comb begin
        if (yaw2 < 0) begin
            yaw2_norm = yaw2 + 16'd36000;
        end else if (yaw2 >= 16'd36000) begin
            yaw2_norm = yaw2 - 16'd36000;
        end else begin
            yaw2_norm = yaw2;
        end
    end
    
    // Signals to track which hand triggered (computed in always_comb)
    logic right_hand_triggered, left_hand_triggered;
    
    // Determine which hand triggered (for debounce flag setting)
    always_comb begin
        right_hand_triggered = 0;
        left_hand_triggered = 0;
        
        if (!button1 && (gyro1_y <= -16'd2000 || gyro2_y <= -16'd2000)) begin
            // Right hand conditions
            if ((yaw1_norm >= YAW_SNARE_MIN && yaw1_norm <= YAW_SNARE_MAX) ||
                (yaw1_norm >= YAW_HIGH_TOM_MIN || yaw1_norm <= 16'd2000) ||
                (yaw1_norm >= YAW_MID_TOM_MIN && yaw1_norm <= YAW_MID_TOM_MAX) ||
                (yaw1_norm >= YAW_FLOOR_TOM_MIN && yaw1_norm <= YAW_FLOOR_TOM_MAX)) begin
                if (gyro1_y < GYRO_THRESHOLD_Y && !printedForGyro1y) begin
                    right_hand_triggered = 1;
                end
            end
            
            // Left hand conditions
            if ((yaw2_norm >= YAW_LEFT_SNARE_MIN || yaw2_norm <= YAW_LEFT_SNARE_MAX) ||
                (yaw2_norm >= YAW_LEFT_HIGH_MIN && yaw2_norm <= YAW_LEFT_HIGH_MAX) ||
                (yaw2_norm >= YAW_LEFT_MID_MIN && yaw2_norm <= YAW_LEFT_MID_MAX) ||
                (yaw2_norm >= YAW_LEFT_FLOOR_MIN && yaw2_norm <= YAW_LEFT_FLOOR_MAX)) begin
                if (gyro2_y < GYRO_THRESHOLD_Y && !printedForGyro2y) begin
                    left_hand_triggered = 1;
                end
            end
        end
    end
    
    // Track previous gyro values for debouncing
    // Combined into single always_ff to avoid multiple drivers
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
            // Set debounce flag when right hand triggers
            else if (right_hand_triggered && gyro1_y < GYRO_THRESHOLD_Y) begin
                printedForGyro1y <= 1;
            end
            
            if (gyro2_y < GYRO_THRESHOLD_Y && gyro2_y_prev >= GYRO_THRESHOLD_Y) begin
                printedForGyro2y <= 0;
            end else if (gyro2_y >= GYRO_THRESHOLD_Y && printedForGyro2y) begin
                printedForGyro2y <= 0;
            end
            // Set debounce flag when left hand triggers
            else if (left_hand_triggered && gyro2_y < GYRO_THRESHOLD_Y) begin
                printedForGyro2y <= 1;
            end
        end
    end
    
    // Gesture recognition logic
    always_comb begin
        sound_id = NO_SOUND;
        
        // Button 1: Kick drum
        if (button1) begin
            sound_id = SOUND_KICK;
        end
        // Early exit if no significant movement
        else if (gyro1_y > -16'd2000 && gyro2_y > -16'd2000) begin
            sound_id = NO_SOUND;
        end
        // RIGHT HAND LOGIC
        else if (yaw1_norm >= YAW_SNARE_MIN && yaw1_norm <= YAW_SNARE_MAX) begin
            if (gyro1_y < GYRO_THRESHOLD_Y && !printedForGyro1y) begin
                sound_id = SOUND_SNARE;
            end
        end
        else if (yaw1_norm >= YAW_HIGH_TOM_MIN || yaw1_norm <= 16'd2000) begin  // 340-360 or 0-20
            if (gyro1_y < GYRO_THRESHOLD_Y && !printedForGyro1y) begin
                if (pitch1 > PITCH_THRESHOLD_HIGH) begin
                    sound_id = SOUND_CRASH;
                end else begin
                    sound_id = SOUND_HIGH_TOM;
                end
            end
        end
        else if (yaw1_norm >= YAW_MID_TOM_MIN && yaw1_norm <= YAW_MID_TOM_MAX) begin
            if (gyro1_y < GYRO_THRESHOLD_Y && !printedForGyro1y) begin
                if (pitch1 > PITCH_THRESHOLD_HIGH) begin
                    sound_id = SOUND_RIDE;
                end else begin
                    sound_id = SOUND_MID_TOM;
                end
            end
        end
        else if (yaw1_norm >= YAW_FLOOR_TOM_MIN && yaw1_norm <= YAW_FLOOR_TOM_MAX) begin
            if (gyro1_y < GYRO_THRESHOLD_Y && !printedForGyro1y) begin
                if (pitch1 > PITCH_THRESHOLD_LOW) begin
                    sound_id = SOUND_RIDE;
                end else begin
                    sound_id = SOUND_FLOOR_TOM;
                end
            end
        end
        
        // LEFT HAND LOGIC (only if right hand didn't trigger)
        if (sound_id == NO_SOUND) begin
            // Left hand snare/hi-hat: yaw 350-100 (wraps around)
            if ((yaw2_norm >= YAW_LEFT_SNARE_MIN || yaw2_norm <= YAW_LEFT_SNARE_MAX)) begin
                if (gyro2_y < GYRO_THRESHOLD_Y && !printedForGyro2y) begin
                    if (pitch2 > PITCH_THRESHOLD_LOW && gyro2_z > GYRO_THRESHOLD_Z) begin
                        sound_id = SOUND_HIHAT;
                    end else begin
                        sound_id = SOUND_SNARE;
                    end
                end
            end
            // Left hand high tom/crash: yaw 325-350
            else if (yaw2_norm >= YAW_LEFT_HIGH_MIN && yaw2_norm <= YAW_LEFT_HIGH_MAX) begin
                if (gyro2_y < GYRO_THRESHOLD_Y && !printedForGyro2y) begin
                    if (pitch2 > PITCH_THRESHOLD_HIGH) begin
                        sound_id = SOUND_CRASH;
                    end else begin
                        sound_id = SOUND_HIGH_TOM;
                    end
                end
            end
            // Left hand mid tom/ride: yaw 300-325
            else if (yaw2_norm >= YAW_LEFT_MID_MIN && yaw2_norm <= YAW_LEFT_MID_MAX) begin
                if (gyro2_y < GYRO_THRESHOLD_Y && !printedForGyro2y) begin
                    if (pitch2 > PITCH_THRESHOLD_HIGH) begin
                        sound_id = SOUND_RIDE;
                    end else begin
                        sound_id = SOUND_MID_TOM;
                    end
                end
            end
            // Left hand floor tom/ride: yaw 200-300
            else if (yaw2_norm >= YAW_LEFT_FLOOR_MIN && yaw2_norm <= YAW_LEFT_FLOOR_MAX) begin
                if (gyro2_y < GYRO_THRESHOLD_Y && !printedForGyro2y) begin
                    if (pitch2 > PITCH_THRESHOLD_LOW) begin
                        sound_id = SOUND_RIDE;
                    end else begin
                        sound_id = SOUND_FLOOR_TOM;
                    end
                end
            end
        end
    end
    
endmodule

