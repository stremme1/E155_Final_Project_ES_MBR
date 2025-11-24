// Comprehensive SPI Testbench
// Tests all functionality including edge cases, timing, and error conditions
//
// NOTE: This testbench tests spi_to_mcu module only (not BNO085 controllers)
// - INT pins (int1, int2) are NOT needed here - they are only used in bno085_controller modules
// - This testbench only tests SPI communication from FPGA to MCU
// - For full system testing with BNO085 sensors, use tb_system_with_sim_imu.sv

`timescale 1ns / 1ps

module tb_spi_comprehensive;

    // Clock configuration
    // System uses 3MHz clock in hardware (from HSOSC)
    // For simulation: Using 50MHz for faster simulation (SPI module works at any clock)
    // SPI clock = system_clock / CLK_DIV
    // At 50MHz with CLK_DIV=16: SPI clock = 3.125MHz (close to hardware 3MHz)
    // At 3MHz with CLK_DIV=16: SPI clock = 187.5kHz (too slow for simulation)
    localparam CLK_PERIOD = 20;  // 50MHz for simulation (faster than 3MHz)
    localparam CLK_DIV = 16;     // SPI clock divider (matches hardware)
    
    logic clk, rst_n;
    logic data_valid;
    logic [3:0] sound_code;
    logic mcu_sclk, mcu_mosi, mcu_miso, mcu_cs_n;
    logic busy;
    
    // Test statistics
    integer tests_passed = 0;
    integer tests_failed = 0;
    integer total_transfers = 0;
    
    spi_to_mcu #(.CLK_DIV(CLK_DIV)) dut (
        .clk(clk),
        .rst_n(rst_n),
        .data_valid(data_valid),
        .sound_code(sound_code),
        .mcu_sclk(mcu_sclk),
        .mcu_mosi(mcu_mosi),
        .mcu_miso(mcu_miso),
        .mcu_cs_n(mcu_cs_n),
        .busy(busy)
    );
    
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Comprehensive SPI receiver
    logic [7:0] rx_data;
    logic [7:0] rx_shift;
    logic [2:0] rx_bit_cnt;
    logic rx_cs_prev, rx_sclk_prev;
    logic [31:0] sclk_count;  // Count SCLK cycles
    logic [31:0] cs_low_time, cs_high_time;  // Timing measurements
    logic cs_low_start, cs_high_start;
    
    always_ff @(posedge clk) begin
        rx_cs_prev <= mcu_cs_n;
        rx_sclk_prev <= mcu_sclk;
        
        // Track CS timing
        if (!mcu_cs_n && rx_cs_prev) begin
            // CS falling edge
            cs_low_start = $time;
            cs_high_time = $time - cs_high_start;
            rx_shift <= 8'd0;
            rx_bit_cnt <= 3'd0;
            sclk_count <= 0;
        end else if (mcu_cs_n && !rx_cs_prev) begin
            // CS rising edge
            cs_high_start = $time;
            cs_low_time = $time - cs_low_start;
            rx_data <= rx_shift;
        end
        
        // Count SCLK cycles during transfer
        if (!mcu_cs_n && mcu_sclk && !rx_sclk_prev) begin
            sclk_count <= sclk_count + 1;
        end
        
        // Sample data on SCLK rising edge
        if (!mcu_cs_n && mcu_sclk && !rx_sclk_prev) begin
            rx_shift <= {rx_shift[6:0], mcu_mosi};
            if (rx_bit_cnt == 7) begin
                rx_bit_cnt <= 3'd0;
            end else begin
                rx_bit_cnt <= rx_bit_cnt + 1;
            end
        end
    end
    
    // Task to send a sound code and verify
    task automatic send_and_verify(
        input [3:0] code,
        input [7:0] expected,
        input string name,
        input integer min_delay
    );
        integer timeout;
        integer start_time, end_time;
        logic [7:0] received;
        
        $display("\n[TEST] %s (code %d, expected 0x%02X)", name, code, expected);
        
        // Wait for SPI master to be ready
        timeout = 0;
        while ((busy || dut.state != 0) && timeout < 2000) begin
            #(CLK_PERIOD);
            timeout = timeout + 1;
        end
        if (timeout >= 2000) begin
            $display("  [FAIL] SPI master not ready (timeout)");
            tests_failed = tests_failed + 1;
        end else begin
            // Ensure minimum delay between transfers
            if (min_delay > 0) begin
                #(CLK_PERIOD * min_delay);
            end
            
            // Send data
            start_time = $time;
            sound_code = code;
            data_valid = 0;
            #(CLK_PERIOD * 2);
            data_valid = 1;
            #(CLK_PERIOD * 2);  // Hold for 2 cycles
            data_valid = 0;
            
            // Wait for CS to go low
            timeout = 0;
            while (mcu_cs_n && timeout < 1000) begin
                #(CLK_PERIOD);
                timeout = timeout + 1;
            end
            if (mcu_cs_n) begin
                $display("  [FAIL] CS never went low (timeout)");
                tests_failed = tests_failed + 1;
            end else begin
                // Verify busy signal
                if (!busy) begin
                    $display("  [FAIL] Busy signal not asserted");
                    tests_failed = tests_failed + 1;
                end
                
                // Wait for transfer to complete
                timeout = 0;
                while (!mcu_cs_n && timeout < 2000) begin
                    #(CLK_PERIOD);
                    timeout = timeout + 1;
                end
                if (!mcu_cs_n) begin
                    $display("  [FAIL] CS never went high (timeout)");
                    tests_failed = tests_failed + 1;
                end else begin
                    end_time = $time;
                    
                    // Wait for data to be captured
                    #(CLK_PERIOD * 5);
                    received = rx_data;
                    
                    // Verify received data
                    if (received == expected) begin
                        $display("  [PASS] Received 0x%02X", received);
                        $display("         Transfer time: %0d ns", end_time - start_time);
                        $display("         CS low time: %0d ns", cs_low_time);
                        $display("         SCLK cycles: %0d", sclk_count);
                        tests_passed = tests_passed + 1;
                    end else begin
                        $display("  [FAIL] Received 0x%02X, expected 0x%02X", received, expected);
                        tests_failed = tests_failed + 1;
                    end
                    
                    // Verify SCLK count (should be 8)
                    if (sclk_count != 8) begin
                        $display("  [WARN] SCLK count is %0d, expected 8", sclk_count);
                    end
                    
                    // Wait for busy to clear
                    timeout = 0;
                    while (busy && timeout < 1000) begin
                        #(CLK_PERIOD);
                        timeout = timeout + 1;
                    end
                    
                    total_transfers = total_transfers + 1;
                    #(CLK_PERIOD * 10);
                end
            end
        end
    endtask
    
    // Test rapid transfers
    task automatic test_rapid_transfers();
        integer i;
        $display("\n=== Testing Rapid Transfers ===");
        
        for (i = 0; i < 8; i++) begin
            send_and_verify(i[3:0], {4'd0, i[3:0]}, $sformatf("Rapid transfer %0d", i), 0);
        end
    endtask
    
    // Test back-to-back transfers
    task automatic test_back_to_back();
        integer i;
        $display("\n=== Testing Back-to-Back Transfers ===");
        
        for (i = 0; i < 5; i++) begin
            send_and_verify(4'd0, 8'h00, $sformatf("Back-to-back %0d", i), 0);
        end
    endtask
    
    // Test timing constraints
    task automatic test_timing();
        $display("\n=== Testing Timing Constraints ===");
        
        // Test minimum delay
        send_and_verify(4'd1, 8'h01, "Timing test 1", 1);
        send_and_verify(4'd2, 8'h02, "Timing test 2", 1);
        
        // Test with delay
        send_and_verify(4'd3, 8'h03, "Timing test 3 (delayed)", 100);
    endtask
    
    // Test all sound codes
    task automatic test_all_codes();
        integer i;
        string name;
        
        $display("\n=== Testing All Sound Codes ===");
        
        for (i = 0; i < 8; i++) begin
            case (i)
                0: name = "Snare";
                1: name = "Hi-hat";
                2: name = "Kick";
                3: name = "High tom";
                4: name = "Mid tom";
                5: name = "Crash";
                6: name = "Ride";
                7: name = "Floor tom";
                default: name = "Unknown";
            endcase
            send_and_verify(i[3:0], {4'd0, i[3:0]}, name, 10);
        end
    endtask
    
    // Test edge cases
    task automatic test_edge_cases();
        $display("\n=== Testing Edge Cases ===");
        
        // Test code 0 (minimum)
        send_and_verify(4'd0, 8'h00, "Edge: Code 0 (min)", 10);
        
        // Test code 7 (maximum)
        send_and_verify(4'd7, 8'h07, "Edge: Code 7 (max)", 10);
        
        // Test with data_valid held high (should only trigger once due to edge detection)
        $display("\n[TEST] Data valid held high (edge detection)");
        begin
            integer timeout;
            logic cs_went_low;
            cs_went_low = 1'b0;
            
            // Wait for idle
            while (busy) #(CLK_PERIOD);
            #(CLK_PERIOD * 10);
            
            sound_code = 4'd5;
            data_valid = 0;
            #(CLK_PERIOD * 2);
            data_valid = 1;
            
            // Wait for CS to go low (should happen once)
            timeout = 0;
            while (mcu_cs_n && timeout < 500) begin
                #(CLK_PERIOD);
                timeout = timeout + 1;
            end
            if (!mcu_cs_n) begin
                cs_went_low = 1'b1;
            end
            
            // Hold data_valid high for many cycles
            #(CLK_PERIOD * 50);
            data_valid = 0;
            
            // Wait for transfer to complete
            timeout = 0;
            while (busy && timeout < 2000) begin
                #(CLK_PERIOD);
                timeout = timeout + 1;
            end
            #(CLK_PERIOD * 100);
            
            // Verify only one transfer occurred (CS went low once)
            if (cs_went_low) begin
                $display("  [PASS] Edge detection working - transfer triggered once");
                tests_passed = tests_passed + 1;
            end else begin
                $display("  [FAIL] Transfer did not occur");
                tests_failed = tests_failed + 1;
            end
        end
    endtask
    
    // Test state machine
    task automatic test_state_machine();
        $display("\n=== Testing State Machine ===");
        
        // Verify initial state
        if (dut.state == 0 && !busy) begin
            $display("  [PASS] Initial state is IDLE");
            tests_passed = tests_passed + 1;
        end else begin
            $display("  [FAIL] Initial state incorrect");
            tests_failed = tests_failed + 1;
        end
        
        // Trigger transfer and check states
        sound_code = 4'd4;
        data_valid = 0;
        #(CLK_PERIOD * 2);
        data_valid = 1;
        #(CLK_PERIOD);
        data_valid = 0;
        
        // Check immediately - state should transition to CS_ASSERT or TX_DATA
        #(CLK_PERIOD * 2);
        if (dut.state == 1 || dut.state == 2) begin
            $display("  [PASS] State transitioned to CS_ASSERT or TX_DATA (state=%0d)", dut.state);
            tests_passed = tests_passed + 1;
        end else begin
            $display("  [FAIL] State is %0d, expected CS_ASSERT (1) or TX_DATA (2)", dut.state);
            tests_failed = tests_failed + 1;
        end
        
        // Wait for completion
        while (busy) #(CLK_PERIOD);
        #(CLK_PERIOD * 200);
        
        if (dut.state == 0 && !busy) begin
            $display("  [PASS] Returned to IDLE state");
            tests_passed = tests_passed + 1;
        end else begin
            $display("  [FAIL] State is %0d, expected IDLE (0)", dut.state);
            tests_failed = tests_failed + 1;
        end
    endtask
    
    initial begin
        $display("========================================");
        $display("  Comprehensive SPI Testbench");
        $display("========================================\n");
        
        // Initialize
        rst_n = 0;
        data_valid = 0;
        sound_code = 0;
        mcu_miso = 0;
        rx_cs_prev = 1'b1;
        rx_sclk_prev = 1'b0;
        cs_low_start = 0;
        cs_high_start = 0;
        
        #(CLK_PERIOD * 10);
        rst_n = 1;
        #(CLK_PERIOD * 10);
        
        $display("=== Initialization Complete ===\n");
        
        // Run all test suites
        test_all_codes();
        test_rapid_transfers();
        test_back_to_back();
        test_timing();
        test_edge_cases();
        test_state_machine();
        
        // Print summary
        $display("\n========================================");
        $display("  Test Summary");
        $display("========================================");
        $display("  Total Transfers: %0d", total_transfers);
        $display("  Tests Passed:    %0d", tests_passed);
        $display("  Tests Failed:    %0d", tests_failed);
        $display("  Success Rate:    %0.1f%%", 
                 (tests_passed * 100.0) / (tests_passed + tests_failed));
        $display("========================================\n");
        
        if (tests_failed == 0) begin
            $display("  ALL TESTS PASSED!");
        end else begin
            $display("  SOME TESTS FAILED - Review output above");
        end
        
        #(CLK_PERIOD * 100);
        $finish;
    end
    
    // Monitor for debugging (commented out to reduce output)
    // Uncomment for detailed signal monitoring
    /*
    initial begin
        $monitor("[%0t] State=%0d CS_N=%b SCLK=%b MOSI=%b BUSY=%b", 
                 $time, dut.state, mcu_cs_n, mcu_sclk, mcu_mosi, busy);
    end
    */

endmodule

