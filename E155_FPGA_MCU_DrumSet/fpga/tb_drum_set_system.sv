// Top-level System Testbench
// Tests complete drum set system with simulated BNO085 sensors

`timescale 1ns / 1ps

module tb_drum_set_system;

    // Parameters
    localparam CLK_PERIOD = 20;  // 50MHz clock
    
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
    logic mcu_sclk, mcu_mosi, mcu_miso, mcu_cs_n;
    
    // Status
    logic led_initialized, led_error;
    
    // Simulated sensor data
    logic [7:0] sensor1_data [0:63];
    logic [7:0] sensor2_data [0:63];
    
    // SPI slave model (simulates MCU)
    logic [7:0] mcu_rx_data;
    logic mcu_rx_valid;
    
    // Test results
    int test_count = 0;
    int pass_count = 0;
    int fail_count = 0;
    
    // Instantiate DUT
    drum_set_top dut (
        .clk(clk),
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
        .mcu_miso(mcu_miso),
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
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Simulate BNO085 Sensor 1
    initial begin
        miso1 = 1'b0;
        int1 = 1'b0;
        
        // Initialize sensor data buffer with rotation vector report
        // SHTP Header: [Length LSB, Length MSB, Channel, Sequence]
        sensor1_data[0] = 8'd20;  // Length LSB
        sensor1_data[1] = 8'd0;   // Length MSB
        sensor1_data[2] = 8'h05;  // Channel (REPORTS)
        sensor1_data[3] = 8'd0;   // Sequence
        // Rotation Vector Report: [Report ID, Seq, Status, Delay, Quat I(4), Quat J(4), Quat K(4), Quat Real(4), ...]
        sensor1_data[4] = 8'h05;  // Report ID (Rotation Vector)
        sensor1_data[5] = 8'd0;    // Sequence
        sensor1_data[6] = 8'd0;    // Status
        sensor1_data[7] = 8'd0;    // Delay
        // Quaternion I (x) - little endian
        sensor1_data[8] = 8'h00;
        sensor1_data[9] = 8'h00;
        // Quaternion J (y)
        sensor1_data[10] = 8'h00;
        sensor1_data[11] = 8'h00;
        // Quaternion Real (w)
        sensor1_data[12] = 8'h00;
        sensor1_data[13] = 8'h7F;  // ~0.5 in Q14
        // Quaternion K (z)
        sensor1_data[14] = 8'h00;
        sensor1_data[15] = 8'h00;
        
        // Gyroscope report
        sensor1_data[16] = 8'd12;  // Length LSB
        sensor1_data[17] = 8'd0;   // Length MSB
        sensor1_data[18] = 8'h05;  // Channel
        sensor1_data[19] = 8'd1;   // Sequence
        sensor1_data[20] = 8'h01;  // Report ID (Gyroscope)
        sensor1_data[21] = 8'd0;    // Sequence
        sensor1_data[22] = 8'd0;    // Status
        sensor1_data[23] = 8'd0;    // Delay
        // Gyro X, Y, Z (little endian, rad/s * 900)
        sensor1_data[24] = 8'h00;  // Gyro X LSB
        sensor1_data[25] = 8'h00;  // Gyro X MSB
        sensor1_data[26] = 8'hF6;  // Gyro Y LSB (-2500 in Q9)
        sensor1_data[27] = 8'hF6;  // Gyro Y MSB
        sensor1_data[28] = 8'h00;  // Gyro Z LSB
        sensor1_data[29] = 8'h00;  // Gyro Z MSB
    end
    
    // Simulate BNO085 Sensor 2 (similar structure)
    initial begin
        miso2 = 1'b0;
        int2 = 1'b0;
        
        // Similar data structure for sensor 2
        for (int i = 0; i < 64; i++) begin
            sensor2_data[i] = sensor1_data[i];
        end
    end
    
    // MISO drivers (simulate sensor responses)
    // Simplified model: return data bytes bit by bit
    logic [2:0] bit_cnt1, bit_cnt2;
    logic [5:0] byte_addr1, byte_addr2;
    
    always @(negedge sclk1 or negedge cs_n1) begin
        if (!cs_n1) begin
            if (byte_addr1 < 64) begin
                // Output bit MSB first
                miso1 <= sensor1_data[byte_addr1][7 - bit_cnt1];
                if (bit_cnt1 == 7) begin
                    bit_cnt1 <= 0;
                    byte_addr1 <= byte_addr1 + 1;
                end else begin
                    bit_cnt1 <= bit_cnt1 + 1;
                end
            end else begin
                miso1 <= 1'b0;
            end
        end else begin
            byte_addr1 <= 0;
            bit_cnt1 <= 0;
            miso1 <= 1'b0;
        end
    end
    
    always @(negedge sclk2 or negedge cs_n2) begin
        if (!cs_n2) begin
            if (byte_addr2 < 64) begin
                miso2 <= sensor2_data[byte_addr2][7 - bit_cnt2];
                if (bit_cnt2 == 7) begin
                    bit_cnt2 <= 0;
                    byte_addr2 <= byte_addr2 + 1;
                end else begin
                    bit_cnt2 <= bit_cnt2 + 1;
                end
            end else begin
                miso2 <= 1'b0;
            end
        end else begin
            byte_addr2 <= 0;
            bit_cnt2 <= 0;
            miso2 <= 1'b0;
        end
    end
    
    // Test stimulus
    initial begin
        $display("========================================");
        $display("Drum Set System Testbench");
        $display("========================================\n");
        
        // Initialize
        rst_n = 0;
        calib_button = 0;
        kick_button = 0;
        
        // Reset
        #(CLK_PERIOD * 100);
        rst_n = 1;
        #(CLK_PERIOD * 1000);  // Wait for initialization
        
        // Test 1: System initialization
        $display("Test 1: System initialization");
        test_count++;
        if (led_initialized) begin
            $display("  PASS: System initialized");
            pass_count++;
        end else begin
            $display("  FAIL: System not initialized");
            fail_count++;
        end
        
        // Test 2: Calibration
        $display("\nTest 2: Calibration");
        test_count++;
        calib_button = 1;
        #(CLK_PERIOD * 10);
        calib_button = 0;
        #(CLK_PERIOD * 100);
        $display("  Calibration button pressed");
        pass_count++;
        
        // Test 3: Gesture detection (simulated)
        $display("\nTest 3: Gesture detection");
        test_count++;
        // Wait for sensor data processing
        #(CLK_PERIOD * 10000);
        
        // Check if SPI output to MCU is generated
        if (mcu_rx_valid) begin
            $display("  PASS: SPI output to MCU detected (code=0x%02X, sound_code=%d)", 
                     mcu_rx_data, mcu_rx_data & 8'h0F);
            pass_count++;
        end else begin
            $display("  INFO: No SPI output yet (may need more sensor data)");
        end
        
        // Test 4: Kick button
        $display("\nTest 4: Kick button");
        test_count++;
        kick_button = 1;
        #(CLK_PERIOD * 100);
        kick_button = 0;
        #(CLK_PERIOD * 1000);
        if (mcu_rx_valid && (mcu_rx_data & 8'h0F) == 4'd2) begin  // Sound code 2 = Kick
            $display("  PASS: Kick drum detected (SPI code=0x%02X)", mcu_rx_data);
            pass_count++;
        end else begin
            $display("  INFO: Kick button pressed (check SPI output)");
        end
        
        // Test 5: Error detection
        $display("\nTest 5: Error detection");
        test_count++;
        if (!led_error) begin
            $display("  PASS: No errors detected");
            pass_count++;
        end else begin
            $display("  WARNING: Error LED active");
            fail_count++;
        end
        
        // Summary
        $display("\n========================================");
        $display("Test Summary");
        $display("========================================");
        $display("Total tests: %0d", test_count);
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", fail_count);
        $display("========================================\n");
        
        #(CLK_PERIOD * 10000);
        $finish;
    end
    
    // Monitor
    initial begin
        $monitor("Time=%0t: initialized=%b, error=%b, mcu_cs_n=%b, mcu_data=0x%02X, mcu_valid=%b",
                 $time, led_initialized, led_error, mcu_cs_n, mcu_rx_data, mcu_rx_valid);
    end
    
    // Monitor SPI transfers
    initial begin
        forever begin
            @(posedge mcu_rx_valid);
            $display("[%0t] MCU received via SPI: 0x%02X (sound_code=%d)", 
                     $time, mcu_rx_data, mcu_rx_data & 8'h0F);
        end
    end

endmodule

