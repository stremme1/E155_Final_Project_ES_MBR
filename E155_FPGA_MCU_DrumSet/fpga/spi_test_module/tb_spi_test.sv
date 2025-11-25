`timescale 1ns / 1ps

module tb_spi_test;

    // Signal declarations matching spi_test_top
    logic rst_n;
    logic sclk1;
    logic mosi1;
    logic miso1;
    logic cs_n1;
    logic int1;
    logic led_initialized;
    logic led_error;
    logic led_heartbeat;

    // Instantiate the DUT (Device Under Test)
    spi_test_top dut (
        .rst_n(rst_n),
        .sclk1(sclk1),
        .mosi1(mosi1),
        .miso1(miso1),
        .cs_n1(cs_n1),
        .int1(int1),
        .led_initialized(led_initialized),
        .led_error(led_error),
        .led_heartbeat(led_heartbeat)
    );

    // Instantiate the Mock BNO085 Sensor
    mock_bno085 sensor_model (
        .clk(dut.clk), // Peek at internal clock for synchronization if needed
        .rst_n(rst_n),
        .cs_n(cs_n1),
        .sclk(sclk1),
        .mosi(mosi1),
        .miso(miso1),
        .int_n(int1)
    );

    // Accelerator: Skip long delays
    initial begin
        wait(rst_n == 1);
        forever begin
            @(posedge dut.clk);
            // INIT_WAIT (State 1): Limit is 300,000
            if (dut.bno085_ctrl_inst.state == 1) begin 
                 if (dut.bno085_ctrl_inst.init_counter < 19'd299_900) begin
                     force dut.bno085_ctrl_inst.init_counter = 19'd299_990;
                     @(posedge dut.clk); // Wait for one clock to ensure it takes effect
                     release dut.bno085_ctrl_inst.init_counter;
                     //$display("Accelerator: Skipped INIT_WAIT");
                 end
            end
            // INIT_DELAY (State 3): Limit is 30,000
            else if (dut.bno085_ctrl_inst.state == 3) begin 
                 if (dut.bno085_ctrl_inst.init_counter < 19'd29_900) begin
                     force dut.bno085_ctrl_inst.init_counter = 19'd29_990;
                     @(posedge dut.clk); // Wait for one clock
                     release dut.bno085_ctrl_inst.init_counter;
                     //$display("Accelerator: Skipped INIT_DELAY");
                 end
            end
        end
    end

    // Simulation Control
    initial begin
        $dumpfile("spi_test.vcd");
        $dumpvars(0, tb_spi_test);

        $display("Starting SPI Test Simulation...");
        
        // 1. Reset System
        rst_n = 0;
        #1000;
        rst_n = 1;
        $display("Reset released.");

        // 2. Wait for Initialization Sequence
        
        // Wait for Initialization to complete
        fork
            begin
                // Wait for initialized signal
                wait(dut.bno085_ctrl_inst.initialized == 1);
                $display("Controller Initialized! LED status: %b", led_initialized);
            end
            begin
                // Timeout after 50ms (simulation time) - enough even with partial skipping
                #50000000; 
                $display("TIMEOUT waiting for initialization!");
                $display("Current State: %d", dut.bno085_ctrl_inst.state);
                $display("Byte Count: %d", dut.bno085_ctrl_inst.byte_cnt);
                $display("INT_N: %b", int1);
                $display("CS_N: %b", cs_n1);
                $display("Init Counter: %d", dut.bno085_ctrl_inst.init_counter);
                $display("CMD Select: %d", dut.bno085_ctrl_inst.cmd_select);
                $finish;
            end
        join_any

        // 3. Send Data Reports
        // Now controller is in WAIT_DATA state.
        // Send a Quaternion: W=1.0 (0x4000), X=0, Y=0, Z=0
        #5000;
        $display("Sending Rotation Vector...");
        sensor_model.send_rotation_vector(16'd0, 16'd0, 16'd0, 16'h4000); // x, y, z, w (real)
        
        // Wait for packet to be read
        fork
            begin
                wait(dut.bno085_ctrl_inst.quat_valid == 1);
                $display("Quaternion Valid! W=%h X=%h Y=%h Z=%h", 
                         dut.bno085_ctrl_inst.quat_w, 
                         dut.bno085_ctrl_inst.quat_x, 
                         dut.bno085_ctrl_inst.quat_y, 
                         dut.bno085_ctrl_inst.quat_z);

                if (dut.bno085_ctrl_inst.quat_w == 16'h4000)
                    $display("TEST PASS: Quaternion received correctly.");
                else
                    $display("TEST FAIL: Quaternion mismatch.");
            end
            begin
                #2000000; // 2ms timeout for reading packet
                $display("TIMEOUT waiting for quaternion data!");
                $finish;
            end
        join_any

        #10000;
        $display("Simulation Completed Successfully.");
        $finish;
    end

endmodule
