`include "timings.svh"

module tb_uart_tx;

/* verilator lint_off UNUSEDSIGNAL */

// Clk speed needs to be provided as parameter
logic clk_i;
// Sync reset, active low
logic rst_n_i;

// Enable TX to exit IDLE state
logic enable_i;

// Data byte to send
logic[7:0] data_i;
// Data line
logic data_o;

// Enable parity bit
logic parity_en_i;
// Select parity type (odd, even)
logic parity_sel_i;

// How many stop bits to send (0 - one, 1 - two)
logic stop_sel_i;

// Transmission in progress
logic busy_o;
// Data was sent - input register can be loaded again
// but transmission has not ended yet
logic data_sent_o;

uart_tx #(
    // speed is relative to the module simulation params, but needs to be in base Hz
    .p_clk_speed_hz(CLK_FREQ * SIM_TICK_PER_S),
    .p_baud_rate(BAUD)
) uart_tx_inst (.*);

always #(CLK_PERIOD / 2) clk_i = ~clk_i;

initial begin
    $dumpfile("tb_uart_tx.vcd");
    $dumpvars(0, tb_uart_tx);
end

task simple_rx(logic[7:0] data, bit parity, bit stop);
    parity_en_i = 1;
    parity_sel_i = 1;
    stop_sel_i = 0;

    data_i = data;

    enable_i = 1;

    #(DELAY * (8 + 1 + 1 + 1));

endtask;

initial begin
    #1 rst_n_i=1'bx; clk_i=1'bx;

    #(CLK_PERIOD*3) rst_n_i = 0; clk_i = 0;

    repeat(5) @(posedge clk_i);

    data_i = 1;
    rst_n_i = 1;

    // Transactions are essentially happening back-to-back
    // with no extra delays in between
    simple_rx("H", '0, '1);
    simple_rx("E", '1, '1);
    simple_rx("L", '1, '1);
    simple_rx("L", '1, '1);
    simple_rx("O", '1, '1);

    data_i = '0;

    $finish(2);
end

endmodule

/* verilator lint_on UNUSEDSIGNAL */
