`timescale 1ns/1ps

`default_nettype none

module uart_rx # (
    parameter integer p_clk_speed_hz = 50_000_000,
    parameter integer p_baud_rate = 9_600
) (
    // Clk speed needs to be provided as parameter
    input wire clk_i,
    // Sync reset, active low
    input wire rst_n_i,

    // Enable the rx to exit idle state
    input wire enable_i,

    // Data line to decode
    input wire data_i,

    // Enable parity bit
    input wire parity_en_i,
    // Select parity type (odd, even)
    input wire parity_sel_i,

    // Output decoded data byte
    output wire[7:0] data_o,

    // Reception in progress
    output wire busy_o,
    // Data is ready to read out
    output reg data_ready_o,

    // Error signals
    output reg parity_err_o,
    //output wire noise_err_o,
    output reg framing_err_o
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
localparam U_ERROR   = `U_STATE_BITS'b101;

reg[`U_STATE_BITS-1:0] current_state;
reg[`U_STATE_BITS-1:0] next_state;

reg sampled_data_i;

reg[U_CNT_REG_LEN-1:0] cycle_cnt;

wire[U_CNT_REG_LEN-1:0] cycles_per_bit_cmp_val = U_CYCLES_PER_BIT[U_CNT_REG_LEN-1:0];

reg next_parity_err_o;
reg next_framing_err_o;

reg[2:0] bit_cnt;
reg[2:0] next_bit_cnt;

reg[7:0] data_reg;
reg[7:0] next_data_reg;

reg next_data_ready_o;

reg data_i_rd_old;
reg data_i_rd;

//////////////

wire parity_even = ^data_reg;

//////////////

always @(posedge clk_i) begin : state_transition
    if (!rst_n_i) begin
        current_state <= U_IDLE;
        data_reg <= 0;
        bit_cnt <= 0;
        parity_err_o <= 0;
        framing_err_o <= 0;
        data_ready_o <= 0;
    end else begin
        current_state <= next_state;
        data_reg <= next_data_reg;
        bit_cnt <= next_bit_cnt;
        parity_err_o <= next_parity_err_o;
        framing_err_o <= next_framing_err_o;
        data_ready_o <= next_data_ready_o;
    end
end

// A double register (or two-flip-flop) synchronizer to prevent CDC issues with input signal
always @(posedge clk_i) begin : data_metastability
    data_i_rd_old <= data_i;
    data_i_rd <= data_i_rd_old;
end

always @(posedge clk_i) begin : cycle_counter_data_sample
    if (!rst_n_i || cycle_cnt == cycles_per_bit_cmp_val || current_state == U_IDLE) begin
        cycle_cnt <= {U_CNT_REG_LEN{1'b0}};
    end else if(current_state == U_START
             || current_state == U_DATA
             || current_state == U_PARITY
             || current_state == U_STOP
             || current_state == U_ERROR)
    begin
        cycle_cnt <= cycle_cnt + 1;

        if (cycle_cnt == cycles_per_bit_cmp_val / 2) begin
            sampled_data_i <= data_i_rd;
        end
    end
end

assign busy_o = current_state != U_IDLE;
assign data_o = data_reg;

always @(*) begin : combo_logic
    next_state = current_state;
    next_bit_cnt = bit_cnt;
    next_parity_err_o = parity_err_o;
    next_framing_err_o = framing_err_o;
    next_data_reg = data_reg;
    next_data_ready_o = data_ready_o;

    case (current_state)
        U_IDLE: begin
            // Data line pulled low, triggers the receive logic
            if (!data_i_rd & enable_i) begin
                next_state = U_START;
            end
        end
        U_START: begin
            if (cycle_cnt == cycles_per_bit_cmp_val) begin
                if (sampled_data_i == 0) begin
                    next_bit_cnt = 0;
                    next_data_ready_o = 0;
                    next_state = U_DATA;
                end else begin
                    // didn't hold the START long enough
                    $display("[%t] unstable START bit (noise on rx line?)", $realtime);
                    next_state = U_IDLE;
                end
            end
        end
        U_DATA: begin
            if (cycle_cnt == cycles_per_bit_cmp_val) begin
                next_bit_cnt = bit_cnt + 1;

                next_data_reg[bit_cnt] = sampled_data_i;
                // Bit of idx 7 is 8th bit, so the last one (since increment is in next clk edge)
                if (bit_cnt == 3'h7) begin
                    next_bit_cnt = 0;
                    // Ready as in: data is "stable", doesn't mean valid ¯\_(ツ)_/¯
                    next_data_ready_o = 1;
                    next_state = parity_en_i ? U_PARITY : U_STOP;
                end
            end
        end
        U_PARITY: begin
            if (cycle_cnt == cycles_per_bit_cmp_val) begin
                if (sampled_data_i == parity_sel_i ? parity_even : ~parity_even) begin
                    next_state = U_STOP;
                end else begin
                    $display("[%t] rcv parity error", $realtime);
                    next_parity_err_o = 1;
                    next_state = U_ERROR;
                end
            end
        end
        U_STOP: begin
            if (cycle_cnt == cycles_per_bit_cmp_val / 2 + 1) begin
                if (sampled_data_i == 0) begin
                    $display("[%t] rcv invalid stop", $realtime);
                    next_framing_err_o = 1;
                    next_state = U_ERROR;
                end else begin
                    next_state = U_IDLE;
                end
            end
        end
        U_ERROR: begin
            if (cycle_cnt == cycles_per_bit_cmp_val / 2) begin
                $display("[%t] rcv error state", $realtime);
                next_parity_err_o = 0;
                next_framing_err_o = 0;
                next_state = U_IDLE;
            end
        end
        default: $write("rx: unreachable state");
    endcase
end


endmodule
