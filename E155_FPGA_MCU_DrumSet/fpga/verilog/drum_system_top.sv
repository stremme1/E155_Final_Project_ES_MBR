// Top-level Drum System Module for iCE40 FPGA - SINGLE IMU VERSION
// CRITICAL OPTIMIZATION: Removed second IMU to save ~400-600 LUTs
// Uses hardened I2C IP block to communicate with BNO055 IMU sensor
// Implements gesture recognition and outputs drum sound IDs
// Author: E155 Final Project
// Date: 2024

module drum_system_top (
    // Clock and Reset
    input  logic        clk_ext,      // External clock input (for simulation)
    input  logic        rst_n,
    
    // System Bus Interface for I2C1 (Left I2C - Single IMU)
    output logic        i2c1_sb_clk,
    output logic        i2c1_sb_wr,
    output logic        i2c1_sb_stb,
    output logic [7:0]  i2c1_sb_addr,
    output logic [7:0]  i2c1_sb_data_i,
    input  logic [7:0]  i2c1_sb_data_o,
    input  logic        i2c1_sb_ack,
    input  logic        i2c1_irq,
    output logic        i2c1_ipload,
    input  logic        i2c1_ipdone,
    
    // REMOVED: I2C2 interface (second IMU removed to save resources)
    
    // User Interface
    input  logic        button1,      // Kick drum
    input  logic        button2,      // Unused (kept for compatibility)
    output logic        led1,         // Status LED
    output logic        led2,         // Status LED (always off)
    
    // Audio Output
    output logic [7:0]  sound_id      // Drum sound ID (0-7, 255 = no sound)
);
    
    // Clock generation
    logic clk;
    
`ifdef SIMULATION
    assign clk = clk_ext;
`else
    HSOSC #(.CLKHF_DIV(2'b11)) hf_osc (
        .CLKHFPU(1'b1), 
        .CLKHFEN(1'b1), 
        .CLKHF(clk)
    );
    (* keep *) wire _unused_clk_ext = clk_ext;
`endif

    // Internal signals for Single IMU (Right Hand only)
    logic [15:0] quat_w, quat_x, quat_y, quat_z;
    logic signed [15:0] gyro_x, gyro_y, gyro_z;
    logic signed [15:0] yaw, pitch, roll;
    logic imu_data_valid;
    
    // Yaw normalization
    logic signed [15:0] yaw_normalized;
    
    // Debouncing
    logic button1_db;
    logic [15:0] debounce_counter;
    localparam DEBOUNCE_COUNT = 3000;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            debounce_counter <= 0;
            button1_db <= 0;
        end else begin
            if (debounce_counter < DEBOUNCE_COUNT) begin
                debounce_counter <= debounce_counter + 16'd1;
            end else begin
                debounce_counter <= 0;
                button1_db <= button1;
            end
        end
    end
    
    // Yaw normalization (direct, no offset)
    always_comb begin
        if (yaw < 0) begin
            yaw_normalized = yaw + 16'sd36000;
        end else if (yaw >= 16'sd36000) begin
            yaw_normalized = yaw - 16'sd36000;
        end else begin
            yaw_normalized = yaw;
        end
    end
    
    // I2C IP initialization
    logic i2c1_ready;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            i2c1_ipload <= 0;
            i2c1_ready <= 0;
        end else begin
            if (!i2c1_ready) begin
                i2c1_ipload <= 1;
                if (i2c1_ipdone) begin
                    i2c1_ready <= 1;
                end
            end
        end
    end
    
    assign i2c1_sb_clk = clk;
    
    // BNO055 I2C Controller (Single IMU)
    bno055_i2c_controller imu_controller (
        .clk(clk),
        .rst_n(rst_n && i2c1_ready),
        .sb_clk(i2c1_sb_clk),
        .sb_wr(i2c1_sb_wr),
        .sb_stb(i2c1_sb_stb),
        .sb_addr(i2c1_sb_addr),
        .sb_data_i(i2c1_sb_data_i),
        .sb_data_o(i2c1_sb_data_o),
        .sb_ack(i2c1_sb_ack),
        .sb_irq(i2c1_irq),
        .quat_w(quat_w),
        .quat_x(quat_x),
        .quat_y(quat_y),
        .quat_z(quat_z),
        .gyro_x(gyro_x),
        .gyro_y(gyro_y),
        .gyro_z(gyro_z),
        .data_valid(imu_data_valid)
    );
    
    // Quaternion-to-Euler converter (no time-multiplexing needed)
    quaternion_to_euler quat_to_euler (
        .clk(clk),
        .rst_n(rst_n),
        .data_valid(imu_data_valid),
        .quat_w(quat_w),
        .quat_x(quat_x),
        .quat_y(quat_y),
        .quat_z(quat_z),
        .yaw(yaw),
        .pitch(pitch),
        .roll(roll),
        .euler_valid()
    );
    
    // Gesture recognition module (single-hand version)
    gesture_recognition gesture_rec (
        .clk(clk),
        .rst_n(rst_n),
        .yaw1(yaw_normalized),
        .pitch1(pitch),
        .gyro1_y(gyro_y),
        .yaw2(16'sd0),  // Not used
        .pitch2(16'sd0),  // Not used
        .gyro2_y(16'sd0),  // Not used
        .gyro2_z(16'sd0),  // Not used
        .button1(button1_db),
        .sound_id(sound_id)
    );
    
    // LED control
    assign led1 = (sound_id != 8'hFF);
    assign led2 = 1'b0;

endmodule
