// Quaternion to Euler Angle Converter
// Converts quaternion (w, x, y, z) to Euler angles (roll, pitch, yaw) in degrees
// Input: Q15 format (1.0 = 32768)
// Output: Degrees as signed 16-bit integer

module quaternion_to_euler (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        valid_in,
    input  logic signed [15:0] quat_w,  // Q15 format
    input  logic signed [15:0] quat_x,
    input  logic signed [15:0] quat_y,
    input  logic signed [15:0] quat_z,
    
    output logic        valid_out,
    output logic signed [15:0] roll,    // Degrees as signed integer
    output logic signed [15:0] pitch,
    output logic signed [15:0] yaw
);

    // Pipeline stage 1: Calculate squares and products
    // Q15 * Q15 = Q30
    logic signed [31:0] sq_w, sq_x, sq_y, sq_z;
    logic signed [31:0] wx, wy, wz, xy, xz, yz;
    logic signed [31:0] roll_num, roll_den, pitch_test, yaw_num, yaw_den;
    
    // Pipeline stage 2: Calculate angles
    logic signed [31:0] roll_rad_q16, pitch_rad_q16, yaw_rad_q16;
    
    // Constants
    localparam logic signed [31:0] ONE_Q30 = 32'd1073741824; // 1.0 in Q30 (2^30)
    localparam logic signed [31:0] RAD_TO_DEG_Q16 = 32'd3754936;  // 180/pi * 65536
    
    // Use DSP blocks for multiplications
    (* use_dsp48 = "yes" *)
    logic signed [31:0] sq_w_dsp, sq_x_dsp, sq_y_dsp, sq_z_dsp;
    (* use_dsp48 = "yes" *)
    logic signed [31:0] wx_dsp, wy_dsp, wz_dsp, xy_dsp, xz_dsp, yz_dsp;
    
    // Pipeline valid signal
    logic valid_stage1, valid_stage2, valid_stage3;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage1 <= 1'b0;
            valid_out <= 1'b0;
        end else begin
            valid_stage1 <= valid_in;
            valid_out <= valid_stage3;
            
            if (valid_in) begin
                // Calculate squares (Q30)
                sq_w_dsp <= quat_w * quat_w;
                sq_x_dsp <= quat_x * quat_x;
                sq_y_dsp <= quat_y * quat_y;
                sq_z_dsp <= quat_z * quat_z;
                
                // Calculate products (Q30)
                wx_dsp <= quat_w * quat_x;
                wy_dsp <= quat_w * quat_y;
                wz_dsp <= quat_w * quat_z;
                xy_dsp <= quat_x * quat_y;
                xz_dsp <= quat_x * quat_z;
                yz_dsp <= quat_y * quat_z;
            end
        end
    end
    
    // Register DSP outputs
    always_ff @(posedge clk) begin
        sq_w <= sq_w_dsp;
        sq_x <= sq_x_dsp;
        sq_y <= sq_y_dsp;
        sq_z <= sq_z_dsp;
        wx <= wx_dsp;
        wy <= wy_dsp;
        wz <= wz_dsp;
        xy <= xy_dsp;
        xz <= xz_dsp;
        yz <= yz_dsp;
    end
    
    // Stage 2: Calculate numerators and denominators
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            roll_num <= 32'd0;
            roll_den <= 32'd0;
            pitch_test <= 32'd0;
            yaw_num <= 32'd0;
            yaw_den <= 32'd0;
            valid_stage2 <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;
            if (valid_stage1) begin
                // Roll: atan2(2(wx + yz), 1 - 2(x^2 + y^2))
                // Terms are Q30. 2*Term is Q30 shifted 1.
                roll_num <= (wx + yz) <<< 1;
                roll_den <= ONE_Q30 - ((sq_x + sq_y) <<< 1);
                
                // Pitch: asin(2(wy - zx))
                pitch_test <= (wy - xz) <<< 1;
                
                // Yaw: atan2(2(wz + xy), 1 - 2(y^2 + z^2))
                yaw_num <= (wz + xy) <<< 1;
                yaw_den <= ONE_Q30 - ((sq_y + sq_z) <<< 1);
            end
        end
    end
    
    // Stage 3: Approximate atan2 and asin
    (* use_dsp48 = "yes" *)
    logic signed [47:0] roll_mult, pitch_mult, yaw_mult;
    logic signed [31:0] roll_rad_q16_reg, pitch_rad_q16_reg, yaw_rad_q16_reg;
    logic signed [31:0] pitch_test_clamped;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            roll_rad_q16_reg <= 32'd0;
            pitch_rad_q16_reg <= 32'd0;
            yaw_rad_q16_reg <= 32'd0;
            pitch_test_clamped <= 32'd0;
            valid_stage3 <= 1'b0;
        end else begin
            valid_stage3 <= valid_stage2;
            if (valid_stage2) begin
                // Roll: atan2 approximation
                // Output: Q16 radians
                if (roll_den != 0) begin
                    // (Q30 << 16) / Q30 = Q16
                    roll_rad_q16_reg <= (roll_num <<< 16) / roll_den;
                end else begin
                    roll_rad_q16_reg <= (roll_num >= 0) ? 32'd102943 : -32'd102943; // pi/2 in Q16
                end
                
                // Pitch: asin approximation (clamp input to [-1, 1] in Q30)
                if (pitch_test > ONE_Q30) 
                    pitch_test_clamped <= ONE_Q30;
                else if (pitch_test < -ONE_Q30) 
                    pitch_test_clamped <= -ONE_Q30;
                else 
                    pitch_test_clamped <= pitch_test;
                
                // Convert Q30 sin value to Q16 radians
                // Simplified: asin(x) ≈ x
                // Shift right by 14 to go from Q30 to Q16
                pitch_rad_q16_reg <= pitch_test_clamped >>> 14;
                
                // Yaw: atan2 approximation
                if (yaw_den != 0) begin
                    yaw_rad_q16_reg <= (yaw_num <<< 16) / yaw_den;
                end else begin
                    yaw_rad_q16_reg <= (yaw_num >= 0) ? 32'd102943 : -32'd102943;
                end
            end
        end
    end
    
    // Final stage: Convert radians to degrees
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            roll <= 16'd0;
            pitch <= 16'd0;
            yaw <= 16'd0;
        end else if (valid_stage3) begin
            // Q16 * Q16 = Q32 degrees
            roll_mult <= roll_rad_q16_reg * RAD_TO_DEG_Q16;
            pitch_mult <= pitch_rad_q16_reg * RAD_TO_DEG_Q16;
            yaw_mult <= yaw_rad_q16_reg * RAD_TO_DEG_Q16;
            
            // Extract integer part (top 16 bits of Q32 result)
            roll <= roll_mult[47:32];
            pitch <= pitch_mult[47:32];
            yaw <= yaw_mult[47:32];
        end
    end
    
endmodule
