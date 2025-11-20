// BNO085 SPI Interface Module
// Handles SHTP (Sensor Hub Transport Protocol) communication
// Reads quaternion (Report ID 0x05) and gyroscope (Report ID 0x06)
// Author: E155 Final Project
// Date: 2024

module bno085_spi_interface (
    input  logic        clk,
    input  logic        rst_n,
    
    // SPI Controller Interface
    output logic        spi_start,
    output logic [7:0]  spi_tx_data,
    output logic        spi_tx_valid,
    input  logic        spi_tx_ready,
    input  logic [7:0]  spi_rx_data,
    input  logic        spi_rx_valid,
    input  logic        spi_busy,
    
    // BNO085 Control
    input  logic        int_n,          // Interrupt (data ready, active low)
    output logic        rst_n_out,      // Reset output (active low)
    
    // Output Data
    output logic        data_valid,     // New data available
    output logic signed [15:0] quat_w, quat_x, quat_y, quat_z,  // Quaternion (Q16 format)
    output logic signed [15:0] gyro_x, gyro_y, gyro_z            // Gyroscope
);

    // SHTP Report IDs
    localparam REPORT_QUATERNION = 8'h05;
    localparam REPORT_GYRO = 8'h06;
    
    // State Machine
    typedef enum logic [4:0] {
        IDLE,
        INIT_WAIT,
        INIT_RESET,
        ENABLE_QUATERNION,
        ENABLE_GYRO,
        WAIT_INT,
        READ_HEADER,
        READ_LENGTH,
        READ_DATA,
        PARSE_REPORT,
        DONE
    } state_t;
    
    state_t state, next_state;
    
    // Initialization counter
    logic [23:0] init_counter;
    logic init_done;
    
    // Packet parsing
    logic [7:0] header_byte;
    logic [15:0] packet_length;
    logic [15:0] byte_counter;
    logic [7:0] report_id;
    logic [7:0] data_buffer [0:15];  // Buffer for report data
    
    // Data extraction
    logic [7:0] byte_index;
    
    // Reset control (hold low for 100ms on startup, then high)
    logic [23:0] reset_counter;
    logic reset_done;
    
    // Initialize reset sequence
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reset_counter <= '0;
            reset_done <= 1'b0;
            rst_n_out <= 1'b0;
            init_counter <= '0;
            init_done <= 1'b0;
        end else begin
            if (!reset_done) begin
                if (reset_counter < 24'd4800000) begin  // 100ms at 48MHz
                    reset_counter <= reset_counter + 1;
                    rst_n_out <= 1'b0;
                end else begin
                    reset_done <= 1'b1;
                    rst_n_out <= 1'b1;
                end
            end
            
            // Wait 300ms after reset for sensor initialization
            if (reset_done && !init_done) begin
                if (init_counter < 24'd14400000) begin  // 300ms at 48MHz
                    init_counter <= init_counter + 1;
                end else begin
                    init_done <= 1'b1;
                end
            end
        end
    end
    
    // SHTP Command/Report structure
    logic [7:0] shtp_tx_buffer [0:15];
    logic [2:0] shtp_tx_index;
    logic shtp_tx_active;
    
    // State machine
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n || !reset_done) begin
            state <= IDLE;
            byte_counter <= '0;
            packet_length <= '0;
            report_id <= '0;
            data_valid <= 1'b0;
            shtp_tx_index <= '0;
            shtp_tx_active <= 1'b0;
        end else begin
            state <= next_state;
            
            case (state)
                IDLE: begin
                    byte_counter <= '0;
                    data_valid <= 1'b0;
                    shtp_tx_index <= '0;
                    shtp_tx_active <= 1'b0;
                end
                
                INIT_WAIT: begin
                    // Wait for initialization to complete
                end
                
                INIT_RESET: begin
                    // Send reset command (if needed)
                end
                
                ENABLE_QUATERNION: begin
                    // Send enable quaternion report command
                    if (spi_rx_valid) begin
                        shtp_tx_index <= shtp_tx_index + 1;
                    end
                end
                
                ENABLE_GYRO: begin
                    // Send enable gyro report command
                    if (spi_rx_valid) begin
                        shtp_tx_index <= shtp_tx_index + 1;
                    end
                end
                
                WAIT_INT: begin
                    // Wait for interrupt (data ready)
                end
                
                READ_HEADER: begin
                    if (spi_rx_valid) begin
                        header_byte <= spi_rx_data;
                        byte_counter <= byte_counter + 1;
                    end
                end
                
                READ_LENGTH: begin
                    if (spi_rx_valid) begin
                        if (byte_counter == 1) begin
                            packet_length[7:0] <= spi_rx_data;
                        end else begin
                            packet_length[15:8] <= spi_rx_data;
                        end
                        byte_counter <= byte_counter + 1;
                    end
                end
                
                READ_DATA: begin
                    if (spi_rx_valid && byte_counter < packet_length) begin
                        data_buffer[byte_counter - 3] <= spi_rx_data;  // Skip header + length
                        byte_counter <= byte_counter + 1;
                    end
                end
                
                PARSE_REPORT: begin
                    // Extract report ID and data
                    report_id <= data_buffer[0];
                    // Parse quaternion or gyro based on report ID
                    if (data_buffer[0] == REPORT_QUATERNION) begin
                        // Quaternion: 4x 16-bit values (w, x, y, z) in Q16 format
                        quat_w <= {data_buffer[2], data_buffer[1]};
                        quat_x <= {data_buffer[4], data_buffer[3]};
                        quat_y <= {data_buffer[6], data_buffer[5]};
                        quat_z <= {data_buffer[8], data_buffer[7]};
                    end else if (data_buffer[0] == REPORT_GYRO) begin
                        // Gyroscope: 3x 16-bit values (x, y, z)
                        gyro_x <= {data_buffer[2], data_buffer[1]};
                        gyro_y <= {data_buffer[4], data_buffer[3]};
                        gyro_z <= {data_buffer[6], data_buffer[5]};
                    end
                    data_valid <= 1'b1;
                end
                
                DONE: begin
                    data_valid <= 1'b0;
                end
            endcase
        end
    end
    
    // Next state logic
    always_comb begin
        next_state = state;
        spi_start = 1'b0;
        spi_tx_data = '0;
        spi_tx_valid = 1'b0;
        
        case (state)
            IDLE: begin
                if (reset_done && init_done) begin
                    next_state = ENABLE_QUATERNION;
                end
            end
            
            INIT_WAIT: begin
                if (init_done) begin
                    next_state = ENABLE_QUATERNION;
                end
            end
            
            ENABLE_QUATERNION: begin
                // Send SHTP command to enable quaternion report (Report ID 0x05)
                // SHTP packet: [Header=0x05] [Length LSB=0x08] [Length MSB=0x00] [Command=0x02] [Report ID=0x05] [Interval=0x00] [0x00] [0x00]
                if (!spi_busy) begin
                    spi_start = 1'b1;
                    spi_tx_valid = 1'b1;
                    // Simplified: Just move to next state after sending
                    if (shtp_tx_index >= 3'd7) begin
                        next_state = ENABLE_GYRO;
                    end
                end
            end
            
            ENABLE_GYRO: begin
                // Send SHTP command to enable gyro report (Report ID 0x06)
                if (!spi_busy) begin
                    spi_start = 1'b1;
                    spi_tx_valid = 1'b1;
                    if (shtp_tx_index >= 3'd7) begin
                        next_state = WAIT_INT;
                    end
                end
            end
            
            WAIT_INT: begin
                if (!int_n) begin  // Interrupt active (low)
                    next_state = READ_HEADER;
                    spi_start = 1'b1;
                    spi_tx_valid = 1'b1;  // Start reading
                end
            end
            
            READ_HEADER: begin
                if (spi_rx_valid) begin
                    next_state = READ_LENGTH;
                    spi_start = 1'b1;
                    spi_tx_valid = 1'b1;
                end
            end
            
            READ_LENGTH: begin
                if (spi_rx_valid && byte_counter >= 3) begin
                    next_state = READ_DATA;
                    spi_start = 1'b1;
                    spi_tx_valid = 1'b1;
                end else if (spi_rx_valid) begin
                    spi_start = 1'b1;
                    spi_tx_valid = 1'b1;
                end
            end
            
            READ_DATA: begin
                if (byte_counter >= packet_length) begin
                    next_state = PARSE_REPORT;
                end else if (spi_rx_valid) begin
                    spi_start = 1'b1;
                    spi_tx_valid = 1'b1;
                end
            end
            
            PARSE_REPORT: begin
                next_state = DONE;
            end
            
            DONE: begin
                next_state = WAIT_INT;
            end
        endcase
    end

endmodule

