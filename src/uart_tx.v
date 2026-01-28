`timescale 1ns/1ps

`default_nettype none

module uart_tx # (
    parameter integer p_clk_speed_hz = 50_000_000,
    parameter integer p_baud_rate = 9_600
) (
    // Clk speed needs to be provided as parameter
    input wire clk_i,
    // Sync reset, active low
    input wire rst_n_i,

    // Enable TX to exit IDLE state
    input wire enable_i,

    // Data byte to send
    input wire[7:0] data_i,
    // Data line
    output reg data_o,

    // Enable parity bit
    input wire parity_en_i,
    // Select parity type (odd, even)
    input wire parity_sel_i,

    // How many stop bits to send (0 - one, 1 - two)
    input wire stop_sel_i,

    // Transmission in progress
    output wire busy_o,
    // Data was sent - input register can be loaded again
    // but transmission has not ended yet
    output reg data_sent_o
);

localparam integer U_CYCLES_PER_BIT = p_clk_speed_hz / p_baud_rate;
localparam integer U_CNT_REG_LEN = $clog2(U_CYCLES_PER_BIT) + 1;

//////////////

`define U_STATE_BITS 3

localparam U_IDLE    = `U_STATE_BITS'b000;
localparam U_START   = `U_STATE_BITS'b001;
localparam U_DATA    = `U_STATE_BITS'b010;
localparam U_PARITY  = `U_STATE_BITS'b011;
localparam U_STOP    = `U_STATE_BITS'b100;
//localparam U_ERROR   = `U_STATE_BITS'b101;

reg[`U_STATE_BITS-1:0] current_state;
reg[`U_STATE_BITS-1:0] next_state;

reg next_data_o;

wire parity_odd = ^data_i;

reg[U_CNT_REG_LEN-1:0] cycle_cnt;

reg[U_CNT_REG_LEN-1:0] cycles_per_bit_cmp_val = U_CYCLES_PER_BIT[U_CNT_REG_LEN-1:0];

reg[2:0] bit_cnt;
reg[2:0] next_bit_cnt;

reg next_data_sent_o;

//////////////

assign busy_o = current_state != U_IDLE;

always @(posedge clk_i) begin
    if (!rst_n_i) begin
        current_state <= U_IDLE;
        // High means no transmission going
        data_o <= 1;
        bit_cnt <= 0;
        data_sent_o <= 0;
    end else begin
        current_state <= next_state;
        data_o <= next_data_o;
        bit_cnt <= next_bit_cnt;
        data_sent_o <= next_data_sent_o;
    end
end

always @(posedge clk_i) begin : cycle_counter_data_sample
    if (!rst_n_i || cycle_cnt == cycles_per_bit_cmp_val || current_state == U_IDLE) begin
        cycle_cnt <= {U_CNT_REG_LEN{1'b0}};
    end else if(current_state == U_START
             || current_state == U_DATA
             || current_state == U_PARITY
             || current_state == U_STOP)
    begin
        cycle_cnt <= cycle_cnt + 1;
    end
end

always @(*) begin
    // defaults
    next_state = current_state;
    next_data_o = data_o;
    next_bit_cnt = bit_cnt;
    next_data_sent_o = data_sent_o;

    case (current_state)
        U_IDLE: begin
            if (enable_i) begin
                // Start to transmit START bit
                next_data_sent_o = 0;
                next_state = U_START;
            end
        end
        U_START: begin
            next_data_o = 0;
            if (cycle_cnt == cycles_per_bit_cmp_val) begin
                next_state = U_DATA;
            end
        end
        U_DATA: begin
            // Bit of idx 7 is 8th bit, so the last one (since increment is in next clk edge)
            next_data_o = data_i[bit_cnt];
            if (cycle_cnt == cycles_per_bit_cmp_val) begin
                next_bit_cnt = bit_cnt + 1;
                if (bit_cnt == 3'h7) begin
                    next_bit_cnt = 0;
                    next_data_sent_o = 1;
                    next_state = parity_en_i ? U_PARITY : U_STOP;
                end
            end
        end
        U_PARITY: begin
            next_data_o = parity_sel_i ? parity_odd : ~parity_odd;
            if (cycle_cnt == cycles_per_bit_cmp_val) begin
                next_state = U_STOP;
            end
        end
        U_STOP: begin
            next_data_o = 1;
            if (cycle_cnt == cycles_per_bit_cmp_val) begin
                next_bit_cnt = bit_cnt + 1;

                if (bit_cnt == (3'b001 + {2'b00, stop_sel_i})) begin
                    next_state = U_IDLE;
                end
            end
        end
        default: $write("rx: unreachable state");
    endcase
end

endmodule
