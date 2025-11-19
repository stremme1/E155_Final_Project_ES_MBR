module top(
    input  logic clk,      // Your system clock
    input  logic rst_n,    // Active-low reset
    inout  wire  i2c_sda,  // IMU SDA pin
    inout  wire  i2c_scl   // IMU SCL pin
);

    //----------------------------------------------------------------------
    // System Bus signals connecting YOUR driver FSM <-> HARD I2C block
    //----------------------------------------------------------------------
    logic        sbstbi;       // strobe / chip-select
    logic        sbrwi;        // write=1, read=0
    logic [7:0]  sbadri;       // bus address (register select)
    logic [7:0]  sbdati;       // data to hard I2C IP
    logic [7:0]  sbdato;       // data from hard I2C IP
    logic        sbacko;       // acknowledge pulse

    //----------------------------------------------------------------------
    // Instantiate the Radiant-generated LEFT I²C block
    //----------------------------------------------------------------------
    i2cconnection i2c_inst (
    .i2c2_scl_io(i2c_scl),   // FPGA pin
    .i2c2_sda_io(i2c_sda),   // FPGA pin
    .rst_i(rst),
    .ipload_i(1'b1),         // REQUIRED to load registers on startup
    .ipdone_o(ipdone),
    .sb_clk_i(clk),
    .sb_wr_i(sb_wr),
    .sb_stb_i(sb_stb),
    .sb_adr_i(sb_addr),
    .sb_dat_i(sb_wdata),
    .sb_dat_o(sb_rdata),
    .sb_ack_o(sb_ack),
    .i2c_pirq_o(),
    .i2c_pwkup_o()
	);


    //----------------------------------------------------------------------
    // Instantiate your I²C driver FSM (that YOU write)
    //----------------------------------------------------------------------
    i2c_driver_bno085 i2c_driver_bno085 (
        .clk(clk),
        .rst_n(rst_n),

        // connect driver to system bus
        .sb_stb   (sbstbi),
        .sb_wr    (sbrwi),
        .sb_addr  (sbadri),
        .sb_wdata (sbdati),
        .sb_rdata (sbdato),
        .sb_ack   (sbacko),

        // IMU data output
        .imu_new_data(),
        .imu_data()
    );

endmodule
