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

logic[7:0] rcv_data;
wire parity_err, framing_err;

wire any_err = parity_err | framing_err;

// In ideal world, I'd have a VIP to decode the signal from the tx module
// Unfortunately I'm poor, so I use the (verified) rx module in a "loopback" mode
uart_rx #(
    .p_clk_speed_hz(CLK_FREQ * SIM_TICK_PER_S),
    .p_baud_rate(BAUD)
) uart_rx_inst (
    // Clk speed needs to be provided as parameter
    .clk_i(clk_i),
    // Sync reset, active low
    .rst_n_i(rst_n_i),

    // Enable the rx to exit idle state
    .enable_i(1),

    // Data line to decode
    .data_i(data_o),

    // Enable parity bit
    .parity_en_i(1),
    // Select parity type (odd, even)
    .parity_sel_i(1),

    // Output decoded data byte
    .data_o(rcv_data),

    // Reception in progress
    .busy_o(),
    // Data is ready to read out
    .data_ready_o(),

    // Error signals
    .parity_err_o(parity_err),
    //output wire noise_err_o,
    .framing_err_o(framing_err)
);

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

    // 8 data bits + START + PARITY + STOP
    #(DELAY * (8 + 1 + 1 + 1));

    assert (!any_err)
    else   $error("error condition on reception");

    assert (rcv_data == data)
    else  $error($sformatf("[%t] Read back mismatch!: %h, expected %h", $realtime, rcv_data, data));

    $display("[%t] Read back: %h, expected %h, OK!", $realtime, rcv_data, data);

endtask;

initial begin
    #1 rst_n_i=1'bx; clk_i=1'bx;

    #(CLK_PERIOD*3) rst_n_i = 0; clk_i = 0;

    repeat(5) @(posedge clk_i);

    data_i = 1;
    rst_n_i = 1;

    // Transactions are essentially happening back-to-back
    // with no extra delays in between
    simple_rx("H", '1, '1);
    simple_rx("E", '1, '1);
    simple_rx("L", '1, '1);
    simple_rx("L", '1, '1);
    simple_rx("O", '1, '1);

    data_i = '0;

    $finish(2);
end

endmodule

/* verilator lint_on UNUSEDSIGNAL */
