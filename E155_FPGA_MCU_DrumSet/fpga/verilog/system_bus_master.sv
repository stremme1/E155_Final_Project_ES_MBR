// System Bus Master for iCE40 I2C Hardened IP
// Implements System Bus protocol to communicate with I2C IP
// Author: E155 Final Project
// Date: 2024

module system_bus_master (
    input  logic        clk,
    input  logic        rst_n,
    
    // System Bus Interface
    // Note: sb_clk is an input - clock is driven by top module
    input  logic        sb_clk,     // System Bus clock (driven by top module)
    output logic        sb_wr,      // 0=read, 1=write
    output logic        sb_stb,     // Strobe
    output logic [7:0]  sb_addr,
    output logic [7:0]  sb_data_i,
    input  logic [7:0]  sb_data_o,
    input  logic        sb_ack,
    input  logic        sb_irq,
    
    // User Interface
    input  logic        start,
    input  logic        write_en,
    input  logic [7:0] addr,
    input  logic [7:0] data_in,
    output logic [7:0] data_out,
    output logic        done,
    output logic        busy
);

    typedef enum logic [2:0] {
        IDLE,
        WRITE_ADDR,
        WRITE_DATA,
        READ_ADDR,
        READ_DATA,
        WAIT_ACK
    } state_t;
    
    state_t state, next_state;
    
    // System Bus clock is provided as input (driven by top module)
    // No assignment needed here
    
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
                if (start) begin
                    if (write_en) begin
                        next_state = WRITE_ADDR;
                    end else begin
                        next_state = READ_ADDR;
                    end
                end
            end
            WRITE_ADDR: next_state = WRITE_DATA;
            WRITE_DATA: next_state = WAIT_ACK;
            READ_ADDR: next_state = READ_DATA;
            READ_DATA: next_state = WAIT_ACK;
            WAIT_ACK: begin
                if (sb_ack) begin
                    next_state = IDLE;
                end
            end
        endcase
    end
    
    // Output logic
    // System Bus protocol: Address and data must be stable when SBSTBi is asserted
    // According to datasheet: SBSTBi is strobe signal, SBACKo is acknowledge
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sb_wr <= 0;
            sb_stb <= 0;
            sb_addr <= 0;
            sb_data_i <= 0;
            data_out <= 0;
            done <= 0;
            busy <= 0;
        end else begin
            done <= 0;
            case (state)
                IDLE: begin
                    sb_stb <= 0;
                    busy <= 0;
                    if (start) begin
                        busy <= 1;
                        sb_addr <= addr;
                        sb_wr <= write_en;
                        // For writes, set data early
                        if (write_en) begin
                            sb_data_i <= data_in;
                        end
                    end
                end
                WRITE_ADDR: begin
                    // Address and data are already set, assert strobe
                    sb_stb <= 1;
                end
                WRITE_DATA: begin
                    // Keep strobe asserted, data already set
                    sb_stb <= 1;
                end
                READ_ADDR: begin
                    // Assert strobe with address
                    sb_stb <= 1;
                end
                READ_DATA: begin
                    // Keep strobe asserted, wait for data
                    sb_stb <= 1;
                end
                WAIT_ACK: begin
                    // Keep strobe asserted until acknowledge
                    if (sb_ack) begin
                        sb_stb <= 0;
                        if (!write_en) begin
                            data_out <= sb_data_o;
                        end
                        done <= 1;
                        busy <= 0;
                    end else begin
                        sb_stb <= 1;  // Keep strobe asserted
                    end
                end
            endcase
        end
    end

endmodule

