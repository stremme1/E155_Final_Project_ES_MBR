// Comprehensive Testbench for Gesture Detection
// Tests all features: zones, boundaries, thresholds, calibration, edge cases

`timescale 1ns / 1ps

module tb_gesture_scenarios;

    // Parameters
    localparam CLK_PERIOD = 20;  // 50MHz clock
    localparam GYRO_Y_THRESHOLD = -2500;
    localparam GYRO_Z_THRESHOLD = -2000;
    localparam PITCH_CRASH = 50;
    localparam PITCH_RIDE = 30;
    
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
    
    // Test scenarios array (using separate arrays for Icarus compatibility)
    string scenario_names [0:49];
    logic signed [15:0] scenario_yaw1 [0:49];
    logic signed [15:0] scenario_pitch1 [0:49];
    logic signed [15:0] scenario_gyro1_y [0:49];
    logic signed [15:0] scenario_gyro1_z [0:49];
    logic signed [15:0] scenario_yaw2 [0:49];
    logic signed [15:0] scenario_pitch2 [0:49];
    logic signed [15:0] scenario_gyro2_y [0:49];
    logic signed [15:0] scenario_gyro2_z [0:49];
    logic signed [15:0] scenario_yaw_offset1 [0:49];
    logic signed [15:0] scenario_yaw_offset2 [0:49];
    logic scenario_use_imu1 [0:49];
    logic [3:0] scenario_expected [0:49];
    logic scenario_expect_strike [0:49];
    
    int scenario_idx;
    int pass_count, fail_count;
    logic sound_detected;
    logic [3:0] detected_code;
    
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
    
    // Initialize comprehensive test scenarios
    initial begin
        integer idx;
        idx = 0;
        
        // ============================================
        // RIGHT HAND TESTS (IMU 1)
        // ============================================
        
        // Zone 1: Yaw 20-120 -> Snare
        scenario_names[idx] = "Right: Snare (yaw=50, center)";
        scenario_yaw1[idx] = 50; scenario_pitch1[idx] = 0; scenario_gyro1_y[idx] = -3000; scenario_gyro1_z[idx] = 0;
        scenario_yaw2[idx] = 0; scenario_pitch2[idx] = 0; scenario_gyro2_y[idx] = 0; scenario_gyro2_z[idx] = 0;
        scenario_yaw_offset1[idx] = 0; scenario_yaw_offset2[idx] = 0;
        scenario_use_imu1[idx] = 1; scenario_expected[idx] = 4'd0; scenario_expect_strike[idx] = 1;
        idx++;
        
        scenario_names[idx] = "Right: Snare (yaw=20, boundary)";
        scenario_yaw1[idx] = 20; scenario_pitch1[idx] = 0; scenario_gyro1_y[idx] = -3000; scenario_gyro1_z[idx] = 0;
        scenario_yaw2[idx] = 0; scenario_pitch2[idx] = 0; scenario_gyro2_y[idx] = 0; scenario_gyro2_z[idx] = 0;
        scenario_yaw_offset1[idx] = 0; scenario_yaw_offset2[idx] = 0;
        scenario_use_imu1[idx] = 1; scenario_expected[idx] = 4'd0; scenario_expect_strike[idx] = 1;
        idx++;
        
        scenario_names[idx] = "Right: Snare (yaw=120, boundary)";
        scenario_yaw1[idx] = 120; scenario_pitch1[idx] = 0; scenario_gyro1_y[idx] = -3000; scenario_gyro1_z[idx] = 0;
        scenario_yaw2[idx] = 0; scenario_pitch2[idx] = 0; scenario_gyro2_y[idx] = 0; scenario_gyro2_z[idx] = 0;
        scenario_yaw_offset1[idx] = 0; scenario_yaw_offset2[idx] = 0;
        scenario_use_imu1[idx] = 1; scenario_expected[idx] = 4'd0; scenario_expect_strike[idx] = 1;
        idx++;
        
        // Zone 2: Yaw 340-20 -> High tom or Crash
        scenario_names[idx] = "Right: High Tom (yaw=10, low pitch)";
        scenario_yaw1[idx] = 10; scenario_pitch1[idx] = 20; scenario_gyro1_y[idx] = -3000; scenario_gyro1_z[idx] = 0;
        scenario_yaw2[idx] = 0; scenario_pitch2[idx] = 0; scenario_gyro2_y[idx] = 0; scenario_gyro2_z[idx] = 0;
        scenario_yaw_offset1[idx] = 0; scenario_yaw_offset2[idx] = 0;
        scenario_use_imu1[idx] = 1; scenario_expected[idx] = 4'd3; scenario_expect_strike[idx] = 1;
        idx++;
        
        scenario_names[idx] = "Right: High Tom (yaw=350, low pitch)";
        scenario_yaw1[idx] = 350; scenario_pitch1[idx] = 20; scenario_gyro1_y[idx] = -3000; scenario_gyro1_z[idx] = 0;
        scenario_yaw2[idx] = 0; scenario_pitch2[idx] = 0; scenario_gyro2_y[idx] = 0; scenario_gyro2_z[idx] = 0;
        scenario_yaw_offset1[idx] = 0; scenario_yaw_offset2[idx] = 0;
        scenario_use_imu1[idx] = 1; scenario_expected[idx] = 4'd3; scenario_expect_strike[idx] = 1;
        idx++;
        
        scenario_names[idx] = "Right: High Tom (yaw=10, pitch=50, at threshold, no crash)";
        scenario_yaw1[idx] = 10; scenario_pitch1[idx] = 50; scenario_gyro1_y[idx] = -3000; scenario_gyro1_z[idx] = 0;
        scenario_yaw2[idx] = 0; scenario_pitch2[idx] = 0; scenario_gyro2_y[idx] = 0; scenario_gyro2_z[idx] = 0;
        scenario_yaw_offset1[idx] = 0; scenario_yaw_offset2[idx] = 0;
        scenario_use_imu1[idx] = 1; scenario_expected[idx] = 4'd3; scenario_expect_strike[idx] = 1;  // > 50 needed, so high tom
        idx++;
        
        scenario_names[idx] = "Right: Crash (yaw=10, pitch=60, above threshold)";
        scenario_yaw1[idx] = 10; scenario_pitch1[idx] = 60; scenario_gyro1_y[idx] = -3000; scenario_gyro1_z[idx] = 0;
        scenario_yaw2[idx] = 0; scenario_pitch2[idx] = 0; scenario_gyro2_y[idx] = 0; scenario_gyro2_z[idx] = 0;
        scenario_yaw_offset1[idx] = 0; scenario_yaw_offset2[idx] = 0;
        scenario_use_imu1[idx] = 1; scenario_expected[idx] = 4'd5; scenario_expect_strike[idx] = 1;
        idx++;
        
        scenario_names[idx] = "Right: High Tom (yaw=10, pitch=49, just below threshold)";
        scenario_yaw1[idx] = 10; scenario_pitch1[idx] = 49; scenario_gyro1_y[idx] = -3000; scenario_gyro1_z[idx] = 0;
        scenario_yaw2[idx] = 0; scenario_pitch2[idx] = 0; scenario_gyro2_y[idx] = 0; scenario_gyro2_z[idx] = 0;
        scenario_yaw_offset1[idx] = 0; scenario_yaw_offset2[idx] = 0;
        scenario_use_imu1[idx] = 1; scenario_expected[idx] = 4'd3; scenario_expect_strike[idx] = 1;
        idx++;
        
        // Zone 3: Yaw 305-340 -> Mid tom or Ride
        scenario_names[idx] = "Right: Mid Tom (yaw=320, low pitch)";
        scenario_yaw1[idx] = 320; scenario_pitch1[idx] = 20; scenario_gyro1_y[idx] = -3000; scenario_gyro1_z[idx] = 0;
        scenario_yaw2[idx] = 0; scenario_pitch2[idx] = 0; scenario_gyro2_y[idx] = 0; scenario_gyro2_z[idx] = 0;
        scenario_yaw_offset1[idx] = 0; scenario_yaw_offset2[idx] = 0;
        scenario_use_imu1[idx] = 1; scenario_expected[idx] = 4'd4; scenario_expect_strike[idx] = 1;
        idx++;
        
        scenario_names[idx] = "Right: Mid Tom (yaw=305, boundary)";
        scenario_yaw1[idx] = 305; scenario_pitch1[idx] = 20; scenario_gyro1_y[idx] = -3000; scenario_gyro1_z[idx] = 0;
        scenario_yaw2[idx] = 0; scenario_pitch2[idx] = 0; scenario_gyro2_y[idx] = 0; scenario_gyro2_z[idx] = 0;
        scenario_yaw_offset1[idx] = 0; scenario_yaw_offset2[idx] = 0;
        scenario_use_imu1[idx] = 1; scenario_expected[idx] = 4'd4; scenario_expect_strike[idx] = 1;
        idx++;
        
        scenario_names[idx] = "Right: High Tom (yaw=340, boundary, Zone 2)";
        scenario_yaw1[idx] = 340; scenario_pitch1[idx] = 20; scenario_gyro1_y[idx] = -3000; scenario_gyro1_z[idx] = 0;
        scenario_yaw2[idx] = 0; scenario_pitch2[idx] = 0; scenario_gyro2_y[idx] = 0; scenario_gyro2_z[idx] = 0;
        scenario_yaw_offset1[idx] = 0; scenario_yaw_offset2[idx] = 0;
        scenario_use_imu1[idx] = 1; scenario_expected[idx] = 4'd3; scenario_expect_strike[idx] = 1;  // 340 is Zone 2, not Zone 3
        idx++;
        
        scenario_names[idx] = "Right: Mid Tom (yaw=320, pitch=50, at threshold, no ride)";
        scenario_yaw1[idx] = 320; scenario_pitch1[idx] = 50; scenario_gyro1_y[idx] = -3000; scenario_gyro1_z[idx] = 0;
        scenario_yaw2[idx] = 0; scenario_pitch2[idx] = 0; scenario_gyro2_y[idx] = 0; scenario_gyro2_z[idx] = 0;
        scenario_yaw_offset1[idx] = 0; scenario_yaw_offset2[idx] = 0;
        scenario_use_imu1[idx] = 1; scenario_expected[idx] = 4'd4; scenario_expect_strike[idx] = 1;  // > 50 needed, so mid tom
        idx++;
        
        // Zone 4: Yaw 200-305 -> Floor tom or Ride
        scenario_names[idx] = "Right: Floor Tom (yaw=250, low pitch)";
        scenario_yaw1[idx] = 250; scenario_pitch1[idx] = 20; scenario_gyro1_y[idx] = -3000; scenario_gyro1_z[idx] = 0;
        scenario_yaw2[idx] = 0; scenario_pitch2[idx] = 0; scenario_gyro2_y[idx] = 0; scenario_gyro2_z[idx] = 0;
        scenario_yaw_offset1[idx] = 0; scenario_yaw_offset2[idx] = 0;
        scenario_use_imu1[idx] = 1; scenario_expected[idx] = 4'd7; scenario_expect_strike[idx] = 1;
        idx++;
        
        scenario_names[idx] = "Right: Floor Tom (yaw=200, boundary)";
        scenario_yaw1[idx] = 200; scenario_pitch1[idx] = 20; scenario_gyro1_y[idx] = -3000; scenario_gyro1_z[idx] = 0;
        scenario_yaw2[idx] = 0; scenario_pitch2[idx] = 0; scenario_gyro2_y[idx] = 0; scenario_gyro2_z[idx] = 0;
        scenario_yaw_offset1[idx] = 0; scenario_yaw_offset2[idx] = 0;
        scenario_use_imu1[idx] = 1; scenario_expected[idx] = 4'd7; scenario_expect_strike[idx] = 1;
        idx++;
        
        scenario_names[idx] = "Right: Mid Tom (yaw=305, boundary, Zone 3)";
        scenario_yaw1[idx] = 305; scenario_pitch1[idx] = 20; scenario_gyro1_y[idx] = -3000; scenario_gyro1_z[idx] = 0;
        scenario_yaw2[idx] = 0; scenario_pitch2[idx] = 0; scenario_gyro2_y[idx] = 0; scenario_gyro2_z[idx] = 0;
        scenario_yaw_offset1[idx] = 0; scenario_yaw_offset2[idx] = 0;
        scenario_use_imu1[idx] = 1; scenario_expected[idx] = 4'd4; scenario_expect_strike[idx] = 1;  // 305 is Zone 3, not Zone 4
        idx++;
        
        scenario_names[idx] = "Right: Floor Tom (yaw=250, pitch=30, at threshold, no ride)";
        scenario_yaw1[idx] = 250; scenario_pitch1[idx] = 30; scenario_gyro1_y[idx] = -3000; scenario_gyro1_z[idx] = 0;
        scenario_yaw2[idx] = 0; scenario_pitch2[idx] = 0; scenario_gyro2_y[idx] = 0; scenario_gyro2_z[idx] = 0;
        scenario_yaw_offset1[idx] = 0; scenario_yaw_offset2[idx] = 0;
        scenario_use_imu1[idx] = 1; scenario_expected[idx] = 4'd7; scenario_expect_strike[idx] = 1;  // > 30 needed, so floor tom
        idx++;
        
        scenario_names[idx] = "Right: Ride (yaw=250, pitch=40, above threshold)";
        scenario_yaw1[idx] = 250; scenario_pitch1[idx] = 40; scenario_gyro1_y[idx] = -3000; scenario_gyro1_z[idx] = 0;
        scenario_yaw2[idx] = 0; scenario_pitch2[idx] = 0; scenario_gyro2_y[idx] = 0; scenario_gyro2_z[idx] = 0;
        scenario_yaw_offset1[idx] = 0; scenario_yaw_offset2[idx] = 0;
        scenario_use_imu1[idx] = 1; scenario_expected[idx] = 4'd6; scenario_expect_strike[idx] = 1;
        idx++;
        
        scenario_names[idx] = "Right: Floor Tom (yaw=250, pitch=29, just below threshold)";
        scenario_yaw1[idx] = 250; scenario_pitch1[idx] = 29; scenario_gyro1_y[idx] = -3000; scenario_gyro1_z[idx] = 0;
        scenario_yaw2[idx] = 0; scenario_pitch2[idx] = 0; scenario_gyro2_y[idx] = 0; scenario_gyro2_z[idx] = 0;
        scenario_yaw_offset1[idx] = 0; scenario_yaw_offset2[idx] = 0;
        scenario_use_imu1[idx] = 1; scenario_expected[idx] = 4'd7; scenario_expect_strike[idx] = 1;
        idx++;
        
        // ============================================
        // LEFT HAND TESTS (IMU 2)
        // ============================================
        
        // Zone 1: Yaw 350-100 -> Snare or Hi-hat
        scenario_names[idx] = "Left: Snare (yaw=10, low pitch)";
        scenario_yaw1[idx] = 0; scenario_pitch1[idx] = 0; scenario_gyro1_y[idx] = 0; scenario_gyro1_z[idx] = 0;
        scenario_yaw2[idx] = 10; scenario_pitch2[idx] = 20; scenario_gyro2_y[idx] = -3000; scenario_gyro2_z[idx] = 0;
        scenario_yaw_offset1[idx] = 0; scenario_yaw_offset2[idx] = 0;
        scenario_use_imu1[idx] = 0; scenario_expected[idx] = 4'd0; scenario_expect_strike[idx] = 1;
        idx++;
        
        scenario_names[idx] = "Left: Snare (yaw=350, boundary)";
        scenario_yaw1[idx] = 0; scenario_pitch1[idx] = 0; scenario_gyro1_y[idx] = 0; scenario_gyro1_z[idx] = 0;
        scenario_yaw2[idx] = 350; scenario_pitch2[idx] = 20; scenario_gyro2_y[idx] = -3000; scenario_gyro2_z[idx] = 0;
        scenario_yaw_offset1[idx] = 0; scenario_yaw_offset2[idx] = 0;
        scenario_use_imu1[idx] = 0; scenario_expected[idx] = 4'd0; scenario_expect_strike[idx] = 1;
        idx++;
        
        scenario_names[idx] = "Left: Snare (yaw=100, boundary)";
        scenario_yaw1[idx] = 0; scenario_pitch1[idx] = 0; scenario_gyro1_y[idx] = 0; scenario_gyro1_z[idx] = 0;
        scenario_yaw2[idx] = 100; scenario_pitch2[idx] = 20; scenario_gyro2_y[idx] = -3000; scenario_gyro2_z[idx] = 0;
        scenario_yaw_offset1[idx] = 0; scenario_yaw_offset2[idx] = 0;
        scenario_use_imu1[idx] = 0; scenario_expected[idx] = 4'd0; scenario_expect_strike[idx] = 1;
        idx++;
        
        scenario_names[idx] = "Left: Hi-hat (yaw=10, pitch=40, gyro_z=-1500, above threshold)";
        scenario_yaw1[idx] = 0; scenario_pitch1[idx] = 0; scenario_gyro1_y[idx] = 0; scenario_gyro1_z[idx] = 0;
        scenario_yaw2[idx] = 10; scenario_pitch2[idx] = 40; scenario_gyro2_y[idx] = -3000; scenario_gyro2_z[idx] = -1500;
        scenario_yaw_offset1[idx] = 0; scenario_yaw_offset2[idx] = 0;
        scenario_use_imu1[idx] = 0; scenario_expected[idx] = 4'd1; scenario_expect_strike[idx] = 1;  // gyro_z > -2000
        idx++;
        
        scenario_names[idx] = "Left: Hi-hat (yaw=10, pitch=31, above pitch threshold, gyro_z=-1500)";
        scenario_yaw1[idx] = 0; scenario_pitch1[idx] = 0; scenario_gyro1_y[idx] = 0; scenario_gyro1_z[idx] = 0;
        scenario_yaw2[idx] = 10; scenario_pitch2[idx] = 31; scenario_gyro2_y[idx] = -3000; scenario_gyro2_z[idx] = -1500;
        scenario_yaw_offset1[idx] = 0; scenario_yaw_offset2[idx] = 0;
        scenario_use_imu1[idx] = 0; scenario_expected[idx] = 4'd1; scenario_expect_strike[idx] = 1;  // pitch > 30, gyro_z > -2000
        idx++;
        
        scenario_names[idx] = "Left: Snare (yaw=10, pitch=40, gyro_z=-2001, just below threshold)";
        scenario_yaw1[idx] = 0; scenario_pitch1[idx] = 0; scenario_gyro1_y[idx] = 0; scenario_gyro1_z[idx] = 0;
        scenario_yaw2[idx] = 10; scenario_pitch2[idx] = 40; scenario_gyro2_y[idx] = -3000; scenario_gyro2_z[idx] = -2001;
        scenario_yaw_offset1[idx] = 0; scenario_yaw_offset2[idx] = 0;
        scenario_use_imu1[idx] = 0; scenario_expected[idx] = 4'd0; scenario_expect_strike[idx] = 1;  // gyro_z <= -2000, so snare
        idx++;
        
        scenario_names[idx] = "Left: Snare (yaw=10, pitch=29, just below pitch threshold, gyro_z=-1500)";
        scenario_yaw1[idx] = 0; scenario_pitch1[idx] = 0; scenario_gyro1_y[idx] = 0; scenario_gyro1_z[idx] = 0;
        scenario_yaw2[idx] = 10; scenario_pitch2[idx] = 29; scenario_gyro2_y[idx] = -3000; scenario_gyro2_z[idx] = -1500;
        scenario_yaw_offset1[idx] = 0; scenario_yaw_offset2[idx] = 0;
        scenario_use_imu1[idx] = 0; scenario_expected[idx] = 4'd0; scenario_expect_strike[idx] = 1;  // pitch <= 30, so snare
        idx++;
        
        // Zone 2: Yaw 325-350 -> High tom or Crash
        scenario_names[idx] = "Left: High Tom (yaw=340, low pitch)";
        scenario_yaw1[idx] = 0; scenario_pitch1[idx] = 0; scenario_gyro1_y[idx] = 0; scenario_gyro1_z[idx] = 0;
        scenario_yaw2[idx] = 340; scenario_pitch2[idx] = 20; scenario_gyro2_y[idx] = -3000; scenario_gyro2_z[idx] = 0;
        scenario_yaw_offset1[idx] = 0; scenario_yaw_offset2[idx] = 0;
        scenario_use_imu1[idx] = 0; scenario_expected[idx] = 4'd3; scenario_expect_strike[idx] = 1;
        idx++;
        
        scenario_names[idx] = "Left: Crash (yaw=340, pitch=60)";
        scenario_yaw1[idx] = 0; scenario_pitch1[idx] = 0; scenario_gyro1_y[idx] = 0; scenario_gyro1_z[idx] = 0;
        scenario_yaw2[idx] = 340; scenario_pitch2[idx] = 60; scenario_gyro2_y[idx] = -3000; scenario_gyro2_z[idx] = 0;
        scenario_yaw_offset1[idx] = 0; scenario_yaw_offset2[idx] = 0;
        scenario_use_imu1[idx] = 0; scenario_expected[idx] = 4'd5; scenario_expect_strike[idx] = 1;
        idx++;
        
        // Zone 3: Yaw 300-325 -> Mid tom or Ride
        scenario_names[idx] = "Left: Mid Tom (yaw=310, low pitch)";
        scenario_yaw1[idx] = 0; scenario_pitch1[idx] = 0; scenario_gyro1_y[idx] = 0; scenario_gyro1_z[idx] = 0;
        scenario_yaw2[idx] = 310; scenario_pitch2[idx] = 20; scenario_gyro2_y[idx] = -3000; scenario_gyro2_z[idx] = 0;
        scenario_yaw_offset1[idx] = 0; scenario_yaw_offset2[idx] = 0;
        scenario_use_imu1[idx] = 0; scenario_expected[idx] = 4'd4; scenario_expect_strike[idx] = 1;
        idx++;
        
        scenario_names[idx] = "Left: Ride (yaw=310, pitch=60)";
        scenario_yaw1[idx] = 0; scenario_pitch1[idx] = 0; scenario_gyro1_y[idx] = 0; scenario_gyro1_z[idx] = 0;
        scenario_yaw2[idx] = 310; scenario_pitch2[idx] = 60; scenario_gyro2_y[idx] = -3000; scenario_gyro2_z[idx] = 0;
        scenario_yaw_offset1[idx] = 0; scenario_yaw_offset2[idx] = 0;
        scenario_use_imu1[idx] = 0; scenario_expected[idx] = 4'd6; scenario_expect_strike[idx] = 1;
        idx++;
        
        // Zone 4: Yaw 200-300 -> Floor tom or Ride
        scenario_names[idx] = "Left: Floor Tom (yaw=250, low pitch)";
        scenario_yaw1[idx] = 0; scenario_pitch1[idx] = 0; scenario_gyro1_y[idx] = 0; scenario_gyro1_z[idx] = 0;
        scenario_yaw2[idx] = 250; scenario_pitch2[idx] = 20; scenario_gyro2_y[idx] = -3000; scenario_gyro2_z[idx] = 0;
        scenario_yaw_offset1[idx] = 0; scenario_yaw_offset2[idx] = 0;
        scenario_use_imu1[idx] = 0; scenario_expected[idx] = 4'd7; scenario_expect_strike[idx] = 1;
        idx++;
        
        scenario_names[idx] = "Left: Ride (yaw=250, pitch=40)";
        scenario_yaw1[idx] = 0; scenario_pitch1[idx] = 0; scenario_gyro1_y[idx] = 0; scenario_gyro1_z[idx] = 0;
        scenario_yaw2[idx] = 250; scenario_pitch2[idx] = 40; scenario_gyro2_y[idx] = -3000; scenario_gyro2_z[idx] = 0;
        scenario_yaw_offset1[idx] = 0; scenario_yaw_offset2[idx] = 0;
        scenario_use_imu1[idx] = 0; scenario_expected[idx] = 4'd6; scenario_expect_strike[idx] = 1;
        idx++;
        
        // ============================================
        // EDGE CASES AND SPECIAL TESTS
        // ============================================
        
        // Yaw normalization tests
        scenario_names[idx] = "Right: Yaw normalization (yaw=-10 -> 350)";
        scenario_yaw1[idx] = -10; scenario_pitch1[idx] = 0; scenario_gyro1_y[idx] = -3000; scenario_gyro1_z[idx] = 0;
        scenario_yaw2[idx] = 0; scenario_pitch2[idx] = 0; scenario_gyro2_y[idx] = 0; scenario_gyro2_z[idx] = 0;
        scenario_yaw_offset1[idx] = 0; scenario_yaw_offset2[idx] = 0;
        scenario_use_imu1[idx] = 1; scenario_expected[idx] = 4'd3; scenario_expect_strike[idx] = 1;  // Zone 2
        idx++;
        
        scenario_names[idx] = "Right: Yaw normalization (yaw=370 -> 10)";
        scenario_yaw1[idx] = 370; scenario_pitch1[idx] = 0; scenario_gyro1_y[idx] = -3000; scenario_gyro1_z[idx] = 0;
        scenario_yaw2[idx] = 0; scenario_pitch2[idx] = 0; scenario_gyro2_y[idx] = 0; scenario_gyro2_z[idx] = 0;
        scenario_yaw_offset1[idx] = 0; scenario_yaw_offset2[idx] = 0;
        scenario_use_imu1[idx] = 1; scenario_expected[idx] = 4'd3; scenario_expect_strike[idx] = 1;  // Zone 2
        idx++;
        
        // Calibration tests
        scenario_names[idx] = "Right: Calibration offset (yaw=50, offset=30 -> normalized to 20)";
        scenario_yaw1[idx] = 50; scenario_pitch1[idx] = 0; scenario_gyro1_y[idx] = -3000; scenario_gyro1_z[idx] = 0;
        scenario_yaw2[idx] = 0; scenario_pitch2[idx] = 0; scenario_gyro2_y[idx] = 0; scenario_gyro2_z[idx] = 0;
        scenario_yaw_offset1[idx] = 30; scenario_yaw_offset2[idx] = 0;
        scenario_use_imu1[idx] = 1; scenario_expected[idx] = 4'd0; scenario_expect_strike[idx] = 1;  // Still Zone 1
        idx++;
        
        scenario_names[idx] = "Right: Calibration offset (yaw=50, offset=30 -> normalized to 20, Zone 1)";
        scenario_yaw1[idx] = 50; scenario_pitch1[idx] = 0; scenario_gyro1_y[idx] = -3000; scenario_gyro1_z[idx] = 0;
        scenario_yaw2[idx] = 0; scenario_pitch2[idx] = 0; scenario_gyro2_y[idx] = 0; scenario_gyro2_z[idx] = 0;
        scenario_yaw_offset1[idx] = 30; scenario_yaw_offset2[idx] = 0;
        scenario_use_imu1[idx] = 1; scenario_expected[idx] = 4'd0; scenario_expect_strike[idx] = 1;
        idx++;
        
        // Gyro threshold edge cases
        // Note: Threshold is exclusive (< -2500), so -2500 itself doesn't trigger
        scenario_names[idx] = "Right: Gyro at threshold (gyro_y=-2500, no strike)";
        scenario_yaw1[idx] = 50; scenario_pitch1[idx] = 0; scenario_gyro1_y[idx] = -2500; scenario_gyro1_z[idx] = 0;
        scenario_yaw2[idx] = 0; scenario_pitch2[idx] = 0; scenario_gyro2_y[idx] = 0; scenario_gyro2_z[idx] = 0;
        scenario_yaw_offset1[idx] = 0; scenario_yaw_offset2[idx] = 0;
        scenario_use_imu1[idx] = 1; scenario_expected[idx] = 4'd15; scenario_expect_strike[idx] = 0;
        idx++;
        
        scenario_names[idx] = "Right: Gyro just above threshold (gyro_y=-2499)";
        scenario_yaw1[idx] = 50; scenario_pitch1[idx] = 0; scenario_gyro1_y[idx] = -2499; scenario_gyro1_z[idx] = 0;
        scenario_yaw2[idx] = 0; scenario_pitch2[idx] = 0; scenario_gyro2_y[idx] = 0; scenario_gyro2_z[idx] = 0;
        scenario_yaw_offset1[idx] = 0; scenario_yaw_offset2[idx] = 0;
        scenario_use_imu1[idx] = 1; scenario_expected[idx] = 4'd15; scenario_expect_strike[idx] = 0;  // No strike
        idx++;
        
        scenario_names[idx] = "Right: Gyro just below threshold (gyro_y=-2501)";
        scenario_yaw1[idx] = 50; scenario_pitch1[idx] = 0; scenario_gyro1_y[idx] = -2501; scenario_gyro1_z[idx] = 0;
        scenario_yaw2[idx] = 0; scenario_pitch2[idx] = 0; scenario_gyro2_y[idx] = 0; scenario_gyro2_z[idx] = 0;
        scenario_yaw_offset1[idx] = 0; scenario_yaw_offset2[idx] = 0;
        scenario_use_imu1[idx] = 1; scenario_expected[idx] = 4'd0; scenario_expect_strike[idx] = 1;
        idx++;
        
        // No strike scenarios
        scenario_names[idx] = "No strike: Gyro above threshold";
        scenario_yaw1[idx] = 50; scenario_pitch1[idx] = 0; scenario_gyro1_y[idx] = -1000; scenario_gyro1_z[idx] = 0;
        scenario_yaw2[idx] = 0; scenario_pitch2[idx] = 0; scenario_gyro2_y[idx] = 0; scenario_gyro2_z[idx] = 0;
        scenario_yaw_offset1[idx] = 0; scenario_yaw_offset2[idx] = 0;
        scenario_use_imu1[idx] = 1; scenario_expected[idx] = 4'd15; scenario_expect_strike[idx] = 0;
        idx++;
        
        scenario_names[idx] = "No strike: Outside all zones (yaw=150)";
        scenario_yaw1[idx] = 150; scenario_pitch1[idx] = 0; scenario_gyro1_y[idx] = -3000; scenario_gyro1_z[idx] = 0;
        scenario_yaw2[idx] = 0; scenario_pitch2[idx] = 0; scenario_gyro2_y[idx] = 0; scenario_gyro2_z[idx] = 0;
        scenario_yaw_offset1[idx] = 0; scenario_yaw_offset2[idx] = 0;
        scenario_use_imu1[idx] = 1; scenario_expected[idx] = 4'd15; scenario_expect_strike[idx] = 0;
        idx++;
        
        // Fill remaining slots with no-op
        for (idx = idx; idx < 50; idx = idx + 1) begin
            scenario_names[idx] = "Reserved";
            scenario_yaw1[idx] = 0; scenario_pitch1[idx] = 0; scenario_gyro1_y[idx] = 0; scenario_gyro1_z[idx] = 0;
            scenario_yaw2[idx] = 0; scenario_pitch2[idx] = 0; scenario_gyro2_y[idx] = 0; scenario_gyro2_z[idx] = 0;
            scenario_yaw_offset1[idx] = 0; scenario_yaw_offset2[idx] = 0;
            scenario_use_imu1[idx] = 0; scenario_expected[idx] = 4'd15; scenario_expect_strike[idx] = 0;
        end
    end
    
    // Test stimulus
    initial begin
        $display("========================================");
        $display("Comprehensive Gesture Detection Testbench");
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
        scenario_idx = 0;
        pass_count = 0;
        fail_count = 0;
        
        // Reset
        #(CLK_PERIOD * 5);
        rst_n = 1;
        #(CLK_PERIOD * 2);
        
        // Run through all scenarios
        for (scenario_idx = 0; scenario_idx < 50; scenario_idx = scenario_idx + 1) begin
            // Skip reserved slots
            if (scenario_names[scenario_idx] == "Reserved") begin
                // Skip this scenario
            end else begin
            
            $display("\n--- Scenario %0d: %s ---", scenario_idx, scenario_names[scenario_idx]);
            
            // Set calibration offsets
            yaw_offset1 = scenario_yaw_offset1[scenario_idx];
            yaw_offset2 = scenario_yaw_offset2[scenario_idx];
            
            // Apply scenario data
            if (scenario_use_imu1[scenario_idx]) begin
                // Right hand scenarios
                yaw1 = scenario_yaw1[scenario_idx];
                pitch1 = scenario_pitch1[scenario_idx];
                gyro1_x = 16'd0;
                gyro1_z = scenario_gyro1_z[scenario_idx];
                
                // Step 1: Set yaw/pitch and start with gyro above threshold
                data_valid_1 = 1;
                gyro1_y = 16'd0;  // Above threshold
                #(CLK_PERIOD * 3);  // Let yaw normalize
                
                // Step 2: Set gyro below threshold (strike)
                gyro1_y = scenario_gyro1_y[scenario_idx];
                
                // Step 3: Check for sound_valid while data_valid is still active
                sound_detected = 1'b0;
                detected_code = 4'd0;
                for (int i = 0; i < 15; i++) begin
                    #(CLK_PERIOD);
                    if (sound_valid && !sound_detected) begin
                        sound_detected = 1'b1;
                        detected_code = sound_code;
                    end
                end
                data_valid_1 = 0;
            end else begin
                // Left hand scenarios
                yaw2 = scenario_yaw2[scenario_idx];
                pitch2 = scenario_pitch2[scenario_idx];
                gyro2_x = 16'd0;
                gyro2_z = scenario_gyro2_z[scenario_idx];
                
                // Step 1: Set yaw/pitch and start with gyro above threshold
                data_valid_2 = 1;
                gyro2_y = 16'd0;  // Above threshold
                #(CLK_PERIOD * 3);  // Let yaw normalize
                
                // Step 2: Set gyro below threshold (strike)
                gyro2_y = scenario_gyro2_y[scenario_idx];
                
                // Step 3: Check for sound_valid while data_valid is still active
                sound_detected = 1'b0;
                detected_code = 4'd0;
                for (int i = 0; i < 15; i++) begin
                    #(CLK_PERIOD);
                    if (sound_valid && !sound_detected) begin
                        sound_detected = 1'b1;
                        detected_code = sound_code;
                    end
                end
                data_valid_2 = 0;
            end
            
            // Check results
            if (!scenario_expect_strike[scenario_idx]) begin
                // No strike expected
                if (!sound_detected) begin
                    $display("  PASS: No strike detected (as expected)");
                    pass_count++;
                end else begin
                    $display("  FAIL: Strike detected when none expected (code=%d)", detected_code);
                    fail_count++;
                end
            end else begin
                // Strike expected
                if (sound_detected && detected_code == scenario_expected[scenario_idx]) begin
                    $display("  PASS: Correct sound detected (code=%d)", detected_code);
                    pass_count++;
                end else begin
                    $display("  FAIL: Expected code=%d, got detected=%b code=%d", 
                             scenario_expected[scenario_idx], sound_detected, detected_code);
                    fail_count++;
                end
            end
            
            #(CLK_PERIOD * 10);  // Wait between scenarios
            end  // else (not reserved)
        end  // for loop
        
        // Summary
        $display("\n========================================");
        $display("Test Summary");
        $display("========================================");
        $display("Total scenarios: %0d", pass_count + fail_count);
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", fail_count);
        $display("========================================\n");
        
        #(CLK_PERIOD * 100);
        $finish;
    end

endmodule
