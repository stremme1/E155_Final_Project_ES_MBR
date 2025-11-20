// Top-level Drum System Module - GYRO-ONLY VERSION
// CRITICAL: Removed quaternion-to-Euler conversion entirely
// Uses only gyroscope data for gesture recognition (saves ~500-700 LUTs)
// Author: E155 Final Project
// Date: 2024

module drum_system_top (
    input  logic        clk_ext,
    input  logic        rst_n,
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
    input  logic        button1,
    input  logic        button2,
    output logic        led1,
    output logic        led2,
    output logic [7:0]  sound_id
);
    
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

    // REMOVED: Quaternion data (not needed)
    // Only need gyroscope data
    logic signed [15:0] gyro_x, gyro_y, gyro_z;
    logic imu_data_valid;
    
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
    
    // BNO055 I2C Controller - GYRO ONLY
    bno055_i2c_controller_gyro_only imu_controller (
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
        .gyro_x(gyro_x),
        .gyro_y(gyro_y),
        .gyro_z(gyro_z),
        .data_valid(imu_data_valid)
    );
    
    // REMOVED: Quaternion-to-Euler conversion entirely
    
    // Gesture recognition - GYRO ONLY (no yaw/pitch)
    gesture_recognition_gyro_only gesture_rec (
        .clk(clk),
        .rst_n(rst_n),
        .gyro_y(gyro_y),
        .gyro_z(gyro_z),
        .button1(button1_db),
        .sound_id(sound_id)
    );
    
    assign led1 = (sound_id != 8'hFF);
    assign led2 = 1'b0;

endmodule
