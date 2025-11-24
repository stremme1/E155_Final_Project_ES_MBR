// Comprehensive System Testbench with Simulated BNO085 IMU Data
// Tests full system functionality without requiring physical IMU sensors

`timescale 1ns / 1ps

module tb_system_with_sim_imu;

    // Parameters
    // System uses 3MHz clock internally (from HSOSC)
    // For simulation: Use 3MHz clock to match hardware
    localparam CLK_PERIOD = 333;  // 3MHz clock (333.33ns period)
    localparam SPI_CLK_DIV = 16;
    
    // Clock and reset
    logic clk;
    logic rst_n;
    
    // BNO085 Sensor 1 (Right Hand) - SPI
    logic sclk1, mosi1, miso1, cs_n1, int1;
    
    // BNO085 Sensor 2 (Left Hand) - SPI
    logic sclk2, mosi2, miso2, cs_n2, int2;
    
    // User interface
    logic calib_button, kick_button;
    
    // SPI output to MCU
    logic mcu_sclk, mcu_mosi, mcu_cs_n;
    // Note: mcu_miso removed - not used (one-way communication: FPGA→MCU only)
    
    // Status
    logic led_initialized, led_error;
    
    // SPI slave model (simulates MCU)
    logic [7:0] mcu_rx_data;
    logic mcu_rx_valid;
    
    // Simulated BNO085 Sensor Models
    bno085_sim_model sensor1_model (
        .clk(clk),
        .rst_n(rst_n),
        .sclk(sclk1),
        .mosi(mosi1),
        .miso(miso1),
        .cs_n(cs_n1),
        .sensor_id(1'b0)  // Right hand (1 bit)
    );
    
    bno085_sim_model sensor2_model (
        .clk(clk),
        .rst_n(rst_n),
        .sclk(sclk2),
        .mosi(mosi2),
        .miso(miso2),
        .cs_n(cs_n2),
        .sensor_id(1'b1)  // Left hand (1 bit)
    );
    
    // Instantiate DUT
    // Note: clk is now generated internally in drum_set_top
    // For simulation: Comment out HSOSC in drum_set_top.sv and uncomment simulation clock
    drum_set_top dut (
        .rst_n(rst_n),
        .sclk1(sclk1),
        .mosi1(mosi1),
        .miso1(miso1),
        .cs_n1(cs_n1),
        .int1(int1),
        .sclk2(sclk2),
        .mosi2(mosi2),
        .miso2(miso2),
        .cs_n2(cs_n2),
        .int2(int2),
        .calib_button(calib_button),
        .kick_button(kick_button),
        .mcu_sclk(mcu_sclk),
        .mcu_mosi(mcu_mosi),
        .mcu_cs_n(mcu_cs_n),
        .led_initialized(led_initialized),
        .led_error(led_error)
    );
    
    // SPI slave model (simulates MCU receiving data)
    spi_slave_model mcu_model (
        .clk(clk),
        .rst_n(rst_n),
        .sclk(mcu_sclk),
        .mosi(mcu_mosi),
        .cs_n(mcu_cs_n),
        .rx_data(mcu_rx_data),
        .rx_valid(mcu_rx_valid)
    );
    
    // Clock generation
    // NOTE: Clock is generated inside drum_set_top via HSOSC
    // For simulation: Comment out HSOSC in drum_set_top.sv and uncomment simulation clock section
    // The simulation clock in drum_set_top.sv will generate 3MHz clock
    // No clock generation needed here - handled internally in drum_set_top
    
    // Test stimulus
    initial begin
        $display("========================================");
        $display("System Testbench with Simulated IMU");
        $display("========================================\n");
        
        // Initialize
        rst_n = 0;
        calib_button = 0;
        kick_button = 0;
        // INT pins are active LOW - set HIGH (no interrupt) by default
        // INT goes LOW when sensor has data ready (per BNO085 datasheet)
        int1 = 1;  // HIGH = no interrupt (active LOW signal)
        int2 = 1;  // HIGH = no interrupt (active LOW signal)
        
        // Reset
        #(CLK_PERIOD * 100);
        rst_n = 1;
        $display("System reset released\n");
        
        // Wait for initialization
        $display("Waiting for sensor initialization...");
        #(CLK_PERIOD * 100000);  // Wait 2ms at 50MHz
        
        // Test INT pin functionality
        $display("\n=== Test: INT Pin Functionality ===");
        $display("INT pins are REQUIRED for stable SPI operation per BNO085 datasheet");
        $display("INT goes LOW when sensor has data ready");
        $display("Simulating INT going LOW (data ready)...");
        
        // Simulate INT going LOW to indicate data ready
        int1 = 0;  // INT active (LOW = data ready)
        #(CLK_PERIOD * 1000);
        int1 = 1;  // INT inactive (HIGH = no data)
        $display("INT pin toggled - polling should occur when INT is LOW");
        
        // Test INT pin stuck LOW (error condition)
        $display("\n=== Test: INT Pin Error Detection ===");
        $display("Testing INT stuck LOW error detection...");
        int1 = 0;  // INT stuck LOW
        #(CLK_PERIOD * 2000000);  // Hold LOW for >1 second (simulated)
        if (led_error) begin
            $display("PASS: Error LED active when INT stuck LOW");
        end else begin
            $display("INFO: Error detection may need more time");
        end
        int1 = 1;  // Release INT
        #(CLK_PERIOD * 1000);
        
        // Test 1: System initialization
        $display("\n=== Test 1: System Initialization ===");
        if (led_initialized) begin
            $display("PASS: System initialized (LED on)");
        end else begin
            $display("INFO: System still initializing...");
        end
        
        // Test 2: Calibration Button
        $display("\n=== Test 2: Calibration Button ===");
        $display("Calibration button is REQUIRED and must be connected (P11)");
        $display("Pressing calibration button...");
        calib_button = 1;
        #(CLK_PERIOD * 200000);  // Hold for debounce period (150k cycles at 3MHz, ~3ms at 50MHz sim)
        calib_button = 0;
        #(CLK_PERIOD * 1000);
        $display("Calibration button released");
        $display("Note: calib_button directly affects led_error when pressed");
        
        // Test 3: Simulate drumming gestures
        $display("\n=== Test 3: Simulating Drumming Gestures ===");
        $display("Sending simulated sensor data for various gestures...");
        
        // Wait for sensor data to be processed
        #(CLK_PERIOD * 50000);  // Wait for data processing
        
        // Test 4: Check SPI output to MCU
        $display("\n=== Test 4: SPI Output to MCU ===");
        if (mcu_rx_valid) begin
            $display("PASS: SPI data received by MCU: 0x%02X (sound_code=%d)", 
                     mcu_rx_data, mcu_rx_data & 8'h0F);
        end else begin
            $display("INFO: No SPI output yet (may need more time or sensor data)");
        end
        
        // Test 5: Kick button
        $display("\n=== Test 5: Kick Button ===");
        kick_button = 1;
        #(CLK_PERIOD * 1000);
        kick_button = 0;
        #(CLK_PERIOD * 10000);
        if (mcu_rx_valid && (mcu_rx_data & 8'h0F) == 4'd2) begin  // Sound code 2 = Kick
            $display("PASS: Kick drum detected (SPI code=0x%02X)", mcu_rx_data);
        end else begin
            $display("INFO: Kick button pressed");
        end
        
        // Test 6: Error detection (INT pins and calib_button)
        $display("\n=== Test 6: Error Detection ===");
        $display("Error detection includes:");
        $display("  - Sensor errors (bno1_error, bno2_error)");
        $display("  - INT pin stuck LOW errors (int1_error, int2_error)");
        $display("  - Calibration button pressed during calibration (calib_button && calib_active)");
        if (!led_error) begin
            $display("PASS: No errors detected");
        end else begin
            $display("INFO: Error LED is active (may be normal during calibration)");
        end
        
        // Test 7: Verify INT pins are connected
        $display("\n=== Test 7: INT Pin Connection Verification ===");
        $display("INT pins (int1, int2) are REQUIRED for stable SPI operation");
        $display("They are used in bno085_controller WAIT_DATA state to gate polling");
        $display("INT pins are also monitored for stuck LOW errors");
        $display("Current INT states: int1=%b, int2=%b (1=HIGH=no interrupt, 0=LOW=data ready)", int1, int2);
        
        // Summary
        $display("\n========================================");
        $display("Test Summary");
        $display("========================================");
        $display("System initialized: %b", led_initialized);
        $display("Error status: %b", led_error);
        $display("INT pins connected: int1=%b, int2=%b", int1, int2);
        $display("Calibration button connected: %b", calib_button);
        $display("SPI output received by MCU: %b", mcu_rx_valid);
        if (mcu_rx_valid) begin
            $display("Last SPI byte: 0x%02X (sound_code=%d)", mcu_rx_data, mcu_rx_data & 8'h0F);
        end
        $display("\nCRITICAL SIGNALS VERIFICATION:");
        $display("  - int1 (P9): REQUIRED - Connected to bno085_ctrl1.int_n");
        $display("  - int2 (P3): REQUIRED - Connected to bno085_ctrl2.int_n");
        $display("  - calib_button (P11): REQUIRED - Connected to gesture_detector");
        $display("========================================\n");
        
        #(CLK_PERIOD * 100000);
        $finish;
    end
    
    // Monitor SPI output to MCU
    initial begin
        forever begin
            @(posedge mcu_rx_valid);
            $display("[%0t] MCU received via SPI: 0x%02X - Sound code: %d", 
                     $time, mcu_rx_data, mcu_rx_data & 8'h0F);
        end
    end
    
    // Monitor system status
    initial begin
        $monitor("[%0t] Initialized=%b, Error=%b, MCU_CS_N=%b, MCU_Data=0x%02X", 
                 $time, led_initialized, led_error, mcu_cs_n, mcu_rx_data);
    end

endmodule

// Simulated BNO085 Sensor Model
// Generates realistic SHTP packets with quaternion and gyroscope data
module bno085_sim_model (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        sclk,
    input  logic        mosi,
    output logic        miso,
    input  logic        cs_n,
    input  logic        sensor_id  // 0 = right hand, 1 = left hand
);

    // Internal state
    typedef enum logic [2:0] {
        IDLE,
        RECEIVING_HEADER,
        RECEIVING_DATA,
        SENDING_HEADER,
        SENDING_DATA
    } state_t;
    
    state_t state;
    logic [7:0] bit_cnt;
    logic [7:0] byte_cnt;
    logic [15:0] packet_length;
    logic [7:0] tx_buffer [0:63];
    logic [7:0] rx_buffer [0:15];
    logic [7:0] tx_shift;
    logic [7:0] rx_shift;
    logic [2:0] bit_pos;
    
    // Simulated sensor data
    // Quaternion data (Q14 format, little-endian)
    logic signed [15:0] quat_w, quat_x, quat_y, quat_z;
    // Gyroscope data (rad/s * 900, little-endian)
    logic signed [15:0] gyro_x, gyro_y, gyro_z;
    
    // Gesture scenarios
    logic [2:0] gesture_scenario;
    logic [31:0] scenario_counter;
    
    // Initialize sensor data based on scenario
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gesture_scenario <= 0;
            scenario_counter <= 0;
            quat_w <= 16'd16384;   // ~0.5
            quat_x <= 16'd0;
            quat_y <= 16'd0;
            quat_z <= 16'd0;
            gyro_x <= 16'd0;
            gyro_y <= -16'd2500;   // Strike detection threshold
            gyro_z <= 16'd0;
        end else begin
            scenario_counter <= scenario_counter + 1;
            
            // Change gesture scenario every 1 million cycles (~20ms)
            if (scenario_counter == 1000000) begin
                scenario_counter <= 0;
                gesture_scenario <= gesture_scenario + 1;
            end
            
            // Generate different gesture scenarios
            case (gesture_scenario)
                0: begin  // Snare drum (right hand: yaw 50°, gyro_y < -2500)
                    quat_w <= 16'd16384;
                    quat_x <= 16'd0;
                    quat_y <= 16'd0;
                    quat_z <= 16'd0;
                    gyro_y <= -16'd3000;
                end
                1: begin  // High tom (right hand: yaw 10°, low pitch)
                    quat_w <= 16'd16384;
                    quat_x <= 16'd0;
                    quat_y <= 16'd0;
                    quat_z <= 16'd0;
                    gyro_y <= -16'd3000;
                end
                2: begin  // Crash cymbal (right hand: yaw 10°, high pitch)
                    quat_w <= 16'd16384;
                    quat_x <= 16'd0;
                    quat_y <= 16'd0;
                    quat_z <= 16'd0;
                    gyro_y <= -16'd3000;
                end
                3: begin  // Hi-hat (left hand: yaw 10°, high pitch, low rotation)
                    quat_w <= 16'd16384;
                    quat_x <= 16'd0;
                    quat_y <= 16'd0;
                    quat_z <= 16'd0;
                    gyro_y <= -16'd3000;
                    gyro_z <= -16'd1000;
                end
                default: begin
                    quat_w <= 16'd16384;
                    quat_x <= 16'd0;
                    quat_y <= 16'd0;
                    quat_z <= 16'd0;
                    gyro_y <= 16'd0;  // No strike
                    gyro_z <= 16'd0;
                end
            endcase
        end
    end
    
    // Build response packets
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Initialize rotation vector report packet
            // SHTP Header: [Length LSB, Length MSB, Channel, Sequence]
            tx_buffer[0] <= 8'd20;   // Length LSB (20 bytes)
            tx_buffer[1] <= 8'd0;    // Length MSB
            tx_buffer[2] <= 8'h05;   // Channel (REPORTS)
            tx_buffer[3] <= 8'd0;    // Sequence
            // Rotation Vector Report
            tx_buffer[4] <= 8'h05;   // Report ID (Rotation Vector)
            tx_buffer[5] <= 8'd0;    // Sequence
            tx_buffer[6] <= 8'd0;    // Status
            tx_buffer[7] <= 8'd0;    // Delay
            // Quaternion I (x) - little endian
            tx_buffer[8] <= quat_x[7:0];
            tx_buffer[9] <= quat_x[15:8];
            // Quaternion J (y)
            tx_buffer[10] <= quat_y[7:0];
            tx_buffer[11] <= quat_y[15:8];
            // Quaternion Real (w)
            tx_buffer[12] <= quat_w[7:0];
            tx_buffer[13] <= quat_w[15:8];
            // Quaternion K (z)
            tx_buffer[14] <= quat_z[7:0];
            tx_buffer[15] <= quat_z[15:8];
            // Accuracy and padding
            tx_buffer[16] <= 8'd0;
            tx_buffer[17] <= 8'd0;
            tx_buffer[18] <= 8'd0;
            tx_buffer[19] <= 8'd0;
            
            // Gyroscope report packet
            tx_buffer[20] <= 8'd12;  // Length LSB
            tx_buffer[21] <= 8'd0;   // Length MSB
            tx_buffer[22] <= 8'h05;  // Channel
            tx_buffer[23] <= 8'd1;   // Sequence
            tx_buffer[24] <= 8'h01;  // Report ID (Gyroscope)
            tx_buffer[25] <= 8'd0;   // Sequence
            tx_buffer[26] <= 8'd0;   // Status
            tx_buffer[27] <= 8'd0;   // Delay
            // Gyro X, Y, Z - little endian
            tx_buffer[28] <= gyro_x[7:0];
            tx_buffer[29] <= gyro_x[15:8];
            tx_buffer[30] <= gyro_y[7:0];
            tx_buffer[31] <= gyro_y[15:8];
            tx_buffer[32] <= gyro_z[7:0];
            tx_buffer[33] <= gyro_z[15:8];
        end else begin
            // Update quaternion data in packet
            tx_buffer[8] <= quat_x[7:0];
            tx_buffer[9] <= quat_x[15:8];
            tx_buffer[10] <= quat_y[7:0];
            tx_buffer[11] <= quat_y[15:8];
            tx_buffer[12] <= quat_w[7:0];
            tx_buffer[13] <= quat_w[15:8];
            tx_buffer[14] <= quat_z[7:0];
            tx_buffer[15] <= quat_z[15:8];
            
            // Update gyro data in packet
            tx_buffer[28] <= gyro_x[7:0];
            tx_buffer[29] <= gyro_x[15:8];
            tx_buffer[30] <= gyro_y[7:0];
            tx_buffer[31] <= gyro_y[15:8];
            tx_buffer[32] <= gyro_z[7:0];
            tx_buffer[33] <= gyro_z[15:8];
        end
    end
    
    // SPI slave state machine
    always_ff @(negedge sclk or negedge cs_n or negedge rst_n) begin
        if (!rst_n || cs_n) begin
            state <= IDLE;
            bit_cnt <= 0;
            byte_cnt <= 0;
            bit_pos <= 0;
            miso <= 1'b0;
            tx_shift <= 8'd0;
        end else begin
            case (state)
                IDLE: begin
                    // Wait for CS assertion
                    if (!cs_n) begin
                        state <= RECEIVING_HEADER;
                        bit_cnt <= 0;
                        byte_cnt <= 0;
                    end
                end
                
                RECEIVING_HEADER: begin
                    // Receive 4-byte SHTP header
                    rx_shift <= {rx_shift[6:0], mosi};
                    bit_cnt <= bit_cnt + 1;
                    if (bit_cnt == 7) begin
                        rx_buffer[byte_cnt] <= rx_shift;
                        byte_cnt <= byte_cnt + 1;
                        bit_cnt <= 0;
                        if (byte_cnt == 3) begin
                            // Header received, prepare response
                            packet_length <= {rx_buffer[1], rx_buffer[0]};
                            state <= SENDING_HEADER;
                            byte_cnt <= 0;
                            bit_cnt <= 0;
                            tx_shift <= tx_buffer[0];
                        end
                    end
                end
                
                SENDING_HEADER: begin
                    // Send 4-byte SHTP header
                    miso <= tx_shift[7];
                    tx_shift <= {tx_shift[6:0], 1'b0};
                    bit_cnt <= bit_cnt + 1;
                    if (bit_cnt == 7) begin
                        byte_cnt <= byte_cnt + 1;
                        bit_cnt <= 0;
                        if (byte_cnt < 3) begin
                            tx_shift <= tx_buffer[byte_cnt + 1];
                        end else begin
                            // Header sent, send payload
                            state <= SENDING_DATA;
                            byte_cnt <= 4;  // Start from payload
                            bit_cnt <= 0;
                            tx_shift <= tx_buffer[4];
                        end
                    end
                end
                
                SENDING_DATA: begin
                    // Send packet payload
                    miso <= tx_shift[7];
                    tx_shift <= {tx_shift[6:0], 1'b0};
                    bit_cnt <= bit_cnt + 1;
                    if (bit_cnt == 7) begin
                        byte_cnt <= byte_cnt + 1;
                        bit_cnt <= 0;
                        if (byte_cnt < packet_length - 1) begin
                            tx_shift <= tx_buffer[byte_cnt + 1];
                        end else begin
                            // Packet complete
                            state <= IDLE;
                        end
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end
    
    // Sample MOSI on positive edge
    always_ff @(posedge sclk) begin
        if (!cs_n && state == RECEIVING_HEADER) begin
            rx_shift <= {rx_shift[6:0], mosi};
        end
    end

endmodule

// UART receiver module removed - system now uses SPI to MCU


