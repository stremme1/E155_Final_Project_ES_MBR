// Quaternion to Euler Angle Converter
// Converts quaternion (w, x, y, z) to Euler angles (yaw, pitch, roll)
// Uses fixed-point arithmetic for FPGA implementation
// Author: E155 Final Project
// Date: 2024

module quaternion_to_euler (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        data_valid,
    input  logic [15:0] quat_w,  // Signed 16-bit, Q14 format (1/16384)
    input  logic [15:0] quat_x,
    input  logic [15:0] quat_y,
    input  logic [15:0] quat_z,
    output logic signed [15:0] yaw,    // Degrees * 100 (e.g., 3600 = 36.00°)
    output logic signed [15:0] pitch,
    output logic signed [15:0] roll,
    output logic        euler_valid
);

    // Fixed-point representation:
    // Quaternions: Q14 format (divide by 16384 to get float)
    // Angles: Q2 format (divide by 100 to get degrees)
    
    // Intermediate calculations (32-bit for precision)
    logic signed [31:0] w, x, y, z;
    logic signed [31:0] w_sq, x_sq, y_sq, z_sq;
    logic signed [31:0] roll_num, roll_den;
    logic signed [31:0] pitch_num;
    logic signed [31:0] yaw_num, yaw_den;
    
    // Convert Q14 to internal Q16 format for calculations
    assign w = {quat_w[15], quat_w, 16'h0000};  // Sign extend and shift
    assign x = {quat_x[15], quat_x, 16'h0000};
    assign y = {quat_y[15], quat_y, 16'h0000};
    assign z = {quat_z[15], quat_z, 16'h0000};
    
    // Calculate squares
    assign w_sq = (w * w) >>> 16;  // Q16 * Q16 = Q32, shift to Q16
    assign x_sq = (x * x) >>> 16;
    assign y_sq = (y * y) >>> 16;
    assign z_sq = (z * z) >>> 16;
    
    // Roll: atan2(2*(w*x + y*z), 1 - 2*(x*x + y*y))
    // Numerator: 2*(w*x + y*z)
    logic signed [31:0] wx, yz, roll_num_temp;
    assign wx = (w * x) >>> 16;
    assign yz = (y * z) >>> 16;
    assign roll_num_temp = wx + yz;
    assign roll_num = roll_num_temp << 1;  // Multiply by 2
    
    // Denominator: 1 - 2*(x*x + y*y)
    logic signed [31:0] xy_sum, roll_den_temp;
    assign xy_sum = x_sq + y_sq;
    assign roll_den_temp = xy_sum << 1;  // Multiply by 2
    assign roll_den = (32'h00010000) - roll_den_temp;  // 1 in Q16 format
    
    // Pitch: asin(2*(w*y - z*x))
    logic signed [31:0] wy, zx, pitch_num_temp;
    assign wy = (w * y) >>> 16;
    assign zx = (z * x) >>> 16;
    assign pitch_num_temp = wy - zx;
    assign pitch_num = pitch_num_temp << 1;  // Multiply by 2
    
    // Yaw: atan2(2*(w*z + x*y), 1 - 2*(y*y + z*z))
    // Numerator: 2*(w*z + x*y)
    logic signed [31:0] wz, xy, yaw_num_temp;
    assign wz = (w * z) >>> 16;
    assign xy = (x * y) >>> 16;
    assign yaw_num_temp = wz + xy;
    assign yaw_num = yaw_num_temp << 1;  // Multiply by 2
    
    // Denominator: 1 - 2*(y*y + z*z)
    logic signed [31:0] yz_sum, yaw_den_temp;
    assign yz_sum = y_sq + z_sq;
    assign yaw_den_temp = yz_sum << 1;  // Multiply by 2
    assign yaw_den = (32'h00010000) - yaw_den_temp;  // 1 in Q16 format
    
    // CORDIC or lookup table for atan2 and asin
    // For now, simplified approximation
    // Note: This is a simplified version. For production, use CORDIC or lookup tables
    
    // Simplified atan2 approximation (linear in first quadrant)
    // atan2(y, x) ≈ (y/x) * (180/π) for small angles
    // For full range, use quadrant detection
    
    // Pipeline registers
    logic signed [31:0] roll_num_reg, roll_den_reg;
    logic signed [31:0] pitch_num_reg;
    logic signed [31:0] yaw_num_reg, yaw_den_reg;
    logic data_valid_reg;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            roll_num_reg <= 0;
            roll_den_reg <= 0;
            pitch_num_reg <= 0;
            yaw_num_reg <= 0;
            yaw_den_reg <= 0;
            data_valid_reg <= 0;
        end else begin
            roll_num_reg <= roll_num;
            roll_den_reg <= roll_den;
            pitch_num_reg <= pitch_num;
            yaw_num_reg <= yaw_num;
            yaw_den_reg <= yaw_den;
            data_valid_reg <= data_valid;
        end
    end
    
    // Simplified angle calculation (divide by 16384 to get float, multiply by 180/π, multiply by 100)
    // Scale factor: (180/π) * 100 / 16384 ≈ 0.35
    // For atan2: result ≈ (num/den) * 5729 (180/π * 100 in Q format)
    // For asin: similar approximation
    
    // Simplified implementation - use lookup table or CORDIC in production
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            roll <= 0;
            pitch <= 0;
            yaw <= 0;
            euler_valid <= 0;
        end else if (data_valid_reg) begin
            // Simplified: use ratio directly (this is approximate)
            // Production code should use proper atan2/asin functions
            // Division by zero protection
            if (roll_den_reg != 0) begin
                roll <= (roll_num_reg * 5729) / roll_den_reg;  // Approximate atan2
            end else begin
                roll <= 0;  // Default to 0 if denominator is zero
            end
            
            // Pitch: asin range is -1 to 1, so check bounds
            if (pitch_num_reg < 16384 && pitch_num_reg > -16384) begin
                pitch <= (pitch_num_reg * 5729) / 16384;  // Approximate asin
            end else if (pitch_num_reg >= 16384) begin
                pitch <= 16'd9000;  // Clamp to 90 degrees
            end else begin
                pitch <= -16'd9000;  // Clamp to -90 degrees
            end
            
            if (yaw_den_reg != 0) begin
                yaw <= (yaw_num_reg * 5729) / yaw_den_reg;  // Approximate atan2
            end else begin
                yaw <= 0;  // Default to 0 if denominator is zero
            end
            euler_valid <= 1;
        end else begin
            euler_valid <= 0;
        end
    end

endmodule

