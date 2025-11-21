// SPI Output Module for MCU Communication
// FPGA acts as SPI Master, MCU acts as SPI Slave
// Sends sound codes (0-7) to MCU when gestures are detected
// Simple protocol: Single byte transfer with chip select

module spi_to_mcu #(
    parameter CLK_DIV = 16  // Divide system clock for SPI clock (adjust for MCU speed)
)(
    input  logic        clk,
    input  logic        rst_n,
    
    // Data interface
    input  logic        data_valid,      // New sound code available
    input  logic [3:0]  sound_code,     // Sound code (0-7)
    
    // SPI interface to MCU
    output logic        mcu_sclk,       // SPI clock to MCU
    output logic        mcu_mosi,       // SPI master out (to MCU)
    input  logic        mcu_miso,        // SPI master in (from MCU, optional)
    output logic        mcu_cs_n,       // Chip select (active low)
    
    // Status
    output logic        busy            // Transfer in progress
);

    typedef enum logic [2:0] {
        IDLE,
        CS_ASSERT,
        TX_DATA,
        CS_DEASSERT,
        DONE
    } state_t;
    
    state_t state;
    logic [3:0] bit_cnt;
    logic [7:0] tx_data;
    logic [7:0] tx_shift;
    logic [7:0] clk_cnt;
    logic [7:0] done_cnt;  // Separate counter for DONE state
    logic sclk_en;
    logic sclk_reg;
    logic data_valid_prev;
    logic data_valid_edge;
    
    // Detect rising edge of data_valid
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_valid_prev <= 1'b0;
            data_valid_edge <= 1'b0;
        end else begin
            data_valid_prev <= data_valid;
            data_valid_edge <= data_valid && !data_valid_prev;
        end
    end
    
    // SPI clock generation (Mode 0: CPOL=0, CPHA=0)
    // Clock idle low, data sampled on rising edge
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_cnt <= 8'd0;
            sclk_reg <= 1'b0;  // CPOL=0: idle low
        end else begin
            if (sclk_en) begin
                clk_cnt <= clk_cnt + 1;
                if (clk_cnt == CLK_DIV - 1) begin
                    clk_cnt <= 8'd0;
                    sclk_reg <= ~sclk_reg;
                end
            end else begin
                sclk_reg <= 1'b0;  // Return to idle low
                clk_cnt <= 8'd0;
            end
        end
    end
    
    assign mcu_sclk = sclk_reg;
    
    // State machine
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            bit_cnt <= 4'd0;
            tx_shift <= 8'd0;
            tx_data <= 8'd0;
            mcu_cs_n <= 1'b1;  // CS inactive (high)
            mcu_mosi <= 1'b0;
            sclk_en <= 1'b0;
            busy <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    mcu_cs_n <= 1'b1;  // CS inactive
                    mcu_mosi <= 1'b0;
                    sclk_en <= 1'b0;
                    busy <= 1'b0;
                    
                    // Capture sound code when valid (rising edge)
                    if (data_valid_edge) begin
                        tx_data <= {4'd0, sound_code};  // Pad to 8 bits
                        state <= CS_ASSERT;
                    end
                end
                
                CS_ASSERT: begin
                    mcu_cs_n <= 1'b0;  // Assert CS (active low)
                    tx_shift <= tx_data;
                    bit_cnt <= 4'd0;
                    sclk_en <= 1'b1;
                    busy <= 1'b1;
                    state <= TX_DATA;
                end
                
                TX_DATA: begin
                    // Output MSB first
                    mcu_mosi <= tx_shift[7];
                    
                    // Shift on falling edge of SCLK
                    // Detect when SCLK transitions from high to low
                    // We check when sclk_reg was high and clk_cnt is about to wrap
                    if (sclk_reg == 1'b1 && clk_cnt == CLK_DIV - 1) begin
                        // SCLK will fall on next cycle - shift data now
                        tx_shift <= {tx_shift[6:0], 1'b0};
                        if (bit_cnt == 7) begin
                            // All 8 bits sent - wait for SCLK to go low then deassert CS
                            sclk_en <= 1'b0;  // Stop clock after this cycle
                            state <= CS_DEASSERT;
                        end else begin
                            bit_cnt <= bit_cnt + 1;
                        end
                    end
                end
                
                CS_DEASSERT: begin
                    mcu_cs_n <= 1'b1;  // Deassert CS
                    mcu_mosi <= 1'b0;
                    done_cnt <= 8'd0;
                    state <= DONE;
                end
                
                DONE: begin
                    // Wait a bit before allowing next transfer
                    done_cnt <= done_cnt + 1;
                    if (done_cnt >= (CLK_DIV * 2)) begin
                        state <= IDLE;
                        busy <= 1'b0;
                    end
                end
            endcase
        end
    end
    
endmodule
