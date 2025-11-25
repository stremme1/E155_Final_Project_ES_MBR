
// BNO085 Controller Module
// Handles SHTP (Sensor Hub Transport Protocol) communication over SPI
// Reads Rotation Vector (quaternion) and Gyroscope reports
// Optimized for low resource usage (ROM-based initialization, no large buffers)

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
    localparam [7:0] CHANNEL_REPORTS = 8'h05;
    localparam [7:0] REPORT_ID_ROTATION_VECTOR = 8'h05;
    localparam [7:0] REPORT_ID_GYROSCOPE = 8'h01;
    
    typedef enum logic [3:0] {
        IDLE,
        INIT_WAIT,
        INIT_SEND_CMD,
        INIT_DELAY,
        WAIT_DATA,
        READ_HEADER_START,
        READ_HEADER,
        READ_PAYLOAD,
        ERROR_STATE
    } state_t;
    
    state_t state;
    logic [7:0] byte_cnt;
    logic [15:0] packet_length;
    logic [7:0] channel;
    logic [7:0] current_report_id;
    
    // Reduced counter width (19 bits is enough for >300,000 counts)
    logic [18:0] init_counter;
    
    // Command selection
    logic [1:0] cmd_select; // 0=ProdID, 1=Rot, 2=Gyro
    
    // Handshake state
    logic [1:0] spi_handshake;
    
    // Temporary storage for parsing
    logic [7:0] temp_byte_lsb;
    
    // INT pin handling
    logic int_n_sync, int_n_prev;
    
    // ========================================================================
    // Initialization Command ROM
    // ========================================================================
    function [7:0] get_init_byte(input [1:0] cmd, input [7:0] idx);
        case (cmd)
            // Product ID Request (5 bytes): 04 00 00 00 F9
            2'd0: begin
                case (idx)
                    0: get_init_byte = 8'h04;
                    1: get_init_byte = 8'h00;
                    2: get_init_byte = 8'h00;
                    3: get_init_byte = 8'h00; // Seq 0
                    4: get_init_byte = 8'hF9;
                    default: get_init_byte = 8'h00;
                endcase
            end
            // Enable Rotation Vector (17 bytes)
            // 17 00 02 01 FD 05 00 00 00 32 00 00 00 00 00 00 00
            2'd1: begin
                case (idx)
                    0: get_init_byte = 8'd17;
                    1: get_init_byte = 8'h00;
                    2: get_init_byte = 8'h02; // Channel Control
                    3: get_init_byte = 8'd1;  // Seq 1
                    4: get_init_byte = 8'hFD; // Set Feature
                    5: get_init_byte = 8'h05; // Report ID (Rot Vec)
                    6: get_init_byte = 8'h00; // Flags
                    7: get_init_byte = 8'h00; // Sensitivity LSB
                    8: get_init_byte = 8'h00; // Sensitivity MSB
                    9: get_init_byte = 8'h32; // Report Interval LSB (50)
                    10: get_init_byte = 8'h00;
                    11: get_init_byte = 8'h00;
                    12: get_init_byte = 8'h00; // Report Interval MSB
                    default: get_init_byte = 8'h00;
                endcase
            end
            // Enable Gyroscope (17 bytes)
            // 17 00 02 02 FD 01 00 00 00 32 00 00 00 00 00 00 00
            2'd2: begin
                case (idx)
                    0: get_init_byte = 8'd17;
                    1: get_init_byte = 8'h00;
                    2: get_init_byte = 8'h02; // Channel Control
                    3: get_init_byte = 8'd2;  // Seq 2
                    4: get_init_byte = 8'hFD; // Set Feature
                    5: get_init_byte = 8'h01; // Report ID (Gyro)
                    6: get_init_byte = 8'h00; // Flags
                    7: get_init_byte = 8'h00; // Sensitivity LSB
                    8: get_init_byte = 8'h00; // Sensitivity MSB
                    9: get_init_byte = 8'h32; // Report Interval LSB (50)
                    10: get_init_byte = 8'h00;
                    11: get_init_byte = 8'h00;
                    12: get_init_byte = 8'h00; // Report Interval MSB
                    default: get_init_byte = 8'h00;
                endcase
            end
            default: get_init_byte = 8'h00;
        endcase
    endfunction
    
    // Command lengths
    function [7:0] get_cmd_len(input [1:0] cmd);
        case (cmd)
            2'd0: get_cmd_len = 8'd5;
            2'd1: get_cmd_len = 8'd17;
            2'd2: get_cmd_len = 8'd17;
            default: get_cmd_len = 8'd0;
        endcase
    endfunction

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int_n_sync <= 1'b1;
            int_n_prev <= 1'b1;
        end else begin
            int_n_sync <= int_n;
            int_n_prev <= int_n_sync;
        end
    end
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= INIT_WAIT;
            initialized <= 1'b0;
            error <= 1'b0;
            init_counter <= 19'd0;
            spi_start <= 1'b0;
            spi_tx_valid <= 1'b0;
            byte_cnt <= 8'd0;
            cs_n <= 1'b1;
            quat_valid <= 1'b0;
            gyro_valid <= 1'b0;
            spi_handshake <= 2'd0;
            current_report_id <= 8'd0;
            temp_byte_lsb <= 8'd0;
            cmd_select <= 2'd0;
            
            quat_w <= 16'd0;
            quat_x <= 16'd0;
            quat_y <= 16'd0;
            quat_z <= 16'd0;
            gyro_x <= 16'd0;
            gyro_y <= 16'd0;
            gyro_z <= 16'd0;
            
        end else begin
            // Default assignments
            if (spi_handshake == 0 || spi_handshake == 2) begin
                spi_start <= 1'b0;
                spi_tx_valid <= 1'b0;
            end
            
            quat_valid <= 1'b0;
            gyro_valid <= 1'b0;
            
            case (state)
                INIT_WAIT: begin
                    cs_n <= 1'b1;
                    // Wait ~100ms at 3MHz (300,000 ticks)
                    if (init_counter < 19'd300_000) begin
                        init_counter <= init_counter + 1;
                    end else begin
                        state <= INIT_SEND_CMD;
                        init_counter <= 19'd0;
                        cmd_select <= 2'd0; // Start with ProdID
                        byte_cnt <= 8'd0;
                        // Pre-assert CS to wake
                        cs_n <= 1'b0;
                    end
                end
                
                INIT_SEND_CMD: begin
                    // STRICT HANDSHAKE: Wait for INT low before clocking
                    if (byte_cnt == 0 && int_n_sync) begin
                        cs_n <= 1'b0;
                        // Stay here until INT goes low
                    end else begin
                        // INT is low (or we are mid-transfer), proceed
                        cs_n <= 1'b0;
                        
                        if (spi_handshake == 0) begin
                            if (!spi_busy && spi_tx_ready) begin
                                if (byte_cnt < get_cmd_len(cmd_select)) begin
                                    spi_tx_data <= get_init_byte(cmd_select, byte_cnt);
                                    spi_tx_valid <= 1'b1;
                                    spi_start <= 1'b1;
                                    spi_handshake <= 1;
                                end else begin
                                    // Done sending command
                                    cs_n <= 1'b1;
                                    byte_cnt <= 8'd0;
                                    state <= INIT_DELAY;
                                    init_counter <= 19'd0;
                                end
                            end
                        end else if (spi_handshake == 1) begin
                            spi_start <= 1'b1; // Hold start
                            spi_tx_valid <= 1'b1;
                            if (spi_busy) begin
                                spi_start <= 1'b0;
                                spi_handshake <= 2;
                            end
                        end else if (spi_handshake == 2) begin
                            if (!spi_busy) begin
                                byte_cnt <= byte_cnt + 1;
                                spi_handshake <= 0;
                            end
                        end
                    end
                end
                
                INIT_DELAY: begin
                    cs_n <= 1'b1;
                    // Small delay between commands (10ms = 30,000 ticks)
                    if (init_counter < 19'd30_000) begin
                        init_counter <= init_counter + 1;
                    end else begin
                        init_counter <= 19'd0;
                        if (cmd_select < 2'd2) begin
                            cmd_select <= cmd_select + 1;
                            state <= INIT_SEND_CMD;
                            cs_n <= 1'b0; // Wake up for next cmd
                        end else begin
                            initialized <= 1'b1;
                            state <= WAIT_DATA;
                        end
                    end
                end
                
                WAIT_DATA: begin
                    cs_n <= 1'b1;
                    // Wait for INT pin LOW (Data Ready)
                    if (!int_n_sync) begin
                        state <= READ_HEADER_START;
                        byte_cnt <= 8'd0;
                    end
                end

                READ_HEADER_START: begin
                    cs_n <= 1'b0;
                    // Redundant check, but safe: wait for INT low
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
                                // seq_num <= spi_rx_data; // Unused, optimize out
                                byte_cnt <= 8'd0;
                                if (packet_length > 4) begin
                                    state <= READ_PAYLOAD;
                                    spi_tx_data <= 8'h00; spi_tx_valid <= 1; spi_start <= 1;
                                end else begin
                                    cs_n <= 1'b1; // Short packet
                                    state <= WAIT_DATA;
                                end
                            end
                        endcase
                    end
                end
                
                READ_PAYLOAD: begin
                    if (spi_rx_valid && !spi_busy) begin
                        if (byte_cnt < packet_length - 4 && byte_cnt < 64) begin
                            // Parse on the fly
                            if (channel == CHANNEL_REPORTS) begin
                                if (byte_cnt == 0) begin
                                    current_report_id <= spi_rx_data;
                                end else if (current_report_id == REPORT_ID_ROTATION_VECTOR) begin
                                    // Rotation Vector (0x05)
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
                                            quat_valid <= 1'b1; 
                                        end
                                    endcase
                                end else if (current_report_id == REPORT_ID_GYROSCOPE) begin
                                    // Gyroscope (0x01)
                                    case (byte_cnt)
                                        4: temp_byte_lsb <= spi_rx_data;
                                        5: gyro_x <= {spi_rx_data, temp_byte_lsb};
                                        6: temp_byte_lsb <= spi_rx_data;
                                        7: gyro_y <= {spi_rx_data, temp_byte_lsb};
                                        8: temp_byte_lsb <= spi_rx_data;
                                        9: begin
                                            gyro_z <= {spi_rx_data, temp_byte_lsb};
                                            gyro_valid <= 1'b1;
                                        end
                                    endcase
                                end
                            end

                            byte_cnt <= byte_cnt + 1;
                            
                            if (byte_cnt < packet_length - 5 && byte_cnt < 63) begin
                                spi_tx_data <= 8'h00; spi_tx_valid <= 1; spi_start <= 1;
                            end else begin
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
