// Top-level Drum System Module - SPI + DSP + BRAM VERSION
// Full implementation with two BNO085 IMUs via SPI
// Uses soft SPI controller (avoids massive I2C IP blocks)
// DSP blocks for quaternion math, BRAM for buffering
// Optimized for iCE40UP5K (5280 LUTs)
// Author: E155 Final Project
// Date: 2024

module drum_system_top (
    input  logic        clk_ext,
    input  logic        rst_n,
    
    // SPI Physical Pins (shared bus, two CS lines for two BNO085 IMUs)
    output logic        spi_sclk,      // SPI Clock (shared, Mode 3: CPOL=1, CPHA=1)
    output logic        spi_mosi,      // SPI Master Out Slave In (shared)
    input  logic        spi_miso,      // SPI Master In Slave Out (shared)
    output logic        spi_cs1_n,     // SPI Chip Select 1 (Right hand BNO085, active low)
    output logic        spi_cs2_n,     // SPI Chip Select 2 (Left hand BNO085, active low)
    
    // BNO085 Control Pins (required for stable SPI operation)
    input  logic        bno085_1_int_n, // BNO085 #1 Interrupt (active low, data ready)
    output logic        bno085_1_rst_n, // BNO085 #1 Reset (active low)
    input  logic        bno085_2_int_n, // BNO085 #2 Interrupt (active low, data ready)
    output logic        bno085_2_rst_n, // BNO085 #2 Reset (active low)
    
    // User Interface
    input  logic        button1,        // Kick drum button
    input  logic        button2,        // Calibration button
    output logic        led1,           // Sound active indicator
    output logic        led2,           // Calibration indicator
    output logic [7:0]  sound_id        // Drum sound ID (0-7, 255 = no sound)
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

    // ========================================================================
    // SPI Controller (shared for both IMUs)
    // ========================================================================
    logic spi_start, spi_tx_valid, spi_tx_ready, spi_rx_valid, spi_busy;
    logic [7:0] spi_tx_data, spi_rx_data;
    
    spi_controller spi_ctrl (
        .clk(clk),
        .rst_n(rst_n),
        .spi_sclk(spi_sclk),
        .spi_mosi(spi_mosi),
        .spi_miso(spi_miso),
        .spi_cs_n(),  // Handled by multiplexer
        .start(spi_start),
        .tx_data(spi_tx_data),
        .tx_valid(spi_tx_valid),
        .tx_ready(spi_tx_ready),
        .rx_data(spi_rx_data),
        .rx_valid(spi_rx_valid),
        .busy(spi_busy)
    );
    
    // ========================================================================
    // SPI Multiplexer (time-multiplex between two IMUs)
    // ========================================================================
    logic imu1_start, imu1_tx_valid, imu1_tx_ready, imu1_rx_valid, imu1_busy;
    logic imu2_start, imu2_tx_valid, imu2_tx_ready, imu2_rx_valid, imu2_busy;
    logic [7:0] imu1_tx_data, imu1_rx_data, imu2_tx_data, imu2_rx_data;
    
    // Note: Simplified - direct connection for now, can add multiplexer if needed
    assign spi_start = imu1_start | imu2_start;
    assign spi_tx_data = imu1_start ? imu1_tx_data : imu2_tx_data;
    assign spi_tx_valid = imu1_tx_valid | imu2_tx_valid;
    assign imu1_tx_ready = spi_tx_ready & imu1_start;
    assign imu2_tx_ready = spi_tx_ready & imu2_start;
    assign imu1_rx_data = spi_rx_data;
    assign imu2_rx_data = spi_rx_data;
    assign imu1_rx_valid = spi_rx_valid & imu1_start;
    assign imu2_rx_valid = spi_rx_valid & imu2_start;
    assign imu1_busy = spi_busy & imu1_start;
    assign imu2_busy = spi_busy & imu2_start;
    
    // CS lines (controlled by SPI transactions, not independent time-multiplexing)
    // CS should be asserted by the SPI controller during transactions
    // Time-multiplexing happens at higher level (which IMU to read)
    logic [15:0] imu_select_counter;
    logic imu_select;  // 0 = IMU1, 1 = IMU2
    
    // Time-multiplex IMU selection (~10ms intervals)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            imu_select_counter <= '0;
            imu_select <= 1'b0;
        end else begin
            if (imu_select_counter >= 16'd480000) begin  // ~10ms at 48MHz
                imu_select_counter <= '0;
                imu_select <= ~imu_select;
            end else begin
                imu_select_counter <= imu_select_counter + 1;
            end
        end
    end
    
    // CS control: Assert CS for selected IMU only when SPI is active
    // CS must be stable during entire SPI transaction
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            spi_cs1_n <= 1'b1;
            spi_cs2_n <= 1'b1;
        end else begin
            // Only assert CS when SPI transaction is active for selected IMU
            if (!imu_select && (imu1_start || spi_busy)) begin
                spi_cs1_n <= 1'b0;  // IMU1 selected and active
            end else begin
                spi_cs1_n <= 1'b1;
            end
            
            if (imu_select && (imu2_start || spi_busy)) begin
                spi_cs2_n <= 1'b0;  // IMU2 selected and active
            end else begin
                spi_cs2_n <= 1'b1;
            end
        end
    end
    
    // ========================================================================
    // BNO085 SPI Interfaces (2x - one per IMU)
    // ========================================================================
    logic imu1_data_valid, imu2_data_valid;
    logic signed [15:0] imu1_quat_w, imu1_quat_x, imu1_quat_y, imu1_quat_z;
    logic signed [15:0] imu1_gyro_x, imu1_gyro_y, imu1_gyro_z;
    logic signed [15:0] imu2_quat_w, imu2_quat_x, imu2_quat_y, imu2_quat_z;
    logic signed [15:0] imu2_gyro_x, imu2_gyro_y, imu2_gyro_z;
    
    bno085_spi_interface bno085_1 (
        .clk(clk),
        .rst_n(rst_n),
        .spi_start(imu1_start),
        .spi_tx_data(imu1_tx_data),
        .spi_tx_valid(imu1_tx_valid),
        .spi_tx_ready(imu1_tx_ready),
        .spi_rx_data(imu1_rx_data),
        .spi_rx_valid(imu1_rx_valid),
        .spi_busy(imu1_busy),
        .int_n(bno085_1_int_n),
        .rst_n_out(bno085_1_rst_n),
        .data_valid(imu1_data_valid),
        .quat_w(imu1_quat_w),
        .quat_x(imu1_quat_x),
        .quat_y(imu1_quat_y),
        .quat_z(imu1_quat_z),
        .gyro_x(imu1_gyro_x),
        .gyro_y(imu1_gyro_y),
        .gyro_z(imu1_gyro_z)
    );
    
    bno085_spi_interface bno085_2 (
        .clk(clk),
        .rst_n(rst_n),
        .spi_start(imu2_start),
        .spi_tx_data(imu2_tx_data),
        .spi_tx_valid(imu2_tx_valid),
        .spi_tx_ready(imu2_tx_ready),
        .spi_rx_data(imu2_rx_data),
        .spi_rx_valid(imu2_rx_valid),
        .spi_busy(imu2_busy),
        .int_n(bno085_2_int_n),
        .rst_n_out(bno085_2_rst_n),
        .data_valid(imu2_data_valid),
        .quat_w(imu2_quat_w),
        .quat_x(imu2_quat_x),
        .quat_y(imu2_quat_y),
        .quat_z(imu2_quat_z),
        .gyro_x(imu2_gyro_x),
        .gyro_y(imu2_gyro_y),
        .gyro_z(imu2_gyro_z)
    );
    
    // ========================================================================
    // Quaternion to Euler Conversion (2x - one per IMU, using DSP)
    // ========================================================================
    logic imu1_euler_valid, imu2_euler_valid;
    logic signed [15:0] imu1_roll, imu1_pitch, imu1_yaw;
    logic signed [15:0] imu2_roll, imu2_pitch, imu2_yaw;
    
    quaternion_to_euler_dsp quat_to_euler_1 (
        .clk(clk),
        .rst_n(rst_n),
        .quat_w(imu1_quat_w),
        .quat_x(imu1_quat_x),
        .quat_y(imu1_quat_y),
        .quat_z(imu1_quat_z),
        .data_valid(imu1_data_valid),
        .roll(imu1_roll),
        .pitch(imu1_pitch),
        .yaw(imu1_yaw),
        .euler_valid(imu1_euler_valid)
    );
    
    quaternion_to_euler_dsp quat_to_euler_2 (
        .clk(clk),
        .rst_n(rst_n),
        .quat_w(imu2_quat_w),
        .quat_x(imu2_quat_x),
        .quat_y(imu2_quat_y),
        .quat_z(imu2_quat_z),
        .data_valid(imu2_data_valid),
        .roll(imu2_roll),
        .pitch(imu2_pitch),
        .yaw(imu2_yaw),
        .euler_valid(imu2_euler_valid)
    );
    
    // ========================================================================
    // Yaw Normalization (2x - one per IMU)
    // ========================================================================
    logic signed [15:0] yaw_offset1, yaw_offset2;
    logic [15:0] yaw1_normalized, yaw2_normalized;
    logic yaw1_valid, yaw2_valid;
    
    yaw_normalize yaw_norm_1 (
        .clk(clk),
        .rst_n(rst_n),
        .yaw_in(imu1_yaw),
        .yaw_offset(yaw_offset1),
        .data_valid(imu1_euler_valid),
        .yaw_out(yaw1_normalized),
        .yaw_valid(yaw1_valid)
    );
    
    yaw_normalize yaw_norm_2 (
        .clk(clk),
        .rst_n(rst_n),
        .yaw_in(imu2_yaw),
        .yaw_offset(yaw_offset2),
        .data_valid(imu2_euler_valid),
        .yaw_out(yaw2_normalized),
        .yaw_valid(yaw2_valid)
    );
    
    // ========================================================================
    // Calibration Logic
    // ========================================================================
    logic calibration_active;
    
    calibration_logic calib (
        .clk(clk),
        .rst_n(rst_n),
        .yaw1_current(yaw1_normalized),
        .yaw2_current(yaw2_normalized),
        .yaw_valid(yaw1_valid & yaw2_valid),
        .button2(button2),
        .yaw_offset1(yaw_offset1),
        .yaw_offset2(yaw_offset2),
        .calibration_active(calibration_active)
    );
    
    // ========================================================================
    // Gesture Recognition (Full Logic Matching C Code)
    // ========================================================================
    logic sound_valid;
    
    gesture_recognition_full gesture (
        .clk(clk),
        .rst_n(rst_n),
        .yaw1_normalized(yaw1_normalized),
        .pitch1(imu1_pitch),
        .gyro1_y(imu1_gyro_y),
        .gyro1_z(imu1_gyro_z),
        .data1_valid(yaw1_valid),
        .yaw2_normalized(yaw2_normalized),
        .pitch2(imu2_pitch),
        .gyro2_y(imu2_gyro_y),
        .gyro2_z(imu2_gyro_z),
        .data2_valid(yaw2_valid),
        .button1(button1),
        .button2(button2),
        .sound_id(sound_id),
        .sound_valid(sound_valid)
    );
    
    // ========================================================================
    // Output Assignments
    // ========================================================================
    assign led1 = (sound_id != 8'hFF) & sound_valid;
    assign led2 = calibration_active;

endmodule

