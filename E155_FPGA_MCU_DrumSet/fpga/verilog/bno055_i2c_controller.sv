// BNO055 I2C Controller - NO BUFFER VERSION (ASSEMBLE ON-THE-FLY)
// Removed data buffer - assemble quaternion/gyro data directly as bytes arrive
// Saves 112 flip-flops per controller = ~224 LUTs per controller
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
    
    // EXTREME: Only 5 states
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
    
    // RESOURCE OPTIMIZATION: No buffer - assemble data directly
    // Store only the 16-bit values (8 registers instead of 14)
    logic [3:0] read_counter;
    logic [7:0] byte_lsb, byte_msb;
    logic [15:0] quat_w_reg, quat_x_reg, quat_y_reg, quat_z_reg;
    logic signed [15:0] gyro_x_reg, gyro_y_reg, gyro_z_reg;
    
    // EXTREME: Single always_ff for everything
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            read_counter <= 0;
            sb_start <= 0;
            sb_write_en <= 0;
            sb_addr_in <= 0;
            data_valid <= 0;
            quat_w_reg <= 0;
            quat_x_reg <= 0;
            quat_y_reg <= 0;
            quat_z_reg <= 0;
            gyro_x_reg <= 0;
            gyro_y_reg <= 0;
            gyro_z_reg <= 0;
            byte_lsb <= 0;
            byte_msb <= 0;
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
                            // Assemble data on-the-fly based on byte position
                            case (read_counter)
                                4'd0: byte_lsb <= sb_data_out;  // quat_w LSB
                                4'd1: quat_w_reg <= {sb_data_out, byte_lsb};  // quat_w MSB
                                4'd2: byte_lsb <= sb_data_out;  // quat_x LSB
                                4'd3: quat_x_reg <= {sb_data_out, byte_lsb};  // quat_x MSB
                                4'd4: byte_lsb <= sb_data_out;  // quat_y LSB
                                4'd5: quat_y_reg <= {sb_data_out, byte_lsb};  // quat_y MSB
                                4'd6: byte_lsb <= sb_data_out;  // quat_z LSB
                                4'd7: quat_z_reg <= {sb_data_out, byte_lsb};  // quat_z MSB
                                4'd8: byte_lsb <= sb_data_out;  // gyro_x LSB
                                4'd9: gyro_x_reg <= $signed({sb_data_out, byte_lsb});  // gyro_x MSB
                                4'd10: byte_lsb <= sb_data_out;  // gyro_y LSB
                                4'd11: gyro_y_reg <= $signed({sb_data_out, byte_lsb});  // gyro_y MSB
                                4'd12: byte_lsb <= sb_data_out;  // gyro_z LSB
                                4'd13: gyro_z_reg <= $signed({sb_data_out, byte_lsb});  // gyro_z MSB
                            endcase
                            
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
    
    // Outputs directly from registers
    assign quat_w = quat_w_reg;
    assign quat_x = quat_x_reg;
    assign quat_y = quat_y_reg;
    assign quat_z = quat_z_reg;
    assign gyro_x = gyro_x_reg;
    assign gyro_y = gyro_y_reg;
    assign gyro_z = gyro_z_reg;

endmodule
