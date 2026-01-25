`timescale 1ns/1ps

module tb_uart_rx;

/* verilator lint_off UNUSEDSIGNAL */

// Clk speed needs to be provided as parameter
logic clk_i;
// Sync reset, active low
logic rst_n_i;

// Enable the rx to exit idle state
logic enable_i;

// Data line to decode
logic data_i;

// Enable parity bit
logic parity_en_i;
// Select parity type (odd, even)
logic parity_sel_i;
// Stop bits - 0 for one, 1 for two
logic stop_bits_i;

// Output decoded data byte
logic[7:0] data_o;

// Reception in progress
logic busy_o;

// Error signals
logic parity_err_o;
//output wire noise_err_o,
logic framing_err_o;

// 50_000_000 Hz
localparam real CLK_FREQ = 0.05;
localparam real CLK_PERIOD = 1/CLK_FREQ;
localparam integer BAUD = 9_600;
localparam integer SIM_TICK_PER_S = 1_000_000_000;

uart_rx #(
    // speed is relative to the module simulation params, but needs to be in base Hz
    .p_clk_speed_hz(CLK_FREQ * SIM_TICK_PER_S),
    .p_baud_rate(BAUD)
) uart_rx_inst (.*);

localparam real DELAY = SIM_TICK_PER_S / BAUD;

always #(CLK_PERIOD / 2) clk_i = ~clk_i;

initial begin
    $dumpfile("tb_uart_rx.vcd");
    $dumpvars(0, tb_uart_rx);
end

initial begin
    #1 rst_n_i=1'bx; clk_i=1'bx;

    #(CLK_PERIOD*3) rst_n_i = 0; clk_i = 0;

    repeat(5) @(posedge clk_i);

    data_i = 1;
    rst_n_i = 1;

    parity_en_i = 1;
    parity_sel_i = 1;

    stop_bits_i = 0;

    @(posedge clk_i);
    @(negedge clk_i);

    //tx_byte_i = 7'b1010011;

    enable_i = '1;

    // START
    data_i = '0;
    #DELAY

    // DATA
    data_i = '1;
    #DELAY
    data_i = '1;
    #DELAY
    data_i = '0;
    #DELAY
    data_i = '0;
    #DELAY
    data_i = '1;
    #DELAY
    data_i = '0;
    #DELAY
    data_i = '1;

    // PARITY
    #DELAY
    data_i = '1;

    #DELAY
    data_i = '1;
    #DELAY
    #DELAY

    $display("done? %d", busy_o);
    assert (busy_o == 0)
    else   $error("Rx not done!");

    #1
    //start_i = '1;

    $finish(2);
end

endmodule

/* verilator lint_on UNUSEDSIGNAL */

`default_nettype wire
