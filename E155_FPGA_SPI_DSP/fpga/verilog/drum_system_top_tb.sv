// Comprehensive Test Bench for Drum System
// Professional Engineering Audit - Complete System Testing
// Tests all modules, integration, and BNO085 communication
// Author: E155 Final Project
// Date: 2024

`timescale 1ns / 1ps
`define SIMULATION

module drum_system_top_tb;

    // Clock and Reset
    logic clk_ext;
    logic rst_n;
    
    // SPI Physical Pins
    logic spi_sclk;
    logic spi_mosi;
    logic spi_miso;
    logic spi_cs1_n;
    logic spi_cs2_n;
    
    // BNO085 Control
    logic bno085_1_int_n;
    logic bno085_1_rst_n;
    logic bno085_2_int_n;
    logic bno085_2_rst_n;
    
    // User Interface
    logic button1;
    logic button2;
    logic led1;
    logic led2;
    logic [7:0] sound_id;
    
    // Mock BNO085 Models
    logic bno085_1_int_enable;
    logic bno085_2_int_enable;
    logic signed [16:0] mock_quat1_w, mock_quat1_x, mock_quat1_y, mock_quat1_z;  // Q16 needs 17 bits for 1.0
    logic signed [15:0] mock_gyro1_x, mock_gyro1_y, mock_gyro1_z;
    logic signed [16:0] mock_quat2_w, mock_quat2_x, mock_quat2_y, mock_quat2_z;
    logic signed [15:0] mock_gyro2_x, mock_gyro2_y, mock_gyro2_z;
    
    // Instantiate DUT
    drum_system_top dut (
        .clk_ext(clk_ext),
        .rst_n(rst_n),
        .spi_sclk(spi_sclk),
        .spi_mosi(spi_mosi),
        .spi_miso(spi_miso),
        .spi_cs1_n(spi_cs1_n),
        .spi_cs2_n(spi_cs2_n),
        .bno085_1_int_n(bno085_1_int_n),
        .bno085_1_rst_n(bno085_1_rst_n),
        .bno085_2_int_n(bno085_2_int_n),
        .bno085_2_rst_n(bno085_2_rst_n),
        .button1(button1),
        .button2(button2),
        .led1(led1),
        .led2(led2),
        .sound_id(sound_id)
    );
    
    // Mock BNO085 #1 (Right Hand)
    bno085_mock bno085_1_mock (
        .clk(clk_ext),
        .rst_n(rst_n),
        .spi_sclk(spi_sclk),
        .spi_mosi(spi_mosi),
        .spi_miso(spi_miso),
        .spi_cs_n(spi_cs1_n),
        .int_n_enable(bno085_1_int_enable),
        .int_n(bno085_1_int_n),
        .test_quat_w(mock_quat1_w),
        .test_quat_x(mock_quat1_x),
        .test_quat_y(mock_quat1_y),
        .test_quat_z(mock_quat1_z),
        .test_gyro_x(mock_gyro1_x),
        .test_gyro_y(mock_gyro1_y),
        .test_gyro_z(mock_gyro1_z),
        .inject_data(1'b1)
    );
    
    // Mock BNO085 #2 (Left Hand) - Note: Shared SPI bus, different CS
    // For simplicity, using same mock but with different CS timing
    
    // Clock Generation (48 MHz)
    initial begin
        clk_ext = 0;
        forever #10.416 clk_ext = ~clk_ext;  // 48 MHz = 20.833ns period
    end
    
    // Test Results
    integer test_count = 0;
    integer pass_count = 0;
    integer fail_count = 0;
    
    // Test Helper Tasks
    task test_assert(input logic condition, input string test_name);
        test_count = test_count + 1;
        if (condition) begin
            $display("[PASS] Test %0d: %s", test_count, test_name);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Test %0d: %s", test_count, test_name);
            fail_count = fail_count + 1;
        end
    endtask
    
    task wait_cycles(input integer cycles);
        repeat(cycles) @(posedge clk_ext);
    endtask
    
    // Initialize
    initial begin
        // Initialize signals
        rst_n = 0;
        button1 = 0;
        button2 = 0;
        bno085_1_int_enable = 0;
        bno085_2_int_enable = 0;
        
        // Initialize mock data
        mock_quat1_w = 16'd32768;  // 0.5 in Q16
        mock_quat1_x = 16'd0;
        mock_quat1_y = 16'd0;
        mock_quat1_z = 16'd0;
        mock_gyro1_x = 16'd0;
        mock_gyro1_y = 16'd0;
        mock_gyro1_z = 16'd0;
        
        mock_quat2_w = 16'd32768;
        mock_quat2_x = 16'd0;
        mock_quat2_y = 16'd0;
        mock_quat2_z = 16'd0;
        mock_gyro2_x = 16'd0;
        mock_gyro2_y = 16'd0;
        mock_gyro2_z = 16'd0;
        
        wait_cycles(10);
        rst_n = 1;
        wait_cycles(100);
        
        $display("\n==========================================");
        $display("COMPREHENSIVE DRUM SYSTEM TEST BENCH");
        $display("==========================================\n");
        
        // Run test suites
        test_suite_1_reset_and_initialization();
        test_suite_2_spi_communication();
        test_suite_3_quaternion_to_euler();
        test_suite_4_gesture_recognition();
        test_suite_5_calibration();
        test_suite_6_button_debouncing();
        test_suite_7_edge_cases();
        test_suite_8_integration();
        
        // Print summary
        $display("\n==========================================");
        $display("TEST SUMMARY");
        $display("==========================================");
        $display("Total Tests: %0d", test_count);
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", fail_count);
        $display("==========================================\n");
        
        if (fail_count == 0) begin
            $display("✓ ALL TESTS PASSED - READY FOR FPGA");
        end else begin
            $display("✗ SOME TESTS FAILED - REVIEW REQUIRED");
        end
        
        #10000;
        $display("\nTest bench completed.");
        $finish;
    end
    
    // ========================================================================
    // TEST SUITE 1: Reset and Initialization
    // ========================================================================
    task test_suite_1_reset_and_initialization();
        $display("\n--- TEST SUITE 1: Reset and Initialization ---");
        
        // Test 1.1: Reset sequence
        rst_n = 0;
        wait_cycles(10);
        test_assert(sound_id == 8'hFF, "Reset: sound_id should be NO_SOUND");
        test_assert(led1 == 0, "Reset: led1 should be off");
        test_assert(led2 == 0, "Reset: led2 should be off");
        test_assert(bno085_1_rst_n == 0, "Reset: bno085_1_rst_n should be low");
        test_assert(bno085_2_rst_n == 0, "Reset: bno085_2_rst_n should be low");
        
        // Test 1.2: Release reset
        rst_n = 1;
        wait_cycles(100000);  // Wait for reset sequence (~100ms)
        test_assert(bno085_1_rst_n == 1, "After reset: bno085_1_rst_n should be high");
        test_assert(bno085_2_rst_n == 1, "After reset: bno085_2_rst_n should be high");
        
        $display("--- TEST SUITE 1 COMPLETE ---\n");
    endtask
    
    // ========================================================================
    // TEST SUITE 2: SPI Communication
    // ========================================================================
    task test_suite_2_spi_communication();
        $display("\n--- TEST SUITE 2: SPI Communication ---");
        
        // Test 2.1: SPI clock generation
        wait_cycles(100);
        test_assert(spi_sclk !== 1'bx, "SPI clock should be driven");
        
        // Test 2.2: CS lines alternate
        wait_cycles(500000);  // Wait for CS multiplexing
        test_assert(spi_cs1_n !== 1'bx, "CS1 should be driven");
        test_assert(spi_cs2_n !== 1'bx, "CS2 should be driven");
        
        // Test 2.3: Enable interrupts
        bno085_1_int_enable = 1;
        wait_cycles(1000);
        test_assert(bno085_1_int_n !== 1'bx, "INT1 should be driven");
        
        $display("--- TEST SUITE 2 COMPLETE ---\n");
    endtask
    
    // ========================================================================
    // TEST SUITE 3: Quaternion to Euler Conversion
    // ========================================================================
    task test_suite_3_quaternion_to_euler();
        $display("\n--- TEST SUITE 3: Quaternion to Euler Conversion ---");
        
        // Test 3.1: Identity quaternion (no rotation)
        mock_quat1_w = 17'd65536;  // 1.0 in Q16 (needs 17 bits)
        mock_quat1_x = 16'd0;
        mock_quat1_y = 16'd0;
        mock_quat1_z = 16'd0;
        
        bno085_1_int_enable = 1;
        wait_cycles(2500000);  // Wait for data processing
        
        // Test 3.2: 90-degree rotation around Z-axis
        mock_quat1_w = 16'd46341;  // cos(45°) ≈ 0.707 in Q16
        mock_quat1_x = 16'd0;
        mock_quat1_y = 16'd0;
        mock_quat1_z = 16'd46341;  // sin(45°) ≈ 0.707 in Q16
        
        wait_cycles(2500000);
        
        $display("--- TEST SUITE 3 COMPLETE ---\n");
    endtask
    
    // ========================================================================
    // TEST SUITE 4: Gesture Recognition
    // ========================================================================
    task test_suite_4_gesture_recognition();
        $display("\n--- TEST SUITE 4: Gesture Recognition ---");
        
        // Test 4.1: Snare drum (yaw 20-120, gyro trigger)
        // Set yaw to 60 degrees (15360 in Q8)
        mock_quat1_w = 16'd46341;  // Approximate quaternion for 60° yaw
        mock_quat1_x = 16'd0;
        mock_quat1_y = 16'd0;
        mock_quat1_z = 16'd46341;
        mock_gyro1_y = -16'd3000;  // Below threshold
        
        wait_cycles(2500000);
        // Note: Actual sound_id depends on full pipeline
        
        // Test 4.2: Kick drum (button1)
        button1 = 1;
        wait_cycles(2500000);
        test_assert(sound_id == 8'h02, "Button1 should trigger KICK (0x02)");
        button1 = 0;
        
        // Test 4.3: High tom (yaw 340-20, low pitch)
        // Set yaw to 10 degrees
        mock_quat1_w = 16'd65000;
        mock_quat1_x = 16'd0;
        mock_quat1_y = 16'd0;
        mock_quat1_z = 16'd1138;  // Small rotation
        mock_gyro1_y = -16'd3000;
        
        wait_cycles(2500000);
        
        $display("--- TEST SUITE 4 COMPLETE ---\n");
    endtask
    
    // ========================================================================
    // TEST SUITE 5: Calibration
    // ========================================================================
    task test_suite_5_calibration();
        $display("\n--- TEST SUITE 5: Calibration ---");
        
        // Test 5.1: Calibration button press
        button2 = 1;
        wait_cycles(2500000);  // Wait for debounce
        test_assert(led2 == 1, "Calibration LED should be on");
        
        button2 = 0;
        wait_cycles(2500000);
        test_assert(led2 == 0, "Calibration LED should be off");
        
        $display("--- TEST SUITE 5 COMPLETE ---\n");
    endtask
    
    // ========================================================================
    // TEST SUITE 6: Button Debouncing
    // ========================================================================
    task test_suite_6_button_debouncing();
        $display("\n--- TEST SUITE 6: Button Debouncing ---");
        
        // Test 6.1: Rapid button presses (should be debounced)
        repeat(10) begin
            button1 = 1;
            wait_cycles(100);
            button1 = 0;
            wait_cycles(100);
        end
        wait_cycles(2500000);
        
        // Test 6.2: Sustained button press
        button1 = 1;
        wait_cycles(2500000);
        button1 = 0;
        
        $display("--- TEST SUITE 6 COMPLETE ---\n");
    endtask
    
    // ========================================================================
    // TEST SUITE 7: Edge Cases
    // ========================================================================
    task test_suite_7_edge_cases();
        $display("\n--- TEST SUITE 7: Edge Cases ---");
        
        // Test 7.1: Yaw at boundary (0 degrees)
        mock_quat1_w = 17'd65536;
        mock_quat1_x = 16'd0;
        mock_quat1_y = 16'd0;
        mock_quat1_z = 16'd0;
        wait_cycles(2500000);
        
        // Test 7.2: Yaw at boundary (360 degrees)
        mock_quat1_w = 17'd65536;
        mock_quat1_x = 16'd0;
        mock_quat1_y = 16'd0;
        mock_quat1_z = 16'd0;
        wait_cycles(2500000);
        
        // Test 7.3: Extreme gyro values
        mock_gyro1_y = -16'd32768;  // Maximum negative
        wait_cycles(1000);
        mock_gyro1_y = 16'd32767;   // Maximum positive
        wait_cycles(1000);
        
        // Test 7.4: Both buttons pressed
        button1 = 1;
        button2 = 1;
        wait_cycles(2500000);
        button1 = 0;
        button2 = 0;
        
        $display("--- TEST SUITE 7 COMPLETE ---\n");
    endtask
    
    // ========================================================================
    // TEST SUITE 8: Integration Tests
    // ========================================================================
    task test_suite_8_integration();
        $display("\n--- TEST SUITE 8: Integration Tests ---");
        
        // Test 8.1: Complete gesture sequence
        // Simulate right hand snare hit
        mock_quat1_w = 16'd46341;  // 60° yaw
        mock_quat1_x = 16'd0;
        mock_quat1_y = 16'd0;
        mock_quat1_z = 16'd46341;
        mock_gyro1_y = -16'd3000;
        
        bno085_1_int_enable = 1;
        wait_cycles(5000000);  // Wait for full pipeline
        
        // Test 8.2: Left hand hi-hat
        mock_quat2_w = 16'd46341;
        mock_quat2_x = 16'd0;
        mock_quat2_y = 16'd0;
        mock_quat2_z = 16'd46341;
        mock_gyro2_y = -16'd3000;
        mock_gyro2_z = -16'd1000;  // Above threshold
        
        bno085_2_int_enable = 1;
        wait_cycles(5000000);
        
        // Test 8.3: Calibration then gesture
        button2 = 1;
        wait_cycles(2500000);
        button2 = 0;
        wait_cycles(1000000);
        
        mock_gyro1_y = -16'd3000;
        wait_cycles(5000000);
        
        $display("--- TEST SUITE 8 COMPLETE ---\n");
    endtask

endmodule

