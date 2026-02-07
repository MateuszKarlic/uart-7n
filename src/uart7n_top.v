module uart7n_top # (
    parameter integer p_clk_speed_hz = 50_000_000,
    parameter integer p_baud_rate = 9_600
) (
    // Clk speed needs to be provided as parameter
    input wire clk_i,
    // Sync reset, active low
    input wire rst_n_i,

    // Enable tx, or rx state machine
    input wire enable_tx_i,
    input wire enable_rx_i,

    // Register holding data to be sent
    // cannot be modified until `tx_data_sent_o` is set
    input wire[7:0] data_tx_i,
    // Register holding read-back data
    output wire[7:0] data_rx_o,

    // Actual receive and transmit lines
    input wire data_i,
    output wire data_o,

    // Whether UART is busy receiving or transmitting data
    output wire rx_busy_o,
    output wire tx_busy_o,

    // Received data is ready/valid to read out
    output wire rx_data_ready_o,

    // Tx can be loaded with new data
    output wire tx_data_sent_o,

    //////     Error signals     //////
    output wire parity_err_o,
    output wire framing_err_o,

    ////// Configuration signals //////

    // Force UART to operate in loopback mode (tx connected to rx)
    input wire loopback_i,
    // Force UART to operate in loopback mode (rx connected to tx)
    // be careful not to use two at once, or infinite cycle will happen
    input wire inverted_loopback_i,

    // Enable parity bit
    input wire parity_en_i,
    // Select parity type (odd, even)
    input wire parity_sel_i,

    // How many stop bits to send (0 - one, 1 - two)
    input wire stop_sel_i
);

wire rx_data_i = loopback_i ? data_o : data_i;
wire[7:0] tx_data_i = inverted_loopback_i ? data_rx_o : data_tx_i;

uart_tx # (
    .p_clk_speed_hz(p_clk_speed_hz),
    .p_baud_rate(p_baud_rate)
) xuart_tx (
    .clk_i(clk_i),
    .rst_n_i(rst_n_i),

    .enable_i(enable_tx_i),

    .data_i(tx_data_i),
    .data_o(data_o),

    .parity_en_i(parity_en_i),
    .parity_sel_i(parity_sel_i),
    .stop_sel_i(stop_sel_i),

    .busy_o(tx_busy_o),
    .data_sent_o(tx_data_sent_o)
);

uart_rx # (
    .p_clk_speed_hz(p_clk_speed_hz),
    .p_baud_rate(p_baud_rate)
) xuart_rx (
    .clk_i(clk_i),
    .rst_n_i(rst_n_i),

    .enable_i(enable_rx_i),

    .data_i(rx_data_i),

    .parity_en_i(parity_en_i),
    .parity_sel_i(parity_sel_i),

    .data_o(data_rx_o),

    .busy_o(rx_busy_o),
    .data_ready_o(rx_data_ready_o),

    .parity_err_o(parity_err_o),
    .framing_err_o(framing_err_o)
);

endmodule
