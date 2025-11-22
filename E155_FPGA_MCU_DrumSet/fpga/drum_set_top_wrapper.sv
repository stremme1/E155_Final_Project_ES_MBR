// Top-level wrapper for Drum Set System
// Includes clock generation: HSOSC for hardware, simulated clock for testbenches
//
// USAGE:
// - For HARDWARE: Uncomment HSOSC section, comment out simulation clock
// - For SIMULATION: Comment out HSOSC section, uncomment simulation clock

module drum_set_top_wrapper (
    // Note: clk is now generated internally, not an input
    input  logic        rst_n,         // Active-low reset
    
    // BNO085 Sensor 1 (Right Hand) - SPI Interface
    output logic        sclk1,          // SPI clock
    output logic        mosi1,          // SPI master out
    input  logic        miso1,          // SPI master in
    output logic        cs_n1,          // Chip select (active low)
    
    // BNO085 Sensor 2 (Left Hand) - SPI Interface
    output logic        sclk2,
    output logic        mosi2,
    input  logic        miso2,
    output logic        cs_n2,
    
    // User Interface
    input  logic        calib_button,   // Calibration button
    input  logic        kick_button,    // Kick drum button (optional)
    
    // SPI Output to MCU
    output logic        mcu_sclk,       // SPI clock to MCU
    output logic        mcu_mosi,       // SPI master out to MCU
    output logic        mcu_cs_n,       // Chip select to MCU (active low)
    
    // Status LEDs (optional)
    output logic        led_initialized,
    output logic        led_error
);

    // Internal clock signal
    logic clk;

    // ============================================
    // CLOCK GENERATION
    // ============================================
    
    // HARDWARE CLOCK - HSOSC (ACTIVE FOR HARDWARE)
    // CLKHF_DIV(2'b11) = divide by 16 to get 3MHz from 48MHz
    // For 48MHz HSOSC: divide by 16 = 3MHz (suitable for SPI)
    // For different frequencies, adjust CLKHF_DIV:
    //   2'b00 = divide by 2
    //   2'b01 = divide by 4  
    //   2'b10 = divide by 8
    //   2'b11 = divide by 16
    
    HSOSC #(.CLKHF_DIV(2'b11)) hf_osc (
        .CLKHFPU(1'b1),   // Power up
        .CLKHFEN(1'b1),   // Enable
        .CLKHF(clk)       // Output clock (3MHz from 48MHz / 16)
    );
    
    // SIMULATION CLOCK - UNCOMMENT FOR SIMULATION
    // Comment out HSOSC above and uncomment this section for testbenches
    /*
    initial begin
        clk = 0;
        forever #10000 clk = ~clk; // 50kHz clock (20us period) - MUCH SLOWER for Questa
    end
    */
    
    // ============================================
    // INSTANTIATE MAIN SYSTEM
    // ============================================
    
    drum_set_top dut (
        .clk(clk),
        .rst_n(rst_n),
        .sclk1(sclk1),
        .mosi1(mosi1),
        .miso1(miso1),
        .cs_n1(cs_n1),
        .sclk2(sclk2),
        .mosi2(mosi2),
        .miso2(miso2),
        .cs_n2(cs_n2),
        .calib_button(calib_button),
        .kick_button(kick_button),
        .mcu_sclk(mcu_sclk),
        .mcu_mosi(mcu_mosi),
        .mcu_cs_n(mcu_cs_n),
        .led_initialized(led_initialized),
        .led_error(led_error)
    );

endmodule

