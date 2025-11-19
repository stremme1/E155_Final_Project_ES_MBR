// System Bus Master - ULTRA-SIMPLIFIED FOR iCE40UP5K
// Reduced from 6 states to 4 states
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
    
    // User Interface
    input  logic        start,
    input  logic        write_en,
    input  logic [7:0] addr,
    input  logic [7:0] data_in,
    output logic [7:0] data_out,
    output logic        done,
    output logic        busy
);

    // ULTRA-SIMPLIFIED: Reduced from 6 to 4 states
    typedef enum logic [1:0] {
        IDLE,
        ACTIVE,      // Combined write/read active state
        WAIT_ACK
    } state_t;
    
    state_t state, next_state;
    
    // State machine
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    // Next state logic (simplified)
    always_comb begin
        next_state = state;
        case (state)
            IDLE: begin
                if (start) begin
                    next_state = ACTIVE;
                end
            end
            ACTIVE: begin
                next_state = WAIT_ACK;
            end
            WAIT_ACK: begin
                if (sb_ack) begin
                    next_state = IDLE;
                end
            end
        endcase
    end
    
    // Output logic (simplified)
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
                        sb_data_i <= data_in;
                    end
                end
                ACTIVE: begin
                    sb_stb <= 1;  // Assert strobe
                end
                WAIT_ACK: begin
                    sb_stb <= 1;  // Keep strobe asserted
                    if (sb_ack) begin
                        sb_stb <= 0;
                        if (!write_en) begin
                            data_out <= sb_data_o;
                        end
                        done <= 1;
                        busy <= 0;
                    end
                end
            endcase
        end
    end

endmodule
