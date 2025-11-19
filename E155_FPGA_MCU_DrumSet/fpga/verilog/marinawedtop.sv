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
    I2C_Left i2cconnection(
        .SBCLKI (clk),      // System bus clock
        .SBSTBI (sbstbi),   // Strobe
        .SBRWI  (sbrwi),    // Write(1)/Read(0)
        .SBADRI (sbadri),   // Register address
        .SBDATI (sbdati),   // Data to I2C
        .SBDATO (sbdato),   // Data from I2C
        .SBACKO (sbacko),   // Acknowledge

        // I2C physical pins
        .I2C_SCL (i2c_scl),
        .I2C_SDA (i2c_sda)
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
