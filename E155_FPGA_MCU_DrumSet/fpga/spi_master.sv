// SPI Master Module for BNO085 Communication
// BNO085 SPI: Mode 3 (CPOL=1, CPHA=1), MSB first, 3MHz max

module spi_master #(
    parameter CLK_DIV = 16  // Divide system clock for SPI clock (adjust for 3MHz max)
)(
    input  logic        clk,
    input  logic        rst_n,
    
    // Control interface
    input  logic        start,
    input  logic        tx_valid,
    input  logic [7:0]  tx_data,
    output logic        tx_ready,
    output logic        rx_valid,
    output logic [7:0]  rx_data,
    output logic        busy,
    
    // SPI interface
    output logic        sclk,
    output logic        mosi,
    input  logic        miso,
    output logic        cs_n
);

    typedef enum logic [2:0] {
        IDLE,
        TX_RX,
        DONE
    } state_t;
    
    state_t state;
    logic [3:0] bit_cnt;
    logic [7:0] tx_shift;
    logic [7:0] rx_shift;
    logic [7:0] clk_cnt;
    logic sclk_en;
    logic sclk_reg;
    
    // Clock divider for SPI clock
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_cnt <= 8'd0;
            sclk_reg <= 1'b1;  // CPOL=1: idle high
        end else begin
            if (sclk_en) begin
                if (clk_cnt == CLK_DIV - 1) begin
                    clk_cnt <= 8'd0;
                    sclk_reg <= ~sclk_reg;
                end else begin
                    clk_cnt <= clk_cnt + 1;
                end
            end else begin
                sclk_reg <= 1'b1;  // Return to idle high
            end
        end
    end
    
    assign sclk = sclk_reg;
    
    // State machine
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            bit_cnt <= 4'd0;
            tx_shift <= 8'd0;  // MOSI will be 0 when idle
            rx_shift <= 8'd0;
            sclk_en <= 1'b0;
            cs_n <= 1'b1;
            tx_ready <= 1'b0;
            rx_valid <= 1'b0;
        end else begin
            rx_valid <= 1'b0;
            
            case (state)
                IDLE: begin
                    cs_n <= 1'b1;
                    sclk_en <= 1'b0;
                    bit_cnt <= 4'd0;
                    tx_ready <= 1'b1;
                    // tx_shift retains value (MOSI driven via assign)
                    
                    if (start && tx_valid) begin
                        state <= TX_RX;
                        cs_n <= 1'b0;
                        tx_shift <= tx_data;
                        rx_shift <= 8'd0;
                        tx_ready <= 1'b0;
                        sclk_en <= 1'b1;
                    end
                end
                
                TX_RX: begin
                    // Sample MISO on falling edge (CPHA=1)
                    if (!sclk_reg && clk_cnt == CLK_DIV/2) begin
                        rx_shift <= {rx_shift[6:0], miso};
                    end
                    
                    // Shift MOSI on rising edge
                    if (sclk_reg && clk_cnt == CLK_DIV/2) begin
                        if (bit_cnt < 7) begin
                            tx_shift <= {tx_shift[6:0], 1'b0};
                            bit_cnt <= bit_cnt + 1;
                        end else begin
                            state <= DONE;
                            sclk_en <= 1'b0;
                        end
                    end
                end
                
                DONE: begin
                    rx_data <= rx_shift;
                    rx_valid <= 1'b1;
                    cs_n <= 1'b1;
                    state <= IDLE;
                end
            endcase
        end
    end
    
    // MOSI output: always driven from MSB of tx_shift register
    // When idle, tx_shift = 0, so MOSI = 0 (safe idle state)
    assign mosi = tx_shift[7];
    assign busy = (state != IDLE);
    
endmodule


