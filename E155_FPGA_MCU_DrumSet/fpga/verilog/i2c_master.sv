// I2C Master Controller for BNO055 IMU Sensors
// SystemVerilog implementation for UPduino v3.1
// Author: E155 Final Project
// Date: 2024

module i2c_master #(
    parameter CLK_FREQ = 16000000,  // 16MHz clock
    parameter I2C_FREQ = 400000     // 400kHz I2C Fast Mode
)(
    input  logic        clk,
    input  logic        rst_n,
    input  logic        start,
    input  logic        stop,
    input  logic [6:0]  device_addr,
    input  logic [7:0]  reg_addr,
    input  logic [7:0]  write_data,
    output logic [7:0]  read_data,
    output logic        i2c_done,
    output logic        i2c_busy,
    inout  wire         sda,
    output logic        scl
);

    // I2C state machine with error handling
    typedef enum logic [4:0] {
        IDLE,
        START,
        ADDR_WRITE,
        ADDR_ACK,
        REG_WRITE,
        REG_ACK,
        DATA_WRITE,
        DATA_ACK,
        RESTART,
        ADDR_READ,
        ADDR_ACK_READ,
        DATA_READ,
        DATA_NACK,
        STOP_STATE,
        ERROR_STATE,
        TIMEOUT_STATE,
        RETRY_STATE
    } i2c_state_t;

    i2c_state_t state, next_state;
    
    // I2C timing parameters
    localparam CLK_DIV = CLK_FREQ / (I2C_FREQ * 4);
    localparam CLK_HALF = CLK_DIV / 2;
    localparam TIMEOUT_CYCLES = CLK_FREQ / 1000; // 1ms timeout
    
    logic [7:0] clk_counter;
    logic [15:0] timeout_counter;
    logic scl_enable;
    logic sda_out;
    logic sda_oe;
    logic [2:0] retry_count;
    logic error_flag;
    logic timeout_flag;
    
    // Clock generation with timeout handling
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_counter <= 0;
            timeout_counter <= 0;
            scl <= 1;
            error_flag <= 0;
            timeout_flag <= 0;
            retry_count <= 0;
        end else begin
            // Timeout counter
            if (timeout_counter < TIMEOUT_CYCLES) begin
                timeout_counter <= timeout_counter + 1;
            end else begin
                timeout_flag <= 1;
            end
            
            // Clock generation
            if (clk_counter < CLK_DIV - 1) begin
                clk_counter <= clk_counter + 1;
            end else begin
                clk_counter <= 0;
                scl <= ~scl;
            end
        end
    end
    
    // SDA control
    assign sda = sda_oe ? sda_out : 1'bz;
    
    // State machine
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    // Next state logic with error handling
    always_comb begin
        next_state = state;
        case (state)
            IDLE: begin
                if (start) next_state = START;
            end
            START: begin
                if (timeout_flag) next_state = TIMEOUT_STATE;
                else if (clk_counter == CLK_HALF) next_state = ADDR_WRITE;
            end
            ADDR_WRITE: begin
                if (timeout_flag) next_state = TIMEOUT_STATE;
                else if (clk_counter == CLK_DIV - 1) next_state = ADDR_ACK;
            end
            ADDR_ACK: begin
                if (timeout_flag) next_state = TIMEOUT_STATE;
                else if (clk_counter == CLK_DIV - 1) next_state = REG_WRITE;
            end
            REG_WRITE: begin
                if (timeout_flag) next_state = TIMEOUT_STATE;
                else if (clk_counter == CLK_DIV - 1) next_state = REG_ACK;
            end
            REG_ACK: begin
                if (timeout_flag) next_state = TIMEOUT_STATE;
                else if (clk_counter == CLK_DIV - 1) next_state = DATA_WRITE;
            end
            DATA_WRITE: begin
                if (timeout_flag) next_state = TIMEOUT_STATE;
                else if (clk_counter == CLK_DIV - 1) next_state = DATA_ACK;
            end
            DATA_ACK: begin
                if (timeout_flag) next_state = TIMEOUT_STATE;
                else if (clk_counter == CLK_DIV - 1) next_state = STOP_STATE;
            end
            STOP_STATE: begin
                if (clk_counter == CLK_DIV - 1) next_state = IDLE;
            end
            ERROR_STATE: begin
                if (retry_count < 3) next_state = RETRY_STATE;
                else next_state = IDLE;
            end
            TIMEOUT_STATE: begin
                if (retry_count < 3) next_state = RETRY_STATE;
                else next_state = ERROR_STATE;
            end
            RETRY_STATE: begin
                next_state = START;
            end
        endcase
    end
    
    // Output logic
    always_comb begin
        i2c_done = (state == IDLE);
        i2c_busy = (state != IDLE);
        scl_enable = (state != IDLE);
        sda_oe = 1'b1;
        sda_out = 1'b1;
        
        case (state)
            START: begin
                sda_out = 1'b0;
            end
            ADDR_WRITE: begin
                sda_out = device_addr[6];
            end
            REG_WRITE: begin
                sda_out = reg_addr[7];
            end
            DATA_WRITE: begin
                sda_out = write_data[7];
            end
            STOP_STATE: begin
                sda_out = 1'b0;
            end
        endcase
    end

endmodule
