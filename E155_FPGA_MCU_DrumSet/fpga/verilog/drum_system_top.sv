// Top-level Drum System Module
// SystemVerilog implementation for UPduino v3.1
// Author: E155 Final Project
// Date: 2024

module drum_system_top (
    // Clock and Reset
    input  logic        clk,
    input  logic        rst_n,
    
    // I2C Interface for BNO055 sensors
    inout  wire         sda1, scl1,  // IMU 1
    inout  wire         sda2, scl2,  // IMU 2
    
    // SPI Interface to MCU
    input  logic        spi_clk,
    input  logic        spi_mosi,
    output logic        spi_miso,
    input  logic        spi_cs,
    
    // User Interface
    input  logic        button1,      // Record mode
    input  logic        button2,      // Playback mode
    input  logic        button3,      // Calibration
    output logic        led1,        // Record indicator
    output logic        led2,        // Playback indicator
    output logic        led3,        // Calibration indicator
    
    // Audio Output
    output logic        audio_out
);

    // Internal signals
    logic [31:0] quat1_w, quat1_x, quat1_y, quat1_z;
    logic [31:0] quat2_w, quat2_x, quat2_y, quat2_z;
    logic [31:0] gyro1_x, gyro1_y, gyro1_z;
    logic [31:0] gyro2_x, gyro2_y, gyro2_z;
    logic [31:0] roll1, pitch1, yaw1;
    logic [31:0] roll2, pitch2, yaw2;
    
    logic [7:0] gesture_data;
    logic [15:0] timestamp;
    logic [7:0] sound_id;
    
    logic i2c_done1, i2c_done2;
    logic euler_valid1, euler_valid2;
    logic data_valid;
    logic playback_ready;
    
    // Button debouncing
    logic button1_db, button2_db, button3_db;
    logic [15:0] debounce_counter;
    
    // Debounce buttons
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            debounce_counter <= 0;
            button1_db <= 0;
            button2_db <= 0;
            button3_db <= 0;
        end else begin
            if (debounce_counter < 16000) begin  // 1ms debounce
                debounce_counter <= debounce_counter + 1;
            end else begin
                debounce_counter <= 0;
                button1_db <= button1;
                button2_db <= button2;
                button3_db <= button3;
            end
        end
    end
    
    // I2C Master for IMU 1
    i2c_master i2c_master1 (
        .clk(clk),
        .rst_n(rst_n),
        .start(1'b1),
        .stop(1'b0),
        .device_addr(7'h28),  // BNO055 address 1
        .reg_addr(8'h20),     // Quaternion data register
        .write_data(8'h00),
        .read_data({quat1_w[7:0], quat1_x[7:0], quat1_y[7:0], quat1_z[7:0]}),
        .i2c_done(i2c_done1),
        .sda(sda1),
        .scl(scl1)
    );
    
    // I2C Master for IMU 2
    i2c_master i2c_master2 (
        .clk(clk),
        .rst_n(rst_n),
        .start(1'b1),
        .stop(1'b0),
        .device_addr(7'h29),  // BNO055 address 2
        .reg_addr(8'h20),     // Quaternion data register
        .write_data(8'h00),
        .read_data({quat2_w[7:0], quat2_x[7:0], quat2_y[7:0], quat2_z[7:0]}),
        .i2c_done(i2c_done2),
        .sda(sda2),
        .scl(scl2)
    );
    
    // Quaternion processor for IMU 1
    quaternion_processor quat_proc1 (
        .clk(clk),
        .rst_n(rst_n),
        .data_valid(i2c_done1),
        .quat_w(quat1_w),
        .quat_x(quat1_x),
        .quat_y(quat1_y),
        .quat_z(quat1_z),
        .roll(roll1),
        .pitch(pitch1),
        .yaw(yaw1),
        .euler_valid(euler_valid1)
    );
    
    // Quaternion processor for IMU 2
    quaternion_processor quat_proc2 (
        .clk(clk),
        .rst_n(rst_n),
        .data_valid(i2c_done2),
        .quat_w(quat2_w),
        .quat_x(quat2_x),
        .quat_y(quat2_y),
        .quat_z(quat2_z),
        .roll(roll2),
        .pitch(pitch2),
        .yaw(yaw2),
        .euler_valid(euler_valid2)
    );
    
    // Pattern recorder
    pattern_recorder pattern_rec (
        .clk(clk),
        .rst_n(rst_n),
        .record_enable(button1_db),
        .playback_enable(button2_db),
        .gesture_data({yaw1[15:0], pitch1[15:0]}),
        .timestamp(timestamp),
        .sound_id(sound_id),
        .playback_data(gesture_data),
        .playback_ready(playback_ready),
        .record_full(),
        .pattern_count()
    );
    
    // SPI interface to MCU
    spi_interface spi_if (
        .clk(clk),
        .rst_n(rst_n),
        .spi_clk(spi_clk),
        .spi_mosi(spi_mosi),
        .spi_miso(spi_miso),
        .spi_cs(spi_cs),
        .data_to_mcu({yaw1[15:0], pitch1[15:0], gyro1_y[15:0]}),
        .data_from_mcu(),
        .data_valid(data_valid),
        .spi_busy()
    );
    
    // Gesture recognition logic (from original Arduino code)
    always_comb begin
        sound_id = 8'h00;  // Default: no sound
        
        // Right hand logic
        if (yaw1 >= 20 && yaw1 <= 120) begin
            if (gyro1_y < -2500) begin
                sound_id = 8'h00;  // Snare drum
            end
        end
        else if (yaw1 >= 340 || yaw1 <= 20) begin
            if (gyro1_y < -2500) begin
                if (pitch1 > 50) begin
                    sound_id = 8'h05;  // Crash cymbal
                end else begin
                    sound_id = 8'h03;  // High tom
                end
            end
        end
        else if (yaw1 >= 305 && yaw1 <= 340) begin
            if (gyro1_y < -2500) begin
                if (pitch1 > 50) begin
                    sound_id = 8'h06;  // Ride cymbal
                end else begin
                    sound_id = 8'h04;  // Mid tom
                end
            end
        end
        else if (yaw1 >= 200 && yaw1 <= 305) begin
            if (gyro1_y < -2500) begin
                if (pitch1 > 30) begin
                    sound_id = 8'h06;  // Ride cymbal
                end else begin
                    sound_id = 8'h07;  // Floor tom
                end
            end
        end
        
        // Left hand logic
        if (yaw2 >= 350 || yaw2 <= 100) begin
            if (gyro2_y < -2500) begin
                if (pitch2 > 30 && gyro2_z > -2000) begin
                    sound_id = 8'h01;  // Hi-hat
                end else begin
                    sound_id = 8'h00;  // Snare drum
                end
            end
        end
    end
    
    // LED control
    assign led1 = button1_db;  // Record mode
    assign led2 = button2_db;  // Playback mode
    assign led3 = button3_db;  // Calibration mode
    
    // Audio output (PWM for MCU)
    assign audio_out = (sound_id != 8'h00) ? 1'b1 : 1'b0;
    
    // Timestamp counter
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timestamp <= 0;
        end else begin
            timestamp <= timestamp + 1;
        end
    end

endmodule
