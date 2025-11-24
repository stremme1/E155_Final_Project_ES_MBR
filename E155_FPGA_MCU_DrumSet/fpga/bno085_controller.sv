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
    output logic        cs_n,   // Chip Select (active low) - Controlled here for packet framing

    // INT pin (REQUIRED for stable SPI operation per Adafruit documentation)
    input  logic        int_n,  // Active LOW interrupt - goes LOW when data ready

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
        INIT_PRODUCT_ID_START,
        INIT_PRODUCT_ID,
        INIT_DELAY_1,
        INIT_ENABLE_ROTATION_START,
        INIT_ENABLE_ROTATION,
        INIT_DELAY_2,
        INIT_ENABLE_GYRO_START,
        INIT_ENABLE_GYRO,
        WAIT_DATA,
        READ_HEADER_START,
        READ_HEADER,
        READ_PAYLOAD,
        PARSE_REPORT,
        ERROR_STATE
    } state_t;
    
    state_t state;
    logic [7:0] byte_cnt;
    logic [15:0] packet_length;
    logic [7:0] seq_num;
    logic [7:0] channel;
    logic [7:0] report_id;
    // Use BRAM for data buffer - 64 bytes
    (* ram_style = "block" *)
    logic [7:0] data_buffer [0:63];
    logic [31:0] init_counter;
    
    // INT pin handling
    logic int_n_sync, int_n_prev;
    logic int_falling_edge;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int_n_sync <= 1'b1;
            int_n_prev <= 1'b1;
            int_falling_edge <= 1'b0;
        end else begin
            int_n_sync <= int_n;
            int_n_prev <= int_n_sync;
            int_falling_edge <= (int_n_prev && !int_n_sync);
        end
    end
    
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
            cs_n <= 1'b1;
            quat_valid <= 1'b0;
            gyro_valid <= 1'b0;
        end else begin
            spi_start <= 1'b0;
            spi_tx_valid <= 1'b0;
            
            case (state)
                INIT_WAIT: begin
                    cs_n <= 1'b1;
                    if (init_counter < 32'd300_000) begin
                        init_counter <= init_counter + 1;
                    end else begin
                        state <= INIT_PRODUCT_ID_START;
                        init_counter <= 32'd0;
                    end
                end
                
                INIT_PRODUCT_ID_START: begin
                    // SHTP Wake-up: Assert CS, Wait for INT low
                    cs_n <= 1'b0;
                    if (!int_n_sync || init_counter > 32'd30000) begin // Wait up to 10ms for wake
                        state <= INIT_PRODUCT_ID;
                        byte_cnt <= 8'd0;
                        init_counter <= 32'd0;
                    end else begin
                        init_counter <= init_counter + 1;
                    end
                end

                INIT_PRODUCT_ID: begin
                    if (!spi_busy && spi_tx_ready) begin
                        case (byte_cnt)
                            0: begin spi_tx_data <= 8'd4; spi_tx_valid <= 1; spi_start <= 1; byte_cnt <= byte_cnt + 1; end
                            1: begin spi_tx_data <= 8'd0; spi_tx_valid <= 1; spi_start <= 1; byte_cnt <= byte_cnt + 1; end
                            2: begin spi_tx_data <= CHANNEL_CONTROL; spi_tx_valid <= 1; spi_start <= 1; byte_cnt <= byte_cnt + 1; end
                            3: begin spi_tx_data <= 8'd0; spi_tx_valid <= 1; spi_start <= 1; byte_cnt <= byte_cnt + 1; end
                            4: begin 
                                spi_tx_data <= CMD_PRODUCT_ID_REQUEST; 
                                spi_tx_valid <= 1; 
                                spi_start <= 1;
                                byte_cnt <= byte_cnt + 1; 
                            end
                            5: begin
                                cs_n <= 1'b1; // Deassert CS after last byte sent
                                byte_cnt <= 8'd0;
                                state <= INIT_DELAY_1;
                            end
                        endcase
                    end
                end
                
                INIT_DELAY_1: begin
                    cs_n <= 1'b1;
                    if (init_counter < 32'd30_000) begin
                        init_counter <= init_counter + 1;
                    end else begin
                        state <= INIT_ENABLE_ROTATION_START;
                        init_counter <= 32'd0;
                    end
                end

                INIT_ENABLE_ROTATION_START: begin
                    cs_n <= 1'b0;
                    if (!int_n_sync || init_counter > 32'd30000) begin
                        state <= INIT_ENABLE_ROTATION;
                        byte_cnt <= 8'd0;
                        init_counter <= 32'd0;
                    end else begin
                        init_counter <= init_counter + 1;
                    end
                end
                
                INIT_ENABLE_ROTATION: begin
                    if (!spi_busy && spi_tx_ready) begin
                        case (byte_cnt)
                            0: begin spi_tx_data <= 8'd17; spi_tx_valid <= 1; spi_start <= 1; byte_cnt <= byte_cnt + 1; end
                            1: begin spi_tx_data <= 8'd0; spi_tx_valid <= 1; spi_start <= 1; byte_cnt <= byte_cnt + 1; end
                            2: begin spi_tx_data <= CHANNEL_CONTROL; spi_tx_valid <= 1; spi_start <= 1; byte_cnt <= byte_cnt + 1; end
                            3: begin spi_tx_data <= 8'd1; spi_tx_valid <= 1; spi_start <= 1; byte_cnt <= byte_cnt + 1; end
                            4: begin spi_tx_data <= CMD_SET_FEATURE; spi_tx_valid <= 1; spi_start <= 1; byte_cnt <= byte_cnt + 1; end
                            5: begin spi_tx_data <= REPORT_ID_ROTATION_VECTOR; spi_tx_valid <= 1; spi_start <= 1; byte_cnt <= byte_cnt + 1; end
                            6: begin spi_tx_data <= 8'd0; spi_tx_valid <= 1; spi_start <= 1; byte_cnt <= byte_cnt + 1; end
                            7: begin spi_tx_data <= 8'd0; spi_tx_valid <= 1; spi_start <= 1; byte_cnt <= byte_cnt + 1; end
                            8: begin spi_tx_data <= 8'd0; spi_tx_valid <= 1; spi_start <= 1; byte_cnt <= byte_cnt + 1; end
                            9: begin spi_tx_data <= 8'd0; spi_tx_valid <= 1; spi_start <= 1; byte_cnt <= byte_cnt + 1; end
                            10: begin spi_tx_data <= 8'd50; spi_tx_valid <= 1; spi_start <= 1; byte_cnt <= byte_cnt + 1; end
                            11: begin spi_tx_data <= 8'd0; spi_tx_valid <= 1; spi_start <= 1; byte_cnt <= byte_cnt + 1; end
                            12: begin spi_tx_data <= 8'd0; spi_tx_valid <= 1; spi_start <= 1; byte_cnt <= byte_cnt + 1; end
                            13: begin 
                                spi_tx_data <= 8'd0; 
                                spi_tx_valid <= 1; 
                                spi_start <= 1; 
                                byte_cnt <= byte_cnt + 1; 
                            end
                            14: begin
                                cs_n <= 1'b1;
                                byte_cnt <= 8'd0;
                                state <= INIT_DELAY_2;
                            end
                        endcase
                    end
                end
                
                INIT_DELAY_2: begin
                    cs_n <= 1'b1;
                    if (init_counter < 32'd30_000) begin
                        init_counter <= init_counter + 1;
                    end else begin
                        state <= INIT_ENABLE_GYRO_START;
                        init_counter <= 32'd0;
                    end
                end

                INIT_ENABLE_GYRO_START: begin
                    cs_n <= 1'b0;
                    if (!int_n_sync || init_counter > 32'd30000) begin
                        state <= INIT_ENABLE_GYRO;
                        byte_cnt <= 8'd0;
                        init_counter <= 32'd0;
                    end else begin
                        init_counter <= init_counter + 1;
                    end
                end
                
                INIT_ENABLE_GYRO: begin
                    if (!spi_busy && spi_tx_ready) begin
                        case (byte_cnt)
                            0: begin spi_tx_data <= 8'd17; spi_tx_valid <= 1; spi_start <= 1; byte_cnt <= byte_cnt + 1; end
                            1: begin spi_tx_data <= 8'd0; spi_tx_valid <= 1; spi_start <= 1; byte_cnt <= byte_cnt + 1; end
                            2: begin spi_tx_data <= CHANNEL_CONTROL; spi_tx_valid <= 1; spi_start <= 1; byte_cnt <= byte_cnt + 1; end
                            3: begin spi_tx_data <= 8'd2; spi_tx_valid <= 1; spi_start <= 1; byte_cnt <= byte_cnt + 1; end
                            4: begin spi_tx_data <= CMD_SET_FEATURE; spi_tx_valid <= 1; spi_start <= 1; byte_cnt <= byte_cnt + 1; end
                            5: begin spi_tx_data <= REPORT_ID_GYROSCOPE; spi_tx_valid <= 1; spi_start <= 1; byte_cnt <= byte_cnt + 1; end
                            6: begin spi_tx_data <= 8'd0; spi_tx_valid <= 1; spi_start <= 1; byte_cnt <= byte_cnt + 1; end
                            7: begin spi_tx_data <= 8'd0; spi_tx_valid <= 1; spi_start <= 1; byte_cnt <= byte_cnt + 1; end
                            8: begin spi_tx_data <= 8'd0; spi_tx_valid <= 1; spi_start <= 1; byte_cnt <= byte_cnt + 1; end
                            9: begin spi_tx_data <= 8'd0; spi_tx_valid <= 1; spi_start <= 1; byte_cnt <= byte_cnt + 1; end
                            10: begin spi_tx_data <= 8'd50; spi_tx_valid <= 1; spi_start <= 1; byte_cnt <= byte_cnt + 1; end
                            11: begin spi_tx_data <= 8'd0; spi_tx_valid <= 1; spi_start <= 1; byte_cnt <= byte_cnt + 1; end
                            12: begin spi_tx_data <= 8'd0; spi_tx_valid <= 1; spi_start <= 1; byte_cnt <= byte_cnt + 1; end
                            13: begin 
                                spi_tx_data <= 8'd0; 
                                spi_tx_valid <= 1; 
                                spi_start <= 1; 
                                byte_cnt <= byte_cnt + 1; 
                            end
                            14: begin
                                cs_n <= 1'b1;
                                byte_cnt <= 8'd0;
                                initialized <= 1'b1;
                                state <= WAIT_DATA;
                            end
                        endcase
                    end
                end
                
                WAIT_DATA: begin
                    cs_n <= 1'b1;
                    // Wait for INT pin LOW (level triggered)
                    if (!int_n_sync || (init_counter > 32'd300_000)) begin
                        state <= READ_HEADER_START;
                        byte_cnt <= 8'd0;
                        init_counter <= 32'd0;
                    end else begin
                        init_counter <= init_counter + 1;
                    end
                end

                READ_HEADER_START: begin
                    cs_n <= 1'b0;
                    // Wait for INT to be LOW if it wasn't already (should be if edge triggered)
                    if (!int_n_sync || init_counter > 32'd30000) begin
                        state <= READ_HEADER;
                        // Start first byte read
                        spi_tx_data <= 8'h00;
                        spi_tx_valid <= 1'b1;
                        spi_start <= 1'b1;
                        byte_cnt <= 8'd0;
                    end else begin
                        init_counter <= init_counter + 1;
                    end
                end
                
                READ_HEADER: begin
                    if (spi_rx_valid && !spi_busy) begin
                        case (byte_cnt)
                            0: begin
                                packet_length[7:0] <= spi_rx_data;
                                byte_cnt <= byte_cnt + 1;
                                spi_tx_data <= 8'h00; spi_tx_valid <= 1; spi_start <= 1;
                            end
                            1: begin
                                packet_length[15:8] <= spi_rx_data;
                                byte_cnt <= byte_cnt + 1;
                                spi_tx_data <= 8'h00; spi_tx_valid <= 1; spi_start <= 1;
                            end
                            2: begin
                                channel <= spi_rx_data;
                                byte_cnt <= byte_cnt + 1;
                                spi_tx_data <= 8'h00; spi_tx_valid <= 1; spi_start <= 1;
                            end
                            3: begin
                                seq_num <= spi_rx_data;
                                byte_cnt <= 8'd0;
                                if (packet_length > 4) begin
                                    state <= READ_PAYLOAD;
                                    spi_tx_data <= 8'h00; spi_tx_valid <= 1; spi_start <= 1;
                                end else begin
                                    cs_n <= 1'b1; // Short packet, done
                                    state <= WAIT_DATA;
                                end
                            end
                        endcase
                    end
                end
                
                READ_PAYLOAD: begin
                    if (spi_rx_valid && !spi_busy) begin
                        if (byte_cnt < packet_length - 4 && byte_cnt < 64) begin
                            data_buffer[byte_cnt] <= spi_rx_data;
                            byte_cnt <= byte_cnt + 1;
                            
                            if (byte_cnt < packet_length - 5 && byte_cnt < 63) begin
                                spi_tx_data <= 8'h00; spi_tx_valid <= 1; spi_start <= 1;
                            end else begin
                                // Last byte read
                                cs_n <= 1'b1;
                                byte_cnt <= 8'd0;
                                state <= PARSE_REPORT;
                            end
                        end else begin
                            cs_n <= 1'b1;
                            byte_cnt <= 8'd0;
                            state <= PARSE_REPORT;
                        end
                    end
                end
                
                PARSE_REPORT: begin
                    // Parse logic same as before
                    if (channel == CHANNEL_REPORTS && byte_cnt < 64) begin
                        report_id <= data_buffer[0];
                        
                        if (report_id == REPORT_ID_ROTATION_VECTOR) begin
                            quat_w <= {data_buffer[13], data_buffer[12]};
                            quat_x <= {data_buffer[5], data_buffer[4]};
                            quat_y <= {data_buffer[9], data_buffer[8]};
                            quat_z <= {data_buffer[17], data_buffer[16]};
                            quat_valid <= 1'b1;
                        end else if (report_id == REPORT_ID_GYROSCOPE) begin
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
                    cs_n <= 1'b1;
                    state <= ERROR_STATE;
                end
                
                default: state <= IDLE;
            endcase
        end
    end
    
endmodule
