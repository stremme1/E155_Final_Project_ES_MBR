// SPI Slave Interface for MCU Communication
// SystemVerilog implementation for UPduino v3.1
// Author: E155 Final Project
// Date: 2024

module spi_interface #(
    parameter DATA_WIDTH = 8,
    parameter BUFFER_DEPTH = 64
)(
    input  logic                    clk,
    input  logic                    rst_n,
    input  logic                    spi_clk,
    input  logic                    spi_mosi,
    output logic                    spi_miso,
    input  logic                    spi_cs,
    input  logic [DATA_WIDTH-1:0]   data_to_mcu,
    output logic [DATA_WIDTH-1:0]   data_from_mcu,
    output logic                    data_valid,
    output logic                    spi_busy
);

    // SPI state machine
    typedef enum logic [2:0] {
        IDLE,
        RECEIVE,
        TRANSMIT,
        COMPLETE
    } spi_state_t;
    
    spi_state_t state, next_state;
    
    // SPI registers
    logic [DATA_WIDTH-1:0] shift_reg_in;
    logic [DATA_WIDTH-1:0] shift_reg_out;
    logic [3:0] bit_counter;
    logic spi_clk_prev;
    logic spi_cs_prev;
    
    // Data buffers
    logic [DATA_WIDTH-1:0] tx_buffer [0:BUFFER_DEPTH-1];
    logic [DATA_WIDTH-1:0] rx_buffer [0:BUFFER_DEPTH-1];
    logic [5:0] tx_wr_ptr, tx_rd_ptr;
    logic [5:0] rx_wr_ptr, rx_rd_ptr;
    logic tx_full, tx_empty;
    logic rx_full, rx_empty;
    
    // SPI clock edge detection
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            spi_clk_prev <= 1'b0;
            spi_cs_prev <= 1'b1;
        end else begin
            spi_clk_prev <= spi_clk;
            spi_cs_prev <= spi_cs;
        end
    end
    
    // SPI clock edge detection
    logic spi_clk_rising, spi_clk_falling;
    assign spi_clk_rising = spi_clk && !spi_clk_prev;
    assign spi_clk_falling = !spi_clk && spi_clk_prev;
    
    // CS edge detection
    logic cs_falling, cs_rising;
    assign cs_falling = !spi_cs && spi_cs_prev;
    assign cs_rising = spi_cs && !spi_cs_prev;
    
    // State machine
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    // Next state logic
    always_comb begin
        next_state = state;
        case (state)
            IDLE: begin
                if (cs_falling) next_state = RECEIVE;
            end
            RECEIVE: begin
                if (bit_counter == DATA_WIDTH-1) next_state = TRANSMIT;
            end
            TRANSMIT: begin
                if (bit_counter == DATA_WIDTH-1) next_state = COMPLETE;
            end
            COMPLETE: begin
                if (cs_rising) next_state = IDLE;
            end
        endcase
    end
    
    // Bit counter
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_counter <= 0;
        end else begin
            case (state)
                IDLE: bit_counter <= 0;
                RECEIVE, TRANSMIT: begin
                    if (spi_clk_rising) begin
                        if (bit_counter == DATA_WIDTH-1) begin
                            bit_counter <= 0;
                        end else begin
                            bit_counter <= bit_counter + 1;
                        end
                    end
                end
            endcase
        end
    end
    
    // Shift register for reception
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg_in <= 0;
        end else begin
            if (state == RECEIVE && spi_clk_rising) begin
                shift_reg_in <= {shift_reg_in[DATA_WIDTH-2:0], spi_mosi};
            end
        end
    end
    
    // Shift register for transmission
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg_out <= 0;
        end else begin
            if (state == TRANSMIT && spi_clk_falling) begin
                shift_reg_out <= {shift_reg_out[DATA_WIDTH-2:0], 1'b0};
            end else if (state == IDLE) begin
                shift_reg_out <= data_to_mcu;
            end
        end
    end
    
    // MISO output
    assign spi_miso = (state == TRANSMIT) ? shift_reg_out[DATA_WIDTH-1] : 1'bz;
    
    // Data valid signal
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_valid <= 1'b0;
        end else begin
            data_valid <= (state == COMPLETE);
        end
    end
    
    // Received data output
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_from_mcu <= 0;
        end else begin
            if (state == COMPLETE) begin
                data_from_mcu <= shift_reg_in;
            end
        end
    end
    
    // SPI busy signal
    assign spi_busy = (state != IDLE);
    
    // Buffer management for data flow
    // TX Buffer (FPGA to MCU)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_wr_ptr <= 0;
            tx_rd_ptr <= 0;
        end else begin
            // Write to TX buffer when new data available
            if (data_valid && !tx_full) begin
                tx_buffer[tx_wr_ptr] <= data_to_mcu;
                tx_wr_ptr <= tx_wr_ptr + 1;
            end
            
            // Read from TX buffer when transmitting
            if (state == TRANSMIT && bit_counter == 0) begin
                tx_rd_ptr <= tx_rd_ptr + 1;
            end
        end
    end
    
    // RX Buffer (MCU to FPGA)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_wr_ptr <= 0;
            rx_rd_ptr <= 0;
        end else begin
            // Write to RX buffer when data received
            if (state == COMPLETE && !rx_full) begin
                rx_buffer[rx_wr_ptr] <= shift_reg_in;
                rx_wr_ptr <= rx_wr_ptr + 1;
            end
        end
    end
    
    // Buffer status flags
    assign tx_full = (tx_wr_ptr + 1 == tx_rd_ptr);
    assign tx_empty = (tx_wr_ptr == tx_rd_ptr);
    assign rx_full = (rx_wr_ptr + 1 == rx_rd_ptr);
    assign rx_empty = (rx_wr_ptr == rx_rd_ptr);

endmodule
