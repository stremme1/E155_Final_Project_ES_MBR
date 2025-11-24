// BNO085 Controller Module
// Handles SHTP (Sensor Hub Transport Protocol) communication over SPI
// Reads Rotation Vector (quaternion) and Gyroscope reports

module bno085_controller (
    input  logic        clk,
    input  logic        rst_n,
    
    // SPI interface
    output logic        spi_start,
    output logic        spi_tx_valid,
    output logic [7:0]  spi_tx_data,
    input  logic        spi_tx_ready,
    input  logic        spi_rx_valid,
    input  logic [7:0]  spi_rx_data,
    input  logic        spi_busy,
    
    // Sensor data outputs
    output logic        quat_valid,
    output logic signed [15:0] quat_w,
    output logic signed [15:0] quat_x,
    output logic signed [15:0] quat_y,
    output logic signed [15:0] quat_z,
    
    output logic        gyro_valid,
    output logic signed [15:0] gyro_x,
    output logic signed [15:0] gyro_y,
    output logic signed [15:0] gyro_z,
    
    // Status
    output logic        initialized,
    output logic        error
);

    // SHTP Protocol constants
    localparam [7:0] CHANNEL_CONTROL = 8'h00;
    localparam [7:0] CHANNEL_REPORTS = 8'h05;
    localparam [7:0] CHANNEL_EXE = 8'h01;
    
    // Report IDs
    localparam [7:0] REPORT_ID_ROTATION_VECTOR = 8'h05;
    localparam [7:0] REPORT_ID_GYROSCOPE = 8'h01;
    
    // Commands
    localparam [7:0] CMD_PRODUCT_ID_REQUEST = 8'hF9;
    localparam [7:0] CMD_SET_FEATURE = 8'hFD;
    
    typedef enum logic [4:0] {
        IDLE,
        INIT_WAIT,
        INIT_PRODUCT_ID,
        INIT_ENABLE_ROTATION,
        INIT_ENABLE_GYRO,
        WAIT_DATA,
        READ_HEADER,
        READ_PAYLOAD,
        PARSE_REPORT,
        ERROR_STATE
    } state_t;
    
    state_t state;
    logic [7:0] byte_cnt;
    logic [15:0] packet_length;
    logic [7:0] seq_num;  // Renamed from 'sequence' (reserved word)
    logic [7:0] channel;
    logic [7:0] report_id;
    // Use BRAM for data buffer - 64 bytes
    // Synthesis attributes to force BRAM usage (vendor-specific)
    // For Xilinx: (* ram_style = "block" *)
    // For Intel: (* ramstyle = "M9K" *)
    // For Lattice: (* syn_ramstyle = "block_ram" *)
    (* ram_style = "block" *)
    logic [7:0] data_buffer [0:63];
    logic [31:0] init_counter;
    
    // Initialize sensor on reset
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= INIT_WAIT;
            initialized <= 1'b0;
            error <= 1'b0;
            init_counter <= 32'd0;
            spi_start <= 1'b0;
            spi_tx_valid <= 1'b0;
            byte_cnt <= 8'd0;
        end else begin
            spi_start <= 1'b0;
            spi_tx_valid <= 1'b0;
            
            case (state)
                INIT_WAIT: begin
                    // Wait 100ms after reset
                    // Clock is 3MHz (48MHz / 16), so 100ms = 3,000,000 / 10 = 300,000 cycles
                    // Using 300,000 cycles for 100ms at 3MHz
                    if (init_counter < 32'd300_000) begin
                        init_counter <= init_counter + 1;
                    end else begin
                        state <= INIT_PRODUCT_ID;
                        init_counter <= 32'd0;
                    end
                end
                
                INIT_PRODUCT_ID: begin
                    // Send Product ID Request
                    // SHTP Header: [Length LSB, Length MSB, Channel, Sequence]
                    if (!spi_busy && spi_tx_ready) begin
                        case (byte_cnt)
                            0: begin
                                spi_tx_data <= 8'd4;  // Length LSB
                                spi_tx_valid <= 1'b1;
                                spi_start <= 1'b1;
                                byte_cnt <= byte_cnt + 1;
                            end
                            1: begin
                                spi_tx_data <= 8'd0;  // Length MSB
                                byte_cnt <= byte_cnt + 1;
                            end
                            2: begin
                                spi_tx_data <= CHANNEL_CONTROL;
                                byte_cnt <= byte_cnt + 1;
                            end
                            3: begin
                                spi_tx_data <= 8'd0;  // Sequence
                                byte_cnt <= byte_cnt + 1;
                            end
                            4: begin
                                spi_tx_data <= CMD_PRODUCT_ID_REQUEST;
                                byte_cnt <= 8'd0;
                                state <= WAIT_DATA;
                            end
                        endcase
                    end
                end
                
                INIT_ENABLE_ROTATION: begin
                    // Enable Rotation Vector report at 50Hz
                    if (!spi_busy && spi_tx_ready) begin
                        case (byte_cnt)
                            0: begin
                                spi_tx_data <= 8'd17;  // Length LSB
                                spi_tx_valid <= 1'b1;
                                spi_start <= 1'b1;
                                byte_cnt <= byte_cnt + 1;
                            end
                            1: begin
                                spi_tx_data <= 8'd0;  // Length MSB
                                byte_cnt <= byte_cnt + 1;
                            end
                            2: begin
                                spi_tx_data <= CHANNEL_CONTROL;
                                byte_cnt <= byte_cnt + 1;
                            end
                            3: begin
                                spi_tx_data <= 8'd1;  // Sequence
                                byte_cnt <= byte_cnt + 1;
                            end
                            4: begin
                                spi_tx_data <= CMD_SET_FEATURE;
                                byte_cnt <= byte_cnt + 1;
                            end
                            5: begin
                                spi_tx_data <= REPORT_ID_ROTATION_VECTOR;
                                byte_cnt <= byte_cnt + 1;
                            end
                            6: begin
                                spi_tx_data <= 8'd0;  // Feature flags
                                byte_cnt <= byte_cnt + 1;
                            end
                            7: begin
                                spi_tx_data <= 8'd0;
                                byte_cnt <= byte_cnt + 1;
                            end
                            8: begin
                                spi_tx_data <= 8'd0;
                                byte_cnt <= byte_cnt + 1;
                            end
                            9: begin
                                spi_tx_data <= 8'd0;
                                byte_cnt <= byte_cnt + 1;
                            end
                            10: begin
                                spi_tx_data <= 8'd50;  // Report interval (50Hz = 20ms)
                                byte_cnt <= byte_cnt + 1;
                            end
                            11: begin
                                spi_tx_data <= 8'd0;
                                byte_cnt <= byte_cnt + 1;
                            end
                            12: begin
                                spi_tx_data <= 8'd0;
                                byte_cnt <= byte_cnt + 1;
                            end
                            13: begin
                                spi_tx_data <= 8'd0;
                                byte_cnt <= 8'd0;
                                state <= INIT_ENABLE_GYRO;
                            end
                        endcase
                    end
                end
                
                INIT_ENABLE_GYRO: begin
                    // Enable Gyroscope report at 50Hz
                    if (!spi_busy && spi_tx_ready) begin
                        case (byte_cnt)
                            0: begin
                                spi_tx_data <= 8'd17;  // Length LSB
                                spi_tx_valid <= 1'b1;
                                spi_start <= 1'b1;
                                byte_cnt <= byte_cnt + 1;
                            end
                            1: begin
                                spi_tx_data <= 8'd0;  // Length MSB
                                byte_cnt <= byte_cnt + 1;
                            end
                            2: begin
                                spi_tx_data <= CHANNEL_CONTROL;
                                byte_cnt <= byte_cnt + 1;
                            end
                            3: begin
                                spi_tx_data <= 8'd2;  // Sequence
                                byte_cnt <= byte_cnt + 1;
                            end
                            4: begin
                                spi_tx_data <= CMD_SET_FEATURE;
                                byte_cnt <= byte_cnt + 1;
                            end
                            5: begin
                                spi_tx_data <= REPORT_ID_GYROSCOPE;
                                byte_cnt <= byte_cnt + 1;
                            end
                            6: begin
                                spi_tx_data <= 8'd0;  // Feature flags
                                byte_cnt <= byte_cnt + 1;
                            end
                            7: begin
                                spi_tx_data <= 8'd0;
                                byte_cnt <= byte_cnt + 1;
                            end
                            8: begin
                                spi_tx_data <= 8'd0;
                                byte_cnt <= byte_cnt + 1;
                            end
                            9: begin
                                spi_tx_data <= 8'd0;
                                byte_cnt <= byte_cnt + 1;
                            end
                            10: begin
                                spi_tx_data <= 8'd50;  // Report interval (50Hz)
                                byte_cnt <= byte_cnt + 1;
                            end
                            11: begin
                                spi_tx_data <= 8'd0;
                                byte_cnt <= byte_cnt + 1;
                            end
                            12: begin
                                spi_tx_data <= 8'd0;
                                byte_cnt <= byte_cnt + 1;
                            end
                            13: begin
                                spi_tx_data <= 8'd0;
                                byte_cnt <= 8'd0;
                                initialized <= 1'b1;
                                state <= WAIT_DATA;
                            end
                        endcase
                    end
                end
                
                WAIT_DATA: begin
                    // Poll for data ready (check INT pin or poll status)
                    // For simplicity, continuously read reports
                    // Start reading header by sending dummy bytes
                    if (!spi_busy && spi_tx_ready) begin
                        state <= READ_HEADER;
                        byte_cnt <= 8'd0;
                        spi_tx_data <= 8'h00;  // Dummy byte to read header
                        spi_tx_valid <= 1'b1;
                        spi_start <= 1'b1;
                    end
                end
                
                READ_HEADER: begin
                    // Read 4-byte SHTP header by sending dummy bytes
                    if (spi_rx_valid && !spi_busy) begin
                        case (byte_cnt)
                            0: begin
                                packet_length[7:0] <= spi_rx_data;
                                byte_cnt <= byte_cnt + 1;
                                // Send next dummy byte
                                spi_tx_data <= 8'h00;
                                spi_tx_valid <= 1'b1;
                                spi_start <= 1'b1;
                            end
                            1: begin
                                packet_length[15:8] <= spi_rx_data;
                                byte_cnt <= byte_cnt + 1;
                                spi_tx_data <= 8'h00;
                                spi_tx_valid <= 1'b1;
                                spi_start <= 1'b1;
                            end
                            2: begin
                                channel <= spi_rx_data;
                                byte_cnt <= byte_cnt + 1;
                                spi_tx_data <= 8'h00;
                                spi_tx_valid <= 1'b1;
                                spi_start <= 1'b1;
                            end
                            3: begin
                                seq_num <= spi_rx_data;
                                byte_cnt <= 8'd0;
                                if (packet_length > 4) begin
                                    state <= READ_PAYLOAD;
                                    // Start reading payload
                                    spi_tx_data <= 8'h00;
                                    spi_tx_valid <= 1'b1;
                                    spi_start <= 1'b1;
                                end else begin
                                    state <= WAIT_DATA;
                                end
                            end
                        endcase
                    end else if (!spi_busy && spi_tx_ready && byte_cnt < 3) begin
                        // Continue reading if SPI transaction completed
                        spi_tx_data <= 8'h00;
                        spi_tx_valid <= 1'b1;
                        spi_start <= 1'b1;
                    end
                end
                
                READ_PAYLOAD: begin
                    // Read payload data by sending dummy bytes
                    // BRAM will be inferred from array access
                    if (spi_rx_valid && !spi_busy) begin
                        if (byte_cnt < packet_length - 4 && byte_cnt < 64) begin
                            data_buffer[byte_cnt] <= spi_rx_data;
                            byte_cnt <= byte_cnt + 1;
                            // Continue reading if more data
                            if (byte_cnt < packet_length - 5 && byte_cnt < 63) begin
                                spi_tx_data <= 8'h00;
                                spi_tx_valid <= 1'b1;
                                spi_start <= 1'b1;
                            end else begin
                                // Done reading payload
                                byte_cnt <= 8'd0;
                                state <= PARSE_REPORT;
                            end
                        end else begin
                            byte_cnt <= 8'd0;
                            state <= PARSE_REPORT;
                        end
                    end else if (!spi_busy && spi_tx_ready && byte_cnt < packet_length - 4 && byte_cnt < 64) begin
                        // Continue reading payload
                        spi_tx_data <= 8'h00;
                        spi_tx_valid <= 1'b1;
                        spi_start <= 1'b1;
                    end
                end
                
                PARSE_REPORT: begin
                    // Parse report based on channel and report ID
                    // BRAM access will be inferred from array indexing
                    if (channel == CHANNEL_REPORTS && byte_cnt < 64) begin
                        report_id <= data_buffer[0];
                        
                        if (report_id == REPORT_ID_ROTATION_VECTOR) begin
                            // Rotation Vector: [Report ID, Seq, Status, Delay, Quat I(4), Quat J(4), Quat K(4), Quat Real(4), Accuracy]
                            // Quaternions are in Q14 format, little-endian
                            quat_w <= {data_buffer[13], data_buffer[12]};
                            quat_x <= {data_buffer[5], data_buffer[4]};
                            quat_y <= {data_buffer[9], data_buffer[8]};
                            quat_z <= {data_buffer[17], data_buffer[16]};
                            quat_valid <= 1'b1;
                        end else if (report_id == REPORT_ID_GYROSCOPE) begin
                            // Gyroscope: [Report ID, Seq, Status, Delay, X(2), Y(2), Z(2)]
                            // Gyro values are in rad/s * 900 (Q9 format), little-endian
                            gyro_x <= {data_buffer[5], data_buffer[4]};
                            gyro_y <= {data_buffer[7], data_buffer[6]};
                            gyro_z <= {data_buffer[9], data_buffer[8]};
                            gyro_valid <= 1'b1;
                        end
                    end
                    
                    quat_valid <= 1'b0;
                    gyro_valid <= 1'b0;
                    state <= WAIT_DATA;
                end
                
                ERROR_STATE: begin
                    error <= 1'b1;
                    state <= ERROR_STATE;
                end
                
                default: state <= IDLE;
            endcase
        end
    end
    
endmodule

