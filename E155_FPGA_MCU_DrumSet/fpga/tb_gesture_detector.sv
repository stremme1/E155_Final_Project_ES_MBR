// Testbench for Gesture Detector Module
// Tests gesture detection logic with various sensor inputs

`timescale 1ns / 1ps

module tb_gesture_detector;

    // Parameters
    localparam CLK_PERIOD = 20;  // 50MHz clock
    
    // Signals
    logic        clk;
    logic        rst_n;
    logic        data_valid_1, data_valid_2;
    logic signed [15:0] yaw1, pitch1, gyro1_x, gyro1_y, gyro1_z;
    logic signed [15:0] yaw2, pitch2, gyro2_x, gyro2_y, gyro2_z;
    logic signed [15:0] yaw_offset1, yaw_offset2;
    logic        calib_button;
    logic        sound_valid;
    logic [3:0]  sound_code;
    logic        calib_active;
    
    // Test counters
    int test_count = 0;
    int pass_count = 0;
    int fail_count = 0;
    
    // Instantiate DUT
    gesture_detector dut (
        .clk(clk),
        .rst_n(rst_n),
        .data_valid_1(data_valid_1),
        .yaw1(yaw1),
        .pitch1(pitch1),
        .gyro1_x(gyro1_x),
        .gyro1_y(gyro1_y),
        .gyro1_z(gyro1_z),
        .data_valid_2(data_valid_2),
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
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Test stimulus
    initial begin
        $display("========================================");
        $display("Gesture Detector Testbench");
        $display("========================================\n");
        
        // Initialize
        rst_n = 0;
        data_valid_1 = 0;
        data_valid_2 = 0;
        yaw1 = 0; pitch1 = 0; gyro1_x = 0; gyro1_y = 0; gyro1_z = 0;
        yaw2 = 0; pitch2 = 0; gyro2_x = 0; gyro2_y = 0; gyro2_z = 0;
        yaw_offset1 = 0;
        yaw_offset2 = 0;
        calib_button = 0;
        
        // Reset
        #(CLK_PERIOD * 5);
        rst_n = 1;
        #(CLK_PERIOD * 2);
        
        // Test 1: Right hand - Snare drum (yaw 20-120, gyro_y < -2500)
        $display("Test 1: Right hand - Snare drum");
        test_count++;
        yaw1 = 50;  // In zone 1 (20-120)
        pitch1 = 0;
        gyro1_y = -3000;  // Below threshold
        data_valid_1 = 1;
        #(CLK_PERIOD * 3);
        data_valid_1 = 0;
        #(CLK_PERIOD * 2);
        check_sound("Snare", 4'd0);
        
        // Test 2: Right hand - High tom (yaw 340-20, low pitch)
        $display("\nTest 2: Right hand - High tom");
        test_count++;
        yaw1 = 10;  // In zone 2 (340-20)
        pitch1 = 20;  // Low pitch
        gyro1_y = -3000;
        data_valid_1 = 1;
        #(CLK_PERIOD * 3);
        data_valid_1 = 0;
        #(CLK_PERIOD * 2);
        check_sound("High tom", 4'd3);
        
        // Test 3: Right hand - Crash cymbal (yaw 340-20, high pitch)
        $display("\nTest 3: Right hand - Crash cymbal");
        test_count++;
        yaw1 = 10;
        pitch1 = 60;  // High pitch (>50)
        gyro1_y = -3000;
        data_valid_1 = 1;
        #(CLK_PERIOD * 3);
        data_valid_1 = 0;
        #(CLK_PERIOD * 2);
        check_sound("Crash", 4'd5);
        
        // Test 4: Right hand - Mid tom (yaw 305-340, low pitch)
        $display("\nTest 4: Right hand - Mid tom");
        test_count++;
        yaw1 = 320;  // In zone 3 (305-340)
        pitch1 = 20;
        gyro1_y = -3000;
        data_valid_1 = 1;
        #(CLK_PERIOD * 3);
        data_valid_1 = 0;
        #(CLK_PERIOD * 2);
        check_sound("Mid tom", 4'd4);
        
        // Test 5: Right hand - Ride cymbal (yaw 305-340, high pitch)
        $display("\nTest 5: Right hand - Ride cymbal");
        test_count++;
        yaw1 = 320;
        pitch1 = 60;
        gyro1_y = -3000;
        data_valid_1 = 1;
        #(CLK_PERIOD * 3);
        data_valid_1 = 0;
        #(CLK_PERIOD * 2);
        check_sound("Ride", 4'd6);
        
        // Test 6: Right hand - Floor tom (yaw 200-305, low pitch)
        $display("\nTest 6: Right hand - Floor tom");
        test_count++;
        yaw1 = 250;  // In zone 4 (200-305)
        pitch1 = 20;
        gyro1_y = -3000;
        data_valid_1 = 1;
        #(CLK_PERIOD * 3);
        data_valid_1 = 0;
        #(CLK_PERIOD * 2);
        check_sound("Floor tom", 4'd7);
        
        // Test 7: Left hand - Snare (yaw 350-100, low pitch)
        $display("\nTest 7: Left hand - Snare");
        test_count++;
        yaw2 = 10;  // In zone 1 (350-100)
        pitch2 = 20;
        gyro2_y = -3000;
        gyro2_z = 0;  // Not rotating
        data_valid_2 = 1;
        #(CLK_PERIOD * 3);
        data_valid_2 = 0;
        #(CLK_PERIOD * 2);
        check_sound("Snare (left)", 4'd0);
        
        // Test 8: Left hand - Hi-hat (yaw 350-100, high pitch, low rotation)
        $display("\nTest 8: Left hand - Hi-hat");
        test_count++;
        yaw2 = 10;
        pitch2 = 40;  // High pitch (>30)
        gyro2_y = -3000;
        gyro2_z = -1000;  // Low rotation (>-2000)
        data_valid_2 = 1;
        #(CLK_PERIOD * 3);
        data_valid_2 = 0;
        #(CLK_PERIOD * 2);
        check_sound("Hi-hat", 4'd1);
        
        // Test 9: No strike (gyro_y above threshold)
        $display("\nTest 9: No strike detected");
        test_count++;
        yaw1 = 50;
        gyro1_y = -1000;  // Above threshold
        data_valid_1 = 1;
        #(CLK_PERIOD * 3);
        data_valid_1 = 0;
        #(CLK_PERIOD * 2);
        if (!sound_valid) begin
            $display("  PASS: No sound detected (gyro above threshold)");
            pass_count++;
        end else begin
            $display("  FAIL: Sound detected when it shouldn't be");
            fail_count++;
        end
        
        // Test 10: Calibration
        $display("\nTest 10: Calibration button");
        test_count++;
        yaw1 = 100;
        yaw2 = 200;
        data_valid_1 = 1;
        data_valid_2 = 1;
        #(CLK_PERIOD);
        calib_button = 1;
        #(CLK_PERIOD * 2);
        calib_button = 0;
        #(CLK_PERIOD * 2);
        if (calib_active) begin
            $display("  PASS: Calibration active");
            pass_count++;
        end else begin
            $display("  FAIL: Calibration not active");
            fail_count++;
        end
        
        // Test 11: Yaw normalization (wrap around 360)
        $display("\nTest 11: Yaw normalization");
        test_count++;
        yaw1 = 370;  // Should normalize to 10
        yaw_offset1 = 0;
        pitch1 = 0;
        gyro1_y = -3000;
        data_valid_1 = 1;
        #(CLK_PERIOD * 3);
        data_valid_1 = 0;
        #(CLK_PERIOD * 2);
        // Should detect as zone 2 (340-20 range)
        check_sound("Normalized yaw", 4'd3);
        
        // Summary
        $display("\n========================================");
        $display("Test Summary");
        $display("========================================");
        $display("Total tests: %0d", test_count);
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", fail_count);
        $display("========================================\n");
        
        #(CLK_PERIOD * 10);
        $finish;
    end
    
    // Task to check sound output
    task check_sound(string test_name, logic [3:0] expected_code);
        wait(sound_valid);
        #(CLK_PERIOD);
        
        if (sound_code == expected_code) begin
            $display("  PASS: %s detected (code=%d)", test_name, sound_code);
            pass_count++;
        end else begin
            $display("  FAIL: %s - Expected code=%d, Got code=%d", 
                     test_name, expected_code, sound_code);
            fail_count++;
        end
    endtask
    
    // Monitor
    initial begin
        $monitor("Time=%0t: yaw1=%d, gyro1_y=%d, sound_valid=%b, sound_code=%d",
                 $time, yaw1, gyro1_y, sound_valid, sound_code);
    end

endmodule


