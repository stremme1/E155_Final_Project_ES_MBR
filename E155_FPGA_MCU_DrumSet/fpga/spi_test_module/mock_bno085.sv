`timescale 1ns / 1ps

module mock_bno085 (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        cs_n,
    input  logic        sclk,
    input  logic        mosi,
    output logic        miso,
    output logic        int_n
);

    // Internal state
    logic [7:0] rx_byte;
    logic [2:0] bit_cnt;
    logic [7:0] tx_byte;
    
    // Response buffers
    logic [7:0] response_queue [0:255];
    integer response_ptr = 0;
    integer response_len = 0;

    // Simulation delays
    localparam INT_DELAY = 1000; // Time from CS low to INT low (in ns)

    initial begin
        miso = 0;
        int_n = 1;
    end

    // INT pin control logic
    always @(negedge cs_n) begin
        // Master initiated transfer. Acknowledge by pulling INT low after delay.
        #(INT_DELAY);
        int_n = 0;
        bit_cnt = 7;
        // Prepare first byte of response if available
        if (response_len > 0)
            tx_byte = response_queue[0];
        else
            tx_byte = 8'h00; // Default padding
    end

    always @(posedge cs_n) begin
        // Transfer done
        int_n = 1;
        // Reset buffer if we sent it (simplified)
        if (response_len > 0) begin
            // Assume we sent the packet
            response_len = 0;
            response_ptr = 0;
        end
    end

    // SPI Shift Logic
    always @(negedge sclk) begin
        if (!cs_n) begin
            // Shift out MISO (MSB first)
            miso = tx_byte[7];
            tx_byte = {tx_byte[6:0], 1'b0};
        end
    end

    always @(posedge sclk) begin
        if (!cs_n) begin
            // Sample MOSI
            rx_byte = {rx_byte[6:0], mosi};
            
            if (bit_cnt == 0) begin
                bit_cnt = 7;
                // Prepare next byte to send
                response_ptr = response_ptr + 1;
                if (response_ptr < response_len)
                    tx_byte = response_queue[response_ptr];
                else
                    tx_byte = 8'h00;
            end else begin
                bit_cnt = bit_cnt - 1;
            end
        end
    end

    // Task to queue a report packet (Rotation Vector)
    // Packet Structure (18 bytes):
    // Header (4): LenLSB, LenMSB, Channel, Seq
    // Payload (14):
    //   0: Report ID (0x05)
    //   1: Sequence (Dummy)
    //   2: Status (Dummy)
    //   3: Delay (Dummy)
    //   4-5: i (Q14)
    //   6-7: j (Q14)
    //   8-9: k (Q14)
    //   10-11: r (Q14)
    //   12-13: Accuracy
    task send_rotation_vector;
        input [15:0] i, j, k, r; // Quaternions
        begin
            // Header
            response_queue[0] = 18; // Length LSB
            response_queue[1] = 0;  // Length MSB
            response_queue[2] = 5;  // Channel (Input Report)
            response_queue[3] = 0;  // Seq
            
            // Report Body
            response_queue[4] = 5;  // Report ID (Rotation Vector)
            response_queue[5] = 0;  // Seq
            response_queue[6] = 0;  // Status
            response_queue[7] = 0;  // Delay
            
            // Q14 fixed point format
            response_queue[8] = i[7:0];   response_queue[9] = i[15:8];
            response_queue[10] = j[7:0];   response_queue[11] = j[15:8];
            response_queue[12] = k[7:0];   response_queue[13] = k[15:8];
            response_queue[14] = r[7:0];   response_queue[15] = r[15:8];
            
            response_queue[16] = 0; response_queue[17] = 0; // Accuracy (dummy)
            
            response_len = 18;
            response_ptr = 0;
            
            // Indicate data ready by pulling INT low
            #1000;
            int_n = 0;
        end
    endtask

endmodule
