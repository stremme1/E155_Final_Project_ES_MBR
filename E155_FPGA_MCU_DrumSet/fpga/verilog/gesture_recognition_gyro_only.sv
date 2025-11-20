// Gesture Recognition - GYRO ONLY VERSION
// Removed all yaw/pitch calculations - uses only gyroscope triggers
// Absolute minimum logic
// Author: E155 Final Project
// Date: 2024

module gesture_recognition_gyro_only (
    input  logic        clk,
    input  logic        rst_n,
    input  logic signed [15:0] gyro_y,   // Gyroscope Y axis
    input  logic signed [15:0] gyro_z,   // Gyroscope Z axis
    input  logic        button1,          // Kick drum button
    output logic [7:0]  sound_id          // Drum sound ID
);

    localparam NO_SOUND = 8'hFF;
    localparam SOUND_SNARE = 8'h00;
    localparam SOUND_HIHAT = 8'h01;
    localparam SOUND_KICK = 8'h02;
    localparam SOUND_HIGH_TOM = 8'h03;
    localparam SOUND_MID_TOM = 8'h04;
    localparam SOUND_CRASH = 8'h05;
    localparam SOUND_RIDE = 8'h06;
    localparam SOUND_FLOOR_TOM = 8'h07;
    
    localparam signed [15:0] GYRO_THRESHOLD_Y = -16'd2500;
    localparam signed [15:0] GYRO_THRESHOLD_Z = -16'd2000;
    
    // MINIMAL: Just track gyro trigger and debounce
    logic gyro_trigger;
    logic printed;
    logic gyro_y_prev;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gyro_trigger <= 0;
            printed <= 0;
            gyro_y_prev <= 0;
        end else begin
            gyro_trigger <= (gyro_y < GYRO_THRESHOLD_Y);
            gyro_y_prev <= gyro_y;
            
            // Simple edge detection
            if (gyro_y < GYRO_THRESHOLD_Y && gyro_y_prev >= GYRO_THRESHOLD_Y) begin
                printed <= 0;  // Falling edge
            end else if (gyro_y >= GYRO_THRESHOLD_Y) begin
                printed <= 0;  // Above threshold
            end else if (gyro_trigger && !printed) begin
                printed <= 1;  // Triggered
            end
        end
    end
    
    // MINIMAL: Simple sound selection based on gyro Z
    always_comb begin
        sound_id = NO_SOUND;
        
        if (button1) begin
            sound_id = SOUND_KICK;
        end
        else if (gyro_trigger && !printed) begin
            // Simple: Use gyro_z to distinguish sounds
            if (gyro_z > GYRO_THRESHOLD_Z) begin
                sound_id = SOUND_HIHAT;
            end else begin
                sound_id = SOUND_SNARE;
            end
        end
    end
    
endmodule

