// Soft SPI Master Controller for BNO085
// Mode 3: CPOL=1, CPHA=1 (clock idle high, data on falling edge)
// Clock: 4.8 MHz (48 MHz / 10)
// Author: E155 Final Project
// Date: 2024

module spi_controller (
    input  logic        clk,
    input  logic        rst_n,
    
    // SPI Physical Interface
    output logic        spi_sclk,
    output logic        spi_mosi,
    input  logic        spi_miso,
    output logic        spi_cs_n,
    
    // Control Interface
    input  logic        start,           // Start SPI transaction
    input  logic [7:0]  tx_data,         // Data to transmit
    input  logic        tx_valid,         // TX data valid
    output logic        tx_ready,         // TX ready for next byte
    output logic [7:0]  rx_data,         // Received data
    output logic        rx_valid,         // RX data valid
    output logic        busy              // SPI transaction in progress
);

    // Clock divider: 48 MHz / 10 = 4.8 MHz SPI clock
    localparam CLK_DIV = 10;
    localparam CLK_DIV_WIDTH = $clog2(CLK_DIV);
    
    logic [CLK_DIV_WIDTH-1:0] clk_div_counter;
    logic spi_clk_en;  // SPI clock enable (half SPI clock rate)
    logic spi_clk_internal;
    
    // SPI State Machine
    typedef enum logic [2:0] {
        IDLE,
        CS_ASSERT,
        TX_BYTE,
        RX_BYTE,
        CS_DEASSERT,
        DONE
    } state_t;
    
    state_t state, next_state;
    
    // Bit counter (8 bits per byte)
    logic [2:0] bit_counter;
    logic [7:0] tx_shift_reg;
    logic [7:0] rx_shift_reg;
    
    // Clock divider
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_div_counter <= '0;
            spi_clk_en <= 1'b0;
        end else begin
            if (clk_div_counter == CLK_DIV - 1) begin
                clk_div_counter <= '0;
                spi_clk_en <= ~spi_clk_en;  // Toggle every CLK_DIV cycles
            end else begin
                clk_div_counter <= clk_div_counter + 1;
            end
        end
    end
    
    // SPI clock generation (Mode 3: idle high)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            spi_clk_internal <= 1'b1;  // Idle high
        end else if (spi_clk_en && (state == TX_BYTE || state == RX_BYTE)) begin
            spi_clk_internal <= ~spi_clk_internal;
        end else if (state == IDLE || state == CS_ASSERT || state == CS_DEASSERT || state == DONE) begin
            spi_clk_internal <= 1'b1;  // Idle high
        end
    end
    
    assign spi_sclk = spi_clk_internal;
    
    // State machine
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            bit_counter <= '0;
            tx_shift_reg <= '0;
            rx_shift_reg <= '0;
            spi_cs_n <= 1'b1;
        end else begin
            state <= next_state;
            
            case (state)
                IDLE: begin
                    spi_cs_n <= 1'b1;
                    bit_counter <= '0;
                end
                
                CS_ASSERT: begin
                    spi_cs_n <= 1'b0;
                    tx_shift_reg <= tx_data;
                end
                
                TX_BYTE: begin
                    if (spi_clk_en && !spi_clk_internal) begin  // Falling edge (data change)
                        if (bit_counter < 7) begin
                            tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                            bit_counter <= bit_counter + 1;
                        end
                    end else if (spi_clk_en && spi_clk_internal) begin  // Rising edge (sample)
                        if (bit_counter < 7) begin
                            rx_shift_reg <= {rx_shift_reg[6:0], spi_miso};
                        end else begin
                            rx_shift_reg <= {rx_shift_reg[6:0], spi_miso};
                        end
                    end
                end
                
                RX_BYTE: begin
                    if (spi_clk_en && spi_clk_internal) begin  // Rising edge (sample)
                        if (bit_counter < 7) begin
                            rx_shift_reg <= {rx_shift_reg[6:0], spi_miso};
                            bit_counter <= bit_counter + 1;
                        end else begin
                            rx_shift_reg <= {rx_shift_reg[6:0], spi_miso};
                        end
                    end
                end
                
                CS_DEASSERT: begin
                    spi_cs_n <= 1'b1;
                end
                
                DONE: begin
                    // Hold state
                end
            endcase
        end
    end
    
    // Next state logic
    always_comb begin
        next_state = state;
        case (state)
            IDLE: begin
                if (start && tx_valid) begin
                    next_state = CS_ASSERT;
                end
            end
            
            CS_ASSERT: begin
                // Wait a few cycles for CS setup time
                next_state = TX_BYTE;
            end
            
            TX_BYTE: begin
                if (bit_counter == 7 && spi_clk_en && spi_clk_internal) begin
                    next_state = CS_DEASSERT;
                end
            end
            
            RX_BYTE: begin
                if (bit_counter == 7 && spi_clk_en && spi_clk_internal) begin
                    next_state = CS_DEASSERT;
                end
            end
            
            CS_DEASSERT: begin
                // Wait a few cycles for CS hold time
                next_state = DONE;
            end
            
            DONE: begin
                next_state = IDLE;
            end
        endcase
    end
    
    // Output assignments
    assign spi_mosi = (state == TX_BYTE || state == RX_BYTE) ? tx_shift_reg[7] : 1'b0;
    assign rx_data = rx_shift_reg;
    assign rx_valid = (state == DONE);
    assign tx_ready = (state == IDLE);
    assign busy = (state != IDLE && state != DONE);

endmodule

