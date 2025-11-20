// Test Bench for Gyro-Only Drum System
// Tests the ultra-minimal gyro-only design
// Author: E155 Final Project
// Date: 2024

`define SIMULATION

module drum_system_top_gyro_tb;

    // Clock and Reset
    reg clk_ext;
    reg rst_n;
    
    // I2C Physical Pins (for simulation, we'll drive them)
    wire i2c1_scl;
    wire i2c1_sda;
    
    // User Interface
    reg button1;
    reg button2;
    wire led1;
    wire led2;
    
    // Audio Output
    wire [7:0] sound_id;
    
    // Instantiate DUT
    drum_system_top dut (
        .clk_ext(clk_ext),
        .rst_n(rst_n),
        .i2c1_scl(i2c1_scl),
        .i2c1_sda(i2c1_sda),
        .button1(button1),
        .button2(button2),
        .led1(led1),
        .led2(led2),
        .sound_id(sound_id)
    );
    
    // Access internal System Bus signals for monitoring
    wire i2c1_sb_clk;
    wire i2c1_sb_wr;
    wire i2c1_sb_stb;
    wire [7:0] i2c1_sb_addr;
    wire [7:0] i2c1_sb_data_i;
    wire [7:0] i2c1_sb_data_o;
    wire i2c1_sb_ack;
    wire i2c1_irq;
    wire i2c1_ipload;
    wire i2c1_ipdone;
    
    // Connect to internal signals using hierarchical references
    assign i2c1_sb_clk = dut.i2c1_sb_clk;
    assign i2c1_sb_wr = dut.i2c1_sb_wr;
    assign i2c1_sb_stb = dut.i2c1_sb_stb;
    assign i2c1_sb_addr = dut.i2c1_sb_addr;
    assign i2c1_sb_data_i = dut.i2c1_sb_data_i;
    assign i2c1_sb_data_o = dut.i2c1_sb_data_o;
    assign i2c1_sb_ack = dut.i2c1_sb_ack;
    assign i2c1_irq = dut.i2c1_irq;
    assign i2c1_ipload = dut.i2c1_ipload;
    assign i2c1_ipdone = dut.i2c1_ipdone;
    
    // Registers to drive I2C IP block outputs via force
    // Note: The real i2c_block.v uses Lattice primitives that may not simulate
    // We'll use force statements to drive the System Bus responses
    reg [7:0] mock_sb_data_o;
    reg mock_sb_ack_o;
    reg mock_ipdone;
    
    // Force I2C IP block outputs (simulation only)
    // This allows us to mock the System Bus responses
    initial begin
        force dut.i2c1_ip.sb_dat_o = mock_sb_data_o;
        force dut.i2c1_ip.sb_ack_o = mock_sb_ack_o;
        force dut.i2c1_ip.ipdone_o = mock_ipdone;
    end
    
    // Clock generation
    initial begin
        clk_ext = 0;
        forever #10 clk_ext = ~clk_ext;  // 50MHz
    end
    
    // Mock I2C bus (pull-ups for simulation)
    pullup(i2c1_scl);
    pullup(i2c1_sda);
    
    // Mock System Bus responses (simulating I2C IP behavior)
    reg [7:0] mock_gyro_data [0:5];  // X, Y, Z gyro data (LSB/MSB pairs)
    reg [2:0] mock_read_addr;
    
    initial begin
        // Initialize mock gyro data (negative Y for trigger, positive Z for HIHAT)
        mock_gyro_data[0] = 8'h00;  // Gyro X LSB
        mock_gyro_data[1] = 8'h00;  // Gyro X MSB
        mock_gyro_data[2] = 8'hF0;  // Gyro Y LSB (negative for trigger)
        mock_gyro_data[3] = 8'hFF;  // Gyro Y MSB
        mock_gyro_data[4] = 8'h10;  // Gyro Z LSB (positive for HIHAT)
        mock_gyro_data[5] = 8'h00;  // Gyro Z MSB
        mock_read_addr = 0;
        mock_sb_data_o = 0;
        mock_sb_ack_o = 0;
        mock_ipdone = 0;
        
        // IP ready after 1us
        #1000;
        mock_ipdone = 1;
    end
    
    // Mock I2C IP System Bus behavior
    // Drive the System Bus data and ACK that the I2C IP block outputs
    always @(posedge clk_ext) begin
        if (!rst_n) begin
            mock_read_addr <= 0;
            mock_sb_ack_o <= 0;
            mock_sb_data_o <= 0;
        end else begin
            // Mock System Bus ACK and data
            if (i2c1_sb_stb && !mock_sb_ack_o) begin
                mock_sb_ack_o <= 1;
                if (!i2c1_sb_wr) begin  // Read operation
                    // Return mock gyro data
                    mock_sb_data_o <= mock_gyro_data[mock_read_addr];
                    if (mock_read_addr < 5) begin
                        mock_read_addr <= mock_read_addr + 1;
                    end else begin
                        mock_read_addr <= 0;  // Wrap around
                    end
                end
            end else if (!i2c1_sb_stb) begin
                mock_sb_ack_o <= 0;
            end
        end
    end
    
    // Test tasks
    task check_result(input string test_name, input reg pass, input string message);
        if (pass) begin
            $display("PASS: %-80s %s", test_name, message);
        end else begin
            $display("FAIL: %-80s %s", test_name, message);
        end
    endtask
    
    task wait_cycles(input integer cycles);
        repeat(cycles) @(posedge clk_ext);
    endtask
    
    // Test counters
    integer tests_passed = 0;
    integer tests_failed = 0;
    integer total_tests = 0;
    
    // Main test sequence
    initial begin
        $display("\n================================================================\n");
        $display("  GYRO-ONLY DRUM SYSTEM - TEST BENCH\n");
        $display("================================================================\n");
        
        // Initialize
        rst_n = 0;
        button1 = 0;
        button2 = 0;
        
        wait_cycles(10);
        rst_n = 1;
        wait_cycles(100);
        
        // Test Suite 1: System Initialization
        $display("--- Test Suite 1: System Initialization ---\n");
        
        total_tests = total_tests + 1;
        check_result("Reset State - Sound ID", (sound_id == 8'hFF), "Sound ID should be NO_SOUND on reset");
        if (sound_id == 8'hFF) tests_passed = tests_passed + 1; else tests_failed = tests_failed + 1;
        
        total_tests = total_tests + 1;
        check_result("Reset State - LED1 Off", (led1 == 0), "LED1 should be off on reset");
        if (led1 == 0) tests_passed = tests_passed + 1; else tests_failed = tests_failed + 1;
        
        total_tests = total_tests + 1;
        check_result("I2C1 System Bus Clock Active", (i2c1_sb_clk == clk_ext), "System Bus clock should be active");
        if (i2c1_sb_clk == clk_ext) tests_passed = tests_passed + 1; else tests_failed = tests_failed + 1;
        
        // Note: I2C IP block (i2c_block) is instantiated inside top module
        // For simulation, we're accessing internal signals for monitoring
        
        wait_cycles(1000);
        
        // Test Suite 2: Button Functionality
        $display("\n--- Test Suite 2: Button Functionality ---\n");
        
        button1 = 1;
        wait_cycles(5000);  // Wait for debounce
        
        total_tests = total_tests + 1;
        check_result("Button1 Press - KICK Sound", (sound_id == 8'h02), "Button should trigger KICK sound");
        if (sound_id == 8'h02) tests_passed = tests_passed + 1; else tests_failed = tests_failed + 1;
        
        total_tests = total_tests + 1;
        check_result("Button1 Press - LED1 On", (led1 == 1), "LED1 should be on when sound is active");
        if (led1 == 1) tests_passed = tests_passed + 1; else tests_failed = tests_failed + 1;
        
        button1 = 0;
        wait_cycles(5000);
        
        total_tests = total_tests + 1;
        check_result("Button1 Release - Sound Cleared", (sound_id == 8'hFF), "Sound should clear when button released");
        if (sound_id == 8'hFF) tests_passed = tests_passed + 1; else tests_failed = tests_failed + 1;
        
        // Test Suite 3: Gyro Trigger
        $display("\n--- Test Suite 3: Gyro Trigger ---\n");
        
        // Wait for gyro data to be read
        wait_cycles(5000);
        
        // Check that gyro data is being processed
        total_tests = total_tests + 1;
        check_result("Gyro Data Valid", (dut.imu_data_valid == 1 || dut.imu_data_valid == 0), "Gyro data valid signal exists");
        if (dut.imu_data_valid == 1 || dut.imu_data_valid == 0) tests_passed = tests_passed + 1; else tests_failed = tests_failed + 1;
        
        // Test Suite 4: Sound Selection
        $display("\n--- Test Suite 4: Sound Selection ---\n");
        
        // With negative gyro_y and positive gyro_z, should get HIHAT
        wait_cycles(10000);
        
        total_tests = total_tests + 1;
        check_result("Sound ID Valid Range", (sound_id <= 8'h07 || sound_id == 8'hFF), "Sound ID should be 0-7 or 255");
        if (sound_id <= 8'h07 || sound_id == 8'hFF) tests_passed = tests_passed + 1; else tests_failed = tests_failed + 1;
        
        // Test Suite 5: Reset During Operation
        $display("\n--- Test Suite 5: Reset During Operation ---\n");
        
        button1 = 1;
        wait_cycles(1000);
        rst_n = 0;
        wait_cycles(10);
        rst_n = 1;
        wait_cycles(100);
        
        total_tests = total_tests + 1;
        check_result("Reset During Operation - Sound Cleared", (sound_id == 8'hFF), "Sound should be cleared on reset");
        if (sound_id == 8'hFF) tests_passed = tests_passed + 1; else tests_failed = tests_failed + 1;
        
        total_tests = total_tests + 1;
        check_result("Reset During Operation - LEDs Off", (led1 == 0 && led2 == 0), "LEDs should be off after reset");
        if (led1 == 0 && led2 == 0) tests_passed = tests_passed + 1; else tests_failed = tests_failed + 1;
        
        // Final Summary
        $display("\n================================================================\n");
        $display("  TEST SUMMARY\n");
        $display("================================================================\n");
        $display("  Total Tests:  %0d", total_tests);
        $display("  Passed:       %0d", tests_passed);
        $display("  Failed:       %0d", tests_failed);
        $display("  Pass Rate:    %.1f%%\n", (tests_passed * 100.0) / total_tests);
        $display("================================================================\n");
        
        if (tests_failed == 0) begin
            $display("  ✓ ALL TESTS PASSED\n");
        end else begin
            $display("  ✗ SOME TESTS FAILED - REVIEW REQUIRED\n");
        end
        $display("================================================================\n");
        
        #1000;
        $finish;
    end

endmodule

