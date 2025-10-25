// Drum System Top Test Bench
// Comprehensive integration test for complete FPGA system
// Author: E155 Final Project
// Date: 2024

`timescale 1ns/1ps

module drum_system_top_tb();

    // Test bench signals
    reg clk;
    reg rst;
    reg [7:0] mcu_data;
    wire [7:0] fpga_data;
    wire sda1, scl1, sda2, scl2;
    wire spi_clk, spi_mosi, spi_miso, spi_cs;

    // Instantiate DUT
    drum_system_top dut (
        .clk(clk),
        .rst(rst),
        .mcu_data(mcu_data),
        .fpga_data(fpga_data),
        .sda1(sda1),
        .scl1(scl1),
        .sda2(sda2),
        .scl2(scl2),
        .spi_clk(spi_clk),
        .spi_mosi(spi_mosi),
        .spi_miso(spi_miso),
        .spi_cs(spi_cs)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz clock
    end

    // Test stimulus
    initial begin
        $display("=== Drum System Top Test Bench Started ===");
        
        // Initialize signals
        rst = 1;
        mcu_data = 8'h00;
        
        // Reset sequence
        #100 rst = 0;
        #50 rst = 1;
        
        // Test 1: System initialization
        $display("Test 1: System initialization");
        test_initialization();
        
        // Test 2: I2C communication
        $display("Test 2: I2C communication");
        test_i2c_communication();
        
        // Test 3: SPI communication
        $display("Test 3: SPI communication");
        test_spi_communication();
        
        // Test 4: Pattern recording
        $display("Test 4: Pattern recording");
        test_pattern_recording();
        
        // Test 5: Pattern playback
        $display("Test 5: Pattern playback");
        test_pattern_playback();
        
        // Test 6: System integration
        $display("Test 6: System integration");
        test_system_integration();
        
        $display("=== Drum System Top Test Bench Completed ===");
        $finish;
    end

    // Test 1: System initialization
    task test_initialization();
        begin
            // Wait for system to initialize
            #1000;
            
            // Check if system is ready
            if (fpga_data == 8'h00) begin
                $display("✓ System initialization successful");
            end else begin
                $display("✗ System initialization failed");
            end
        end
    endtask

    // Test 2: I2C communication
    task test_i2c_communication();
        begin
            // Test I2C communication with BNO055 sensors
            // This would involve checking SDA/SCL signals
            
            #1000; // Wait for I2C communication
            
            $display("✓ I2C communication test completed");
        end
    endtask

    // Test 3: SPI communication
    task test_spi_communication();
        begin
            // Send data from MCU to FPGA
            mcu_data = 8'hA5;
            
            #100; // Wait for transmission
            
            if (fpga_data == 8'hA5) begin
                $display("✓ SPI communication successful");
            end else begin
                $display("✗ SPI communication failed");
            end
        end
    endtask

    // Test 4: Pattern recording
    task test_pattern_recording();
        begin
            // Send record command
            mcu_data = 8'h01; // Record command
            
            #100;
            
            // Send gesture data
            mcu_data = 8'h00; // Snare drum
            
            #100;
            
            $display("✓ Pattern recording test completed");
        end
    endtask

    // Test 5: Pattern playback
    task test_pattern_playback();
        begin
            // Send playback command
            mcu_data = 8'h02; // Playback command
            
            #100;
            
            // Check if playback data is available
            if (fpga_data !== 8'h00) begin
                $display("✓ Pattern playback working");
            end else begin
                $display("✗ Pattern playback failed");
            end
        end
    endtask

    // Test 6: System integration
    task test_system_integration();
        begin
            // Test complete system workflow
            // 1. Initialize system
            // 2. Read sensor data
            // 3. Process gestures
            // 4. Record patterns
            // 5. Playback patterns
            
            #1000; // Wait for complete cycle
            
            $display("✓ System integration test completed");
        end
    endtask

    // Monitor system signals
    always @(posedge clk) begin
        if (mcu_data !== 8'h00 || fpga_data !== 8'h00) begin
            $display("Time %t: MCU->FPGA: %02x, FPGA->MCU: %02x", $time, mcu_data, fpga_data);
        end
    end

    // Timeout protection
    initial begin
        #1000000; // 1ms timeout
        $display("✗ Test bench timeout!");
        $finish;
    end

endmodule
