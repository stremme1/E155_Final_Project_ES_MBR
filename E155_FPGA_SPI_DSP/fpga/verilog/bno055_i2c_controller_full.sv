// BNO055 I²C Controller - Full Data (Quaternion + Gyroscope)
// Reads quaternion (w,x,y,z) and gyroscope (x,y,z) from BNO055
// Uses iCE40UP5K hardened I²C IP blocks via System Bus
// Author: E155 Final Project
// Date: 2024

module bno055_i2c_controller_full (
    input  logic        clk,
    input  logic        rst_n,
    
    // System Bus Interface (to I²C IP)
    input  logic        sb_clk,
    output logic        sb_wr,
    output logic        sb_stb,
    output logic [7:0]  sb_addr,
    output logic [7:0]  sb_data_i,
    input  logic [7:0]  sb_data_o,
    input  logic        sb_ack,
    input  logic        sb_irq,
    
    // BNO055 I²C Address
    input  logic [7:0]  i2c_address,  // 0x28 or 0x29
    
    // Output Data
    output logic signed [15:0] quat_w, quat_x, quat_y, quat_z,  // Quaternion (scaled by 16384)
    output logic signed [15:0] gyro_x, gyro_y, gyro_z,          // Gyroscope
    output logic        data_valid
);

    // BNO055 Register Addresses (from bno055.h)
    localparam BNO055_QUATERNION_DATA_W_LSB_ADDR = 8'h20;
    localparam BNO055_GYRO_DATA_X_LSB_ADDR = 8'h14;
    
    // System Bus Register Addresses (I²C IP)
    localparam I2C_CTRL_REG = 8'h00;  // I²C Control Register
    localparam I2C_TX_REG = 8'h01;    // I²C Transmit Data Register
    localparam I2C_RX_REG = 8'h02;    // I²C Receive Data Register
    localparam I2C_STAT_REG = 8'h03;  // I²C Status Register
    
    // State Machine
    typedef enum logic [3:0] {
        IDLE,
        READ_QUAT_START,
        READ_QUAT_WAIT,
        READ_QUAT_DATA,      // Read 8 bytes (w,x,y,z)
        READ_GYRO_START,
        READ_GYRO_WAIT,
        READ_GYRO_DATA,      // Read 6 bytes (x,y,z)
        DATA_READY
    } state_t;
    
    state_t state;
    logic [2:0] byte_counter;
    logic [7:0] read_buffer [0:13];  // 8 bytes quat + 6 bytes gyro
    
    // System Bus Master (inlined for efficiency)
    logic sb_busy, sb_done;
    logic sb_start, sb_write_en;
    logic [7:0] sb_addr_in;
    
    // System Bus Master FSM
    typedef enum logic {
        SB_IDLE = 1'b0,
        SB_WAIT_ACK = 1'b1
    } sb_state_t;
    
    sb_state_t sb_state;
    
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
    
    // Main Controller FSM
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            byte_counter <= 0;
            sb_start <= 0;
            sb_write_en <= 0;
            sb_addr_in <= 0;
            data_valid <= 0;
            quat_w <= 0;
            quat_x <= 0;
            quat_y <= 0;
            quat_z <= 0;
            gyro_x <= 0;
            gyro_y <= 0;
            gyro_z <= 0;
        end else begin
            sb_start <= 0;
            data_valid <= 0;
            
            case (state)
                IDLE: begin
                    state <= READ_QUAT_START;
                    byte_counter <= 0;
                end
                
                READ_QUAT_START: begin
                    if (!sb_busy) begin
                        // Start I²C read transaction for quaternion
                        // Write I²C address + read bit to control register
                        sb_start <= 1;
                        sb_write_en <= 1;
                        sb_addr_in <= I2C_CTRL_REG;
                        // TODO: Set up I²C transaction (address, register, read)
                        state <= READ_QUAT_WAIT;
                    end
                end
                
                READ_QUAT_WAIT: begin
                    if (sb_done && !sb_busy) begin
                        state <= READ_QUAT_DATA;
                    end
                end
                
                READ_QUAT_DATA: begin
                    if (!sb_busy) begin
                        sb_start <= 1;
                        sb_write_en <= 0;
                        sb_addr_in <= I2C_RX_REG;
                        state <= READ_QUAT_WAIT;
                    end else if (sb_done) begin
                        read_buffer[byte_counter] <= sb_data_o;
                        if (byte_counter < 7) begin
                            byte_counter <= byte_counter + 1;
                            state <= READ_QUAT_DATA;
                        end else begin
                            // Assemble quaternion (16-bit signed, LSB first)
                            quat_w <= $signed({read_buffer[1], read_buffer[0]});
                            quat_x <= $signed({read_buffer[3], read_buffer[2]});
                            quat_y <= $signed({read_buffer[5], read_buffer[4]});
                            quat_z <= $signed({read_buffer[7], read_buffer[6]});
                            byte_counter <= 0;
                            state <= READ_GYRO_START;
                        end
                    end
                end
                
                READ_GYRO_START: begin
                    if (!sb_busy) begin
                        // Start I²C read transaction for gyroscope
                        sb_start <= 1;
                        sb_write_en <= 1;
                        sb_addr_in <= I2C_CTRL_REG;
                        // TODO: Set up I²C transaction
                        state <= READ_GYRO_WAIT;
                    end
                end
                
                READ_GYRO_WAIT: begin
                    if (sb_done && !sb_busy) begin
                        state <= READ_GYRO_DATA;
                    end
                end
                
                READ_GYRO_DATA: begin
                    if (!sb_busy) begin
                        sb_start <= 1;
                        sb_write_en <= 0;
                        sb_addr_in <= I2C_RX_REG;
                        state <= READ_GYRO_WAIT;
                    end else if (sb_done) begin
                        read_buffer[byte_counter] <= sb_data_o;
                        if (byte_counter < 5) begin
                            byte_counter <= byte_counter + 1;
                            state <= READ_GYRO_DATA;
                        end else begin
                            // Assemble gyroscope (16-bit signed, LSB first)
                            gyro_x <= $signed({read_buffer[1], read_buffer[0]});
                            gyro_y <= $signed({read_buffer[3], read_buffer[2]});
                            gyro_z <= $signed({read_buffer[5], read_buffer[4]});
                            state <= DATA_READY;
                        end
                    end
                end
                
                DATA_READY: begin
                    data_valid <= 1;
                    state <= READ_QUAT_START;  // Start next cycle
                end
            endcase
        end
    end

endmodule

