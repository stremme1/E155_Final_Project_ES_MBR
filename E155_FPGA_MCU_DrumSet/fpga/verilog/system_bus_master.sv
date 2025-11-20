// System Bus Master - EXTREME OPTIMIZATION FOR iCE40UP5K
// Minimal 3-state FSM
// Author: E155 Final Project
// Date: 2024

module system_bus_master (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        sb_clk,
    output logic        sb_wr,
    output logic        sb_stb,
    output logic [7:0]  sb_addr,
    output logic [7:0]  sb_data_i,
    input  logic [7:0]  sb_data_o,
    input  logic        sb_ack,
    input  logic        sb_irq,
    input  logic        start,
    input  logic        write_en,
    input  logic [7:0] addr,
    input  logic [7:0] data_in,
    output logic [7:0] data_out,
    output logic        done,
    output logic        busy
);

    // EXTREME: Only 3 states with explicit encoding
    typedef enum logic [1:0] {
        IDLE = 2'b00,
        ACTIVE = 2'b01,
        WAIT_ACK = 2'b10
    } state_t;
    
    state_t state;
    
    // EXTREME: Single always_ff for state and outputs
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
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
                        state <= ACTIVE;
                        busy <= 1;
                        sb_addr <= addr;
                        sb_wr <= write_en;
                        sb_data_i <= data_in;
                    end
                end
                ACTIVE: begin
                    sb_stb <= 1;
                    state <= WAIT_ACK;
                end
                WAIT_ACK: begin
                    sb_stb <= 1;
                    if (sb_ack) begin
                        sb_stb <= 0;
                        if (!write_en) begin
                            data_out <= sb_data_o;
                        end
                        done <= 1;
                        busy <= 0;
                        state <= IDLE;
                    end
                end
            endcase
        end
    end

endmodule
