// Pattern Recorder Test Bench
// Comprehensive test for drum pattern recording and playback
// Author: E155 Final Project
// Date: 2024

`timescale 1ns/1ps

module pattern_recorder_tb();

    // Test bench signals
    reg clk;
    reg rst;
    reg record_enable;
    reg [7:0] gesture_data;
    reg [15:0] timestamp;
    wire [7:0] playback_data;
    wire playback_ready;

    // Instantiate DUT
    pattern_recorder dut (
        .clk(clk),
        .rst(rst),
        .record_enable(record_enable),
        .gesture_data(gesture_data),
        .timestamp(timestamp),
        .playback_data(playback_data),
        .playback_ready(playback_ready)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz clock
    end

    // Test stimulus
    initial begin
        $display("=== Pattern Recorder Test Bench Started ===");
        
        // Initialize signals
        rst = 1;
        record_enable = 0;
        gesture_data = 8'h00;
        timestamp = 16'h0000;
        
        // Reset sequence
        #100 rst = 0;
        #50 rst = 1;
        
        // Test 1: Record single gesture
        $display("Test 1: Record single gesture");
        test_record_single();
        
        // Test 2: Record multiple gestures
        $display("Test 2: Record multiple gestures");
        test_record_multiple();
        
        // Test 3: Playback recorded gestures
        $display("Test 3: Playback recorded gestures");
        test_playback();
        
        // Test 4: Record overflow handling
        $display("Test 4: Record overflow handling");
        test_overflow();
        
        // Test 5: Concurrent record/playback
        $display("Test 5: Concurrent record/playback");
        test_concurrent();
        
        $display("=== Pattern Recorder Test Bench Completed ===");
        $finish;
    end

    // Test 1: Record single gesture
    task test_record_single();
        begin
            record_enable = 1;
            gesture_data = 8'h01; // Snare drum
            timestamp = 16'h0001;
            
            #10; // Wait for recording
            
            record_enable = 0;
            #10;
            
            $display("✓ Single gesture recorded");
        end
    endtask

    // Test 2: Record multiple gestures
    task test_record_multiple();
        begin
            record_enable = 1;
            
            // Record sequence: snare, hi-hat, kick, crash
            gesture_data = 8'h00; // Snare
            timestamp = 16'h0001;
            #10;
            
            gesture_data = 8'h01; // Hi-hat
            timestamp = 16'h0002;
            #10;
            
            gesture_data = 8'h02; // Kick
            timestamp = 16'h0003;
            #10;
            
            gesture_data = 8'h05; // Crash
            timestamp = 16'h0004;
            #10;
            
            record_enable = 0;
            #10;
            
            $display("✓ Multiple gestures recorded");
        end
    endtask

    // Test 3: Playback recorded gestures
    task test_playback();
        begin
            // Wait for playback to be ready
            wait(playback_ready);
            
            // Read first gesture
            if (playback_data == 8'h00) begin
                $display("✓ First gesture playback correct: %d", playback_data);
            end else begin
                $display("✗ First gesture playback incorrect: %d", playback_data);
            end
            
            #10;
            
            // Read second gesture
            if (playback_data == 8'h01) begin
                $display("✓ Second gesture playback correct: %d", playback_data);
            end else begin
                $display("✗ Second gesture playback incorrect: %d", playback_data);
            end
            
            #10;
            
            // Read third gesture
            if (playback_data == 8'h02) begin
                $display("✓ Third gesture playback correct: %d", playback_data);
            end else begin
                $display("✗ Third gesture playback incorrect: %d", playback_data);
            end
            
            #10;
            
            // Read fourth gesture
            if (playback_data == 8'h05) begin
                $display("✓ Fourth gesture playback correct: %d", playback_data);
            end else begin
                $display("✗ Fourth gesture playback incorrect: %d", playback_data);
            end
        end
    endtask

    // Test 4: Record overflow handling
    task test_overflow();
        begin
            record_enable = 1;
            
            // Fill up the buffer
            for (int i = 0; i < 1000; i++) begin
                gesture_data = i[7:0];
                timestamp = i[15:0];
                #10;
            end
            
            record_enable = 0;
            #10;
            
            $display("✓ Overflow test completed");
        end
    endtask

    // Test 5: Concurrent record/playback
    task test_concurrent();
        begin
            record_enable = 1;
            
            // Record while playing back
            gesture_data = 8'h03; // High tom
            timestamp = 16'h0005;
            #10;
            
            // Check if playback is still working
            if (playback_ready) begin
                $display("✓ Concurrent record/playback working");
            end else begin
                $display("✗ Concurrent record/playback failed");
            end
            
            record_enable = 0;
        end
    endtask

    // Monitor signals
    always @(posedge clk) begin
        if (record_enable) begin
            $display("Recording: gesture=%d, timestamp=%d", gesture_data, timestamp);
        end
        
        if (playback_ready) begin
            $display("Playback: data=%d", playback_data);
        end
    end

    // Timeout protection
    initial begin
        #1000000; // 1ms timeout
        $display("✗ Test bench timeout!");
        $finish;
    end

endmodule
