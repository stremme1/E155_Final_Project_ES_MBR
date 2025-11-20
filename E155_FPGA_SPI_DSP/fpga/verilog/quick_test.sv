// Quick Test to Verify Test Bench Works
`timescale 1ns / 1ps
`define SIMULATION

module quick_test;
    logic clk;
    logic rst_n;
    
    initial begin
        $display("==========================================");
        $display("QUICK TEST - Verifying test bench works");
        $display("==========================================");
        
        clk = 0;
        rst_n = 0;
        
        #100;
        rst_n = 1;
        $display("Reset released at time %0t", $time);
        
        #1000;
        $display("Test completed successfully!");
        $display("==========================================");
        $finish;
    end
    
    always #10 clk = ~clk;
endmodule

