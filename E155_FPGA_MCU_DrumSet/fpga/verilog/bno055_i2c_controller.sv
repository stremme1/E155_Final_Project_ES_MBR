// BNO055 I2C Controller - EXTREME OPTIMIZATION FOR iCE40UP5K
// Minimal state machine - only 5 states
// Removed initialization (assume BNO055 pre-configured)
// Author: E155 Final Project
// Date: 2024

module bno055_i2c_controller (
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
    output logic [15:0] quat_w,
    output logic [15:0] quat_x,
    output logic [15:0] quat_y,
    output logic [15:0] quat_z,
    output logic signed [15:0] gyro_x,
    output logic signed [15:0] gyro_y,
    output logic signed [15:0] gyro_z,
    output logic        data_valid
);

    // I2C Register Addresses
    localparam I2C_CTRL_REG = 8'h00;
    localparam I2C_RX_REG = 8'h02;
    
    // EXTREME: Only 5 states (removed initialization)
    typedef enum logic [2:0] {
        IDLE,
        READ_START,
        READ_DATA,
        READ_WAIT,
        DATA_READY
    } state_t;
    
    state_t state;
    
    // System Bus Master
    logic sb_start, sb_write_en;
    logic [7:0] sb_addr_in, sb_data_out;
    logic sb_done, sb_busy;
    
    system_bus_master sb_master (
        .clk(clk),
        .rst_n(rst_n),
        .sb_clk(sb_clk),
        .sb_wr(sb_wr),
        .sb_stb(sb_stb),
        .sb_addr(sb_addr),
        .sb_data_i(sb_data_i),
        .sb_data_o(sb_data_o),
        .sb_ack(sb_ack),
        .sb_irq(sb_irq),
        .start(sb_start),
        .write_en(sb_write_en),
        .addr(sb_addr_in),
        .data_in(8'h0),
        .data_out(sb_data_out),
        .done(sb_done),
        .busy(sb_busy)
    );
    
    // EXTREME: Minimal counters and storage
    logic [3:0] read_counter;
    logic [7:0] data_buffer [0:13];
    
    // EXTREME: Single always_ff for everything
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            read_counter <= 0;
            sb_start <= 0;
            sb_write_en <= 0;
            sb_addr_in <= 0;
            data_valid <= 0;
            for (int i = 0; i < 14; i++) data_buffer[i] <= 0;
        end else begin
            sb_start <= 0;
            data_valid <= 0;
            
            case (state)
                IDLE: begin
                    state <= READ_START;
                end
                READ_START: begin
                    if (!sb_busy) begin
                        sb_start <= 1;
                        sb_write_en <= 1;
                        sb_addr_in <= I2C_CTRL_REG;
                        read_counter <= 0;
                        state <= READ_DATA;
                    end
                end
                READ_DATA: begin
                    if (!sb_busy) begin
                        sb_start <= 1;
                        sb_write_en <= 0;
                        sb_addr_in <= I2C_RX_REG;
                        state <= READ_WAIT;
                    end
                end
                READ_WAIT: begin
                    if (sb_done && !sb_busy) begin
                        if (read_counter < 14) begin
                            data_buffer[read_counter] <= sb_data_out;
                            read_counter <= read_counter + 1;
                            state <= READ_DATA;
                        end else begin
                            state <= DATA_READY;
                        end
                    end
                end
                DATA_READY: begin
                    data_valid <= 1;
                    state <= READ_START;
                end
            endcase
        end
    end
    
    // Assemble outputs
    always_comb begin
        quat_w = {data_buffer[1], data_buffer[0]};
        quat_x = {data_buffer[3], data_buffer[2]};
        quat_y = {data_buffer[5], data_buffer[4]};
        quat_z = {data_buffer[7], data_buffer[6]};
        gyro_x = $signed({data_buffer[9], data_buffer[8]});
        gyro_y = $signed({data_buffer[11], data_buffer[10]});
        gyro_z = $signed({data_buffer[13], data_buffer[12]});
    end

endmodule
