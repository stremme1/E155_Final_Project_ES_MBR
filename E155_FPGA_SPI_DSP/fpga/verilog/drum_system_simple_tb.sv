// Simplified Test Bench - Quick Verification
// Tests basic functionality without long waits
`timescale 1ns / 1ps
`define SIMULATION

module drum_system_simple_tb;

    // Clock and Reset
    logic clk_ext;
    logic rst_n;
    
    // SPI Physical Pins
    logic spi_sclk;
    logic spi_mosi;
    logic spi_miso;
    logic spi_cs1_n;
    logic spi_cs2_n;
    
    // BNO085 Control
    logic bno085_1_int_n;
    logic bno085_1_rst_n;
    logic bno085_2_int_n;
    logic bno085_2_rst_n;
    
    // User Interface
    logic button1;
    logic button2;
    logic led1;
    logic led2;
    logic [7:0] sound_id;
    
    // Instantiate DUT
    drum_system_top dut (
        .clk_ext(clk_ext),
        .rst_n(rst_n),
        .spi_sclk(spi_sclk),
        .spi_mosi(spi_mosi),
        .spi_miso(spi_miso),
        .spi_cs1_n(spi_cs1_n),
        .spi_cs2_n(spi_cs2_n),
        .bno085_1_int_n(bno085_1_int_n),
        .bno085_1_rst_n(bno085_1_rst_n),
        .bno085_2_int_n(bno085_2_int_n),
        .bno085_2_rst_n(bno085_2_rst_n),
        .button1(button1),
        .button2(button2),
        .led1(led1),
        .led2(led2),
        .sound_id(sound_id)
    );
    
    // Clock Generation (48 MHz)
    initial begin
        clk_ext = 0;
        forever #10.416 clk_ext = ~clk_ext;  // 48 MHz
    end
    
    // Test Results
    integer test_count = 0;
    integer pass_count = 0;
    integer fail_count = 0;
    
    task test_assert(input logic condition, input string test_name);
        test_count = test_count + 1;
        if (condition) begin
            $display("[PASS] Test %0d: %s", test_count, test_name);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Test %0d: %s", test_count, test_name);
            fail_count = fail_count + 1;
        end
    endtask
    
    // Main Test
    initial begin
        $display("\n==========================================");
        $display("SIMPLIFIED DRUM SYSTEM TEST BENCH");
        $display("==========================================\n");
        
        // Initialize
        rst_n = 0;
        button1 = 0;
        button2 = 0;
        bno085_1_int_n = 1;
        bno085_2_int_n = 1;
        
        #100;
        $display("Test 1: Reset state");
        test_assert(sound_id == 8'hFF, "Reset: sound_id should be NO_SOUND");
        test_assert(led1 == 0, "Reset: led1 should be off");
        test_assert(led2 == 0, "Reset: led2 should be off");
        
        #100;
        rst_n = 1;
        $display("\nTest 2: After reset release");
        #1000;
        test_assert(bno085_1_rst_n !== 1'bx, "BNO085_1 reset should be driven");
        test_assert(bno085_2_rst_n !== 1'bx, "BNO085_2 reset should be driven");
        
        #100;
        $display("\nTest 3: SPI signals");
        test_assert(spi_sclk !== 1'bx, "SPI clock should be driven");
        test_assert(spi_cs1_n !== 1'bx, "CS1 should be driven");
        test_assert(spi_cs2_n !== 1'bx, "CS2 should be driven");
        
        #100;
        $display("\nTest 4: Button1 (Kick drum)");
        button1 = 1;
        #1000;
        // Note: May need debounce time, but checking basic functionality
        $display("Button1 pressed, sound_id = 0x%02h", sound_id);
        
        button1 = 0;
        #100;
        
        $display("\n==========================================");
        $display("TEST SUMMARY");
        $display("==========================================");
        $display("Total Tests: %0d", test_count);
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", fail_count);
        $display("==========================================\n");
        
        if (fail_count == 0) begin
            $display("ALL BASIC TESTS PASSED");
        end else begin
            $display("SOME TESTS FAILED");
        end
        
        #1000;
        $finish;
    end

endmodule

