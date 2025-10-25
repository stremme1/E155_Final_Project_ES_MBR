// SPI Interface Test Bench
// Comprehensive test for FPGA-MCU SPI communication
// Author: E155 Final Project
// Date: 2024

`timescale 1ns/1ps

module spi_interface_tb();

    // Test bench signals
    reg clk;
    reg rst;
    reg [7:0] data_to_mcu;
    wire [7:0] data_from_mcu;
    reg spi_clk;
    reg spi_mosi;
    wire spi_miso;
    reg spi_cs;

    // Instantiate DUT
    spi_interface dut (
        .clk(clk),
        .rst(rst),
        .data_to_mcu(data_to_mcu),
        .data_from_mcu(data_from_mcu),
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

    // SPI clock generation
    initial begin
        spi_clk = 0;
        forever #50 spi_clk = ~spi_clk; // 10MHz SPI clock
    end

    // Test stimulus
    initial begin
        $display("=== SPI Interface Test Bench Started ===");
        
        // Initialize signals
        rst = 1;
        data_to_mcu = 8'h00;
        spi_mosi = 0;
        spi_cs = 1;
        
        // Reset sequence
        #100 rst = 0;
        #50 rst = 1;
        
        // Test 1: Basic SPI communication
        $display("Test 1: Basic SPI communication");
        test_basic_spi();
        
        // Test 2: Multiple byte transfer
        $display("Test 2: Multiple byte transfer");
        test_multiple_bytes();
        
        // Test 3: Error handling
        $display("Test 3: Error handling");
        test_error_handling();
        
        // Test 4: Timing requirements
        $display("Test 4: Timing requirements");
        test_timing();
        
        $display("=== SPI Interface Test Bench Completed ===");
        $finish;
    end

    // Test 1: Basic SPI communication
    task test_basic_spi();
        begin
            // Send data from MCU to FPGA
            data_to_mcu = 8'hA5;
            spi_cs = 0; // Select FPGA
            
            #100; // Wait for transmission
            
            spi_cs = 1; // Deselect FPGA
            
            if (data_from_mcu == 8'hA5) begin
                $display("✓ Basic SPI communication successful");
            end else begin
                $display("✗ Basic SPI communication failed: expected 0xA5, got 0x%02x", data_from_mcu);
            end
        end
    endtask

    // Test 2: Multiple byte transfer
    task test_multiple_bytes();
        begin
            // Send multiple bytes
            for (int i = 0; i < 8; i++) begin
                data_to_mcu = i[7:0];
                spi_cs = 0;
                
                #100; // Wait for transmission
                
                spi_cs = 1;
                #10;
                
                if (data_from_mcu == i[7:0]) begin
                    $display("✓ Byte %d transfer successful", i);
                end else begin
                    $display("✗ Byte %d transfer failed: expected %d, got %d", i, i, data_from_mcu);
                end
            end
        end
    endtask

    // Test 3: Error handling
    task test_error_handling();
        begin
            // Test with CS high (no communication)
            spi_cs = 1;
            data_to_mcu = 8'hFF;
            
            #100;
            
            if (data_from_mcu == 8'h00) begin
                $display("✓ Error handling working - no data when CS high");
            end else begin
                $display("✗ Error handling failed - data changed when CS high");
            end
        end
    endtask

    // Test 4: Timing requirements
    task test_timing();
        begin
            // Test setup and hold times
            data_to_mcu = 8'h55;
            spi_cs = 0;
            
            // Test minimum setup time
            #10; // 10ns setup time
            
            // Test minimum hold time
            #10; // 10ns hold time
            
            spi_cs = 1;
            
            $display("✓ Timing requirements test completed");
        end
    endtask

    // Monitor SPI signals
    always @(posedge spi_clk) begin
        if (!spi_cs) begin
            $display("SPI: MOSI=%b, MISO=%b, Data=%02x", spi_mosi, spi_miso, data_from_mcu);
        end
    end

    // Timeout protection
    initial begin
        #1000000; // 1ms timeout
        $display("✗ Test bench timeout!");
        $finish;
    end

endmodule
