// BNO085 Mock Model for Test Bench
// Simulates BNO085 SHTP protocol responses
// Author: E155 Final Project
// Date: 2024

module bno085_mock (
    input  logic        clk,
    input  logic        rst_n,
    
    // SPI Slave Interface
    input  logic        spi_sclk,
    input  logic        spi_mosi,
    output logic        spi_miso,
    input  logic        spi_cs_n,
    
    // Control
    input  logic        int_n_enable,  // Enable interrupt generation
    output logic        int_n,         // Interrupt output (active low)
    
    // Test Data Injection
    input  logic signed [16:0] test_quat_w, test_quat_x, test_quat_y, test_quat_z,  // Q16 needs 17 bits
    input  logic signed [15:0] test_gyro_x, test_gyro_y, test_gyro_z,
    input  logic        inject_data
);

    // SHTP Packet Structure
    // [Header Byte 0] [Header Byte 1] [Length LSB] [Length MSB] [Data...]
    
    logic [7:0] rx_shift_reg;
    logic [7:0] tx_shift_reg;
    logic [2:0] bit_counter;
    logic [3:0] byte_counter;
    logic spi_cs_prev;
    logic transaction_active;
    
    // Packet state
    typedef enum logic [2:0] {
        IDLE,
        RX_HEADER,
        RX_LENGTH,
        TX_RESPONSE
    } packet_state_t;
    
    packet_state_t state;
    
    // Response packet (quaternion report)
    logic [7:0] response_packet [0:15];
    logic [15:0] response_length;
    
    // Generate interrupt periodically
    logic [23:0] int_counter;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int_counter <= '0;
            int_n <= 1'b1;
        end else if (int_n_enable) begin
            if (int_counter >= 24'd2400000) begin  // ~50ms at 48MHz
                int_counter <= '0;
                int_n <= 1'b0;  // Assert interrupt
            end else begin
                int_counter <= int_counter + 1;
                if (int_counter > 24'd1000) begin
                    int_n <= 1'b1;  // Deassert after short pulse
                end
            end
        end else begin
            int_n <= 1'b1;
        end
    end
    
    // SPI Slave State Machine
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            bit_counter <= '0;
            byte_counter <= '0;
            rx_shift_reg <= '0;
            tx_shift_reg <= '0;
            transaction_active <= 1'b0;
            spi_cs_prev <= 1'b1;
        end else begin
            spi_cs_prev <= spi_cs_n;
            
            // Detect CS falling edge (start of transaction)
            if (!spi_cs_n && spi_cs_prev) begin
                state <= RX_HEADER;
                bit_counter <= '0;
                byte_counter <= '0;
                transaction_active <= 1'b1;
            end
            // Detect CS rising edge (end of transaction)
            else if (spi_cs_n && !spi_cs_prev) begin
                state <= IDLE;
                transaction_active <= 1'b0;
            end
            
            // SPI clock edge detection (falling edge for Mode 3)
            if (!spi_cs_n && !spi_sclk && transaction_active) begin
                // Shift in MOSI data
                rx_shift_reg <= {rx_shift_reg[6:0], spi_mosi};
                bit_counter <= bit_counter + 1;
                
                if (bit_counter == 7) begin
                    byte_counter <= byte_counter + 1;
                    bit_counter <= '0;
                    
                    case (state)
                        RX_HEADER: begin
                            if (byte_counter == 1) begin
                                state <= RX_LENGTH;
                            end
                        end
                        RX_LENGTH: begin
                            if (byte_counter == 3) begin
                                state <= TX_RESPONSE;
                                // Prepare response packet
                                response_packet[0] <= 8'h05;  // Report ID: Quaternion
                                response_packet[1] <= 8'h00;  // Reserved
                                response_packet[2] <= test_quat_w[7:0];
                                response_packet[3] <= test_quat_w[15:8];
                                response_packet[4] <= test_quat_x[7:0];
                                response_packet[5] <= test_quat_x[15:8];
                                response_packet[6] <= test_quat_y[7:0];
                                response_packet[7] <= test_quat_y[15:8];
                                response_packet[8] <= test_quat_z[7:0];
                                response_packet[9] <= test_quat_z[15:8];
                                response_length <= 16'd10;
                                byte_counter <= '0;
                            end
                        end
                        TX_RESPONSE: begin
                            if (byte_counter < response_length) begin
                                tx_shift_reg <= response_packet[byte_counter];
                            end
                        end
                    endcase
                end
            end
        end
    end
    
    // MISO output (shift out on rising edge for Mode 3)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            spi_miso <= 1'b0;
        end else if (!spi_cs_n && spi_sclk && state == TX_RESPONSE) begin
            spi_miso <= tx_shift_reg[7];
            tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
        end else begin
            spi_miso <= 1'bZ;
        end
    end

endmodule

