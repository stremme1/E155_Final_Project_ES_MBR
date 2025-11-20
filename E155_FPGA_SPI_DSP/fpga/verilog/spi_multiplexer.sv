// SPI Multiplexer for Two BNO085 IMUs
// Time-multiplexes SPI controller between two IMUs
// Author: E155 Final Project
// Date: 2024

module spi_multiplexer (
    input  logic        clk,
    input  logic        rst_n,
    
    // SPI Controller Interface
    output logic        spi_start,
    output logic [7:0]  spi_tx_data,
    output logic        spi_tx_valid,
    input  logic        spi_tx_ready,
    input  logic [7:0]  spi_rx_data,
    input  logic        spi_rx_valid,
    input  logic        spi_busy,
    
    // Physical SPI Pins
    output logic        spi_sclk,
    output logic        spi_mosi,
    input  logic        spi_miso,
    output logic        spi_cs1_n,      // CS for IMU1 (Right hand)
    output logic        spi_cs2_n,      // CS for IMU2 (Left hand)
    
    // IMU1 Interface (Right hand)
    output logic        imu1_start,
    output logic [7:0]  imu1_tx_data,
    output logic        imu1_tx_valid,
    input  logic        imu1_tx_ready,
    input  logic [7:0]  imu1_rx_data,
    input  logic        imu1_rx_valid,
    input  logic        imu1_busy,
    
    // IMU2 Interface (Left hand)
    output logic        imu2_start,
    output logic [7:0]  imu2_tx_data,
    output logic        imu2_tx_valid,
    input  logic        imu2_tx_ready,
    input  logic [7:0]  imu2_rx_data,
    input  logic        imu2_rx_valid,
    input  logic        imu2_busy
);

    // Time-multiplexing state
    typedef enum logic {
        SELECT_IMU1,
        SELECT_IMU2
    } mux_state_t;
    
    mux_state_t mux_state;
    logic [15:0] mux_counter;
    
    // Multiplexer: Alternate between IMU1 and IMU2
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mux_state <= SELECT_IMU1;
            mux_counter <= '0;
        end else begin
            // Switch every ~10ms (480000 cycles at 48MHz)
            if (mux_counter >= 16'd480000) begin
                mux_state <= (mux_state == SELECT_IMU1) ? SELECT_IMU2 : SELECT_IMU1;
                mux_counter <= '0;
            end else begin
                mux_counter <= mux_counter + 1;
            end
        end
    end
    
    // Route SPI signals based on selected IMU
    always_comb begin
        if (mux_state == SELECT_IMU1) begin
            spi_start = imu1_start;
            spi_tx_data = imu1_tx_data;
            spi_tx_valid = imu1_tx_valid;
            imu1_tx_ready = spi_tx_ready;
            imu1_rx_data = spi_rx_data;
            imu1_rx_valid = spi_rx_valid;
            imu1_busy = spi_busy;
            spi_cs1_n = 1'b0;  // Select IMU1
            spi_cs2_n = 1'b1;  // Deselect IMU2
            
            // IMU2 signals inactive
            imu2_start = 1'b0;
            imu2_tx_data = '0;
            imu2_tx_valid = 1'b0;
            imu2_tx_ready = 1'b0;
            imu2_rx_data = '0;
            imu2_rx_valid = 1'b0;
            imu2_busy = 1'b0;
        end else begin
            spi_start = imu2_start;
            spi_tx_data = imu2_tx_data;
            spi_tx_valid = imu2_tx_valid;
            imu2_tx_ready = spi_tx_ready;
            imu2_rx_data = spi_rx_data;
            imu2_rx_valid = spi_rx_valid;
            imu2_busy = spi_busy;
            spi_cs1_n = 1'b1;  // Deselect IMU1
            spi_cs2_n = 1'b0;  // Select IMU2
            
            // IMU1 signals inactive
            imu1_start = 1'b0;
            imu1_tx_data = '0;
            imu1_tx_valid = 1'b0;
            imu1_tx_ready = 1'b0;
            imu1_rx_data = '0;
            imu1_rx_valid = 1'b0;
            imu1_busy = 1'b0;
        end
    end

endmodule

