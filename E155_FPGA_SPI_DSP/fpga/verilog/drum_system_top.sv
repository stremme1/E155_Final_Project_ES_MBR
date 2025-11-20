// Top-level Drum System Module - SPI + DSP + BRAM VERSION
// Fresh implementation using SPI, DSP blocks, and BRAM
// Optimized for iCE40UP5K (5280 LUTs)
// Author: E155 Final Project
// Date: 2024

module drum_system_top (
    input  logic        clk_ext,
    input  logic        rst_n,
    
    // SPI Physical Pins (connect to BNO055 sensor)
    output logic        spi_sclk,      // SPI Clock
    output logic        spi_mosi,      // SPI Master Out Slave In
    input  logic        spi_miso,      // SPI Master In Slave Out
    output logic        spi_cs_n,      // SPI Chip Select (active low)
    
    // User Interface
    input  logic        button1,        // Kick drum button
    output logic        led1,
    output logic [7:0]  sound_id       // Drum sound ID (0-7, 255 = no sound)
);
    
    logic clk;
    
`ifdef SIMULATION
    assign clk = clk_ext;
`else
    HSOSC #(.CLKHF_DIV(2'b11)) hf_osc (
        .CLKHFPU(1'b1), 
        .CLKHFEN(1'b1), 
        .CLKHF(clk)
    );
    (* keep *) wire _unused_clk_ext = clk_ext;
`endif

    // Internal signals
    logic signed [15:0] gyro_x, gyro_y, gyro_z;
    logic imu_data_valid;
    
    // TODO: Instantiate SPI controller
    // TODO: Instantiate BNO055 SPI interface
    // TODO: Instantiate BRAM buffer
    // TODO: Instantiate gesture recognition with DSP
    
    // Temporary: Simple button-to-sound mapping
    assign sound_id = button1 ? 8'h02 : 8'hFF; // KICK = 0x02, NO_SOUND = 0xFF
    assign led1 = (sound_id != 8'hFF);

endmodule

