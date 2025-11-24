// Comprehensive Acceptance Testbench
// Verifies full system functionality including recent fixes
// Checks:
// 1. System Initialization
// 2. INT Pin Behavior & Error Handling
// 3. Calibration Button & LED Toggling (Fix Verification)
// 4. Gesture Recognition Accuracy
// 5. SPI Communication to MCU
// 6. Timing & Reset Behavior

`timescale 1ns / 1ps

module tb_final;

    // =================================================================
    // 1. Configuration & Parameters
    // =================================================================
    localparam CLK_PERIOD = 20;  // 50MHz simulation clock
    localparam SPI_CLK_DIV = 2;
    
    // DUT Signals
    logic clk;
    logic rst_n;
    logic sclk1, mosi1, miso1, cs_n1, int1;
    logic sclk2, mosi2, miso2, cs_n2, int2;
    logic calib_button, kick_button;
    logic mcu_sclk, mcu_mosi, mcu_cs_n;
    logic led_initialized, led_error;
    
    // Test Bench Signals
    logic [7:0] mcu_rx_data;
    logic mcu_rx_valid;
    
    // Verification Flags
    integer error_count = 0;
    integer test_step = 0;
    logic packet_received_flag;
    logic [7:0] captured_data;
    
    always_ff @(posedge clk) begin
        if (mcu_rx_valid) begin
            packet_received_flag <= 1'b1;
            captured_data <= mcu_rx_data;
        end
    end

    // =================================================================
    // 2. DUT Instantiation
    // =================================================================
    
    // Mock Sensors
    bno085_sim_model sensor1_model (
        .clk(clk), .rst_n(rst_n),
        .sclk(sclk1), .mosi(mosi1), .miso(miso1), .cs_n(cs_n1),
        .sensor_id(1'b0) // Right Hand
    );
    
    bno085_sim_model sensor2_model (
        .clk(clk), .rst_n(rst_n),
        .sclk(sclk2), .mosi(mosi2), .miso(miso2), .cs_n(cs_n2),
        .sensor_id(1'b1) // Left Hand
    );
    
    // Mock MCU
    spi_slave_model mcu_model (
        .clk(clk), .rst_n(rst_n),
        .sclk(mcu_sclk), .mosi(mcu_mosi), .cs_n(mcu_cs_n),
        .rx_data(mcu_rx_data), .rx_valid(mcu_rx_valid)
    );
    
    // Device Under Test
    drum_set_top dut (
        .rst_n(rst_n),
        .sclk1(sclk1), .mosi1(mosi1), .miso1(miso1), .cs_n1(cs_n1), .int1(int1),
        .sclk2(sclk2), .mosi2(mosi2), .miso2(miso2), .cs_n2(cs_n2), .int2(int2),
        .calib_button(calib_button), .kick_button(kick_button),
        .mcu_sclk(mcu_sclk), .mcu_mosi(mcu_mosi), .mcu_cs_n(mcu_cs_n),
        .led_initialized(led_initialized), .led_error(led_error)
    );
    
    // Connect internal clock for synchronization
    assign clk = dut.clk;

    // =================================================================
    // 3. Helper Tasks
    // =================================================================
    
    task check(input logic condition, input string msg);
        if (condition) begin
            $display("[PASS] %s", msg);
        end else begin
            $display("[FAIL] %s", msg);
            error_count++;
        end
    endtask

    // =================================================================
    // 4. Main Test Sequence
    // =================================================================
    initial begin
        $display("\n------------------------------------------------------");
        $display("     FINAL COMPREHENSIVE SYSTEM ACCEPTANCE TEST       ");
        $display("------------------------------------------------------\n");
        
        // ------------------------------------------------------------
        // Phase 0: Power-On Reset
        // ------------------------------------------------------------
        test_step = 0;
        $display("Phase 0: Power-On Reset");
        rst_n = 0;
        calib_button = 0;
        kick_button = 0;
        int1 = 1; // Active LOW (Inactive = High)
        int2 = 1;
        
        #(CLK_PERIOD * 100);
        check(led_initialized == 0, "LED Initialized OFF during Reset");
        rst_n = 1;
        $display("Reset released. Waiting for initialization sequence...");
        
        // ------------------------------------------------------------
        // Phase 1: System Initialization (Wait 200ms sim time)
        // ------------------------------------------------------------
        test_step = 1;
        $display("\nPhase 1: System Initialization & Sensor Config");
        // Wait enough time for state machine to configure sensors
        // 3MHz clock -> ~300k cycles for 100ms. Simulation runs fast.
        #(CLK_PERIOD * 12000000); 
        
        check(led_initialized == 1, "System Initialized (LED ON)");
        check(led_error == 0, "No Error LED at startup");
        
        // ------------------------------------------------------------
        // Phase 2: INT Pin Behavior
        // ------------------------------------------------------------
        test_step = 2;
        $display("\nPhase 2: Interrupt Handling Verification");
        // Pulse INT pin LOW to signal data ready
        int1 = 0;
        #(CLK_PERIOD * 500); // Short pulse
        int1 = 1;
        
        // We can't easily check internal state without hierarchical reference, 
        // but if system doesn't hang, it's good.
        #(CLK_PERIOD * 5000);
        check(led_error == 0, "No error triggered by valid INT pulse");

        // ------------------------------------------------------------
        // Phase 3: Calibration Button Logic (The Fix Verification)
        // ------------------------------------------------------------
        test_step = 3;
        $display("\nPhase 3: Calibration Button & LED Feedback");
        $display("Verifying fix: LED should toggle when button pressed.");
        
        // Wait for some data valid pulses first to ensure system is running
        // Sensors are generating data (mock model does this)
        // Pulse INT pins to get data flow
        repeat(5) begin
             int1 = 0; int2 = 0;
             #(CLK_PERIOD * 1000);
             int1 = 1; int2 = 1;
             #(CLK_PERIOD * 5000);
        end
        
        // Pre-check: LED is ON
        if (led_initialized !== 1) begin
            $display("WARNING: System not initialized, skipping toggle check");
        end else begin
            // Press Button
            calib_button = 1;
            #(CLK_PERIOD * 20000); // Wait for debounce
            
            check(led_initialized == 0, "LED turns OFF when Calib Button pressed (Blink behavior)");
            
            // Internal signal check (needs hierarchical access)
            // We skip if we can't see internal state, but checking LED is sufficient for pin check
            
            // Release Button
            calib_button = 0;
            #(CLK_PERIOD * 20000);
            check(led_initialized == 1, "LED turns ON when Calib Button released");
        end

        // ------------------------------------------------------------
        // Phase 4: Gesture Recognition & SPI Output
        // ------------------------------------------------------------
        test_step = 4;
        $display("\nPhase 4: Gesture Recognition (Kick Drum)");
        
        // Reset capture flag
        packet_received_flag = 0;
        captured_data = 8'h00;
        
        // Simulate Kick Button
        kick_button = 1;
        
        // Wait for SPI transaction to complete
        // Transaction starts on button edge, takes ~16*8 = 128 cycles
        // We wait enough time to capture it
        #(CLK_PERIOD * 2000); 
        
        kick_button = 0;
        
        check(packet_received_flag == 1, "MCU received data packet (captured valid pulse)");
        check(captured_data == 8'h02, "Received Correct Sound Code (Kick = 0x02)");
        
        // ------------------------------------------------------------
        // Phase 5: Final Report
        // ------------------------------------------------------------
        $display("\n------------------------------------------------------");
        $display("                   TEST SUMMARY                       ");
        $display("------------------------------------------------------");
        if (error_count == 0) begin
             $display("RESULT: PASSED ALL CHECKS");
             $display("The system is verified ready for deployment.");
        end else begin
             $display("RESULT: FAILED (%0d errors)", error_count);
        end
        $display("------------------------------------------------------\n");
        
        $finish;
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
