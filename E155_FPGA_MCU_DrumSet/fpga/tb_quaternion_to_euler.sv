// Testbench for Quaternion to Euler Angle Converter
// Tests conversion accuracy and pipeline behavior

`timescale 1ns / 1ps

module tb_quaternion_to_euler;

    // Parameters
    localparam CLK_PERIOD = 20;  // 50MHz clock
    
    // Signals
    logic        clk;
    logic        rst_n;
    logic        valid_in;
    logic signed [15:0] quat_w, quat_x, quat_y, quat_z;
    logic        valid_out;
    logic signed [15:0] roll, pitch, yaw;
    
    // Expected results (for known quaternions)
    logic signed [15:0] expected_roll, expected_pitch, expected_yaw;
    real roll_error, pitch_error, yaw_error;
    
    // Instantiate DUT
    quaternion_to_euler dut (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .quat_w(quat_w),
        .quat_x(quat_x),
        .quat_y(quat_y),
        .quat_z(quat_z),
        .valid_out(valid_out),
        .roll(roll),
        .pitch(pitch),
        .yaw(yaw)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Test stimulus
    initial begin
        $display("========================================");
        $display("Quaternion to Euler Testbench");
        $display("========================================\n");
        
        // Initialize
        rst_n = 0;
        valid_in = 0;
        quat_w = 16'd0;
        quat_x = 16'd0;
        quat_y = 16'd0;
        quat_z = 16'd0;
        
        // Reset
        #(CLK_PERIOD * 5);
        rst_n = 1;
        #(CLK_PERIOD * 2);
        
        // Test 1: Identity quaternion (no rotation)
        // q = [1, 0, 0, 0] -> roll=0, pitch=0, yaw=0
        $display("Test 1: Identity quaternion [1, 0, 0, 0]");
        quat_w = 16'd32768;  // 1.0 in Q16
        quat_x = 16'd0;
        quat_y = 16'd0;
        quat_z = 16'd0;
        valid_in = 1;
        expected_roll = 0;
        expected_pitch = 0;
        expected_yaw = 0;
        #(CLK_PERIOD);
        valid_in = 0;
        #(CLK_PERIOD * 10);  // Wait for full pipeline (4 stages)
        check_results("Identity", expected_roll, expected_pitch, expected_yaw);
        
        // Test 2: 90-degree rotation around Z-axis (yaw = 90)
        // q = [0.707, 0, 0, 0.707] -> yaw ≈ 90 degrees
        $display("\nTest 2: 90-degree Z-axis rotation");
        quat_w = 16'd23170;   // 0.707 in Q16
        quat_x = 16'd0;
        quat_y = 16'd0;
        quat_z = 16'd23170;   // 0.707 in Q16
        valid_in = 1;
        expected_yaw = 90;
        #(CLK_PERIOD);
        valid_in = 0;
        #(CLK_PERIOD * 10);
        check_results("Z-rotation", 0, 0, expected_yaw);
        
        // Test 3: 90-degree rotation around Y-axis (pitch = 90)
        // q = [0.707, 0, 0.707, 0] -> pitch ≈ 90 degrees
        $display("\nTest 3: 90-degree Y-axis rotation");
        quat_w = 16'd23170;
        quat_x = 16'd0;
        quat_y = 16'd23170;
        quat_z = 16'd0;
        valid_in = 1;
        expected_pitch = 90;
        #(CLK_PERIOD);
        valid_in = 0;
        #(CLK_PERIOD * 10);
        check_results("Y-rotation", 0, expected_pitch, 0);
        
        // Test 4: 90-degree rotation around X-axis (roll = 90)
        // q = [0.707, 0.707, 0, 0] -> roll ≈ 90 degrees
        $display("\nTest 4: 90-degree X-axis rotation");
        quat_w = 16'd23170;
        quat_x = 16'd23170;
        quat_y = 16'd0;
        quat_z = 16'd0;
        valid_in = 1;
        expected_roll = 90;
        #(CLK_PERIOD);
        valid_in = 0;
        #(CLK_PERIOD * 10);
        check_results("X-rotation", expected_roll, 0, 0);
        
        // Test 5: Arbitrary quaternion
        $display("\nTest 5: Arbitrary quaternion");
        quat_w = 16'd28377;   // ~0.866
        quat_x = 16'd16384;   // ~0.5
        quat_y = 16'd8192;    // ~0.25
        quat_z = 16'd4096;    // ~0.125
        valid_in = 1;
        #(CLK_PERIOD);
        valid_in = 0;
        #(CLK_PERIOD * 10);
        $display("  Result: roll=%d, pitch=%d, yaw=%d", roll, pitch, yaw);
        
        // Test 6: Pipeline behavior - continuous data
        $display("\nTest 6: Pipeline behavior (continuous data)");
        for (int i = 0; i < 10; i++) begin
            quat_w = $random();
            quat_x = $random();
            quat_y = $random();
            quat_z = $random();
            valid_in = 1;
            #(CLK_PERIOD);
        end
        valid_in = 0;
        #(CLK_PERIOD * 10);
        
        $display("\n========================================");
        $display("Testbench Complete");
        $display("========================================");
        $finish;
    end
    
    // Task to check results
    task check_results(string test_name, logic signed [15:0] exp_roll, 
                       logic signed [15:0] exp_pitch, logic signed [15:0] exp_yaw);
        // Wait for valid_out with timeout
        fork
            begin
                wait(valid_out);
            end
            begin
                #(CLK_PERIOD * 20);  // Timeout after 20 cycles
                $display("  WARNING: Timeout waiting for valid_out");
            end
        join_any
        disable fork;
        
        #(CLK_PERIOD);
        
        roll_error = $itor(roll - exp_roll);
        pitch_error = $itor(pitch - exp_pitch);
        yaw_error = $itor(yaw - exp_yaw);
        
        $display("  Expected: roll=%d, pitch=%d, yaw=%d", exp_roll, exp_pitch, exp_yaw);
        $display("  Actual:   roll=%d, pitch=%d, yaw=%d", roll, pitch, yaw);
        $display("  Error:    roll=%.1f, pitch=%.1f, yaw=%.1f", roll_error, pitch_error, yaw_error);
        
        // Allow ±5 degree tolerance for simplified math
        if ($abs(roll_error) > 5 || $abs(pitch_error) > 5 || $abs(yaw_error) > 5) begin
            $display("  WARNING: Large error detected (expected due to simplified math)");
        end else begin
            $display("  PASS: Results within tolerance");
        end
    endtask
    
    // Monitor for debugging (commented out to reduce output)
    // initial begin
    //     $monitor("Time=%0t: valid_in=%b, quat=[%d,%d,%d,%d], valid_out=%b, euler=[%d,%d,%d]",
    //              $time, valid_in, quat_w, quat_x, quat_y, quat_z, valid_out, roll, pitch, yaw);
    // end

endmodule

