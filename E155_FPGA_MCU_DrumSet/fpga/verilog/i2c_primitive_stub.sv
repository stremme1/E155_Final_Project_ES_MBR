// Simulation Stub for Lattice I2C_B and SPI_B Primitives
// These are Lattice-specific primitives that don't exist in iVerilog
// This stub allows simulation to proceed
// Author: E155 Final Project
// Date: 2024

`ifdef SIMULATION
// Stub for I2C_B primitive
module I2C_B #(
    parameter I2C_SLAVE_INIT_ADDR = "0b1111101",
    parameter BUS_ADDR74 = "0b0001",
    parameter I2C_CLK_DIVIDER = "29",
    parameter FREQUENCY_PIN_SBCLKI = "48.0",
    parameter SDA_INPUT_DELAYED = "1",
    parameter SDA_OUTPUT_DELAYED = "1"
) (
    input SBCLKI,
    input SBRWI,
    input SBSTBI,
    input SBADRI7, SBADRI6, SBADRI5, SBADRI4, SBADRI3, SBADRI2, SBADRI1, SBADRI0,
    input SBDATI7, SBDATI6, SBDATI5, SBDATI4, SBDATI3, SBDATI2, SBDATI1, SBDATI0,
    input SCLI,
    input SDAI,
    output SBDATO7, SBDATO6, SBDATO5, SBDATO4, SBDATO3, SBDATO2, SBDATO1, SBDATO0,
    output SBACKO,
    output I2CIRQ,
    output I2CWKUP,
    output SCLO,
    output SCLOE,
    output SDAO,
    output SDAOE
);
    // Minimal stub - just drive outputs to safe values
    assign {SBDATO7, SBDATO6, SBDATO5, SBDATO4, SBDATO3, SBDATO2, SBDATO1, SBDATO0} = 8'h00;
    assign SBACKO = SBSTBI;  // ACK when strobe is active
    assign I2CIRQ = 1'b0;
    assign I2CWKUP = 1'b0;
    assign SCLO = 1'b0;
    assign SCLOE = 1'b0;
    assign SDAO = 1'b0;
    assign SDAOE = 1'b0;
endmodule

// Stub for SPI_B primitive
module SPI_B #(
    parameter FREQUENCY_PIN_SBCLKI = "48.0",
    parameter SPI_CLK_DIVIDER = "1",
    parameter BUS_ADDR74 = "0b0000"
) (
    input SBCLKI,
    input SBRWI,
    input SBSTBI,
    input SBADRI7, SBADRI6, SBADRI5, SBADRI4, SBADRI3, SBADRI2, SBADRI1, SBADRI0,
    input SBDATI7, SBDATI6, SBDATI5, SBDATI4, SBDATI3, SBDATI2, SBDATI1, SBDATI0,
    input MI, SI, SCKI, SCSNI,
    output SBDATO7, SBDATO6, SBDATO5, SBDATO4, SBDATO3, SBDATO2, SBDATO1, SBDATO0,
    output SBACKO,
    output SPIIRQ,
    output SPIWKUP,
    output SO, SOE, MO, MOE, SCKO, SCKOE,
    output MCSNO3, MCSNO2, MCSNO1, MCSNO0,
    output MCSNOE3, MCSNOE2, MCSNOE1, MCSNOE0
);
    // Minimal stub
    assign {SBDATO7, SBDATO6, SBDATO5, SBDATO4, SBDATO3, SBDATO2, SBDATO1, SBDATO0} = 8'h00;
    assign SBACKO = SBSTBI;
    assign SPIIRQ = 1'b0;
    assign SPIWKUP = 1'b0;
    assign SO = 1'b0;
    assign SOE = 1'b0;
    assign MO = 1'b0;
    assign MOE = 1'b0;
    assign SCKO = 1'b0;
    assign SCKOE = 1'b0;
    assign {MCSNO3, MCSNO2, MCSNO1, MCSNO0} = 4'b0;
    assign {MCSNOE3, MCSNOE2, MCSNOE1, MCSNOE0} = 4'b0;
endmodule
`endif

