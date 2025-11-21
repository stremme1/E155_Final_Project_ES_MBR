// Testbench for SPI Master Module
// Tests SPI communication with BNO085-like device

`timescale 1ns / 1ps

module tb_spi_master;

    // Parameters
    localparam CLK_PERIOD = 20;  // 50MHz clock
    localparam CLK_DIV = 16;     // SPI clock divider
    
    // Signals
    logic        clk;
    logic        rst_n;
    logic        start;
    logic        tx_valid;
    logic [7:0]  tx_data;
    logic        tx_ready;
    logic        rx_valid;
    logic [7:0]  rx_data;
    logic        busy;
    logic        sclk;
    logic        mosi;
    logic        miso;
    logic        cs_n;
    
    // Test data
    logic [7:0] tx_byte;
    logic [7:0] rx_byte;
    int test_count = 0;
    int pass_count = 0;
    
    // Instantiate DUT
    spi_master #(.CLK_DIV(CLK_DIV)) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .tx_valid(tx_valid),
        .tx_data(tx_data),
        .tx_ready(tx_ready),
        .rx_valid(rx_valid),
        .rx_data(rx_data),
        .busy(busy),
        .sclk(sclk),
        .mosi(mosi),
        .miso(miso),
        .cs_n(cs_n)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // MISO driver (simulates BNO085 response)
    always_ff @(negedge sclk or negedge rst_n) begin
        if (!rst_n) begin
            miso <= 1'b0;
        end else if (!cs_n) begin
            // Echo back inverted data for testing
            miso <= ~mosi;
        end
    end
    
    // Test stimulus
    initial begin
        $display("========================================");
        $display("SPI Master Testbench");
        $display("========================================\n");
        
        // Initialize
        rst_n = 0;
        start = 0;
        tx_valid = 0;
        tx_data = 8'h00;
        
        // Reset
        #(CLK_PERIOD * 5);
        rst_n = 1;
        #(CLK_PERIOD * 2);
        
        // Test 1: Single byte transmission
        $display("Test 1: Single byte transmission");
        test_count++;
        tx_byte = 8'hAA;
        send_byte(tx_byte);
        wait(rx_valid);
        #(CLK_PERIOD);
        if (rx_data == ~tx_byte) begin  // MISO echoes inverted
            $display("  PASS: Received 0x%02X (expected inverted)", rx_data);
            pass_count++;
        end else begin
            $display("  FAIL: Received 0x%02X, expected 0x%02X", rx_data, ~tx_byte);
        end
        
        // Test 2: Multiple bytes
        $display("\nTest 2: Multiple byte transmission");
        for (int i = 0; i < 5; i++) begin
            test_count++;
            tx_byte = $random();
            send_byte(tx_byte);
            wait(rx_valid);
            #(CLK_PERIOD);
            if (rx_data == ~tx_byte) begin
                $display("  Byte %0d: PASS (0x%02X -> 0x%02X)", i, tx_byte, rx_data);
                pass_count++;
            end else begin
                $display("  Byte %0d: FAIL (0x%02X -> 0x%02X, expected 0x%02X)", 
                         i, tx_byte, rx_data, ~tx_byte);
            end
            #(CLK_PERIOD * 2);
        end
        
        // Test 3: Continuous transmission
        $display("\nTest 3: Continuous transmission");
        test_count++;
        for (int i = 0; i < 10; i++) begin
            tx_byte = 8'h55 + i;
            send_byte(tx_byte);
            wait(rx_valid);
            #(CLK_PERIOD);
        end
        $display("  PASS: Continuous transmission completed");
        pass_count++;
        
        // Test 4: Busy signal
        $display("\nTest 4: Busy signal");
        test_count++;
        tx_byte = 8'hFF;
        start = 1;
        tx_valid = 1;
        tx_data = tx_byte;
        #(CLK_PERIOD);
        if (busy) begin
            $display("  PASS: Busy signal asserted during transmission");
            pass_count++;
        end else begin
            $display("  FAIL: Busy signal not asserted");
        end
        wait(!busy);
        start = 0;
        tx_valid = 0;
        
        // Test 5: CS signal timing
        $display("\nTest 5: Chip select timing");
        test_count++;
        tx_byte = 8'h42;
        send_byte(tx_byte);
        if (cs_n == 0) begin
            $display("  PASS: CS asserted during transmission");
            pass_count++;
        end else begin
            $display("  FAIL: CS not asserted");
        end
        wait(!busy);
        if (cs_n == 1) begin
            $display("  PASS: CS deasserted after transmission");
            pass_count++;
        end else begin
            $display("  FAIL: CS not deasserted");
        end
        
        // Summary
        $display("\n========================================");
        $display("Test Summary");
        $display("========================================");
        $display("Total tests: %0d", test_count);
        $display("Passed: %0d", pass_count);
        $display("========================================\n");
        
        #(CLK_PERIOD * 10);
        $finish;
    end
    
    // Task to send a byte
    task send_byte(logic [7:0] data);
        wait(tx_ready);
        tx_data = data;
        tx_valid = 1;
        start = 1;
        #(CLK_PERIOD);
        start = 0;
        wait(!busy);
        tx_valid = 0;
    endtask
    
    // Monitor
    initial begin
        $monitor("Time=%0t: start=%b, tx_data=0x%02X, busy=%b, cs_n=%b, sclk=%b, mosi=%b, miso=%b, rx_data=0x%02X",
                 $time, start, tx_data, busy, cs_n, sclk, mosi, miso, rx_data);
    end

endmodule


