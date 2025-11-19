// Quaternion to Euler Angle Converter - OPTIMIZED FOR iCE40UP5K
// Converts quaternion (w, x, y, z) to Euler angles (yaw, pitch)
// Uses simplified fixed-point arithmetic and pipelined operations
// Time-multiplexed to share resources between two IMUs
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
    output logic signed [15:0] roll,   // Not used in gesture recognition, but kept for compatibility
    output logic        euler_valid
);

    // OPTIMIZATION: Simplified calculation using only needed operations
    // For gesture recognition, we only need yaw and pitch (roll not used)
    // Use simpler approximations to save LUTs
    
    // Stage 1: Pipeline input
    logic [15:0] quat_w_reg, quat_x_reg, quat_y_reg, quat_z_reg;
    logic data_valid_stage1;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            quat_w_reg <= 0;
            quat_x_reg <= 0;
            quat_y_reg <= 0;
            quat_z_reg <= 0;
            data_valid_stage1 <= 0;
        end else begin
            quat_w_reg <= quat_w;
            quat_x_reg <= quat_x;
            quat_y_reg <= quat_y;
            quat_z_reg <= quat_z;
            data_valid_stage1 <= data_valid;
        end
    end
    
    // Stage 2: Calculate products (pipelined to reduce combinational logic)
    // Use 16-bit signed arithmetic to save resources
    logic signed [15:0] w, x, y, z;
    logic signed [31:0] wz, xy, wy, zx;
    logic data_valid_stage2;
    
    assign w = quat_w_reg;
    assign x = quat_x_reg;
    assign y = quat_y_reg;
    assign z = quat_z_reg;
    
    // Calculate products (16-bit * 16-bit = 32-bit, but we only need MSBs)
    // Use right shift to reduce bit width and save LUTs
    assign wz = (w * z) >>> 14;  // Q14 * Q14 = Q28, shift to Q14
    assign xy = (x * y) >>> 14;
    assign wy = (w * y) >>> 14;
    assign zx = (z * x) >>> 14;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_valid_stage2 <= 0;
        end else begin
            data_valid_stage2 <= data_valid_stage1;
        end
    end
    
    // Stage 3: Calculate numerators and denominators
    logic signed [15:0] yaw_num, yaw_den;
    logic signed [15:0] pitch_num;
    logic signed [15:0] roll_num, roll_den;
    logic data_valid_stage3;
    
    // Yaw: atan2(2*(w*z + x*y), 1 - 2*(y*y + z*z))
    // Simplified: use 16-bit arithmetic
    logic signed [15:0] wz_xy_sum, yz_sum;
    logic signed [15:0] y_sq, z_sq;
    
    assign wz_xy_sum = (wz[15:0] + xy[15:0]) << 1;  // 2*(w*z + x*y)
    assign y_sq = (y * y) >>> 14;
    assign z_sq = (z * z) >>> 14;
    assign yz_sum = (y_sq + z_sq) << 1;  // 2*(y*y + z*z)
    assign yaw_num = wz_xy_sum;
    assign yaw_den = 16'sd16384 - yz_sum;  // 1 in Q14 format (16384 = 1.0)
    
    // Pitch: asin(2*(w*y - z*x))
    assign pitch_num = (wy[15:0] - zx[15:0]) << 1;  // 2*(w*y - z*x)
    
    // Roll: atan2(2*(w*x + y*z), 1 - 2*(x*x + y*y))
    logic signed [15:0] wx, yz, x_sq;
    assign wx = (w * x) >>> 14;
    assign yz = (y * z) >>> 14;
    assign x_sq = (x * x) >>> 14;
    assign roll_num = (wx + yz) << 1;
    assign roll_den = 16'sd16384 - ((x_sq + y_sq) << 1);
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_valid_stage3 <= 0;
        end else begin
            data_valid_stage3 <= data_valid_stage2;
        end
    end
    
    // Stage 4: Simplified angle calculation (avoid expensive division)
    // Use linear approximation: atan2(y, x) ≈ (y/x) * 5729 for small angles
    // For larger angles, use quadrant detection and piecewise linear
    logic signed [15:0] yaw_result, pitch_result, roll_result;
    logic data_valid_stage4;
    
    // Simplified atan2: use ratio with scaling, avoid division
    // Scale: 5729 = (180/π) * 100 in Q format
    // Instead of division, use multiplication by reciprocal approximation
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            yaw_result <= 0;
            pitch_result <= 0;
            roll_result <= 0;
            data_valid_stage4 <= 0;
        end else if (data_valid_stage3) begin
            // Yaw calculation - simplified to avoid division
            // Use: result ≈ (num * 5729) / den
            // Approximate division using multiplication by reciprocal
            if (yaw_den != 0 && yaw_den > 16'sd100) begin  // Avoid division by very small numbers
                // Simplified: multiply numerator by scale, then approximate divide
                // Use bit shifts for division by powers of 2
                logic signed [31:0] yaw_temp;
                yaw_temp = (yaw_num * 16'sd5729);
                // Approximate division: find closest power of 2
                if (yaw_den >= 16'sd8192) begin
                    yaw_result <= yaw_temp[31:16];  // Divide by 16384 (>> 14)
                end else if (yaw_den >= 16'sd4096) begin
                    yaw_result <= yaw_temp[30:15];  // Divide by 32768 (>> 15)
                end else begin
                    yaw_result <= yaw_temp[29:14];  // Divide by 16384 (>> 14)
                end
            end else begin
                yaw_result <= 0;
            end
            
            // Pitch: asin approximation
            // asin(x) ≈ x * 5729 / 16384 for small x
            if (pitch_num < 16'sd16384 && pitch_num > -16'sd16384) begin
                pitch_result <= (pitch_num * 16'sd5729) >>> 14;
            end else if (pitch_num >= 16'sd16384) begin
                pitch_result <= 16'sd9000;  // Clamp to 90 degrees
            end else begin
                pitch_result <= -16'sd9000;  // Clamp to -90 degrees
            end
            
            // Roll: similar to yaw
            if (roll_den != 0 && roll_den > 16'sd100) begin
                logic signed [31:0] roll_temp;
                roll_temp = (roll_num * 16'sd5729);
                if (roll_den >= 16'sd8192) begin
                    roll_result <= roll_temp[31:16];
                end else if (roll_den >= 16'sd4096) begin
                    roll_result <= roll_temp[30:15];
                end else begin
                    roll_result <= roll_temp[29:14];
                end
            end else begin
                roll_result <= 0;
            end
            
            data_valid_stage4 <= 1;
        end else begin
            data_valid_stage4 <= 0;
        end
    end
    
    // Stage 5: Output
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            yaw <= 0;
            pitch <= 0;
            roll <= 0;
            euler_valid <= 0;
        end else begin
            yaw <= yaw_result;
            pitch <= pitch_result;
            roll <= roll_result;
            euler_valid <= data_valid_stage4;
        end
    end

endmodule
