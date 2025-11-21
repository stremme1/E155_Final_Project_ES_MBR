// Top-level module for BNO085-based Drum Set Gesture Detection System
// Integrates SPI communication, sensor control, quaternion processing, and gesture detection

module drum_set_top (
    input  logic        clk,           // System clock (e.g., 50MHz)
    input  logic        rst_n,         // Active-low reset
    
    // BNO085 Sensor 1 (Right Hand) - SPI Interface
    output logic        sclk1,          // SPI clock
    output logic        mosi1,          // SPI master out
    input  logic        miso1,          // SPI master in
    output logic        cs_n1,          // Chip select (active low)
    input  logic        int1,           // Interrupt pin (optional)
    
    // BNO085 Sensor 2 (Left Hand) - SPI Interface
    output logic        sclk2,
    output logic        mosi2,
    input  logic        miso2,
    output logic        cs_n2,
    input  logic        int2,
    
    // User Interface
    input  logic        calib_button,   // Calibration button
    input  logic        kick_button,    // Kick drum button (optional)
    
    // SPI Output to MCU
    output logic        mcu_sclk,       // SPI clock to MCU
    output logic        mcu_mosi,       // SPI master out to MCU
    input  logic        mcu_miso,       // SPI master in from MCU (optional)
    output logic        mcu_cs_n,       // Chip select to MCU (active low)
    
    // Status LEDs (optional)
    output logic        led_initialized,
    output logic        led_error
);

    // Internal signals for Sensor 1
    logic spi1_start, spi1_tx_valid, spi1_tx_ready, spi1_rx_valid, spi1_busy;
    logic [7:0] spi1_tx_data, spi1_rx_data;
    logic quat1_valid, gyro1_valid;
    logic signed [15:0] quat1_w, quat1_x, quat1_y, quat1_z;
    logic signed [15:0] gyro1_x, gyro1_y, gyro1_z;
    logic signed [15:0] roll1, pitch1, yaw1;
    logic euler1_valid;
    logic bno1_initialized, bno1_error;
    
    // Internal signals for Sensor 2
    logic spi2_start, spi2_tx_valid, spi2_tx_ready, spi2_rx_valid, spi2_busy;
    logic [7:0] spi2_tx_data, spi2_rx_data;
    logic quat2_valid, gyro2_valid;
    logic signed [15:0] quat2_w, quat2_x, quat2_y, quat2_z;
    logic signed [15:0] gyro2_x, gyro2_y, gyro2_z;
    logic signed [15:0] roll2, pitch2, yaw2;
    logic euler2_valid;
    logic bno2_initialized, bno2_error;
    
    // Gesture detection signals
    logic sound_valid;
    logic [3:0] sound_code;
    logic [3:0] mcu_sound_code;
    logic mcu_data_valid;
    logic mcu_busy;
    logic calib_active;
    
    // Yaw offsets for calibration
    logic signed [15:0] yaw_offset1, yaw_offset2;
    
    // ============================================
    // Sensor 1 (Right Hand) - BNO085
    // ============================================
    
    spi_master #(.CLK_DIV(16)) spi_master1 (
        .clk(clk),
        .rst_n(rst_n),
        .start(spi1_start),
        .tx_valid(spi1_tx_valid),
        .tx_data(spi1_tx_data),
        .tx_ready(spi1_tx_ready),
        .rx_valid(spi1_rx_valid),
        .rx_data(spi1_rx_data),
        .busy(spi1_busy),
        .sclk(sclk1),
        .mosi(mosi1),
        .miso(miso1),
        .cs_n(cs_n1)
    );
    
    bno085_controller bno085_ctrl1 (
        .clk(clk),
        .rst_n(rst_n),
        .spi_start(spi1_start),
        .spi_tx_valid(spi1_tx_valid),
        .spi_tx_data(spi1_tx_data),
        .spi_tx_ready(spi1_tx_ready),
        .spi_rx_valid(spi1_rx_valid),
        .spi_rx_data(spi1_rx_data),
        .spi_busy(spi1_busy),
        .quat_valid(quat1_valid),
        .quat_w(quat1_w),
        .quat_x(quat1_x),
        .quat_y(quat1_y),
        .quat_z(quat1_z),
        .gyro_valid(gyro1_valid),
        .gyro_x(gyro1_x),
        .gyro_y(gyro1_y),
        .gyro_z(gyro1_z),
        .initialized(bno1_initialized),
        .error(bno1_error)
    );
    
    quaternion_to_euler quat_to_euler1 (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(quat1_valid),
        .quat_w(quat1_w),
        .quat_x(quat1_x),
        .quat_y(quat1_y),
        .quat_z(quat1_z),
        .valid_out(euler1_valid),
        .roll(roll1),
        .pitch(pitch1),
        .yaw(yaw1)
    );
    
    // ============================================
    // Sensor 2 (Left Hand) - BNO085
    // ============================================
    
    spi_master #(.CLK_DIV(16)) spi_master2 (
        .clk(clk),
        .rst_n(rst_n),
        .start(spi2_start),
        .tx_valid(spi2_tx_valid),
        .tx_data(spi2_tx_data),
        .tx_ready(spi2_tx_ready),
        .rx_valid(spi2_rx_valid),
        .rx_data(spi2_rx_data),
        .busy(spi2_busy),
        .sclk(sclk2),
        .mosi(mosi2),
        .miso(miso2),
        .cs_n(cs_n2)
    );
    
    bno085_controller bno085_ctrl2 (
        .clk(clk),
        .rst_n(rst_n),
        .spi_start(spi2_start),
        .spi_tx_valid(spi2_tx_valid),
        .spi_tx_data(spi2_tx_data),
        .spi_tx_ready(spi2_tx_ready),
        .spi_rx_valid(spi2_rx_valid),
        .spi_rx_data(spi2_rx_data),
        .spi_busy(spi2_busy),
        .quat_valid(quat2_valid),
        .quat_w(quat2_w),
        .quat_x(quat2_x),
        .quat_y(quat2_y),
        .quat_z(quat2_z),
        .gyro_valid(gyro2_valid),
        .gyro_x(gyro2_x),
        .gyro_y(gyro2_y),
        .gyro_z(gyro2_z),
        .initialized(bno2_initialized),
        .error(bno2_error)
    );
    
    quaternion_to_euler quat_to_euler2 (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(quat2_valid),
        .quat_w(quat2_w),
        .quat_x(quat2_x),
        .quat_y(quat2_y),
        .quat_z(quat2_z),
        .valid_out(euler2_valid),
        .roll(roll2),
        .pitch(pitch2),
        .yaw(yaw2)
    );
    
    // ============================================
    // Gesture Detection
    // ============================================
    
    gesture_detector gesture_det (
        .clk(clk),
        .rst_n(rst_n),
        .data_valid_1(euler1_valid && gyro1_valid),
        .yaw1(yaw1),
        .pitch1(pitch1),
        .gyro1_x(gyro1_x),
        .gyro1_y(gyro1_y),
        .gyro1_z(gyro1_z),
        .data_valid_2(euler2_valid && gyro2_valid),
        .yaw2(yaw2),
        .pitch2(pitch2),
        .gyro2_x(gyro2_x),
        .gyro2_y(gyro2_y),
        .gyro2_z(gyro2_z),
        .yaw_offset1(yaw_offset1),
        .yaw_offset2(yaw_offset2),
        .calib_button(calib_button),
        .sound_valid(sound_valid),
        .sound_code(sound_code),
        .calib_active(calib_active)
    );
    
    // Capture yaw offsets during calibration
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            yaw_offset1 <= 16'd0;
            yaw_offset2 <= 16'd0;
        end else if (calib_active && euler1_valid && euler2_valid) begin
            yaw_offset1 <= yaw1;
            yaw_offset2 <= yaw2;
        end
    end
    
    // ============================================
    // SPI Output to MCU
    // ============================================
    
    // Capture sound code and kick button for MCU transmission
    logic kick_button_prev;
    logic kick_button_edge;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            kick_button_prev <= 1'b0;
        end else begin
            kick_button_prev <= kick_button;
        end
    end
    
    assign kick_button_edge = kick_button && !kick_button_prev;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mcu_sound_code <= 4'd0;
            mcu_data_valid <= 1'b0;
        end else begin
            mcu_data_valid <= 1'b0;
            
            // Send sound code when gesture detected (and not busy)
            if (sound_valid && !mcu_busy) begin
                mcu_sound_code <= sound_code;
                mcu_data_valid <= 1'b1;
            end
            // Send kick drum code when button pressed (rising edge, and not busy)
            else if (kick_button_edge && !mcu_busy) begin
                mcu_sound_code <= 4'd2;  // Code 2 = Kick drum
                mcu_data_valid <= 1'b1;
            end
        end
    end
    
    spi_to_mcu #(.CLK_DIV(16)) spi_mcu_output (
        .clk(clk),
        .rst_n(rst_n),
        .data_valid(mcu_data_valid),
        .sound_code(mcu_sound_code),
        .mcu_sclk(mcu_sclk),
        .mcu_mosi(mcu_mosi),
        .mcu_miso(mcu_miso),
        .mcu_cs_n(mcu_cs_n),
        .busy(mcu_busy)
    );
    
    // ============================================
    // Status Outputs
    // ============================================
    
    assign led_initialized = bno1_initialized && bno2_initialized;
    assign led_error = bno1_error || bno2_error;
    
endmodule


