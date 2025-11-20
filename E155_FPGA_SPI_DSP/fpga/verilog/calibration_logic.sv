// Calibration Logic Module
// Stores yaw offsets when button2 is pressed
// Matching C code: yawOffset1 = yaw1; yawOffset2 = yaw2;
// Author: E155 Final Project
// Date: 2024

module calibration_logic (
    input  logic        clk,
    input  logic        rst_n,
    
    // Input: Current yaw values
    input  logic [15:0] yaw1_current,
    input  logic [15:0] yaw2_current,
    input  logic        yaw_valid,
    
    // Calibration trigger
    input  logic        button2,              // Calibration button
    
    // Output: Yaw offsets
    output logic signed [15:0] yaw_offset1,
    output logic signed [15:0] yaw_offset2,
    output logic        calibration_active    // LED indicator
);

    logic button2_prev;
    logic button2_debounced;
    logic [15:0] button2_debounce_counter;
    
    // Button2 debouncing (50ms = 2400000 cycles at 48MHz)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            button2_prev <= 1'b0;
            button2_debounced <= 1'b0;
            button2_debounce_counter <= '0;
            yaw_offset1 <= '0;
            yaw_offset2 <= '0;
            calibration_active <= 1'b0;
        end else begin
            button2_prev <= button2;
            
            // Debounce logic
            if (button2 != button2_prev) begin
                button2_debounce_counter <= '0;
            end else if (button2_debounce_counter < 16'd2400000) begin
                button2_debounce_counter <= button2_debounce_counter + 1;
            end else begin
                button2_debounced <= button2;
            end
            
            // Calibration: Store current yaw values as offsets
            if (button2_debounced && yaw_valid) begin
                yaw_offset1 <= $signed(yaw1_current);
                yaw_offset2 <= $signed(yaw2_current);
                calibration_active <= 1'b1;
            end else if (!button2_debounced) begin
                calibration_active <= 1'b0;
            end
        end
    end

endmodule

