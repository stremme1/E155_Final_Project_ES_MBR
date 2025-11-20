// BNO055 I2C Controller - ULTRA-SIMPLIFIED FOR iCE40UP5K
// Drastically reduced state machine to save LUTs
// Uses counter-based reading instead of individual states
// Author: E155 Final Project
// Date: 2024

module bno055_i2c_controller (
    input  logic        clk,
    input  logic        rst_n,
    
    // System Bus Interface to I2C Hard IP
    input  logic        sb_clk,
    output logic        sb_wr,
    output logic        sb_stb,
    output logic [7:0]  sb_addr,
    output logic [7:0]  sb_data_i,
    input  logic [7:0]  sb_data_o,
    input  logic        sb_ack,
    input  logic        sb_irq,
    
    // Sensor Data Output
    output logic [15:0] quat_w,
    output logic [15:0] quat_x,
    output logic [15:0] quat_y,
    output logic [15:0] quat_z,
    output logic signed [15:0] gyro_x,
    output logic signed [15:0] gyro_y,
    output logic signed [15:0] gyro_z,
    output logic        data_valid
);

    // BNO055 I2C Address
    localparam BNO055_ADDR = 7'h28;
    localparam BNO055_REG_OPR_MODE = 8'h3D;
    localparam BNO055_MODE_NDOF = 8'h0C;
    localparam BNO055_QUAT_W_LSB = 8'h20;
    localparam BNO055_GYRO_X_LSB = 8'h14;
    
    // I2C Register Addresses
    localparam I2C_CTRL_REG = 8'h00;
    localparam I2C_TX_REG = 8'h01;
    localparam I2C_RX_REG = 8'h02;
    
    // ULTRA-SIMPLIFIED: Reduced from 25 states to 8 states
    typedef enum logic [2:0] {
        IDLE,
        INIT_MODE,      // Set mode (skip soft reset to save states)
        INIT_WAIT,      // Wait after mode set
        READ_START,     // Start read transaction
        READ_DATA,       // Read data bytes (counter-based)
        READ_WAIT,      // Wait for read complete
        DATA_READY      // Data ready
    } state_t;
    
    state_t state, next_state;
    
    // System Bus Master (simplified)
    logic sb_start, sb_write_en;
    logic [7:0] sb_addr_in, sb_data_in, sb_data_out;
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
        .data_in(sb_data_in),
        .data_out(sb_data_out),
        .done(sb_done),
        .busy(sb_busy)
    );
    
    // ULTRA-SIMPLIFIED: Counter-based reading instead of individual states
    logic [3:0] read_counter;  // 0-13 for 14 bytes (4 quat + 3 gyro, each 2 bytes)
    logic [15:0] delay_counter;
    logic init_complete;
    
    // Data storage - ULTRA-OPTIMIZED: Individual registers instead of array
    // This avoids expensive variable-indexed array access (multiplexers)
    logic [7:0] data_0, data_1, data_2, data_3, data_4, data_5, data_6, data_7;
    logic [7:0] data_8, data_9, data_10, data_11, data_12, data_13;
    
    // State machine
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            read_counter <= 0;
            delay_counter <= 0;
            init_complete <= 0;
            data_valid <= 0;
            // Explicit reset (no for loop - saves LUTs)
            data_0 <= 0; data_1 <= 0; data_2 <= 0; data_3 <= 0;
            data_4 <= 0; data_5 <= 0; data_6 <= 0; data_7 <= 0;
            data_8 <= 0; data_9 <= 0; data_10 <= 0; data_11 <= 0;
            data_12 <= 0; data_13 <= 0;
        end else begin
            state <= next_state;
            data_valid <= 0;
            
            // Simple delay counter
            if (delay_counter > 0) begin
                delay_counter <= delay_counter - 1;
            end
            
            // Store read data - ULTRA-OPTIMIZED: Direct assignment instead of array indexing
            // This avoids expensive multiplexers for variable indexing
            if (sb_done && !sb_busy && !sb_write_en && state == READ_WAIT) begin
                case (read_counter)
                    4'd0: data_0 <= sb_data_out;
                    4'd1: data_1 <= sb_data_out;
                    4'd2: data_2 <= sb_data_out;
                    4'd3: data_3 <= sb_data_out;
                    4'd4: data_4 <= sb_data_out;
                    4'd5: data_5 <= sb_data_out;
                    4'd6: data_6 <= sb_data_out;
                    4'd7: data_7 <= sb_data_out;
                    4'd8: data_8 <= sb_data_out;
                    4'd9: data_9 <= sb_data_out;
                    4'd10: data_10 <= sb_data_out;
                    4'd11: data_11 <= sb_data_out;
                    4'd12: data_12 <= sb_data_out;
                    4'd13: data_13 <= sb_data_out;
                endcase
            end
            
            // Mark data ready
            if (state == DATA_READY) begin
                data_valid <= 1;
            end
            
            // Mark init complete
            if (state == INIT_WAIT && delay_counter == 0) begin
                init_complete <= 1;
            end
        end
    end
    
    // Next state logic (simplified)
    always_comb begin
        next_state = state;
        case (state)
            IDLE: begin
                if (!init_complete) begin
                    next_state = INIT_MODE;
                end else begin
                    next_state = READ_START;
                end
            end
            INIT_MODE: begin
                if (sb_done && !sb_busy) begin
                    next_state = INIT_WAIT;
                end
            end
            INIT_WAIT: begin
                if (delay_counter == 0) begin
                    next_state = READ_START;
                end
            end
            READ_START: begin
                if (sb_done && !sb_busy) begin
                    next_state = READ_DATA;
                end
            end
            READ_DATA: begin
                if (sb_done && !sb_busy) begin
                    next_state = READ_WAIT;
                end
            end
            READ_WAIT: begin
                if (sb_done && !sb_busy) begin
                    if (read_counter >= 13) begin
                        next_state = DATA_READY;
                    end else begin
                        next_state = READ_DATA;
                    end
                end
            end
            DATA_READY: begin
                if (delay_counter == 0) begin
                    next_state = READ_START;
                end
            end
        endcase
    end
    
    // Control logic (simplified)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sb_start <= 0;
            sb_write_en <= 0;
            sb_addr_in <= 0;
            sb_data_in <= 0;
            read_counter <= 0;
            delay_counter <= 0;
        end else begin
            sb_start <= 0;
            
            case (state)
                INIT_MODE: begin
                    if (!sb_busy) begin
                        sb_start <= 1;
                        sb_write_en <= 1;
                        sb_addr_in <= I2C_TX_REG;
                        sb_data_in <= BNO055_MODE_NDOF;
                        delay_counter <= 16'd100;  // Reduced delay
                    end
                end
                READ_START: begin
                    if (!sb_busy) begin
                        sb_start <= 1;
                        sb_write_en <= 1;
                        sb_addr_in <= I2C_CTRL_REG;
                        sb_data_in <= 8'h01;  // Start read
                        read_counter <= 0;
                    end
                end
                READ_DATA: begin
                    if (!sb_busy) begin
                        sb_start <= 1;
                        sb_write_en <= 0;  // Read
                        sb_addr_in <= I2C_RX_REG;
                    end
                end
                READ_WAIT: begin
                    if (sb_done && !sb_busy) begin
                        read_counter <= read_counter + 1;
                    end
                end
                DATA_READY: begin
                    if (delay_counter == 0) begin
                        delay_counter <= 16'd10;  // Small delay
                    end
                end
                default: begin end
            endcase
        end
    end
    
    // Assemble outputs from registers (ultra-optimized - no array indexing)
    always_comb begin
        quat_w = {data_1, data_0};   // MSB, LSB
        quat_x = {data_3, data_2};
        quat_y = {data_5, data_4};
        quat_z = {data_7, data_6};
        gyro_x = $signed({data_9, data_8});
        gyro_y = $signed({data_11, data_10});
        gyro_z = $signed({data_13, data_12});
    end

endmodule
