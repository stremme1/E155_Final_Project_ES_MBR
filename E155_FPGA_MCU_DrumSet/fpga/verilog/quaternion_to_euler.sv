// Quaternion to Euler Angle Converter - ULTRA-OPTIMIZED FOR iCE40UP5K
// Converts quaternion (w, x, y, z) to Euler angles (yaw, pitch only)
// REMOVED: Roll calculation (not used in gesture recognition)
// Uses minimal fixed-point arithmetic with aggressive optimizations
// Author: E155 Final Project
// Date: 2024

module quaternion_to_euler (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        data_valid,
    input  logic [15:0] quat_w,  // Signed 16-bit, Q14 format
    input  logic [15:0] quat_x,
    input  logic [15:0] quat_y,
    input  logic [15:0] quat_z,
    output logic signed [15:0] yaw,    // Degrees * 100
    output logic signed [15:0] pitch,
    output logic signed [15:0] roll,   // Always 0 (not calculated to save resources)
    output logic        euler_valid
);

    // ULTRA-OPTIMIZATION: Minimal pipeline (3 stages instead of 5)
    // Only calculate yaw and pitch - roll removed entirely
    
    // Stage 1: Register inputs
    logic [15:0] quat_w_reg, quat_x_reg, quat_y_reg, quat_z_reg;
    logic data_valid_reg1;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            quat_w_reg <= 0;
            quat_x_reg <= 0;
            quat_y_reg <= 0;
            quat_z_reg <= 0;
            data_valid_reg1 <= 0;
        end else begin
            quat_w_reg <= quat_w;
            quat_x_reg <= quat_x;
            quat_y_reg <= quat_y;
            quat_z_reg <= quat_z;
            data_valid_reg1 <= data_valid;
        end
    end
    
    // Stage 2: Calculate products (minimal multiplications)
    // Use 16-bit arithmetic only - no 32-bit intermediates
    logic signed [15:0] w, x, y, z;
    logic signed [15:0] wz_approx, xy_approx, wy_approx, zx_approx;
    logic signed [15:0] y_sq_approx, z_sq_approx;
    logic data_valid_reg2;
    
    assign w = quat_w_reg;
    assign x = quat_x_reg;
    assign y = quat_y_reg;
    assign z = quat_z_reg;
    
    // ULTRA-OPTIMIZATION: Use approximate multiplications with reduced precision
    // Instead of full 16x16 multiply, use truncated multiply
    // (a * b) >> 14 approximates Q14 * Q14 = Q14
    assign wz_approx = ((w * z) >>> 14);
    assign xy_approx = ((x * y) >>> 14);
    assign wy_approx = ((w * y) >>> 14);
    assign zx_approx = ((z * x) >>> 14);
    assign y_sq_approx = ((y * y) >>> 14);
    assign z_sq_approx = ((z * z) >>> 14);
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_valid_reg2 <= 0;
        end else begin
            data_valid_reg2 <= data_valid_reg1;
        end
    end
    
    // Stage 3: Calculate yaw and pitch (ultra-simplified)
    // Yaw: atan2(2*(w*z + x*y), 1 - 2*(y*y + z*z))
    // Pitch: asin(2*(w*y - z*x))
    logic signed [15:0] yaw_num, yaw_den;
    logic signed [15:0] pitch_num;
    logic data_valid_reg3;
    
    // Calculate numerators and denominators (all 16-bit)
    logic signed [15:0] wz_xy_sum, yz_sum;
    assign wz_xy_sum = ((wz_approx + xy_approx) << 1);  // 2*(w*z + x*y)
    assign yz_sum = ((y_sq_approx + z_sq_approx) << 1);  // 2*(y*y + z*z)
    assign yaw_num = wz_xy_sum;
    assign yaw_den = 16'sd16384 - yz_sum;  // 1 - 2*(y*y + z*z) in Q14
    
    assign pitch_num = ((wy_approx - zx_approx) << 1);  // 2*(w*y - z*x)
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_valid_reg3 <= 0;
        end else begin
            data_valid_reg3 <= data_valid_reg2;
        end
    end
    
    // Stage 4: Ultra-simplified angle calculation
    // Use very simple linear approximation - no complex division
    logic signed [15:0] yaw_result, pitch_result;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            yaw_result <= 0;
            pitch_result <= 0;
            euler_valid <= 0;
        end else if (data_valid_reg3) begin
            // ULTRA-SIMPLIFIED: Use ratio directly with fixed scaling
            // atan2(y, x) ≈ (y * scale) / x for small angles
            // Use fixed shift instead of variable division
            if (yaw_den != 0 && yaw_den > 16'sd1000) begin
                // Very simple: (num * 5729) >> 14 approximates atan2
                // Scale factor 5729 = (180/π) * 100
                logic signed [31:0] yaw_temp;
                yaw_temp = yaw_num * 16'sd5729;
                // Fixed shift by 14 bits (divide by 16384)
                yaw_result <= yaw_temp[31:14];  // Simplified: always shift by 14
            end else begin
                yaw_result <= 0;
            end
            
            // Pitch: asin(x) ≈ x * 5729 / 16384 for small x
            if (pitch_num < 16'sd16384 && pitch_num > -16'sd16384) begin
                pitch_result <= (pitch_num * 16'sd5729) >>> 14;
            end else if (pitch_num >= 16'sd16384) begin
                pitch_result <= 16'sd9000;  // Clamp to 90 degrees
            end else begin
                pitch_result <= -16'sd9000;  // Clamp to -90 degrees
            end
            
            euler_valid <= 1;
        end else begin
            euler_valid <= 0;
        end
    end
    
    // Outputs
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            yaw <= 0;
            pitch <= 0;
            roll <= 0;  // Always 0 - not calculated
        end else begin
            yaw <= yaw_result;
            pitch <= pitch_result;
            roll <= 0;  // Always 0 - not calculated to save resources
        end
    end

endmodule
