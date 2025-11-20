// Mock I2C Block for Simulation
// This is a simplified version for test bench use only
// The real i2c_block.v uses Lattice primitives (I2C_B) that don't simulate
// Author: E155 Final Project
// Date: 2024

`ifdef SIMULATION
module i2c_block (
    inout i2c2_scl_io,
    inout i2c2_sda_io,
    inout i2c1_scl_io,
    inout i2c1_sda_io,
    input rst_i,
    input ipload_i,
    output reg ipdone_o,
    input sb_clk_i,
    input sb_wr_i,
    input sb_stb_i,
    input [7:0] sb_adr_i,
    input [7:0] sb_dat_i,
    output reg [7:0] sb_dat_o,
    output reg sb_ack_o,
    output [1:0] i2c_pirq_o,
    output [1:0] i2c_pwkup_o
);
    
    // Mock I2C pins (just pass through for simulation)
    assign i2c1_scl_io = 1'bZ;
    assign i2c1_sda_io = 1'bZ;
    assign i2c2_scl_io = 1'bZ;
    assign i2c2_sda_io = 1'bZ;
    
    // Mock IPDONE - assert after reset
    always @(posedge sb_clk_i or posedge rst_i) begin
        if (rst_i) begin
            ipdone_o <= 0;
        end else if (ipload_i) begin
            // Simulate IP initialization delay
            #1000;
            ipdone_o <= 1;
        end
    end
    
    // Mock System Bus - driven by test bench via force
    // The test bench will force these signals
    // For now, just initialize them
    initial begin
        sb_ack_o = 0;
        sb_dat_o = 0;
    end
    
    // Mock interrupts (not used in test)
    assign i2c_pirq_o = 2'b00;
    assign i2c_pwkup_o = 2'b00;
    
endmodule
`endif

