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
// Data is ready to read out
logic data_ready_o;

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

task simple_tx(logic[7:0] data, bit parity, bit stop);
    $display("[%t] Tx start. Data %h:%c, parity %d, stop %d", $realtime, data, data, parity, stop);
    parity_en_i = 1;
    parity_sel_i = 1;

    stop_bits_i = 0;

    enable_i = '1;

    // START
    data_i = '0;
    #DELAY

    // DATA
    for (int i = 0; i < $size(data); i++) begin
        $display("[%t] Sending %h, idx %0d", $realtime, data[i], i);
        data_i = data[i];
        #DELAY;
    end

    // PARITY
    data_i = parity;
    #DELAY

    // STOP
    data_i = '1;
    #DELAY

    $display("[%t] busy? %d", $realtime, busy_o);
    assert (busy_o == 0)
    else   $error("Rx not done!");

    assert (data_ready_o == 1)
    else   $error("data is not ready");

    assert (data_o == data)
    else   $error("output mismatch!");

    $display("[%t] Read back: %h:%c", $realtime, data_o, data_o);
endtask;

initial begin
    #1 rst_n_i=1'bx; clk_i=1'bx;

    #(CLK_PERIOD*3) rst_n_i = 0; clk_i = 0;

    repeat(5) @(posedge clk_i);

    data_i = 1;
    rst_n_i = 1;

    // Transactions are essentially happening back-to-back
    // with no extra delays in between
    simple_tx("H", '0, '1);
    simple_tx("E", '1, '1);
    simple_tx("L", '1, '1);
    simple_tx("L", '1, '1);
    simple_tx("O", '1, '1);

    data_i = '0;

    $finish(2);
end

endmodule

/* verilator lint_on UNUSEDSIGNAL */
