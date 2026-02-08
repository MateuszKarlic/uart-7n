module tang_echo_demo
(
    input wire data_i,
    input wire clk_i,
    input wire rst_n_i,
    output wire data_o,

    output wire rx_busy_o,
    output wire tx_busy_o,
    output wire rx_data_ready_o,
    output wire tx_data_sent_o,

    output wire parity_err_o,
    output wire framing_err_o
);

wire clkout;
Gowin_rPLL your_instance_name(
        .clkout(clkout), //output clkout
        .clkin(clk_i) //input clkin
    );


// Convert "level" send_data to "pulse"
reg send_data, send_data_P;
always @(posedge clk_i) begin : level_to_pulse
    if(rst_n_i) begin
        send_data <= 0;
        send_data_P <= 0;
    end else begin
        if (rx_data_ready_o & !send_data_P) begin
            send_data <= 1;
            send_data_P <= 1;
        end else if(!rx_data_ready_o) begin
            send_data_P <= 0;
        end else if(send_data_P) begin
            send_data <= 0;
        end
    end
end

uart7n_top # (
    .p_clk_speed_hz(50_000_000),
    .p_baud_rate(115_200)
) xuart7n_top (
    // Clk speed needs to be provided as parameter
    .clk_i(clkout),
    // Sync reset, active low
    .rst_n_i(~rst_n_i),

    .rx_busy_o(rx_busy_o),
    .tx_busy_o(tx_busy_o),
    .rx_data_ready_o(rx_data_ready_o),
    .tx_data_sent_o(tx_data_sent_o),

    .data_rx_o(s_data),

    // Enable tx, or rx state machine
    .enable_tx_i(send_data),
    .enable_rx_i(1),

    // Actual receive and transmit lines
    .data_i(data_i),
    .data_o(data_o),

    .loopback_i(0),
    .inverted_loopback_i(1),

    // Error signals
    .parity_err_o(parity_err_o),
    .framing_err_o(framing_err_o),

    // Enable parity bit
    .parity_en_i(1),
    // Select parity type (odd, even)
    .parity_sel_i(0),

    // How many stop bits to send (0 - one, 1 - two)
    .stop_sel_i(0)
);

assign data_readback = xuart7n_top.xuart_rx.data_o;

endmodule