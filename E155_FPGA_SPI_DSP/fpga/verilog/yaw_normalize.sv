// Yaw Normalization Module
// Normalizes yaw angle to 0-360 degree range
// Implements: yaw = fmod(yaw, 360.0); if (yaw < 0) yaw += 360.0;
// Author: E155 Final Project
// Date: 2024

module yaw_normalize (
    input  logic        clk,
    input  logic        rst_n,
    
    // Input: Yaw angle in degrees (Q8 format: 1.0 degree = 256)
    input  logic signed [15:0] yaw_in,
    input  logic signed [15:0] yaw_offset,  // Calibration offset
    input  logic        data_valid,
    
    // Output: Normalized yaw (0-360 degrees)
    output logic [15:0] yaw_out,  // 0-360 degrees in Q8 format
    output logic        yaw_valid
);

    // Fixed-point: Q8 format (1.0 degree = 256)
    // 360 degrees = 92160 (360 * 256)
    localparam [15:0] YAW_360 = 16'd92160;
    
    logic signed [16:0] yaw_adjusted;  // 17-bit for subtraction
    logic signed [15:0] yaw_normalized;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            yaw_adjusted <= '0;
            yaw_normalized <= '0;
            yaw_out <= '0;
            yaw_valid <= 1'b0;
        end else if (data_valid) begin
            // Subtract offset: yaw - yaw_offset
            yaw_adjusted <= $signed(yaw_in) - $signed(yaw_offset);
            
            // Normalize to 0-360 range
            if (yaw_adjusted < 0) begin
                yaw_normalized <= yaw_adjusted + YAW_360;
            end else if (yaw_adjusted >= YAW_360) begin
                yaw_normalized <= yaw_adjusted - YAW_360;
            end else begin
                yaw_normalized <= yaw_adjusted[15:0];
            end
            
            // Ensure positive (0-360)
            if (yaw_normalized < 0) begin
                yaw_out <= yaw_normalized + YAW_360;
            end else if (yaw_normalized >= YAW_360) begin
                yaw_out <= yaw_normalized - YAW_360;
            end else begin
                yaw_out <= yaw_normalized;
            end
            
            yaw_valid <= 1'b1;
        end else begin
            yaw_valid <= 1'b0;
        end
    end

endmodule

