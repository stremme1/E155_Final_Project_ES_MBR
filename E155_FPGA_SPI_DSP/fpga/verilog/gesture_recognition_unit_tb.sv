// Unit Test Bench for Gesture Recognition Module
// Tests all gesture detection scenarios matching C code exactly
// Author: E155 Final Project - Engineering Audit
// Date: 2024

`timescale 1ns / 1ps

module gesture_recognition_unit_tb;

    // Clock and Reset
    logic clk;
    logic rst_n;
    
    // Inputs
    logic [15:0] yaw1_normalized, yaw2_normalized;
    logic signed [15:0] pitch1, pitch2;
    logic signed [15:0] gyro1_y, gyro1_z;
    logic signed [15:0] gyro2_y, gyro2_z;
    logic data1_valid, data2_valid;
    logic button1, button2;
    
    // Outputs
    logic [7:0] sound_id;
    logic sound_valid;
    
    // Test counters
    integer test_count = 0;
    integer pass_count = 0;
    integer fail_count = 0;
    
    // Clock generation (48 MHz)
    initial begin
        clk = 0;
        forever #10.416 clk = ~clk;
    end
    
    // DUT
    gesture_recognition_full dut (
        .clk(clk),
        .rst_n(rst_n),
        .yaw1_normalized(yaw1_normalized),
        .pitch1(pitch1),
        .gyro1_y(gyro1_y),
        .gyro1_z(gyro1_z),
        .data1_valid(data1_valid),
        .yaw2_normalized(yaw2_normalized),
        .pitch2(pitch2),
        .gyro2_y(gyro2_y),
        .gyro2_z(gyro2_z),
        .data2_valid(data2_valid),
        .button1(button1),
        .button2(button2),
        .sound_id(sound_id),
        .sound_valid(sound_valid)
    );
    
    // Helper tasks
    task reset();
        rst_n = 0;
        yaw1_normalized = 0;
        yaw2_normalized = 0;
        pitch1 = 0;
        pitch2 = 0;
        gyro1_y = 0;
        gyro1_z = 0;
        gyro2_y = 0;
        gyro2_z = 0;
        data1_valid = 0;
        data2_valid = 0;
        button1 = 0;
        button2 = 0;
        repeat(10) @(posedge clk);
        rst_n = 1;
        repeat(10) @(posedge clk);
    endtask
    
    task check_sound(string desc, logic [7:0] expected);
        test_count = test_count + 1;
        @(posedge clk);
        if (sound_id == expected && sound_valid) begin
            pass_count = pass_count + 1;
            $display("[PASS] %s: Sound ID = 0x%02X (expected 0x%02X)", desc, sound_id, expected);
        end else begin
            fail_count = fail_count + 1;
            $display("[FAIL] %s: Sound ID = 0x%02X (expected 0x%02X)", desc, sound_id, expected);
        end
    endtask
    
    // Test Right Hand - Snare Drum (Yaw 20-120)
    task test_right_snare();
        $display("\n=== Right Hand: Snare Drum (Yaw 20-120) ===");
        reset();
        
        // Yaw = 50 degrees (12800 in Q8), gyro_y < -2500
        yaw1_normalized = 16'd12800;  // 50 degrees
        pitch1 = 0;
        gyro1_y = -16'd3000;  // Below threshold
        data1_valid = 1;
        @(posedge clk);
        data1_valid = 0;
        repeat(5) @(posedge clk);
        check_sound("Right hand snare (yaw=50)", 8'h00);
    endtask
    
    // Test Right Hand - High Tom (Yaw 340-360 or 0-20, pitch <= 50)
    task test_right_high_tom();
        $display("\n=== Right Hand: High Tom (Yaw 340-20, pitch <= 50) ===");
        reset();
        
        // Yaw = 10 degrees, pitch = 30 degrees, gyro_y < -2500
        yaw1_normalized = 16'd2560;  // 10 degrees
        pitch1 = 16'd7680;  // 30 degrees
        gyro1_y = -16'd3000;
        data1_valid = 1;
        @(posedge clk);
        data1_valid = 0;
        repeat(5) @(posedge clk);
        check_sound("Right hand high tom (yaw=10, pitch=30)", 8'h03);
    endtask
    
    // Test Right Hand - Crash Cymbal (Yaw 340-20, pitch > 50)
    task test_right_crash();
        $display("\n=== Right Hand: Crash Cymbal (Yaw 340-20, pitch > 50) ===");
        reset();
        
        // Yaw = 10 degrees, pitch = 60 degrees, gyro_y < -2500
        yaw1_normalized = 16'd2560;  // 10 degrees
        pitch1 = 16'd15360;  // 60 degrees
        gyro1_y = -16'd3000;
        data1_valid = 1;
        @(posedge clk);
        data1_valid = 0;
        repeat(5) @(posedge clk);
        check_sound("Right hand crash (yaw=10, pitch=60)", 8'h05);
    endtask
    
    // Test Right Hand - Mid Tom (Yaw 305-340, pitch <= 50)
    task test_right_mid_tom();
        $display("\n=== Right Hand: Mid Tom (Yaw 305-340, pitch <= 50) ===");
        reset();
        
        // Yaw = 320 degrees, pitch = 30 degrees, gyro_y < -2500
        yaw1_normalized = 16'd81920;  // 320 degrees
        pitch1 = 16'd7680;  // 30 degrees
        gyro1_y = -16'd3000;
        data1_valid = 1;
        @(posedge clk);
        data1_valid = 0;
        repeat(5) @(posedge clk);
        check_sound("Right hand mid tom (yaw=320, pitch=30)", 8'h04);
    endtask
    
    // Test Right Hand - Ride Cymbal (Yaw 305-340, pitch > 50)
    task test_right_ride_high();
        $display("\n=== Right Hand: Ride Cymbal (Yaw 305-340, pitch > 50) ===");
        reset();
        
        // Yaw = 320 degrees, pitch = 60 degrees, gyro_y < -2500
        yaw1_normalized = 16'd81920;  // 320 degrees
        pitch1 = 16'd15360;  // 60 degrees
        gyro1_y = -16'd3000;
        data1_valid = 1;
        @(posedge clk);
        data1_valid = 0;
        repeat(5) @(posedge clk);
        check_sound("Right hand ride from mid (yaw=320, pitch=60)", 8'h06);
    endtask
    
    // Test Right Hand - Floor Tom (Yaw 200-305, pitch <= 30)
    task test_right_floor_tom();
        $display("\n=== Right Hand: Floor Tom (Yaw 200-305, pitch <= 30) ===");
        reset();
        
        // Yaw = 250 degrees, pitch = 20 degrees, gyro_y < -2500
        yaw1_normalized = 16'd64000;  // 250 degrees
        pitch1 = 16'd5120;  // 20 degrees
        gyro1_y = -16'd3000;
        data1_valid = 1;
        @(posedge clk);
        data1_valid = 0;
        repeat(5) @(posedge clk);
        check_sound("Right hand floor tom (yaw=250, pitch=20)", 8'h07);
    endtask
    
    // Test Right Hand - Ride from Floor Tom (Yaw 200-305, pitch > 30)
    task test_right_ride_floor();
        $display("\n=== Right Hand: Ride from Floor Tom (Yaw 200-305, pitch > 30) ===");
        reset();
        
        // Yaw = 250 degrees, pitch = 40 degrees, gyro_y < -2500
        yaw1_normalized = 16'd64000;  // 250 degrees
        pitch1 = 16'd10240;  // 40 degrees
        gyro1_y = -16'd3000;
        data1_valid = 1;
        @(posedge clk);
        data1_valid = 0;
        repeat(5) @(posedge clk);
        check_sound("Right hand ride from floor (yaw=250, pitch=40)", 8'h06);
    endtask
    
    // Test Left Hand - Snare (Yaw 350-100, pitch <= 30 or gyro_z <= -2000)
    task test_left_snare();
        $display("\n=== Left Hand: Snare Drum (Yaw 350-100) ===");
        reset();
        
        // Yaw = 50 degrees, pitch = 20 degrees, gyro_z = -3000
        yaw2_normalized = 16'd12800;  // 50 degrees
        pitch2 = 16'd5120;  // 20 degrees
        gyro2_y = -16'd3000;
        gyro2_z = -16'd3000;  // Below threshold
        data2_valid = 1;
        @(posedge clk);
        data2_valid = 0;
        repeat(5) @(posedge clk);
        check_sound("Left hand snare (yaw=50, gyro_z=-3000)", 8'h00);
    endtask
    
    // Test Left Hand - Hi-Hat (Yaw 350-100, pitch > 30 AND gyro_z > -2000)
    task test_left_hihat();
        $display("\n=== Left Hand: Hi-Hat (Yaw 350-100, pitch > 30, gyro_z > -2000) ===");
        reset();
        
        // Yaw = 50 degrees, pitch = 40 degrees, gyro_z = -1000
        yaw2_normalized = 16'd12800;  // 50 degrees
        pitch2 = 16'd10240;  // 40 degrees
        gyro2_y = -16'd3000;
        gyro2_z = -16'd1000;  // Above threshold
        data2_valid = 1;
        @(posedge clk);
        data2_valid = 0;
        repeat(5) @(posedge clk);
        check_sound("Left hand hi-hat (yaw=50, pitch=40, gyro_z=-1000)", 8'h01);
    endtask
    
    // Test Button1 - Kick Drum
    task test_button_kick();
        $display("\n=== Button1: Kick Drum ===");
        reset();
        
        button1 = 1;
        repeat(2500000) @(posedge clk);  // Wait for debounce
        check_sound("Button1 kick drum", 8'h02);
        
        button1 = 0;
        repeat(100) @(posedge clk);
        check_sound("No sound when button released", 8'hFF);
    endtask
    
    // Test Gyro Debouncing
    task test_gyro_debounce();
        $display("\n=== Gyro Debouncing ===");
        reset();
        
        // First trigger
        yaw1_normalized = 16'd12800;  // 50 degrees
        gyro1_y = -16'd3000;
        data1_valid = 1;
        @(posedge clk);
        data1_valid = 0;
        repeat(5) @(posedge clk);
        check_sound("First gyro trigger", 8'h00);
        
        // Second trigger (should be ignored)
        gyro1_y = -16'd3000;
        data1_valid = 1;
        @(posedge clk);
        data1_valid = 0;
        repeat(5) @(posedge clk);
        // Should still be snare (debounced)
        check_sound("Second trigger debounced", sound_id == 8'h00 || sound_id == 8'hFF);
        
        // Reset debounce
        gyro1_y = -16'd2000;  // Above threshold
        data1_valid = 1;
        @(posedge clk);
        data1_valid = 0;
        repeat(5) @(posedge clk);
        
        // Third trigger (should work)
        gyro1_y = -16'd3000;
        data1_valid = 1;
        @(posedge clk);
        data1_valid = 0;
        repeat(5) @(posedge clk);
        check_sound("Third trigger after reset", 8'h00);
    endtask
    
    // Main test runner
    initial begin
        $display("========================================");
        $display("GESTURE RECOGNITION UNIT TEST");
        $display("========================================\n");
        
        test_right_snare();
        test_right_high_tom();
        test_right_crash();
        test_right_mid_tom();
        test_right_ride_high();
        test_right_floor_tom();
        test_right_ride_floor();
        test_left_snare();
        test_left_hihat();
        test_button_kick();
        test_gyro_debounce();
        
        $display("\n========================================");
        $display("TEST SUMMARY");
        $display("========================================");
        $display("Total Tests: %0d", test_count);
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", fail_count);
        $display("Pass Rate: %0.1f%%", (pass_count * 100.0) / test_count);
        $display("========================================\n");
        
        if (fail_count == 0) begin
            $display("✓ ALL TESTS PASSED");
        end else begin
            $display("✗ SOME TESTS FAILED");
        end
        
        #1000;
        $finish;
    end

endmodule

