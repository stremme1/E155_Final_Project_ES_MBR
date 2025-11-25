
// BNO085 Controller Module
// Handles SHTP (Sensor Hub Transport Protocol) communication over SPI
// Reads Rotation Vector (quaternion) and Gyroscope reports
// Optimized for low resource usage (no large buffers)

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
        ERROR_STATE
    } state_t;
    
    state_t state;
    logic [7:0] byte_cnt;
    logic [15:0] packet_length;
    logic [7:0] seq_num;
    logic [7:0] channel;
    logic [7:0] current_report_id;
    
    // REMOVED: Large data buffer to save resources
    // logic [7:0] data_buffer [0:63];
    
    logic [31:0] init_counter;
    
    // INT pin handling
    logic int_n_sync, int_n_prev;
    logic int_falling_edge;
    // Handshake state for robust SPI Master control
    // 0: Ready to send
    // 1: Start asserted, waiting for BUSY
    // 2: Start deasserted, waiting for DONE (!BUSY)
    logic [1:0] spi_handshake;
    
    // Temporary storage for parsing
    logic [7:0] temp_byte_lsb;

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
            spi_handshake <= 2'd0;
            current_report_id <= 8'd0;
            temp_byte_lsb <= 8'd0;
            
            quat_w <= 16'd0;
            quat_x <= 16'd0;
            quat_y <= 16'd0;
            quat_z <= 16'd0;
            gyro_x <= 16'd0;
            gyro_y <= 16'd0;
            gyro_z <= 16'd0;
            
        end else begin
            // Default assignments (overridden in states)
            // spi_start must be held in state 1, cleared in 0 and 2
            if (spi_handshake == 0 || spi_handshake == 2) begin
                spi_start <= 1'b0;
                spi_tx_valid <= 1'b0;
            end
            
            // Pulse outputs
            quat_valid <= 1'b0;
            gyro_valid <= 1'b0;
            
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
                    // STRICT HANDSHAKE: Do NOT proceed until INT goes low
                    if (!int_n_sync) begin 
                        state <= INIT_PRODUCT_ID;
                        byte_cnt <= 8'd0;
                        init_counter <= 32'd0;
                        // Pre-load first byte data to ensure stability before start
                        spi_tx_data <= 8'd4; 
                    end 
                end

                INIT_PRODUCT_ID: begin
                    if (spi_handshake == 0) begin
                        if (!spi_busy && spi_tx_ready) begin
                            case (byte_cnt)
                                0: begin spi_tx_data <= 8'd4; spi_tx_valid <= 1; spi_start <= 1; spi_handshake <= 1; end
                                1: begin spi_tx_data <= 8'd0; spi_tx_valid <= 1; spi_start <= 1; spi_handshake <= 1; end
                                2: begin spi_tx_data <= CHANNEL_CONTROL; spi_tx_valid <= 1; spi_start <= 1; spi_handshake <= 1; end
                                3: begin spi_tx_data <= 8'd0; spi_tx_valid <= 1; spi_start <= 1; spi_handshake <= 1; end
                                4: begin 
                                    spi_tx_data <= CMD_PRODUCT_ID_REQUEST; 
                                    spi_tx_valid <= 1; 
                                    spi_start <= 1;
                                    spi_handshake <= 1;
                                end
                                5: begin
                                    cs_n <= 1'b1; // Deassert CS after last byte sent
                                    byte_cnt <= 8'd0;
                                    state <= INIT_DELAY_1;
                                end
                            endcase
                        end
                    end else if (spi_handshake == 1) begin
                        // Wait for BUSY assertion
                        spi_start <= 1; // Hold Start
                        spi_tx_valid <= 1;
                        if (spi_busy) begin
                            spi_start <= 0; 
                            spi_handshake <= 2;
                        end
                    end else if (spi_handshake == 2) begin
                        // Wait for DONE (!BUSY)
                        if (!spi_busy) begin
                            byte_cnt <= byte_cnt + 1;
                            spi_handshake <= 0;
                        end
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
                    if (!int_n_sync) begin
                        state <= INIT_ENABLE_ROTATION;
                        byte_cnt <= 8'd0;
                        init_counter <= 32'd0;
                        spi_tx_data <= 8'd17; // Pre-load
                    end
                end
                
                INIT_ENABLE_ROTATION: begin
                    if (spi_handshake == 0) begin
                        if (!spi_busy && spi_tx_ready) begin
                            case (byte_cnt)
                                0: begin spi_tx_data <= 8'd17; spi_tx_valid <= 1; spi_start <= 1; spi_handshake <= 1; end
                                1: begin spi_tx_data <= 8'd0; spi_tx_valid <= 1; spi_start <= 1; spi_handshake <= 1; end
                                2: begin spi_tx_data <= CHANNEL_CONTROL; spi_tx_valid <= 1; spi_start <= 1; spi_handshake <= 1; end
                                3: begin spi_tx_data <= 8'd1; spi_tx_valid <= 1; spi_start <= 1; spi_handshake <= 1; end
                                4: begin spi_tx_data <= CMD_SET_FEATURE; spi_tx_valid <= 1; spi_start <= 1; spi_handshake <= 1; end
                                5: begin spi_tx_data <= REPORT_ID_ROTATION_VECTOR; spi_tx_valid <= 1; spi_start <= 1; spi_handshake <= 1; end
                                6: begin spi_tx_data <= 8'd0; spi_tx_valid <= 1; spi_start <= 1; spi_handshake <= 1; end
                                7: begin spi_tx_data <= 8'd0; spi_tx_valid <= 1; spi_start <= 1; spi_handshake <= 1; end
                                8: begin spi_tx_data <= 8'd0; spi_tx_valid <= 1; spi_start <= 1; spi_handshake <= 1; end
                                9: begin spi_tx_data <= 8'd0; spi_tx_valid <= 1; spi_start <= 1; spi_handshake <= 1; end
                                10: begin spi_tx_data <= 8'd50; spi_tx_valid <= 1; spi_start <= 1; spi_handshake <= 1; end
                                11: begin spi_tx_data <= 8'd0; spi_tx_valid <= 1; spi_start <= 1; spi_handshake <= 1; end
                                12: begin spi_tx_data <= 8'd0; spi_tx_valid <= 1; spi_start <= 1; spi_handshake <= 1; end
                                13: begin 
                                    spi_tx_data <= 8'd0; 
                                    spi_tx_valid <= 1; 
                                    spi_start <= 1; 
                                    spi_handshake <= 1; 
                                end
                                14: begin
                                    cs_n <= 1'b1;
                                    byte_cnt <= 8'd0;
                                    state <= INIT_DELAY_2;
                                end
                            endcase
                        end
                    end else if (spi_handshake == 1) begin
                        spi_start <= 1; 
                        spi_tx_valid <= 1;
                        if (spi_busy) begin
                            spi_start <= 0; 
                            spi_handshake <= 2;
                        end
                    end else if (spi_handshake == 2) begin
                        if (!spi_busy) begin
                            byte_cnt <= byte_cnt + 1;
                            spi_handshake <= 0;
                        end
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
                    if (!int_n_sync) begin
                        state <= INIT_ENABLE_GYRO;
                        byte_cnt <= 8'd0;
                        init_counter <= 32'd0;
                        spi_tx_data <= 8'd17; // Pre-load
                    end
                end
                
                INIT_ENABLE_GYRO: begin
                    if (spi_handshake == 0) begin
                        if (!spi_busy && spi_tx_ready) begin
                            case (byte_cnt)
                                0: begin spi_tx_data <= 8'd17; spi_tx_valid <= 1; spi_start <= 1; spi_handshake <= 1; end
                                1: begin spi_tx_data <= 8'd0; spi_tx_valid <= 1; spi_start <= 1; spi_handshake <= 1; end
                                2: begin spi_tx_data <= CHANNEL_CONTROL; spi_tx_valid <= 1; spi_start <= 1; spi_handshake <= 1; end
                                3: begin spi_tx_data <= 8'd2; spi_tx_valid <= 1; spi_start <= 1; spi_handshake <= 1; end
                                4: begin spi_tx_data <= CMD_SET_FEATURE; spi_tx_valid <= 1; spi_start <= 1; spi_handshake <= 1; end
                                5: begin spi_tx_data <= REPORT_ID_GYROSCOPE; spi_tx_valid <= 1; spi_start <= 1; spi_handshake <= 1; end
                                6: begin spi_tx_data <= 8'd0; spi_tx_valid <= 1; spi_start <= 1; spi_handshake <= 1; end
                                7: begin spi_tx_data <= 8'd0; spi_tx_valid <= 1; spi_start <= 1; spi_handshake <= 1; end
                                8: begin spi_tx_data <= 8'd0; spi_tx_valid <= 1; spi_start <= 1; spi_handshake <= 1; end
                                9: begin spi_tx_data <= 8'd0; spi_tx_valid <= 1; spi_start <= 1; spi_handshake <= 1; end
                                10: begin spi_tx_data <= 8'd50; spi_tx_valid <= 1; spi_start <= 1; spi_handshake <= 1; end
                                11: begin spi_tx_data <= 8'd0; spi_tx_valid <= 1; spi_start <= 1; spi_handshake <= 1; end
                                12: begin spi_tx_data <= 8'd0; spi_tx_valid <= 1; spi_start <= 1; spi_handshake <= 1; end
                                13: begin 
                                    spi_tx_data <= 8'd0; 
                                    spi_tx_valid <= 1; 
                                    spi_start <= 1; 
                                    spi_handshake <= 1; 
                                end
                                14: begin
                                    cs_n <= 1'b1;
                                    byte_cnt <= 8'd0;
                                    initialized <= 1'b1;
                                    state <= WAIT_DATA;
                                end
                            endcase
                        end
                    end else if (spi_handshake == 1) begin
                        spi_start <= 1; 
                        spi_tx_valid <= 1;
                        if (spi_busy) begin
                            spi_start <= 0; 
                            spi_handshake <= 2;
                        end
                    end else if (spi_handshake == 2) begin
                        if (!spi_busy) begin
                            byte_cnt <= byte_cnt + 1;
                            spi_handshake <= 0;
                        end
                    end
                end
                
                WAIT_DATA: begin
                    cs_n <= 1'b1;
                    // Wait for INT pin LOW (level triggered)
                    // Strictly wait for INT. No timeout.
                    if (!int_n_sync) begin
                        state <= READ_HEADER_START;
                        byte_cnt <= 8'd0;
                        init_counter <= 32'd0;
                    end
                end

                READ_HEADER_START: begin
                    cs_n <= 1'b0;
                    // Wait for INT to be LOW if it wasn't already (should be if edge triggered)
                    if (!int_n_sync) begin
                        state <= READ_HEADER;
                        // Start first byte read
                        spi_tx_data <= 8'h00;
                        spi_tx_valid <= 1'b1;
                        spi_start <= 1'b1;
                        byte_cnt <= 8'd0;
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
                            // Parse on the fly based on channel and report ID
                            
                            if (channel == CHANNEL_REPORTS) begin
                                if (byte_cnt == 0) begin
                                    current_report_id <= spi_rx_data;
                                end else if (current_report_id == REPORT_ID_ROTATION_VECTOR) begin
                                    // Rotation Vector (0x05):
                                    // Byte 4-5: i (X), 6-7: j (Y), 8-9: k (Z), 10-11: real (W)
                                    case (byte_cnt)
                                        4: temp_byte_lsb <= spi_rx_data;
                                        5: quat_x <= {spi_rx_data, temp_byte_lsb};
                                        6: temp_byte_lsb <= spi_rx_data;
                                        7: quat_y <= {spi_rx_data, temp_byte_lsb};
                                        8: temp_byte_lsb <= spi_rx_data;
                                        9: quat_z <= {spi_rx_data, temp_byte_lsb};
                                        10: temp_byte_lsb <= spi_rx_data;
                                        11: begin
                                            quat_w <= {spi_rx_data, temp_byte_lsb};
                                            quat_valid <= 1'b1; // Pulse valid
                                        end
                                    endcase
                                end else if (current_report_id == REPORT_ID_GYROSCOPE) begin
                                    // Gyroscope (0x01):
                                    // Byte 4-5: X, 6-7: Y, 8-9: Z
                                    case (byte_cnt)
                                        4: temp_byte_lsb <= spi_rx_data;
                                        5: gyro_x <= {spi_rx_data, temp_byte_lsb};
                                        6: temp_byte_lsb <= spi_rx_data;
                                        7: gyro_y <= {spi_rx_data, temp_byte_lsb};
                                        8: temp_byte_lsb <= spi_rx_data;
                                        9: begin
                                            gyro_z <= {spi_rx_data, temp_byte_lsb};
                                            gyro_valid <= 1'b1; // Pulse valid
                                        end
                                    endcase
                                end
                            end

                            byte_cnt <= byte_cnt + 1;
                            
                            // Decide if we need to read more
                            if (byte_cnt < packet_length - 5 && byte_cnt < 63) begin
                                spi_tx_data <= 8'h00; spi_tx_valid <= 1; spi_start <= 1;
                            end else begin
                                // Last byte read
                                cs_n <= 1'b1;
                                byte_cnt <= 8'd0;
                                state <= WAIT_DATA;
                            end
                        end else begin
                            cs_n <= 1'b1;
                            byte_cnt <= 8'd0;
                            state <= WAIT_DATA;
                        end
                    end
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
