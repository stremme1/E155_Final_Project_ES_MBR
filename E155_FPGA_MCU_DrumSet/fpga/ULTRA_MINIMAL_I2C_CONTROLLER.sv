// ULTRA-MINIMAL I2C Controller - ABSOLUTE MINIMUM
// Removed all unnecessary states, simplified to bare minimum
// Author: E155 Final Project
// Date: 2024

module bno055_i2c_controller_ultra_minimal (
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
    output logic signed [15:0] gyro_y,  // Only Y and Z needed for gestures
    output logic signed [15:0] gyro_z,
    output logic        data_valid
);

    // I2C Register Addresses (from datasheet)
    localparam I2C_CTRL_REG = 8'h00;  // Control register
    localparam I2C_RX_REG = 8'h02;    // Receive data register
    
    // ULTRA-MINIMAL: Combined System Bus + I2C FSM (3 states total)
    typedef enum logic [1:0] {
        IDLE = 2'b00,
        WRITE_CTRL = 2'b01,
        READ_DATA = 2'b10
    } state_t;
    
    state_t state;
    logic [1:0] byte_cnt;  // 0=LSB, 1=MSB for Y, 2=LSB, 3=MSB for Z
    logic [7:0] byte_lsb;
    logic signed [15:0] gyro_y_reg, gyro_z_reg;
    logic sb_busy;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            byte_cnt <= 0;
            sb_wr <= 0;
            sb_stb <= 0;
            sb_addr <= 0;
            sb_data_i <= 0;
            sb_busy <= 0;
            data_valid <= 0;
            gyro_y_reg <= 0;
            gyro_z_reg <= 0;
            byte_lsb <= 0;
        end else begin
            data_valid <= 0;
            sb_busy <= sb_stb && !sb_ack;
            
            case (state)
                IDLE: begin
                    sb_stb <= 0;
                    state <= WRITE_CTRL;
                end
                
                WRITE_CTRL: begin
                    if (!sb_busy) begin
                        sb_stb <= 1;
                        sb_wr <= 1;  // Write operation
                        sb_addr <= I2C_CTRL_REG;
                        sb_data_i <= 8'h0;  // Start read command
                    end
                    if (sb_ack && sb_stb) begin
                        sb_stb <= 0;
                        byte_cnt <= 0;
                        state <= READ_DATA;
                    end
                end
                
                READ_DATA: begin
                    if (!sb_busy) begin
                        sb_stb <= 1;
                        sb_wr <= 0;  // Read operation
                        sb_addr <= I2C_RX_REG;
                    end
                    if (sb_ack && sb_stb) begin
                        sb_stb <= 0;
                        case (byte_cnt)
                            2'd0: begin  // Gyro Y LSB
                                byte_lsb <= sb_data_o;
                                byte_cnt <= 1;
                                state <= READ_DATA;  // Continue reading
                            end
                            2'd1: begin  // Gyro Y MSB
                                gyro_y_reg <= $signed({sb_data_o, byte_lsb});
                                byte_lsb <= sb_data_o;
                                byte_cnt <= 2;
                                state <= READ_DATA;  // Continue reading
                            end
                            2'd2: begin  // Gyro Z LSB
                                byte_lsb <= sb_data_o;
                                byte_cnt <= 3;
                                state <= READ_DATA;  // Continue reading
                            end
                            2'd3: begin  // Gyro Z MSB
                                gyro_z_reg <= $signed({sb_data_o, byte_lsb});
                                data_valid <= 1;
                                byte_cnt <= 0;
                                state <= IDLE;
                            end
                        endcase
                    end
                end
            endcase
        end
    end
    
    assign gyro_y = gyro_y_reg;
    assign gyro_z = gyro_z_reg;

endmodule

