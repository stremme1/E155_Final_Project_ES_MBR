// Quaternion to Euler Angle Converter
// Converts quaternion (w, x, y, z) to Euler angles (roll, pitch, yaw) in degrees
// Input: Q16 format (1.15 fixed point, range -1 to +1)
// Output: Degrees as signed 16-bit integer

module quaternion_to_euler (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        valid_in,
    input  logic signed [15:0] quat_w,  // Q16 format (1.15 fixed point)
    input  logic signed [15:0] quat_x,
    input  logic signed [15:0] quat_y,
    input  logic signed [15:0] quat_z,
    
    output logic        valid_out,
    output logic signed [15:0] roll,    // Degrees as signed integer
    output logic signed [15:0] pitch,
    output logic signed [15:0] yaw
);

    // Pipeline stage 1: Calculate squares and products
    logic signed [31:0] sq_w, sq_x, sq_y, sq_z;
    logic signed [31:0] wx, wy, wz, xy, xz, yz;
    logic signed [31:0] roll_num, roll_den, pitch_test, yaw_num, yaw_den;
    
    // Pipeline stage 2: Calculate angles (simplified - use CORDIC for production)
    logic signed [31:0] roll_rad_q16, pitch_rad_q16, yaw_rad_q16;
    logic signed [15:0] roll_deg, pitch_deg, yaw_deg;
    
    // Constants
    localparam logic signed [31:0] ONE_Q16 = 32'd32768;  // 1.0 in Q16
    localparam logic signed [31:0] TWO_Q16 = 32'd65536;  // 2.0 in Q16
    localparam logic signed [31:0] RAD_TO_DEG_Q16 = 32'd3754936;  // 180/pi * 65536
    
    // Use DSP blocks for multiplications - synthesis will infer DSP48/MULT18X18
    // Force DSP usage with (* use_dsp48 = "yes" *) or equivalent synthesis attributes
    (* use_dsp48 = "yes" *)
    logic signed [31:0] sq_w_dsp, sq_x_dsp, sq_y_dsp, sq_z_dsp;
    (* use_dsp48 = "yes" *)
    logic signed [31:0] wx_dsp, wy_dsp, wz_dsp, xy_dsp, xz_dsp, yz_dsp;
    
    // Pipeline valid signal through all stages (4 stages total)
    logic valid_stage1, valid_stage2, valid_stage3;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage1 <= 1'b0;
            valid_out <= 1'b0;
            roll <= 16'd0;
            pitch <= 16'd0;
            yaw <= 16'd0;
        end else begin
            // Pipeline valid signal through 4 stages
            valid_stage1 <= valid_in;      // Stage 1: DSP multiplications
            // Note: valid_stage2 and valid_stage3 are driven in their respective always_ff blocks below
            valid_out <= valid_stage3;     // Stage 4: Final conversion
            
            if (valid_in) begin
                // Calculate squares - will use DSP blocks
                sq_w_dsp <= quat_w * quat_w;
                sq_x_dsp <= quat_x * quat_x;
                sq_y_dsp <= quat_y * quat_y;
                sq_z_dsp <= quat_z * quat_z;
                
                // Calculate products - will use DSP blocks
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
    
    // Stage 2: Calculate intermediate values for Euler angles
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            roll_num <= 32'd0;
            roll_den <= 32'd0;
            pitch_test <= 32'd0;
            yaw_num <= 32'd0;
            yaw_den <= 32'd0;
            valid_stage2 <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;  // Pipeline valid signal
            if (valid_stage1) begin
                // Roll: atan2(2*(w*x + y*z), 1 - 2*(x^2 + y^2))
                roll_num <= TWO_Q16 * (wx + yz) / ONE_Q16;
                roll_den <= ONE_Q16 - (TWO_Q16 * (sq_x + sq_y) / ONE_Q16);
                
                // Pitch: asin(2*(w*y - z*x))
                pitch_test <= TWO_Q16 * (wy - xz) / ONE_Q16;
                
                // Yaw: atan2(2*(w*z + x*y), 1 - 2*(y^2 + z^2))
                yaw_num <= TWO_Q16 * (wz + xy) / ONE_Q16;
                yaw_den <= ONE_Q16 - (TWO_Q16 * (sq_y + sq_z) / ONE_Q16);
            end
        end
    end
    
    // Stage 3: Approximate atan2 and asin, convert to degrees
    // Simplified implementation - for production use CORDIC
    // Use DSP blocks for multiplications
    (* use_dsp48 = "yes" *)
    logic signed [47:0] roll_mult, pitch_mult, yaw_mult;
    logic signed [31:0] roll_rad_q16_reg, pitch_rad_q16_reg, yaw_rad_q16_reg;
    logic signed [31:0] pitch_test_clamped;
    
    // Stage 3: Approximate atan2 and asin
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            roll_rad_q16_reg <= 32'd0;
            pitch_rad_q16_reg <= 32'd0;
            yaw_rad_q16_reg <= 32'd0;
            pitch_test_clamped <= 32'd0;
            valid_stage3 <= 1'b0;
        end else begin
            valid_stage3 <= valid_stage2;  // Pipeline valid signal
            if (valid_stage2) begin
                // Roll: atan2 approximation
                if (roll_den != 0) begin
                    roll_rad_q16_reg <= (roll_num << 16) / roll_den;
                end else begin
                    roll_rad_q16_reg <= (roll_num >= 0) ? 32'd51471 : -32'd51471;  // ±pi/2
                end
                
                // Pitch: asin approximation (clamp input to [-1, 1])
                if (pitch_test > ONE_Q16) 
                    pitch_test_clamped <= ONE_Q16;
                else if (pitch_test < -ONE_Q16) 
                    pitch_test_clamped <= -ONE_Q16;
                else 
                    pitch_test_clamped <= pitch_test;
                
                pitch_rad_q16_reg <= pitch_test_clamped;  // Simplified: asin(x) ≈ x for small x
                
                // Yaw: atan2 approximation
                if (yaw_den != 0) begin
                    yaw_rad_q16_reg <= (yaw_num << 16) / yaw_den;
                end else begin
                    yaw_rad_q16_reg <= (yaw_num >= 0) ? 32'd51471 : -32'd51471;
                end
            end
        end
    end
    
    // Final stage: Convert radians to degrees - use DSP for multiplication
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            roll <= 16'd0;
            pitch <= 16'd0;
            yaw <= 16'd0;
        end else if (valid_stage3) begin
            // Convert radians to degrees - use DSP for multiplication
            roll_mult <= roll_rad_q16_reg * RAD_TO_DEG_Q16;
            pitch_mult <= pitch_rad_q16_reg * RAD_TO_DEG_Q16;
            yaw_mult <= yaw_rad_q16_reg * RAD_TO_DEG_Q16;
            
            roll <= roll_mult[31:16];  // Take upper bits after multiplication
            pitch <= pitch_mult[31:16];
            yaw <= yaw_mult[31:16];
        end
    end
    
endmodule

