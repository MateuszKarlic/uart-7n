module tang_echo_demo
(
    input wire data_i,
    input wire clk_i,
    output wire data_o,

    output wire rx_busy_o,
    output wire tx_busy_o,
    output wire rx_data_ready_o,
    output wire neg_rx_data_ready_o,
    output wire tx_data_sent_o,

    output wire[2:0] state_rx
);

assign neg_rx_data_ready_o = ~rx_data_ready_o;

uart7n_top # (
    .p_clk_speed_hz(50_000_000),
    .p_baud_rate(9_600)
) xuart7n_top (
    // Clk speed needs to be provided as parameter
    .clk_i(clk_i),
    // Sync reset, active low
    .rst_n_i(1),

    .rx_busy_o(rx_busy_o),
    .tx_busy_o(tx_busy_o),
    .rx_data_ready_o(rx_data_ready_o),
    .tx_data_sent_o(tx_data_sent_o),

    // Enable tx, or rx state machine
    .enable_tx_i(1),
    .enable_rx_i(1),

    // Actual receive and transmit lines
    .data_i(data_i),
    .data_o(data_o),

    .loopback_i(0),
    .inverted_loopback_i(1),

    // Enable parity bit
    .parity_en_i(1),
    // Select parity type (odd, even)
    .parity_sel_i(0),

    // How many stop bits to send (0 - one, 1 - two)
    .stop_sel_i(0)
);

assign state_rx = xuart7n_top.xuart_rx.current_state;

endmodule