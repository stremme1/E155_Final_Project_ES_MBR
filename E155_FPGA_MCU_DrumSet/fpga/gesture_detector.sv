// Gesture Detection Module
// Implements the same logic from main.c for drum set gesture recognition
// Detects drum hits based on yaw zones, pitch angles, and gyro thresholds

module gesture_detector (
    input  logic        clk,
    input  logic        rst_n,
    
    // Sensor data inputs (right hand - IMU 1)
    input  logic        data_valid_1,
    input  logic signed [15:0] yaw1,
    input  logic signed [15:0] pitch1,
    input  logic signed [15:0] gyro1_x,
    input  logic signed [15:0] gyro1_y,
    input  logic signed [15:0] gyro1_z,
    
    // Sensor data inputs (left hand - IMU 2)
    input  logic        data_valid_2,
    input  logic signed [15:0] yaw2,
    input  logic signed [15:0] pitch2,
    input  logic signed [15:0] gyro2_x,
    input  logic signed [15:0] gyro2_y,
    input  logic signed [15:0] gyro2_z,
    
    // Yaw offsets for calibration
    input  logic signed [15:0] yaw_offset1,
    input  logic signed [15:0] yaw_offset2,
    
    // Calibration button (resets yaw offsets)
    input  logic        calib_button,
    
    // Output: Drum sound code (0-7)
    output logic        sound_valid,
    output logic [3:0]  sound_code,  // 0=snare, 1=hihat, 2=kick, 3=high_tom, 4=mid_tom, 5=crash, 6=ride, 7=floor_tom
    
    // Status
    output logic        calib_active
);

    // Thresholds (matching main.c values)
    localparam logic signed [15:0] GYRO_Y_THRESHOLD = -16'd2500;  // Strike detection threshold
    localparam logic signed [15:0] GYRO_Z_THRESHOLD = -16'd2000;   // Hi-hat rotation threshold
    localparam logic signed [15:0] PITCH_CRASH = 16'd50;          // Pitch threshold for crash/ride
    localparam logic signed [15:0] PITCH_RIDE = 16'd30;           // Pitch threshold for ride
    
    // Normalized yaw values
    logic signed [15:0] yaw1_norm, yaw2_norm;
    
    // Debounce flags for strike detection
    logic printed_gyro1_y, printed_gyro2_y;
    logic [15:0] last_gyro1_y, last_gyro2_y;
    
    // Calibration logic with debouncing
    // Debounce parameters: 50ms at 3MHz = 150,000 cycles
    localparam logic [31:0] DEBOUNCE_COUNT = 32'd150_000;  // 50ms debounce at 3MHz
    logic calib_button_sync1, calib_button_sync2;  // Double synchronize
    logic calib_button_prev;
    logic [31:0] debounce_counter;
    logic calib_button_debounced;
    
    // Normalize yaw to 0-360 range
    function logic signed [15:0] normalize_yaw(logic signed [15:0] yaw_in);
        logic signed [15:0] yaw_temp;
        logic signed [15:0] yaw_abs;
        // Handle modulo for signed numbers
        if (yaw_in < 0) begin
            yaw_abs = -yaw_in;
            yaw_temp = 16'd360 - (yaw_abs % 16'd360);
            if (yaw_temp == 16'd360) yaw_temp = 16'd0;
        end else begin
            yaw_temp = yaw_in % 16'd360;
        end
        return yaw_temp;
    endfunction
    
    // Button synchronization and debouncing
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            calib_button_sync1 <= 1'b0;
            calib_button_sync2 <= 1'b0;
            calib_button_prev <= 1'b0;
            calib_button_debounced <= 1'b0;
            debounce_counter <= 32'd0;
        end else begin
            // Double synchronize asynchronous button signal
            calib_button_sync1 <= calib_button;
            calib_button_sync2 <= calib_button_sync1;
            
            // Debounce logic
            if (calib_button_sync2 != calib_button_debounced) begin
                // Button state changed - start debounce counter
                debounce_counter <= debounce_counter + 1;
                if (debounce_counter >= DEBOUNCE_COUNT) begin
                    // Debounce period elapsed - update debounced signal
                    calib_button_debounced <= calib_button_sync2;
                    debounce_counter <= 32'd0;
                end
            end else begin
                // Button state stable - reset counter
                debounce_counter <= 32'd0;
            end
            
            calib_button_prev <= calib_button_debounced;
        end
    end
    
    // Apply yaw offset and normalize
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            yaw1_norm <= 16'd0;
            yaw2_norm <= 16'd0;
            calib_active <= 1'b0;
        end else begin
            // Calibration: Signal to top level to capture offsets when button is held
            // Top level handles the data validity check before capturing
            calib_active <= calib_button_debounced;
            
            // Normalize yaw values using input offsets (captured by top level)
            if (data_valid_1) begin
                yaw1_norm <= normalize_yaw(yaw1 - yaw_offset1);
            end
            if (data_valid_2) begin
                yaw2_norm <= normalize_yaw(yaw2 - yaw_offset2);
            end
        end
    end
    
    // Right hand gesture detection (IMU 1)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            printed_gyro1_y <= 1'b0;
            last_gyro1_y <= 16'd0;
        end else begin
            if (data_valid_1) begin
                last_gyro1_y <= gyro1_y;
                
                // Zone 1: Yaw 20-120 -> Snare drum
                if (yaw1_norm >= 16'd20 && yaw1_norm <= 16'd120) begin
                    if (gyro1_y < GYRO_Y_THRESHOLD && !printed_gyro1_y) begin
                        printed_gyro1_y <= 1'b1;
                    end else if (gyro1_y >= GYRO_Y_THRESHOLD && printed_gyro1_y) begin
                        printed_gyro1_y <= 1'b0;
                    end
                end
                // Zone 2: Yaw 340-20 -> High tom or Crash
                else if ((yaw1_norm >= 16'd340) || (yaw1_norm <= 16'd20)) begin
                    if (gyro1_y < GYRO_Y_THRESHOLD && !printed_gyro1_y) begin
                        printed_gyro1_y <= 1'b1;
                    end else if (gyro1_y >= GYRO_Y_THRESHOLD && printed_gyro1_y) begin
                        printed_gyro1_y <= 1'b0;
                    end
                end
                // Zone 3: Yaw 305-340 -> Mid tom or Ride
                else if (yaw1_norm >= 16'd305 && yaw1_norm <= 16'd340) begin
                    if (gyro1_y < GYRO_Y_THRESHOLD && !printed_gyro1_y) begin
                        printed_gyro1_y <= 1'b1;
                    end else if (gyro1_y >= GYRO_Y_THRESHOLD && printed_gyro1_y) begin
                        printed_gyro1_y <= 1'b0;
                    end
                end
                // Zone 4: Yaw 200-305 -> Floor tom or Ride
                else if (yaw1_norm >= 16'd200 && yaw1_norm <= 16'd305) begin
                    if (gyro1_y < GYRO_Y_THRESHOLD && !printed_gyro1_y) begin
                        printed_gyro1_y <= 1'b1;
                    end else if (gyro1_y >= GYRO_Y_THRESHOLD && printed_gyro1_y) begin
                        printed_gyro1_y <= 1'b0;
                    end
                end
            end else begin
                // When data_valid_1 is false, keep printed_gyro1_y state
                // This allows the rising edge to be detected even if data_valid goes low
            end
        end
    end
    
    // Left hand gesture detection (IMU 2)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            printed_gyro2_y <= 1'b0;
            last_gyro2_y <= 16'd0;
        end else begin
            if (data_valid_2) begin
                last_gyro2_y <= gyro2_y;
                
                // Always reset printed_gyro2_y when gyro is above threshold (regardless of zone)
                if (gyro2_y >= GYRO_Y_THRESHOLD && printed_gyro2_y) begin
                    printed_gyro2_y <= 1'b0;
                end
                // Set printed_gyro2_y when gyro is below threshold AND in correct zone
                else if (gyro2_y < GYRO_Y_THRESHOLD && !printed_gyro2_y) begin
                    // Zone 1: Yaw 350-100 -> Snare or Hi-hat
                    if ((yaw2_norm >= 16'd350) || (yaw2_norm <= 16'd100)) begin
                        printed_gyro2_y <= 1'b1;
                    end
                    // Zone 2: Yaw 325-350 -> High tom or Crash
                    else if (yaw2_norm >= 16'd325 && yaw2_norm <= 16'd350) begin
                        printed_gyro2_y <= 1'b1;
                    end
                    // Zone 3: Yaw 300-325 -> Mid tom or Ride
                    else if (yaw2_norm >= 16'd300 && yaw2_norm <= 16'd325) begin
                        printed_gyro2_y <= 1'b1;
                    end
                    // Zone 4: Yaw 200-300 -> Floor tom or Ride
                    else if (yaw2_norm >= 16'd200 && yaw2_norm <= 16'd300) begin
                        printed_gyro2_y <= 1'b1;
                    end
                end
            end else begin
                // When data_valid_2 is false, keep printed_gyro2_y state
            end
        end
    end
    
    // Sound code generation logic (sequential)
    logic sound_valid_reg;
    logic [3:0] sound_code_reg;
    logic printed_gyro1_y_prev, printed_gyro2_y_prev;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sound_valid <= 1'b0;
            sound_code <= 4'd0;
            sound_valid_reg <= 1'b0;
            sound_code_reg <= 4'd0;
            printed_gyro1_y_prev <= 1'b0;
            printed_gyro2_y_prev <= 1'b0;
        end else begin
            printed_gyro1_y_prev <= printed_gyro1_y;
            printed_gyro2_y_prev <= printed_gyro2_y;
            
            sound_valid <= 1'b0;
            sound_code <= 4'd0;
            
            // Right hand (IMU 1) sound detection - trigger on rising edge of printed_gyro1_y
            // Check rising edge: printed_gyro1_y=1 and printed_gyro1_y_prev=0
            // Note: We check last_gyro1_y instead of gyro1_y to use the value when data was valid
            if (printed_gyro1_y && !printed_gyro1_y_prev && (last_gyro1_y < GYRO_Y_THRESHOLD)) begin
                if (yaw1_norm >= 16'd20 && yaw1_norm <= 16'd120) begin
                    sound_code <= 4'd0;  // Snare
                    sound_valid <= 1'b1;
                end
                else if ((yaw1_norm >= 16'd340) || (yaw1_norm <= 16'd20)) begin
                    if (pitch1 > PITCH_CRASH) begin
                        sound_code <= 4'd5;  // Crash
                    end else begin
                        sound_code <= 4'd3;  // High tom
                    end
                    sound_valid <= 1'b1;
                end
                else if (yaw1_norm >= 16'd305 && yaw1_norm <= 16'd340) begin
                    if (pitch1 > PITCH_CRASH) begin
                        sound_code <= 4'd6;  // Ride
                    end else begin
                        sound_code <= 4'd4;  // Mid tom
                    end
                    sound_valid <= 1'b1;
                end
                else if (yaw1_norm >= 16'd200 && yaw1_norm <= 16'd305) begin
                    if (pitch1 > PITCH_RIDE) begin
                        sound_code <= 4'd6;  // Ride
                    end else begin
                        sound_code <= 4'd7;  // Floor tom
                    end
                    sound_valid <= 1'b1;
                end
            end
            
            // Left hand (IMU 2) sound detection - trigger on rising edge of printed_gyro2_y
            // Check rising edge: printed_gyro2_y=1 and printed_gyro2_y_prev=0
            // Note: We check last_gyro2_y instead of gyro2_y to use the value when data was valid
            if (printed_gyro2_y && !printed_gyro2_y_prev && (last_gyro2_y < GYRO_Y_THRESHOLD)) begin
                if ((yaw2_norm >= 16'd350) || (yaw2_norm <= 16'd100)) begin
                    if (pitch2 > PITCH_RIDE && gyro2_z > GYRO_Z_THRESHOLD) begin
                        sound_code <= 4'd1;  // Hi-hat
                    end else begin
                        sound_code <= 4'd0;  // Snare
                    end
                    sound_valid <= 1'b1;
                end
                else if (yaw2_norm >= 16'd325 && yaw2_norm <= 16'd350) begin
                    if (pitch2 > PITCH_CRASH) begin
                        sound_code <= 4'd5;  // Crash
                    end else begin
                        sound_code <= 4'd3;  // High tom
                    end
                    sound_valid <= 1'b1;
                end
                else if (yaw2_norm >= 16'd300 && yaw2_norm <= 16'd325) begin
                    if (pitch2 > PITCH_CRASH) begin
                        sound_code <= 4'd6;  // Ride
                    end else begin
                        sound_code <= 4'd4;  // Mid tom
                    end
                    sound_valid <= 1'b1;
                end
                else if (yaw2_norm >= 16'd200 && yaw2_norm <= 16'd300) begin
                    if (pitch2 > PITCH_RIDE) begin
                        sound_code <= 4'd6;  // Ride
                    end else begin
                        sound_code <= 4'd7;  // Floor tom
                    end
                    sound_valid <= 1'b1;
                end
            end
        end
    end
    
endmodule

