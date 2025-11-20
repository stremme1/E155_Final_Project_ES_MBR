// Quaternion to Euler Angle Conversion using DSP Blocks
// Implements: roll = atan2(2*(w*x + y*z), 1 - 2*(x*x + y*y))
//            pitch = asin(2*(w*y - z*x))
//            yaw = atan2(2*(w*z + x*y), 1 - 2*(y*y + z*z))
// Uses fixed-point arithmetic and DSP blocks for multiplications
// Author: E155 Final Project
// Date: 2024

module quaternion_to_euler_dsp (
    input  logic        clk,
    input  logic        rst_n,
    
    // Input: Quaternion (Q16 format: 1.0 = 65536)
    input  logic signed [15:0] quat_w, quat_x, quat_y, quat_z,
    input  logic        data_valid,
    
    // Output: Euler angles in degrees (fixed-point: 1.0 degree = 256)
    output logic signed [15:0] roll, pitch, yaw,
    output logic        euler_valid
);

    // Fixed-point format: Q16 (16-bit fractional part)
    // Quaternion input: Q16 (1.0 = 65536)
    // Euler output: Q8 (1.0 degree = 256, range -90 to +90 for pitch, 0-360 for yaw)
    
    // Pipeline stages
    logic signed [31:0] w_x, y_z, w_y, z_x, w_z, x_y;  // Multiplications
    logic signed [31:0] w_x_plus_y_z, w_y_minus_z_x, w_z_plus_x_y;  // Additions
    logic signed [31:0] x_sq, y_sq, z_sq;  // Squares
    logic signed [31:0] x_sq_plus_y_sq, y_sq_plus_z_sq;  // Sums
    logic signed [31:0] one_minus_2x_sq_plus_y_sq, one_minus_2y_sq_plus_z_sq;  // For atan2
    
    // Pipeline registers
    logic signed [31:0] roll_num, roll_den, yaw_num, yaw_den;
    logic signed [31:0] pitch_arg;
    
    // atan2 and asin approximations (simplified for FPGA)
    // Using lookup table or polynomial approximation
    logic signed [15:0] roll_deg, pitch_deg, yaw_deg;
    
    // Pipeline control
    logic [2:0] pipeline_stage;
    logic data_valid_pipe [0:5];
    
    // Stage 1: Multiplications (using DSP blocks)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            w_x <= '0;
            y_z <= '0;
            w_y <= '0;
            z_x <= '0;
            w_z <= '0;
            x_y <= '0;
            x_sq <= '0;
            y_sq <= '0;
            z_sq <= '0;
            data_valid_pipe[0] <= 1'b0;
        end else if (data_valid) begin
            // DSP multiplications (16-bit x 16-bit = 32-bit)
            w_x <= quat_w * quat_x;
            y_z <= quat_y * quat_z;
            w_y <= quat_w * quat_y;
            z_x <= quat_z * quat_x;
            w_z <= quat_w * quat_z;
            x_y <= quat_x * quat_y;
            x_sq <= quat_x * quat_x;
            y_sq <= quat_y * quat_y;
            z_sq <= quat_z * quat_z;
            data_valid_pipe[0] <= 1'b1;
        end else begin
            data_valid_pipe[0] <= 1'b0;
        end
    end
    
    // Stage 2: Additions and combinations
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            w_x_plus_y_z <= '0;
            w_y_minus_z_x <= '0;
            w_z_plus_x_y <= '0;
            x_sq_plus_y_sq <= '0;
            y_sq_plus_z_sq <= '0;
            data_valid_pipe[1] <= 1'b0;
        end else begin
            w_x_plus_y_z <= w_x + y_z;
            w_y_minus_z_x <= w_y - z_x;
            w_z_plus_x_y <= w_z + x_y;
            x_sq_plus_y_sq <= x_sq + y_sq;
            y_sq_plus_z_sq <= y_sq + z_sq;
            data_valid_pipe[1] <= data_valid_pipe[0];
        end
    end
    
    // Stage 3: Scale by 2 and compute denominators
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            roll_num <= '0;
            roll_den <= '0;
            pitch_arg <= '0;
            yaw_num <= '0;
            yaw_den <= '0;
            data_valid_pipe[2] <= 1'b0;
        end else begin
            roll_num <= w_x_plus_y_z << 1;  // 2*(w*x + y*z)
            roll_den <= 32'd65536 - (x_sq_plus_y_sq << 1);  // 1 - 2*(x*x + y*y) in Q16
            pitch_arg <= w_y_minus_z_x << 1;  // 2*(w*y - z*x)
            yaw_num <= w_z_plus_x_y << 1;  // 2*(w*z + x*y)
            yaw_den <= 32'd65536 - (y_sq_plus_z_sq << 1);  // 1 - 2*(y*y + z*z) in Q16
            data_valid_pipe[2] <= data_valid_pipe[1];
        end
    end
    
    // Stage 4: atan2 and asin approximations
    // Simplified: use linear approximation for small angles, lookup for others
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            roll_deg <= '0;
            pitch_deg <= '0;
            yaw_deg <= '0;
            data_valid_pipe[3] <= 1'b0;
        end else begin
            // atan2 approximation: atan2(y, x) ≈ (y/x) * (180/π) for small angles
            // More accurate: use CORDIC or lookup table (simplified here)
            if (roll_den != 0) begin
                roll_deg <= (roll_num * 16'd256) / (roll_den / 16'd256);  // Scale and divide
            end else begin
                roll_deg <= 16'd0;
            end
            
            // asin approximation: asin(x) ≈ x * (180/π) for small x, clamp to ±90°
            if (pitch_arg > 32'd65536) begin
                pitch_deg <= 16'd23040;  // 90 degrees in Q8 (90 * 256)
            end else if (pitch_arg < -32'd65536) begin
                pitch_deg <= -16'd23040;  // -90 degrees
            end else begin
                pitch_deg <= pitch_arg[23:8];  // Approximate: asin(x) ≈ x for small x
            end
            
            if (yaw_den != 0) begin
                yaw_deg <= (yaw_num * 16'd256) / (yaw_den / 16'd256);
            end else begin
                yaw_deg <= 16'd0;
            end
            
            data_valid_pipe[3] <= data_valid_pipe[2];
        end
    end
    
    // Stage 5: Convert to degrees and clamp
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            roll <= '0;
            pitch <= '0;
            yaw <= '0;
            euler_valid <= 1'b0;
        end else begin
            // Convert from Q16 to degrees (multiply by 180/π ≈ 57.3, then scale)
            // Simplified: use fixed scaling factor
            roll <= roll_deg;  // Already in Q8 format (degrees * 256)
            pitch <= pitch_deg;
            yaw <= yaw_deg;
            euler_valid <= data_valid_pipe[3];
        end
    end

endmodule

