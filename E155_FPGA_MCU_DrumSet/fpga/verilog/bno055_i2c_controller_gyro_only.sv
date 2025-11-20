// BNO055 I2C Controller - GYRO ONLY + INLINED SYSTEM BUS
// Reads only gyroscope data (3 bytes instead of 14)
// Inlined system bus master to save module overhead
// Author: E155 Final Project
// Date: 2024

module bno055_i2c_controller_gyro_only (
    input  logic        clk,
    input  logic        rst_n,
    // REMOVED: sb_clk (not used, we use clk directly)
    output logic        sb_wr,
    output logic        sb_stb,
    output logic [7:0]  sb_addr,
    output logic [7:0]  sb_data_i,
    input  logic [7:0]  sb_data_o,
    input  logic        sb_ack,
    input  logic        sb_irq,
    output logic signed [15:0] gyro_x,
    output logic signed [15:0] gyro_y,
    output logic signed [15:0] gyro_z,
    output logic        data_valid
);

    localparam I2C_CTRL_REG = 8'h00;
    localparam I2C_RX_REG = 8'h02;
    
    // INLINED: System Bus Master (2-state FSM)
    typedef enum logic {
        SB_IDLE = 1'b0,
        SB_WAIT_ACK = 1'b1
    } sb_state_t;
    
    sb_state_t sb_state;
    logic sb_start, sb_write_en;
    logic [7:0] sb_addr_in;
    logic sb_done, sb_busy;
    
    // FIX: Remove unused sb_clk input (we use clk directly)
    // sb_clk is not used in inlined system bus master
    
    // INLINED System Bus Master
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sb_state <= SB_IDLE;
            sb_wr <= 0;
            sb_stb <= 0;
            sb_addr <= 0;
            sb_data_i <= 0;
            sb_done <= 0;
            sb_busy <= 0;
        end else begin
            sb_done <= 0;
            case (sb_state)
                SB_IDLE: begin
                    sb_stb <= 0;
                    sb_busy <= 0;
                    if (sb_start) begin
                        sb_state <= SB_WAIT_ACK;
                        sb_busy <= 1;
                        sb_addr <= sb_addr_in;
                        sb_wr <= sb_write_en;
                        sb_data_i <= 8'h0;
                        sb_stb <= 1;
                    end
                end
                SB_WAIT_ACK: begin
                    sb_stb <= 1;
                    if (sb_ack) begin
                        sb_stb <= 0;
                        sb_done <= 1;
                        sb_busy <= 0;
                        sb_state <= SB_IDLE;
                    end
                end
            endcase
        end
    end
    
    // I2C Controller - GYRO ONLY (3 bytes: X, Y, Z)
    typedef enum logic [2:0] {
        IDLE_CTRL,
        READ_START,
        WAIT_START_ACK,
        READ_DATA,
        WAIT_DATA_ACK,
        DATA_READY
    } state_t;
    
    state_t state;
    logic [1:0] read_counter;  // 0-2 for 3 bytes
    logic [7:0] byte_lsb;
    logic signed [15:0] gyro_x_reg, gyro_y_reg, gyro_z_reg;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE_CTRL;
            read_counter <= 0;
            sb_start <= 0;
            sb_write_en <= 0;
            sb_addr_in <= 0;
            data_valid <= 0;
            gyro_x_reg <= 0;
            gyro_y_reg <= 0;
            gyro_z_reg <= 0;
            byte_lsb <= 0;
        end else begin
            sb_start <= 0;
            data_valid <= 0;
            
            case (state)
                IDLE_CTRL: begin
                    state <= READ_START;
                end
                READ_START: begin
                    if (!sb_busy) begin
                        sb_start <= 1;
                        sb_write_en <= 1;
                        sb_addr_in <= I2C_CTRL_REG;  // 8'h00
                        read_counter <= 0;
                        state <= WAIT_START_ACK;
                    end
                end
                WAIT_START_ACK: begin
                    if (sb_done && !sb_busy) begin
                        state <= READ_DATA;
                    end
                end
                READ_DATA: begin
                    if (!sb_busy) begin
                        sb_start <= 1;
                        sb_write_en <= 0;
                        sb_addr_in <= I2C_RX_REG;  // 8'h02 - only bit 1 is set
                        state <= WAIT_DATA_ACK;
                    end
                end
                WAIT_DATA_ACK: begin
                    if (sb_done && !sb_busy) begin
                        if (read_counter < 3) begin
                            case (read_counter)
                                2'd0: begin
                                    byte_lsb <= sb_data_o;
                                    read_counter <= 1;
                                end
                                2'd1: begin
                                    gyro_x_reg <= $signed({sb_data_o, byte_lsb});
                                    byte_lsb <= sb_data_o;
                                    read_counter <= 2;
                                end
                                2'd2: begin
                                    gyro_y_reg <= $signed({sb_data_o, byte_lsb});
                                    byte_lsb <= sb_data_o;
                                    read_counter <= 3;
                                end
                            endcase
                            state <= READ_DATA;
                        end else begin
                            gyro_z_reg <= $signed({sb_data_o, byte_lsb});
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
    
    assign gyro_x = gyro_x_reg;
    assign gyro_y = gyro_y_reg;
    assign gyro_z = gyro_z_reg;

endmodule
