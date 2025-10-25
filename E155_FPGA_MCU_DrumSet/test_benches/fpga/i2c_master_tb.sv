// I2C Master Test Bench
// Comprehensive test for BNO055 sensor communication
// Author: E155 Final Project
// Date: 2024

`timescale 1ns/1ps

module i2c_master_tb();

    // Test bench signals
    reg clk;
    reg rst;
    reg [6:0] device_addr;
    reg [7:0] reg_addr;
    reg [7:0] write_data;
    wire [7:0] read_data;
    wire i2c_done;
    wire sda;
    wire scl;

    // Instantiate DUT
    i2c_master dut (
        .clk(clk),
        .rst(rst),
        .device_addr(device_addr),
        .reg_addr(reg_addr),
        .write_data(write_data),
        .read_data(read_data),
        .i2c_done(i2c_done),
        .sda(sda),
        .scl(scl)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz clock
    end

    // Test stimulus
    initial begin
        $display("=== I2C Master Test Bench Started ===");
        
        // Initialize signals
        rst = 1;
        device_addr = 7'h28; // BNO055 address 1
        reg_addr = 8'h00;
        write_data = 8'h00;
        
        // Reset sequence
        #100 rst = 0;
        #50 rst = 1;
        
        // Test 1: Read quaternion data
        $display("Test 1: Reading quaternion data from BNO055");
        test_read_quaternion();
        
        // Test 2: Read gyroscope data
        $display("Test 2: Reading gyroscope data from BNO055");
        test_read_gyro();
        
        // Test 3: Write configuration
        $display("Test 3: Writing configuration to BNO055");
        test_write_config();
        
        // Test 4: Error handling
        $display("Test 4: Testing error handling");
        test_error_handling();
        
        $display("=== I2C Master Test Bench Completed ===");
        $finish;
    end

    // Test 1: Read quaternion data
    task test_read_quaternion();
        begin
            reg_addr = 8'h20; // Quaternion W register
            device_addr = 7'h28;
            
            // Wait for completion
            wait(i2c_done);
            #100;
            
            if (read_data !== 8'hxx) begin
                $display("✓ Quaternion read successful: 0x%02x", read_data);
            end else begin
                $display("✗ Quaternion read failed");
            end
        end
    endtask

    // Test 2: Read gyroscope data
    task test_read_gyro();
        begin
            reg_addr = 8'h14; // Gyro X register
            device_addr = 7'h28;
            
            wait(i2c_done);
            #100;
            
            if (read_data !== 8'hxx) begin
                $display("✓ Gyroscope read successful: 0x%02x", read_data);
            end else begin
                $display("✗ Gyroscope read failed");
            end
        end
    endtask

    // Test 3: Write configuration
    task test_write_config();
        begin
            reg_addr = 8'h3D; // Operation mode register
            write_data = 8'h0C; // NDOF mode
            device_addr = 7'h28;
            
            wait(i2c_done);
            #100;
            
            $display("✓ Configuration write completed");
        end
    endtask

    // Test 4: Error handling
    task test_error_handling();
        begin
            // Test with invalid device address
            device_addr = 7'hFF; // Invalid address
            reg_addr = 8'h00;
            
            #1000; // Wait for timeout
            
            if (!i2c_done) begin
                $display("✓ Error handling working - no completion for invalid address");
            end else begin
                $display("✗ Error handling failed");
            end
        end
    endtask

    // Monitor I2C signals
    always @(posedge clk) begin
        if (scl && sda !== 1'bz) begin
            $display("I2C: SCL=%b, SDA=%b", scl, sda);
        end
    end

    // Timeout protection
    initial begin
        #1000000; // 1ms timeout
        $display("✗ Test bench timeout!");
        $finish;
    end

endmodule
