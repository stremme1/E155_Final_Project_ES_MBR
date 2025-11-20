// Quaternion to Euler Angle Converter - EXTREME OPTIMIZATION FOR iCE40UP5K
// Minimal 2-stage pipeline
// Ultra-simplified math - no complex calculations
// Author: E155 Final Project
// Date: 2024

module quaternion_to_euler (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        data_valid,
    input  logic [15:0] quat_w,
    input  logic [15:0] quat_x,
    input  logic [15:0] quat_y,
    input  logic [15:0] quat_z,
    output logic signed [15:0] yaw,
    output logic signed [15:0] pitch,
    output logic signed [15:0] roll,
    output logic        euler_valid
);

    // EXTREME: Only 2 stages (input register + calculation)
    logic [15:0] quat_w_reg, quat_x_reg, quat_y_reg, quat_z_reg;
    logic data_valid_reg;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            quat_w_reg <= 0;
            quat_x_reg <= 0;
            quat_y_reg <= 0;
            quat_z_reg <= 0;
            data_valid_reg <= 0;
        end else begin
            quat_w_reg <= quat_w;
            quat_x_reg <= quat_x;
            quat_y_reg <= quat_y;
            quat_z_reg <= quat_z;
            data_valid_reg <= data_valid;
        end
    end
    
    // EXTREME: Ultra-simplified calculation (minimal multiplications)
    // Use only essential calculations for yaw and pitch
    logic signed [15:0] wz_sum, xy_sum, wy_diff;
    logic signed [15:0] y_sq, z_sq;
    
    // Calculate only what's needed (simplified products)
    assign wz_sum = ((quat_w_reg * quat_z_reg) >>> 14) + ((quat_x_reg * quat_y_reg) >>> 14);
    assign wy_diff = ((quat_w_reg * quat_y_reg) >>> 14) - ((quat_z_reg * quat_x_reg) >>> 14);
    assign y_sq = (quat_y_reg * quat_y_reg) >>> 14;
    assign z_sq = (quat_z_reg * quat_z_reg) >>> 14;
    
    // EXTREME: Simplified angle calculation (no division, just scaling)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            yaw <= 0;
            pitch <= 0;
            roll <= 0;
            euler_valid <= 0;
        end else if (data_valid_reg) begin
            // Yaw: simplified approximation (wz_sum * scale_factor)
            // Use fixed scaling instead of division
            yaw <= (wz_sum * 16'sd5729) >>> 14;
            
            // Pitch: simplified approximation
            if (wy_diff < 16'sd16384 && wy_diff > -16'sd16384) begin
                pitch <= (wy_diff * 16'sd5729) >>> 14;
            end else if (wy_diff >= 16'sd16384) begin
                pitch <= 16'sd9000;
            end else begin
                pitch <= -16'sd9000;
            end
            
            roll <= 0;  // Always 0
            euler_valid <= 1;
        end else begin
            euler_valid <= 0;
        end
    end

endmodule
