// Testbench for Calibration Button Functionality
// Tests calibration button debouncing, yaw offset capture, and zone normalization
//
// NOTE: calib_button is REQUIRED and must be connected (P11)
// - Connected to gesture_detector module
// - Directly affects led_error output when pressed during calibration
// - Used to capture yaw offsets for normalization

`timescale 1ns / 1ps

module tb_calibration;

    // Parameters
    // Note: System uses 3MHz clock (333.33ns period)
    // For simulation, using 50MHz (20ns period) is fine - debounce count is in clock cycles
    localparam CLK_PERIOD = 20;  // 50MHz clock for simulation
    localparam DEBOUNCE_COUNT_TB = 150_000;  // 50ms at 3MHz = 150,000 cycles
    // At 50MHz simulation: 150,000 cycles = 3ms, but we'll use the actual count
    
    // Clock and reset
    logic clk;
    logic rst_n;
    
    // DUT signals
    logic calib_button;
    logic data_valid_1, data_valid_2;
    logic signed [15:0] yaw1, yaw2;
    logic signed [15:0] pitch1, pitch2;
    logic signed [15:0] gyro1_x, gyro1_y, gyro1_z;
    logic signed [15:0] gyro2_x, gyro2_y, gyro2_z;
    logic signed [15:0] yaw_offset1, yaw_offset2;
    logic sound_valid;
    logic [3:0] sound_code;
    logic calib_active;
    
    // Capture yaw offsets (simulating top-level behavior)
    // Only capture on rising edge of calib_active, not continuously
    logic calib_active_prev;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            yaw_offset1 <= 16'd0;
            yaw_offset2 <= 16'd0;
            calib_active_prev <= 1'b0;
        end else begin
            calib_active_prev <= calib_active;
            // Capture offsets only on rising edge of calib_active when data is valid
            if (calib_active && !calib_active_prev && data_valid_1 && data_valid_2) begin
                yaw_offset1 <= yaw1;
                yaw_offset2 <= yaw2;
            end
        end
    end
    
    // Instantiate gesture detector (DUT)
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
    
    // Task to simulate button press with bounce
    task automatic press_button_with_bounce(integer bounce_cycles);
        integer i;
        calib_button = 0;
        #(CLK_PERIOD * 10);
        
        // Simulate button bounce (rapid on/off transitions)
        for (i = 0; i < bounce_cycles; i++) begin
            calib_button = 1;
            #(CLK_PERIOD * 5);
            calib_button = 0;
            #(CLK_PERIOD * 5);
        end
        
        // Final stable press
        calib_button = 1;
        #(CLK_PERIOD * 1000);  // Hold for debounce period
        calib_button = 0;
        #(CLK_PERIOD * 100);
    endtask
    
    // Task to send sensor data
    task automatic send_sensor_data(
        logic signed [15:0] y1, logic signed [15:0] y2,
        logic signed [15:0] p1, logic signed [15:0] p2
    );
        yaw1 = y1;
        yaw2 = y2;
        pitch1 = p1;
        pitch2 = p2;
        gyro1_x = 16'd0;
        gyro1_y = 16'd0;
        gyro1_z = 16'd0;
        gyro2_x = 16'd0;
        gyro2_y = 16'd0;
        gyro2_z = 16'd0;
        data_valid_1 = 1;
        data_valid_2 = 1;
        #(CLK_PERIOD * 10);
        data_valid_1 = 0;
        data_valid_2 = 0;
        #(CLK_PERIOD * 10);
    endtask
    
    // Test sequence
    initial begin
        $display("========================================");
        $display("Calibration Button Testbench");
        $display("========================================\n");
        
        // Initialize
        rst_n = 0;
        calib_button = 0;
        data_valid_1 = 0;
        data_valid_2 = 0;
        yaw1 = 16'd0;
        yaw2 = 16'd0;
        pitch1 = 16'd0;
        pitch2 = 16'd0;
        gyro1_x = 16'd0;
        gyro1_y = 16'd0;
        gyro1_z = 16'd0;
        gyro2_x = 16'd0;
        gyro2_y = 16'd0;
        gyro2_z = 16'd0;
        yaw_offset1 = 16'd0;
        yaw_offset2 = 16'd0;
        
        // Reset
        #(CLK_PERIOD * 100);
        rst_n = 1;
        #(CLK_PERIOD * 100);
        $display("Reset released\n");
        
        // Test 1: Initial state (no calibration)
        $display("=== Test 1: Initial State (No Calibration) ===");
        send_sensor_data(16'd45, 16'd315, 16'd0, 16'd0);
        #(CLK_PERIOD * 100);
        $display("Yaw1=%0d, Yaw2=%0d (raw values)", yaw1, yaw2);
        $display("Yaw offsets should be 0: offset1=%0d, offset2=%0d", 
                 yaw_offset1, yaw_offset2);
        $display("Normalized yaw should equal raw: yaw1_norm=%0d, yaw2_norm=%0d",
                 dut.yaw1_norm, dut.yaw2_norm);
        if (yaw_offset1 == 0 && yaw_offset2 == 0) begin
            $display("PASS: Initial offsets are zero\n");
        end else begin
            $display("FAIL: Initial offsets not zero\n");
        end
        
        // Test 2: Calibration button press (without bounce)
        $display("=== Test 2: Calibration Button Press (Clean) ===");
        // Send data and keep it valid while pressing button
        yaw1 = 16'd45;
        yaw2 = 16'd315;
        pitch1 = 16'd0;
        pitch2 = 16'd0;
        gyro1_x = 16'd0;
        gyro1_y = 16'd0;
        gyro1_z = 16'd0;
        gyro2_x = 16'd0;
        gyro2_y = 16'd0;
        gyro2_z = 16'd0;
        data_valid_1 = 1;
        data_valid_2 = 1;
        #(CLK_PERIOD * 100);  // Wait a bit for data to be registered
        $display("Pressing calibration button at yaw1=45, yaw2=315...");
        $display("  Keeping data_valid high during entire debounce period...");
        calib_button = 1;
        #(CLK_PERIOD * (DEBOUNCE_COUNT_TB + 100));  // Hold for debounce period + margin
        // Keep data_valid high for a bit more after button release
        #(CLK_PERIOD * 100);
        calib_button = 0;
        #(CLK_PERIOD * 1000);
        data_valid_1 = 0;
        data_valid_2 = 0;
        #(CLK_PERIOD * 1000);
        
        // Check if offsets were captured
        $display("Checking captured offsets...");
        $display("  Expected: offset1=45, offset2=315");
        $display("  Actual:   offset1=%0d, offset2=%0d", 
                 yaw_offset1, yaw_offset2);
        $display("  Calib active: %b", calib_active);
        
        if (yaw_offset1 == 16'd45 && yaw_offset2 == 16'd315) begin
            $display("PASS: Offsets captured correctly\n");
        end else begin
            $display("FAIL: Offsets not captured correctly\n");
        end
        
        // Test 3: Verify normalization after calibration
        $display("=== Test 3: Yaw Normalization After Calibration ===");
        send_sensor_data(16'd45, 16'd315, 16'd0, 16'd0);
        #(CLK_PERIOD * 100);
        $display("Raw yaw: yaw1=45, yaw2=315");
        $display("Normalized yaw: yaw1_norm=%0d, yaw2_norm=%0d",
                 dut.yaw1_norm, dut.yaw2_norm);
        if (dut.yaw1_norm == 16'd0 && dut.yaw2_norm == 16'd0) begin
            $display("PASS: Normalized yaw is zero (calibrated position)\n");
        end else begin
            $display("FAIL: Normalized yaw should be zero\n");
        end
        
        // Test 4: Test with different yaw values after calibration
        $display("=== Test 4: Different Yaw Values After Calibration ===");
        send_sensor_data(16'd90, 16'd0, 16'd0, 16'd0);
        #(CLK_PERIOD * 100);
        $display("Raw yaw: yaw1=90, yaw2=0");
        $display("Normalized yaw: yaw1_norm=%0d, yaw2_norm=%0d",
                 dut.yaw1_norm, dut.yaw2_norm);
        $display("Expected: yaw1_norm=45 (90-45), yaw2_norm=45 (0+360-315)");
        if (dut.yaw1_norm == 16'd45) begin
            $display("PASS: Right hand normalization correct\n");
        end else begin
            $display("FAIL: Right hand normalization incorrect\n");
        end
        
        // Test 5: Button debouncing (with bounce)
        $display("=== Test 5: Button Debouncing (With Bounce) ===");
        send_sensor_data(16'd90, 16'd0, 16'd0, 16'd0);
        #(CLK_PERIOD * 10);
        $display("Pressing button with simulated bounce...");
        press_button_with_bounce(5);  // 5 bounce cycles
        #(CLK_PERIOD * 1000);
        
        $display("Checking if debounce prevented false triggers...");
        $display("  Offset1 should still be 45 (from previous calibration): %0d", 
                 yaw_offset1);
        $display("  Offset2 should still be 315 (from previous calibration): %0d",
                 yaw_offset2);
        if (yaw_offset1 == 16'd45 && yaw_offset2 == 16'd315) begin
            $display("PASS: Debouncing prevented false trigger\n");
        end else begin
            $display("FAIL: Debouncing may have failed\n");
        end
        
        // Test 6: Recalibration
        $display("=== Test 6: Recalibration ===");
        // Wait for calib_active to clear first (button must be released)
        while (calib_active) #(CLK_PERIOD);
        #(CLK_PERIOD * 1000);
        // Send data and keep it valid while pressing button
        yaw1 = 16'd120;
        yaw2 = 16'd60;
        pitch1 = 16'd0;
        pitch2 = 16'd0;
        gyro1_x = 16'd0;
        gyro1_y = 16'd0;
        gyro1_z = 16'd0;
        gyro2_x = 16'd0;
        gyro2_y = 16'd0;
        gyro2_z = 16'd0;
        data_valid_1 = 1;
        data_valid_2 = 1;
        #(CLK_PERIOD * 100);  // Wait for data to be registered
        $display("Recalibrating at yaw1=120, yaw2=60...");
        $display("  Previous offsets: offset1=%0d, offset2=%0d", 
                 yaw_offset1, yaw_offset2);
        calib_button = 1;
        #(CLK_PERIOD * (DEBOUNCE_COUNT_TB + 100));  // Hold for debounce period + margin
        #(CLK_PERIOD * 100);  // Keep data_valid high a bit more
        calib_button = 0;
        #(CLK_PERIOD * 2000);  // Wait for calib_active to clear
        data_valid_1 = 0;
        data_valid_2 = 0;
        #(CLK_PERIOD * 1000);
        
        $display("Checking new offsets...");
        $display("  Expected: offset1=120, offset2=60");
        $display("  Actual:   offset1=%0d, offset2=%0d",
                 yaw_offset1, yaw_offset2);
        if (yaw_offset1 == 16'd120 && yaw_offset2 == 16'd60) begin
            $display("PASS: Recalibration successful\n");
        end else begin
            $display("FAIL: Recalibration failed (expected 120/60, got %0d/%0d)\n",
                     yaw_offset1, yaw_offset2);
        end
        
        // Test 7: Calibration requires valid data
        $display("=== Test 7: Calibration Requires Valid Data ===");
        // Wait for calib_active to clear
        #(CLK_PERIOD * 2000);
        data_valid_1 = 0;
        data_valid_2 = 0;
        yaw1 = 16'd200;
        yaw2 = 16'd250;
        #(CLK_PERIOD * 100);
        $display("Pressing button without valid data...");
        $display("  data_valid_1=%b, data_valid_2=%b", data_valid_1, data_valid_2);
        calib_button = 1;
        #(CLK_PERIOD * (DEBOUNCE_COUNT_TB + 100));  // Hold for debounce period + margin
        calib_button = 0;
        #(CLK_PERIOD * 1000);
        
        $display("Checking if offsets changed (should not)...");
        $display("  Offset1: %0d (should still be 120)", yaw_offset1);
        $display("  Offset2: %0d (should still be 60)", yaw_offset2);
        if (yaw_offset1 == 16'd120 && yaw_offset2 == 16'd60) begin
            $display("PASS: Calibration correctly requires valid data\n");
        end else begin
            $display("FAIL: Calibration triggered without valid data\n");
        end
        
        // Test 8: Zone detection with calibration
        $display("=== Test 8: Zone Detection With Calibration ===");
        send_sensor_data(16'd165, 16'd105, 16'd0, 16'd0);  // 165-120=45, 105-60=45
        #(CLK_PERIOD * 100);
        $display("Raw yaw: yaw1=165, yaw2=105");
        $display("Normalized: yaw1_norm=%0d, yaw2_norm=%0d",
                 dut.yaw1_norm, dut.yaw2_norm);
        $display("Expected normalized: yaw1_norm=45, yaw2_norm=45");
        if (dut.yaw1_norm == 16'd45 && dut.yaw2_norm == 16'd45) begin
            $display("PASS: Zone detection uses normalized values\n");
        end else begin
            $display("FAIL: Zone detection normalization incorrect\n");
        end
        
        // Summary
        $display("\n========================================");
        $display("Calibration Test Summary");
        $display("========================================");
        $display("All calibration tests completed.");
        $display("Check results above for PASS/FAIL status.");
        $display("========================================\n");
        
        #(CLK_PERIOD * 1000);
        $finish;
    end
    
    // Monitor for debugging (less verbose)
    initial begin
        $monitor("[%0t] calib_button=%b calib_active=%b debounced=%b offset1=%0d offset2=%0d",
                 $time, calib_button, calib_active, dut.calib_button_debounced, 
                 yaw_offset1, yaw_offset2);
    end

endmodule

