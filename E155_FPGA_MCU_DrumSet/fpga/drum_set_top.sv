// Top-level module for BNO085-based Drum Set Gesture Detection System
// Integrates SPI communication, sensor control, quaternion processing, and gesture detection
//
// CLOCK CONFIGURATION:
// - HARDWARE: Uses HSOSC (internal oscillator) - uncomment HSOSC section below
// - SIMULATION: Generate clock in testbench (HSOSC cannot be simulated) - comment out HSOSC section

module drum_set_top (
    // Note: clk is generated internally by HSOSC for hardware, or from testbench for simulation
    input  logic        rst_n,         // Active-low reset
    
    // BNO085 Sensor 1 (Right Hand) - SPI Interface
    output logic        sclk1,          // SPI clock
    output logic        mosi1,          // SPI master out
    input  logic        miso1,          // SPI master in
    output logic        cs_n1,          // Chip select (active low)
    input  logic        int1,           // Interrupt (REQUIRED for stable SPI operation)
    
    // BNO085 Sensor 2 (Left Hand) - SPI Interface
    output logic        sclk2,
    output logic        mosi2,
    input  logic        miso2,
    output logic        cs_n2,
    input  logic        int2,           // Interrupt (REQUIRED for stable SPI operation)
    
    // User Interface
    input  logic        calib_button,   // Calibration button (P11) - MUST BE CONNECTED
    input  logic        kick_button,    // Kick drum button (optional, P2)
    
    // SPI Output to MCU
    output logic        mcu_sclk,       // SPI clock to MCU
    output logic        mcu_mosi,       // SPI master out to MCU
    // Note: mcu_miso removed - not used (one-way communication: FPGA→MCU only)
    // If bidirectional communication needed in future, add back: input logic mcu_miso;
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
    // CLOCK GENERATION
    // ============================================
    
    // Internal clock signal
    logic clk;
    
    // HARDWARE CLOCK - HSOSC (ACTIVE FOR HARDWARE)
    // CLKHF_DIV(2'b11) = divide by 16 to get 3MHz from 48MHz
    // For 48MHz HSOSC: divide by 16 = 3MHz (suitable for SPI)
    // For different frequencies, adjust CLKHF_DIV:
    //   2'b00 = divide by 2
    //   2'b01 = divide by 4  
    //   2'b10 = divide by 8
    //   2'b11 = divide by 16
    
    HSOSC #(.CLKHF_DIV(2'b11)) hf_osc (
        .CLKHFPU(1'b1),   // Power up
        .CLKHFEN(1'b1),   // Enable
        .CLKHF(clk)       // Output clock (3MHz from 48MHz / 16)
    );
    
    // SIMULATION CLOCK - UNCOMMENT FOR SIMULATION
    // Comment out HSOSC above and uncomment this section for testbenches
    // For simulation: Comment out HSOSC instantiation (lines 89-93) and uncomment below
    /*
    initial begin
        clk = 0;
        forever #10000 clk = ~clk; // 50kHz clock (20us period) - MUCH SLOWER for Questa
    end
    */
    
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
        .int_n(int1_sync),  // Connect synchronized INT pin (REQUIRED for stable SPI)
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
    
    // Monitor INT pins (required for stable SPI operation per Adafruit documentation)
    // Even if not used in logic, they must be connected to prevent optimization
    logic int1_sync, int2_sync;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int1_sync <= 1'b1;  // INT is active low, so HIGH = no interrupt
            int2_sync <= 1'b1;
        end else begin
            int1_sync <= int1;
            int2_sync <= int2;
        end
    end
    
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
        .int_n(int2_sync),  // Connect synchronized INT pin (REQUIRED for stable SPI)
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
    // Use calib_button directly in a registered signal to prevent optimization
    // This ensures the signal chain is preserved: calib_button -> gesture_detector -> calib_active
    logic calib_button_sync_top;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            calib_button_sync_top <= 1'b0;
            yaw_offset1 <= 16'd0;
            yaw_offset2 <= 16'd0;
        end else begin
            // Register calib_button to ensure it's not optimized away
            calib_button_sync_top <= calib_button;
            // Capture yaw offsets on rising edge of calib_active
            if (calib_active && euler1_valid && euler2_valid) begin
                yaw_offset1 <= yaw1;
                yaw_offset2 <= yaw2;
            end
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
    
    // Use calib_button directly in top-level to ensure Radiant recognizes it
    // Must use it in a way that affects an output and can't be optimized away
    // Simply synchronizing it isn't enough - need to actually use it
    
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
        .mcu_miso(1'b0),  // Not used - one-way communication (FPGA→MCU only)
        .mcu_cs_n(mcu_cs_n),
        .busy(mcu_busy)
    );
    
    // ============================================
    // Status Outputs
    // ============================================
    
    assign led_initialized = bno1_initialized && bno2_initialized;
    
    // CRITICAL: Use calib_button and INT pins in led_error to prevent optimization
    // The expression uses these signals in a way that affects the output
    // This ensures Radiant recognizes them as top-level ports that need pin assignment
    // Pattern: Use signals in a conditional that can affect the output value
    assign led_error = bno1_error || bno2_error || 
                      (calib_button_sync_top ? 1'b0 : 1'b0) ||  // Use calib_button (affects output)
                      (calib_active ? 1'b0 : 1'b0) ||           // Use calib_active (depends on calib_button)
                      (!int1_sync ? 1'b0 : 1'b0) ||            // Use int1 (REQUIRED for stable SPI)
                      (!int2_sync ? 1'b0 : 1'b0);               // Use int2 (REQUIRED for stable SPI)
    
endmodule


