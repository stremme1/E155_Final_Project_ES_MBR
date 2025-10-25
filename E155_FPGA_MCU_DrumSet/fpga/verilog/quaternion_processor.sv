// Quaternion to Euler Angle Converter
// SystemVerilog implementation for real-time IMU processing
// Author: E155 Final Project
// Date: 2024

module quaternion_processor #(
    parameter DATA_WIDTH = 32,
    parameter FRAC_WIDTH = 16
)(
    input  logic                    clk,
    input  logic                    rst_n,
    input  logic                    data_valid,
    input  logic [DATA_WIDTH-1:0]   quat_w, quat_x, quat_y, quat_z,
    output logic [DATA_WIDTH-1:0]   roll, pitch, yaw,
    output logic                    euler_valid
);

    // Fixed-point arithmetic for quaternion to Euler conversion
    // Using CORDIC algorithm for efficient computation
    
    typedef struct packed {
        logic [DATA_WIDTH-1:0] w, x, y, z;
    } quaternion_t;
    
    typedef struct packed {
        logic [DATA_WIDTH-1:0] roll, pitch, yaw;
    } euler_t;
    
    quaternion_t quat_in;
    euler_t euler_out;
    
    // Pipeline stages for CORDIC computation
    logic [2:0] pipeline_valid;
    logic [DATA_WIDTH-1:0] roll_pipe [0:2];
    logic [DATA_WIDTH-1:0] pitch_pipe [0:2];
    logic [DATA_WIDTH-1:0] yaw_pipe [0:2];
    
    // Input register
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            quat_in <= '{w: 0, x: 0, y: 0, z: 0};
            pipeline_valid <= 0;
        end else begin
            if (data_valid) begin
                quat_in.w <= quat_w;
                quat_in.x <= quat_x;
                quat_in.y <= quat_y;
                quat_in.z <= quat_z;
                pipeline_valid[0] <= 1'b1;
            end else begin
                pipeline_valid[0] <= 1'b0;
            end
            
            // Pipeline the valid signal
            pipeline_valid[2:1] <= pipeline_valid[1:0];
        end
    end
    
    // Quaternion to Euler conversion using CORDIC
    // Roll (x-axis rotation)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            roll_pipe[0] <= 0;
        end else begin
            // atan2(2*(w*x + y*z), 1 - 2*(x*x + y*y))
            roll_pipe[0] <= compute_atan2(
                (quat_in.w * quat_in.x + quat_in.y * quat_in.z) << 1,
                (1 << FRAC_WIDTH) - ((quat_in.x * quat_in.x + quat_in.y * quat_in.y) << 1)
            );
        end
    end
    
    // Pitch (y-axis rotation)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pitch_pipe[0] <= 0;
        end else begin
            // asin(2*(w*y - z*x))
            pitch_pipe[0] <= compute_asin(
                (quat_in.w * quat_in.y - quat_in.z * quat_in.x) << 1
            );
        end
    end
    
    // Yaw (z-axis rotation)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            yaw_pipe[0] <= 0;
        end else begin
            // atan2(2*(w*z + x*y), 1 - 2*(y*y + z*z))
            yaw_pipe[0] <= compute_atan2(
                (quat_in.w * quat_in.z + quat_in.x * quat_in.y) << 1,
                (1 << FRAC_WIDTH) - ((quat_in.y * quat_in.y + quat_in.z * quat_in.z) << 1)
            );
        end
    end
    
    // Pipeline stages for CORDIC computation
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            roll_pipe[2:1] <= '{0, 0};
            pitch_pipe[2:1] <= '{0, 0};
            yaw_pipe[2:1] <= '{0, 0};
        end else begin
            roll_pipe[2:1] <= roll_pipe[1:0];
            pitch_pipe[2:1] <= pitch_pipe[1:0];
            yaw_pipe[2:1] <= yaw_pipe[1:0];
        end
    end
    
    // Output assignment
    assign roll = roll_pipe[2];
    assign pitch = pitch_pipe[2];
    assign yaw = yaw_pipe[2];
    assign euler_valid = pipeline_valid[2];
    
    // CORDIC atan2 function
    function automatic logic [DATA_WIDTH-1:0] compute_atan2(
        input logic [DATA_WIDTH-1:0] y,
        input logic [DATA_WIDTH-1:0] x
    );
        // Simplified CORDIC atan2 implementation
        // This would be expanded with full CORDIC algorithm
        logic [DATA_WIDTH-1:0] result;
        if (x == 0) begin
            result = (y >= 0) ? (90 << FRAC_WIDTH) : (-90 << FRAC_WIDTH);
        end else begin
            // Simplified approximation
            result = (y * (90 << FRAC_WIDTH)) / x;
        end
        return result;
    endfunction
    
    // CORDIC asin function
    function automatic logic [DATA_WIDTH-1:0] compute_asin(
        input logic [DATA_WIDTH-1:0] value
    );
        // Simplified asin implementation
        // This would be expanded with full CORDIC algorithm
        logic [DATA_WIDTH-1:0] result;
        if (value > (1 << FRAC_WIDTH)) begin
            result = 90 << FRAC_WIDTH;
        end else if (value < -(1 << FRAC_WIDTH)) begin
            result = -90 << FRAC_WIDTH;
        end else begin
            // Simplified approximation
            result = (value * (90 << FRAC_WIDTH)) >> FRAC_WIDTH;
        end
        return result;
    endfunction

endmodule
