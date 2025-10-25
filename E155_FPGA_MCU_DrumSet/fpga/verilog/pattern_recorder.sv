// Pattern Recorder for Drumming Sequences
// SystemVerilog implementation using block RAM
// Author: E155 Final Project
// Date: 2024

module pattern_recorder #(
    parameter ADDR_WIDTH = 16,  // 64K addresses
    parameter DATA_WIDTH = 32,  // 32-bit data
    parameter MAX_PATTERNS = 1000
)(
    input  logic                    clk,
    input  logic                    rst_n,
    input  logic                    record_enable,
    input  logic                    playback_enable,
    input  logic [DATA_WIDTH-1:0]   gesture_data,
    input  logic [15:0]             timestamp,
    input  logic [7:0]              sound_id,
    output logic [DATA_WIDTH-1:0]   playback_data,
    output logic                    playback_ready,
    output logic                    record_full,
    output logic [15:0]             pattern_count
);

    // Block RAM for pattern storage
    logic [DATA_WIDTH-1:0] pattern_memory [0:2**ADDR_WIDTH-1];
    
    // Record/Playback state machine
    typedef enum logic [2:0] {
        IDLE,
        RECORDING,
        PLAYBACK,
        FULL
    } recorder_state_t;
    
    recorder_state_t state, next_state;
    
    // Address counters
    logic [ADDR_WIDTH-1:0] write_addr;
    logic [ADDR_WIDTH-1:0] read_addr;
    logic [ADDR_WIDTH-1:0] pattern_start_addr;
    
    // Pattern management
    logic [15:0] pattern_length;
    logic [15:0] current_pattern;
    logic [15:0] pattern_end_addr;
    
    // Control signals
    logic write_enable;
    logic read_enable;
    logic pattern_start;
    logic pattern_end;
    
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
                if (record_enable) next_state = RECORDING;
                else if (playback_enable) next_state = PLAYBACK;
            end
            RECORDING: begin
                if (!record_enable) next_state = IDLE;
                else if (write_addr >= MAX_PATTERNS) next_state = FULL;
            end
            PLAYBACK: begin
                if (!playback_enable) next_state = IDLE;
                else if (read_addr >= pattern_end_addr) next_state = IDLE;
            end
            FULL: begin
                if (!record_enable) next_state = IDLE;
            end
        endcase
    end
    
    // Write control
    always_comb begin
        write_enable = (state == RECORDING) && record_enable;
        read_enable = (state == PLAYBACK) && playback_enable;
    end
    
    // Address management
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            write_addr <= 0;
            read_addr <= 0;
            pattern_count <= 0;
        end else begin
            case (state)
                RECORDING: begin
                    if (write_enable) begin
                        write_addr <= write_addr + 1;
                        if (pattern_start) begin
                            pattern_count <= pattern_count + 1;
                            pattern_start_addr <= write_addr;
                        end
                    end
                end
                PLAYBACK: begin
                    if (read_enable) begin
                        read_addr <= read_addr + 1;
                    end
                end
                IDLE: begin
                    read_addr <= pattern_start_addr;
                end
            endcase
        end
    end
    
    // Pattern start detection
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pattern_start <= 1'b0;
        end else begin
            pattern_start <= (state == RECORDING) && (sound_id != 0);
        end
    end
    
    // Pattern end detection
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pattern_end <= 1'b0;
        end else begin
            pattern_end <= (state == RECORDING) && (sound_id == 0) && (write_addr > pattern_start_addr);
        end
    end
    
    // Memory write
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Initialize memory
            for (int i = 0; i < 2**ADDR_WIDTH; i++) begin
                pattern_memory[i] <= 0;
            end
        end else begin
            if (write_enable) begin
                pattern_memory[write_addr] <= {sound_id, timestamp, gesture_data[23:0]};
            end
        end
    end
    
    // Memory read
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            playback_data <= 0;
        end else begin
            if (read_enable) begin
                playback_data <= pattern_memory[read_addr];
            end
        end
    end
    
    // Output control
    assign playback_ready = (state == PLAYBACK) && read_enable;
    assign record_full = (state == FULL);
    
    // Pattern length calculation
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pattern_length <= 0;
        end else begin
            if (pattern_end) begin
                pattern_length <= write_addr - pattern_start_addr;
                pattern_end_addr <= write_addr;
            end
        end
    end

endmodule
