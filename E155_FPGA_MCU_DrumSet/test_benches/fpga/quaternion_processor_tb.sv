// Quaternion Processor Test Bench
// Comprehensive test for quaternion to Euler conversion
// Author: E155 Final Project
// Date: 2024

`timescale 1ns/1ps

module quaternion_processor_tb();

    // Test bench signals
    reg clk;
    reg rst;
    reg [31:0] quat_w, quat_x, quat_y, quat_z;
    wire [15:0] roll, pitch, yaw;

    // Instantiate DUT
    quaternion_processor dut (
        .clk(clk),
        .rst(rst),
        .quat_w(quat_w),
        .quat_x(quat_x),
        .quat_y(quat_y),
        .quat_z(quat_z),
        .roll(roll),
        .pitch(pitch),
        .yaw(yaw)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz clock
    end

    // Test stimulus
    initial begin
        $display("=== Quaternion Processor Test Bench Started ===");
        
        // Initialize signals
        rst = 1;
        quat_w = 32'h00000000;
        quat_x = 32'h00000000;
        quat_y = 32'h00000000;
        quat_z = 32'h00000000;
        
        // Reset sequence
        #100 rst = 0;
        #50 rst = 1;
        
        // Test 1: Identity quaternion (no rotation)
        $display("Test 1: Identity quaternion");
        test_identity_quaternion();
        
        // Test 2: 90-degree rotation around Z-axis
        $display("Test 2: 90-degree Z rotation");
        test_z_rotation();
        
        // Test 3: 90-degree rotation around X-axis
        $display("Test 3: 90-degree X rotation");
        test_x_rotation();
        
        // Test 4: 90-degree rotation around Y-axis
        $display("Test 4: 90-degree Y rotation");
        test_y_rotation();
        
        // Test 5: Complex rotation
        $display("Test 5: Complex rotation");
        test_complex_rotation();
        
        // Test 6: Edge cases
        $display("Test 6: Edge cases");
        test_edge_cases();
        
        $display("=== Quaternion Processor Test Bench Completed ===");
        $finish;
    end

    // Test 1: Identity quaternion
    task test_identity_quaternion();
        begin
            quat_w = 32'h00010000; // 1.0 in Q1.15 format
            quat_x = 32'h00000000; // 0.0
            quat_y = 32'h00000000; // 0.0
            quat_z = 32'h00000000; // 0.0
            
            #100; // Wait for processing
            
            if (roll == 16'h0000 && pitch == 16'h0000 && yaw == 16'h0000) begin
                $display("✓ Identity quaternion test passed");
            end else begin
                $display("✗ Identity quaternion test failed: roll=%d, pitch=%d, yaw=%d", roll, pitch, yaw);
            end
        end
    endtask

    // Test 2: 90-degree Z rotation
    task test_z_rotation();
        begin
            quat_w = 32'h0000B505; // cos(45°) ≈ 0.707 in Q1.15
            quat_x = 32'h00000000; // 0.0
            quat_y = 32'h00000000; // 0.0
            quat_z = 32'h0000B505; // sin(45°) ≈ 0.707 in Q1.15
            
            #100; // Wait for processing
            
            // Should result in 90-degree yaw rotation
            if (yaw == 16'h5A00) begin // 90° in Q8.8 format
                $display("✓ Z rotation test passed");
            end else begin
                $display("✗ Z rotation test failed: yaw=%d (expected 90°)", yaw);
            end
        end
    endtask

    // Test 3: 90-degree X rotation
    task test_x_rotation();
        begin
            quat_w = 32'h0000B505; // cos(45°)
            quat_x = 32'h0000B505; // sin(45°)
            quat_y = 32'h00000000; // 0.0
            quat_z = 32'h00000000; // 0.0
            
            #100; // Wait for processing
            
            // Should result in 90-degree pitch rotation
            if (pitch == 16'h5A00) begin // 90° in Q8.8 format
                $display("✓ X rotation test passed");
            end else begin
                $display("✗ X rotation test failed: pitch=%d (expected 90°)", pitch);
            end
        end
    endtask

    // Test 4: 90-degree Y rotation
    task test_y_rotation();
        begin
            quat_w = 32'h0000B505; // cos(45°)
            quat_x = 32'h00000000; // 0.0
            quat_y = 32'h0000B505; // sin(45°)
            quat_z = 32'h00000000; // 0.0
            
            #100; // Wait for processing
            
            // Should result in 90-degree roll rotation
            if (roll == 16'h5A00) begin // 90° in Q8.8 format
                $display("✓ Y rotation test passed");
            end else begin
                $display("✗ Y rotation test failed: roll=%d (expected 90°)", roll);
            end
        end
    endtask

    // Test 5: Complex rotation
    task test_complex_rotation();
        begin
            quat_w = 32'h00008000; // 0.5
            quat_x = 32'h00004000; // 0.25
            quat_y = 32'h00004000; // 0.25
            quat_z = 32'h00004000; // 0.25
            
            #100; // Wait for processing
            
            $display("Complex rotation result: roll=%d, pitch=%d, yaw=%d", roll, pitch, yaw);
            $display("✓ Complex rotation test completed");
        end
    endtask

    // Test 6: Edge cases
    task test_edge_cases();
        begin
            // Test maximum values
            quat_w = 32'h0000FFFF; // Maximum positive
            quat_x = 32'h0000FFFF;
            quat_y = 32'h0000FFFF;
            quat_z = 32'h0000FFFF;
            
            #100;
            $display("Max values: roll=%d, pitch=%d, yaw=%d", roll, pitch, yaw);
            
            // Test minimum values
            quat_w = 32'h00000001; // Minimum positive
            quat_x = 32'h00000001;
            quat_y = 32'h00000001;
            quat_z = 32'h00000001;
            
            #100;
            $display("Min values: roll=%d, pitch=%d, yaw=%d", roll, pitch, yaw);
            
            $display("✓ Edge cases test completed");
        end
    endtask

    // Monitor outputs
    always @(posedge clk) begin
        if (roll !== 16'hxxxx || pitch !== 16'hxxxx || yaw !== 16'hxxxx) begin
            $display("Time %t: roll=%d, pitch=%d, yaw=%d", $time, roll, pitch, yaw);
        end
    end

    // Timeout protection
    initial begin
        #1000000; // 1ms timeout
        $display("✗ Test bench timeout!");
        $finish;
    end

endmodule
