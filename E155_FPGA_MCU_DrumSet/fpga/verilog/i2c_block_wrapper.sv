// I2C Block Wrapper - Adapts to different Module Generator port configurations
// This wrapper allows the design to work with different i2c_block.v files
// Author: E155 Final Project
// Date: 2024

module i2c_block_wrapper (
    // I2C Physical Pins
    inout  wire         i2c1_scl,
    inout  wire         i2c1_sda,
    
    // Reset and IP Configuration
    input  logic        rst_i,
    input  logic        ipload_i,
    output logic        ipdone_o,
    
    // System Bus Interface
    input  logic        sb_clk_i,
    input  logic        sb_wr_i,
    input  logic        sb_stb_i,
    input  logic [7:0]  sb_adr_i,
    input  logic [7:0]  sb_dat_i,
    output logic [7:0]  sb_dat_o,
    output logic        sb_ack_o,
    output logic [1:0]  i2c_pirq_o,
    output logic [1:0]  i2c_pwkup_o
);

    // Try to instantiate with common port name variations
    // If this fails, check the actual Module Generator file port names
    
    // Common configuration: Both I2Cs enabled
    // Ports: i2c2_scl_io, i2c2_sda_io, i2c1_scl_io, i2c1_sda_io, ...
    i2c_block i2c_inst (
        .i2c2_scl_io(1'bZ),      // I2C2 unused
        .i2c2_sda_io(1'bZ),      // I2C2 unused
        .i2c1_scl_io(i2c1_scl),  // I2C1 Clock
        .i2c1_sda_io(i2c1_sda),  // I2C1 Data
        .rst_i(rst_i),
        .ipload_i(ipload_i),
        .ipdone_o(ipdone_o),
        .sb_clk_i(sb_clk_i),
        .sb_wr_i(sb_wr_i),
        .sb_stb_i(sb_stb_i),
        .sb_adr_i(sb_adr_i),
        .sb_dat_i(sb_dat_i),
        .sb_dat_o(sb_dat_o),
        .sb_ack_o(sb_ack_o),
        .i2c_pirq_o(i2c_pirq_o),
        .i2c_pwkup_o(i2c_pwkup_o)
    );

endmodule

