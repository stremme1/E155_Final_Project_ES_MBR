// BNO055 I2C Controller
// Manages I2C communication with BNO055 IMU sensor via System Bus
// Reads quaternion and gyroscope data
// Author: E155 Final Project
// Date: 2024

module bno055_i2c_controller (
    input  logic        clk,
    input  logic        rst_n,
    
    // System Bus Interface to I2C Hard IP
    // Note: sb_clk is an input - clock is driven by top module
    input  logic        sb_clk,      // System Bus clock (driven by top module)
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
    output logic signed [15:0] gyro_x,  // Gyro values are signed
    output logic signed [15:0] gyro_y,  // Gyro values are signed
    output logic signed [15:0] gyro_z,  // Gyro values are signed
    output logic        data_valid
);

    // BNO055 I2C Address (default 0x28, can be 0x29 if ADR pin is high)
    localparam BNO055_ADDR = 7'h28;
    
    // BNO055 Register Addresses
    localparam BNO055_REG_PAGE_ID = 8'h07;
    localparam BNO055_REG_CHIP_ID = 8'h00;
    localparam BNO055_REG_OPR_MODE = 8'h3D;  // Operation mode register
    localparam BNO055_REG_SYS_TRIGGER = 8'h3F;  // System trigger register (soft reset)
    localparam BNO055_QUAT_W_LSB = 8'h20;
    localparam BNO055_QUAT_W_MSB = 8'h21;
    localparam BNO055_QUAT_X_LSB = 8'h22;
    localparam BNO055_QUAT_X_MSB = 8'h23;
    localparam BNO055_QUAT_Y_LSB = 8'h24;
    localparam BNO055_QUAT_Y_MSB = 8'h25;
    localparam BNO055_QUAT_Z_LSB = 8'h26;
    localparam BNO055_QUAT_Z_MSB = 8'h27;
    localparam BNO055_GYRO_X_LSB = 8'h14;
    localparam BNO055_GYRO_X_MSB = 8'h15;
    localparam BNO055_GYRO_Y_LSB = 8'h16;
    localparam BNO055_GYRO_Y_MSB = 8'h17;
    localparam BNO055_GYRO_Z_LSB = 8'h18;
    localparam BNO055_GYRO_Z_MSB = 8'h19;
    
    // BNO055 Operation Modes
    localparam BNO055_MODE_CONFIG = 8'h00;
    localparam BNO055_MODE_NDOF = 8'h0C;  // NDOF fusion mode
    
    // I2C Control Register Addresses (System Bus addresses)
    // Note: These are typical addresses. Actual addresses depend on Module Generator output
    // Typical I2C IP register map:
    // 0x00: Control Register (start/stop I2C, enable)
    // 0x01: Transmit Data Register (slave address, register address, data)
    // 0x02: Receive Data Register (read data)
    // 0x03: Status Register (busy, error flags)
    localparam I2C_CTRL_REG = 8'h00;  // I2C Control Register
    localparam I2C_TX_REG = 8'h01;     // I2C Transmit Data Register
    localparam I2C_RX_REG = 8'h02;     // I2C Receive Data Register
    localparam I2C_STATUS_REG = 8'h03; // I2C Status Register
    
    // Delay counters (for 16MHz clock)
    // 650ms = 650,000,000ns / 62.5ns = 10,400,000 cycles
    // For simulation, use smaller values
    localparam DELAY_650MS = 16'd1000;  // Reduced for simulation
    localparam DELAY_30MS = 16'd100;    // Reduced for simulation
    localparam DELAY_I2C = 16'd10;      // Delay between I2C transactions
    
    typedef enum logic [5:0] {
        IDLE,
        // Initialization sequence
        INIT_RESET_WRITE,
        INIT_RESET_WAIT,
        INIT_RESET_DELAY,
        INIT_MODE_WRITE,
        INIT_MODE_WAIT,
        INIT_MODE_DELAY,
        // Reading sequence
        READ_START,
        READ_QUAT_W_LSB,
        READ_QUAT_W_MSB,
        READ_QUAT_X_LSB,
        READ_QUAT_X_MSB,
        READ_QUAT_Y_LSB,
        READ_QUAT_Y_MSB,
        READ_QUAT_Z_LSB,
        READ_QUAT_Z_MSB,
        READ_GYRO_X_LSB,
        READ_GYRO_X_MSB,
        READ_GYRO_Y_LSB,
        READ_GYRO_Y_MSB,
        READ_GYRO_Z_LSB,
        READ_GYRO_Z_MSB,
        DATA_READY
    } state_t;
    
    state_t state, next_state;
    
    // System Bus Master instance
    logic sb_start;
    logic sb_write_en;
    logic [7:0] sb_addr_in;
    logic [7:0] sb_data_in;
    logic [7:0] sb_data_out;
    logic sb_done;
    logic sb_busy;
    
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
    
    // Data registers
    logic [7:0] quat_w_lsb, quat_w_msb;
    logic [7:0] quat_x_lsb, quat_x_msb;
    logic [7:0] quat_y_lsb, quat_y_msb;
    logic [7:0] quat_z_lsb, quat_z_msb;
    logic [7:0] gyro_x_lsb, gyro_x_msb;
    logic [7:0] gyro_y_lsb, gyro_y_msb;
    logic [7:0] gyro_z_lsb, gyro_z_msb;
    
    // Counter for delays
    logic [15:0] delay_counter;
    
    // Initialization complete flag
    logic init_complete;
    
    // State machine
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            delay_counter <= 0;
            data_valid <= 0;
            init_complete <= 0;
            quat_w_lsb <= 0;
            quat_w_msb <= 0;
            quat_x_lsb <= 0;
            quat_x_msb <= 0;
            quat_y_lsb <= 0;
            quat_y_msb <= 0;
            quat_z_lsb <= 0;
            quat_z_msb <= 0;
            gyro_x_lsb <= 0;
            gyro_x_msb <= 0;
            gyro_y_lsb <= 0;
            gyro_y_msb <= 0;
            gyro_z_lsb <= 0;
            gyro_z_msb <= 0;
        end else begin
            state <= next_state;
            data_valid <= 0;
            
            if (state == DATA_READY) begin
                data_valid <= 1;
            end
            
            // Decrement delay counter
            if (delay_counter > 0) begin
                delay_counter <= delay_counter - 1;
            end
            
            // Store data when read completes
            if (sb_done && !sb_busy && !sb_write_en) begin
                case (state)
                    READ_QUAT_W_LSB: quat_w_lsb <= sb_data_out;
                    READ_QUAT_W_MSB: quat_w_msb <= sb_data_out;
                    READ_QUAT_X_LSB: quat_x_lsb <= sb_data_out;
                    READ_QUAT_X_MSB: quat_x_msb <= sb_data_out;
                    READ_QUAT_Y_LSB: quat_y_lsb <= sb_data_out;
                    READ_QUAT_Y_MSB: quat_y_msb <= sb_data_out;
                    READ_QUAT_Z_LSB: quat_z_lsb <= sb_data_out;
                    READ_QUAT_Z_MSB: quat_z_msb <= sb_data_out;
                    READ_GYRO_X_LSB: gyro_x_lsb <= sb_data_out;
                    READ_GYRO_X_MSB: gyro_x_msb <= sb_data_out;
                    READ_GYRO_Y_LSB: gyro_y_lsb <= sb_data_out;
                    READ_GYRO_Y_MSB: gyro_y_msb <= sb_data_out;
                    READ_GYRO_Z_LSB: gyro_z_lsb <= sb_data_out;
                    READ_GYRO_Z_MSB: gyro_z_msb <= sb_data_out;
                    default: begin end
                endcase
            end
            
            // Mark initialization complete
            if (state == INIT_MODE_DELAY && delay_counter == 0) begin
                init_complete <= 1;
            end
        end
    end
    
    // Next state logic
    always_comb begin
        next_state = state;
        case (state)
            IDLE: begin
                if (!init_complete) begin
                    next_state = INIT_RESET_WRITE;
                end else begin
                    next_state = READ_START;
                end
            end
            
            // Initialization: Soft reset
            INIT_RESET_WRITE: begin
                if (sb_done && !sb_busy) begin
                    next_state = INIT_RESET_WAIT;
                end
            end
            INIT_RESET_WAIT: begin
                if (delay_counter == 0) begin
                    next_state = INIT_RESET_DELAY;
                end
            end
            INIT_RESET_DELAY: begin
                if (delay_counter == 0) begin
                    next_state = INIT_MODE_WRITE;
                end
            end
            
            // Initialization: Set operation mode to NDOF
            INIT_MODE_WRITE: begin
                if (sb_done && !sb_busy) begin
                    next_state = INIT_MODE_WAIT;
                end
            end
            INIT_MODE_WAIT: begin
                if (delay_counter == 0) begin
                    next_state = INIT_MODE_DELAY;
                end
            end
            INIT_MODE_DELAY: begin
                if (delay_counter == 0) begin
                    next_state = READ_START;
                end
            end
            
            // Reading sequence
            READ_START: begin
                if (sb_done && !sb_busy) begin
                    next_state = READ_QUAT_W_LSB;
                end
            end
            READ_QUAT_W_LSB: begin
                if (sb_done && !sb_busy) begin
                    next_state = READ_QUAT_W_MSB;
                end
            end
            READ_QUAT_W_MSB: begin
                if (sb_done && !sb_busy) begin
                    next_state = READ_QUAT_X_LSB;
                end
            end
            READ_QUAT_X_LSB: begin
                if (sb_done && !sb_busy) begin
                    next_state = READ_QUAT_X_MSB;
                end
            end
            READ_QUAT_X_MSB: begin
                if (sb_done && !sb_busy) begin
                    next_state = READ_QUAT_Y_LSB;
                end
            end
            READ_QUAT_Y_LSB: begin
                if (sb_done && !sb_busy) begin
                    next_state = READ_QUAT_Y_MSB;
                end
            end
            READ_QUAT_Y_MSB: begin
                if (sb_done && !sb_busy) begin
                    next_state = READ_QUAT_Z_LSB;
                end
            end
            READ_QUAT_Z_LSB: begin
                if (sb_done && !sb_busy) begin
                    next_state = READ_QUAT_Z_MSB;
                end
            end
            READ_QUAT_Z_MSB: begin
                if (sb_done && !sb_busy) begin
                    next_state = READ_GYRO_X_LSB;
                end
            end
            READ_GYRO_X_LSB: begin
                if (sb_done && !sb_busy) begin
                    next_state = READ_GYRO_X_MSB;
                end
            end
            READ_GYRO_X_MSB: begin
                if (sb_done && !sb_busy) begin
                    next_state = READ_GYRO_Y_LSB;
                end
            end
            READ_GYRO_Y_LSB: begin
                if (sb_done && !sb_busy) begin
                    next_state = READ_GYRO_Y_MSB;
                end
            end
            READ_GYRO_Y_MSB: begin
                if (sb_done && !sb_busy) begin
                    next_state = READ_GYRO_Z_LSB;
                end
            end
            READ_GYRO_Z_LSB: begin
                if (sb_done && !sb_busy) begin
                    next_state = READ_GYRO_Z_MSB;
                end
            end
            READ_GYRO_Z_MSB: begin
                if (sb_done && !sb_busy) begin
                    next_state = DATA_READY;
                end
            end
            DATA_READY: begin
                // Wait a bit then start next read cycle
                if (delay_counter == 0) begin
                    next_state = READ_START;
                end
            end
        endcase
    end
    
    // Control logic for System Bus Master
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sb_start <= 0;
            sb_write_en <= 0;
            sb_addr_in <= 0;
            sb_data_in <= 0;
            delay_counter <= 0;
        end else begin
            sb_start <= 0;
            
            case (state)
                // Initialization: Soft reset (write 0x20 to register 0x3F)
                INIT_RESET_WRITE: begin
                    if (!sb_busy) begin
                        sb_start <= 1;
                        sb_write_en <= 1;
                        sb_addr_in <= I2C_TX_REG;
                        // Simplified: Write slave address + register + data
                        // In real implementation, this would be multiple I2C transactions
                        sb_data_in <= {BNO055_ADDR, 1'b0};  // Slave address with write bit
                        delay_counter <= DELAY_I2C;
                    end
                end
                INIT_RESET_WAIT: begin
                    // Wait for I2C transaction to complete
                    if (delay_counter == 0 && sb_done) begin
                        delay_counter <= DELAY_650MS;  // Wait 650ms after reset
                    end
                end
                INIT_RESET_DELAY: begin
                    // Delay counter decrements in state machine
                end
                
                // Initialization: Set operation mode to NDOF (write 0x0C to register 0x3D)
                INIT_MODE_WRITE: begin
                    if (!sb_busy) begin
                        sb_start <= 1;
                        sb_write_en <= 1;
                        sb_addr_in <= I2C_TX_REG;
                        sb_data_in <= BNO055_MODE_NDOF;  // Operation mode data
                        delay_counter <= DELAY_I2C;
                    end
                end
                INIT_MODE_WAIT: begin
                    if (delay_counter == 0 && sb_done) begin
                        delay_counter <= DELAY_30MS;  // Wait 30ms after setting mode
                    end
                end
                INIT_MODE_DELAY: begin
                    // Delay counter decrements in state machine
                end
                
                // Reading: Start I2C read transaction
                READ_START: begin
                    if (!sb_busy) begin
                        sb_start <= 1;
                        sb_write_en <= 1;
                        sb_addr_in <= I2C_CTRL_REG;
                        sb_data_in <= 8'h01;  // Start I2C read transaction
                        delay_counter <= DELAY_I2C;
                    end
                end
                
                // Reading: Read quaternion W LSB (register 0x20)
                READ_QUAT_W_LSB: begin
                    if (!sb_busy && !sb_done) begin
                        sb_start <= 1;
                        sb_write_en <= 0;  // Read operation
                        sb_addr_in <= I2C_RX_REG;
                    end
                end
                
                // Reading: Read quaternion W MSB (register 0x21)
                READ_QUAT_W_MSB: begin
                    if (!sb_busy && !sb_done) begin
                        sb_start <= 1;
                        sb_write_en <= 0;
                        sb_addr_in <= I2C_RX_REG;
                    end
                end
                
                // Reading: Read quaternion X LSB (register 0x22)
                READ_QUAT_X_LSB: begin
                    if (!sb_busy && !sb_done) begin
                        sb_start <= 1;
                        sb_write_en <= 0;
                        sb_addr_in <= I2C_RX_REG;
                    end
                end
                
                // Reading: Read quaternion X MSB (register 0x23)
                READ_QUAT_X_MSB: begin
                    if (!sb_busy && !sb_done) begin
                        sb_start <= 1;
                        sb_write_en <= 0;
                        sb_addr_in <= I2C_RX_REG;
                    end
                end
                
                // Reading: Read quaternion Y LSB (register 0x24)
                READ_QUAT_Y_LSB: begin
                    if (!sb_busy && !sb_done) begin
                        sb_start <= 1;
                        sb_write_en <= 0;
                        sb_addr_in <= I2C_RX_REG;
                    end
                end
                
                // Reading: Read quaternion Y MSB (register 0x25)
                READ_QUAT_Y_MSB: begin
                    if (!sb_busy && !sb_done) begin
                        sb_start <= 1;
                        sb_write_en <= 0;
                        sb_addr_in <= I2C_RX_REG;
                    end
                end
                
                // Reading: Read quaternion Z LSB (register 0x26)
                READ_QUAT_Z_LSB: begin
                    if (!sb_busy && !sb_done) begin
                        sb_start <= 1;
                        sb_write_en <= 0;
                        sb_addr_in <= I2C_RX_REG;
                    end
                end
                
                // Reading: Read quaternion Z MSB (register 0x27)
                READ_QUAT_Z_MSB: begin
                    if (!sb_busy && !sb_done) begin
                        sb_start <= 1;
                        sb_write_en <= 0;
                        sb_addr_in <= I2C_RX_REG;
                    end
                end
                
                // Reading: Read gyroscope X LSB (register 0x14)
                READ_GYRO_X_LSB: begin
                    if (!sb_busy && !sb_done) begin
                        sb_start <= 1;
                        sb_write_en <= 0;
                        sb_addr_in <= I2C_RX_REG;
                    end
                end
                
                // Reading: Read gyroscope X MSB (register 0x15)
                READ_GYRO_X_MSB: begin
                    if (!sb_busy && !sb_done) begin
                        sb_start <= 1;
                        sb_write_en <= 0;
                        sb_addr_in <= I2C_RX_REG;
                    end
                end
                
                // Reading: Read gyroscope Y LSB (register 0x16)
                READ_GYRO_Y_LSB: begin
                    if (!sb_busy && !sb_done) begin
                        sb_start <= 1;
                        sb_write_en <= 0;
                        sb_addr_in <= I2C_RX_REG;
                    end
                end
                
                // Reading: Read gyroscope Y MSB (register 0x17)
                READ_GYRO_Y_MSB: begin
                    if (!sb_busy && !sb_done) begin
                        sb_start <= 1;
                        sb_write_en <= 0;
                        sb_addr_in <= I2C_RX_REG;
                    end
                end
                
                // Reading: Read gyroscope Z LSB (register 0x18)
                READ_GYRO_Z_LSB: begin
                    if (!sb_busy && !sb_done) begin
                        sb_start <= 1;
                        sb_write_en <= 0;
                        sb_addr_in <= I2C_RX_REG;
                    end
                end
                
                // Reading: Read gyroscope Z MSB (register 0x19)
                READ_GYRO_Z_MSB: begin
                    if (!sb_busy && !sb_done) begin
                        sb_start <= 1;
                        sb_write_en <= 0;
                        sb_addr_in <= I2C_RX_REG;
                    end
                end
                
                DATA_READY: begin
                    // Set delay before next read cycle
                    if (delay_counter == 0) begin
                        delay_counter <= DELAY_I2C;
                    end
                end
                
                default: begin
                    // Other states don't need System Bus transactions
                end
            endcase
        end
    end
    
    // Combine LSB and MSB to form 16-bit values
    // Note: BNO055 sends data as signed 16-bit, MSB first
    assign quat_w = {quat_w_msb, quat_w_lsb};
    assign quat_x = {quat_x_msb, quat_x_lsb};
    assign quat_y = {quat_y_msb, quat_y_lsb};
    assign quat_z = {quat_z_msb, quat_z_lsb};
    
    // Gyroscope values are signed, so sign-extend from MSB
    assign gyro_x = $signed({gyro_x_msb, gyro_x_lsb});
    assign gyro_y = $signed({gyro_y_msb, gyro_y_lsb});
    assign gyro_z = $signed({gyro_z_msb, gyro_z_lsb});

endmodule
