
/* verilator lint_off UNUSEDPARAM */
`include "timings.svh"
/* verilator lint_on UNUSEDPARAM */

module tb_fifo;

/* verilator lint_off UNUSEDSIGNAL */

parameter p_depth = 8;
parameter p_word_size = 8;

logic clk_i;
// Sync reset, active low
logic rst_n_i;

logic[p_word_size - 1 : 0] data_i;
logic[p_word_size - 1 : 0] data_o;

logic write_enable_i;
logic read_enable_i;

// Indicates, that there is data left to read (NOT empty)
logic read_valid_o;
// The FIFO is full, and won't accept data
logic full_o;

depth_fifo #(
    .p_depth(p_depth),
    .p_word_size(p_word_size)
) xdepth_fifo (.*);

/* verilator lint_on UNUSEDSIGNAL */

always #(CLK_PERIOD / 2) clk_i = ~clk_i;

initial begin
    $dumpfile("tb_fifo.vcd");
    $dumpvars(0, xdepth_fifo);
end

typedef logic[p_word_size - 1 : 0] fifo_word_t;

function automatic fifo_word_t get_rand_word();
    /* verilator lint_off WIDTHTRUNC */
    logic[p_word_size - 1 : 0] rand_word = $urandom_range(1, 1 << p_word_size - 1);
    /* verilator lint_on WIDTHTRUNC */
    return rand_word;
endfunction

task automatic write_data_and_cmp(input fifo_word_t input_val, input fifo_word_t expected_val);
    data_i = input_val;
    write_enable_i = 1;

    @(posedge clk_i)
    write_enable_i = 0;

    assert (expected_val == data_o)
    else  $error($sformatf("[%t] Read back mismatch!: %h, expected %h", $realtime, data_o, expected_val));
endtask

task read_data(output fifo_word_t output_val, input fifo_word_t expected_val);
    read_enable_i = 1;

    assert (expected_val == data_o)
    else  $error($sformatf("[%t] Read back mismatch!: %h, expected %h", $realtime, data_o, expected_val));
    output_val = data_o;

    @(posedge clk_i)
    read_enable_i = 0;
endtask

/* verilator lint_off UNUSEDSIGNAL */
initial begin
    fifo_word_t wrd1 = get_rand_word();
    fifo_word_t wrd2 = get_rand_word();
    fifo_word_t wrd3 = get_rand_word();
    fifo_word_t wrd4 = get_rand_word();
    fifo_word_t wrd5 = get_rand_word();
    fifo_word_t wrd6 = get_rand_word();
    fifo_word_t outp;

    #1 rst_n_i=1'bx; clk_i=1'bx;

    #(CLK_PERIOD*3) rst_n_i = 0; clk_i = 0;

    repeat(5) @(posedge clk_i);

    data_i = '0;
    rst_n_i = 1;
    write_enable_i = 0;
    read_enable_i = 0;

    write_data_and_cmp(wrd1, wrd1);
    // No read, so we see prev val
    write_data_and_cmp(wrd2, wrd1);
    // Ditto
    write_data_and_cmp(wrd3, wrd1);

    read_data(outp, wrd1);
    read_data(outp, wrd2);

    write_data_and_cmp(wrd1, wrd3);
    write_data_and_cmp(wrd2, wrd3);
    write_data_and_cmp(wrd3, wrd3);
    write_data_and_cmp(wrd4, wrd3);

    write_data_and_cmp(wrd1, wrd3);
    write_data_and_cmp(wrd2, wrd3);

    assert (full_o != 1)
    else  $error($sformatf("[%t] FIFO full!", $realtime));

    write_data_and_cmp(wrd5, wrd3);

    assert (full_o == 1)
    else  $error($sformatf("[%t] FIFO not full!", $realtime));

    // This one will be dropped
    write_data_and_cmp(wrd6, wrd3);

    assert (full_o == 1)
    else  $error($sformatf("[%t] FIFO not full!", $realtime));

    read_data(outp, wrd3);

    assert (full_o != 1)
    else  $error($sformatf("[%t] FIFO full!", $realtime));

    read_data(outp, wrd1);
    read_data(outp, wrd2);
    read_data(outp, wrd3);
    read_data(outp, wrd4);

    read_data(outp, wrd1);
    read_data(outp, wrd2);
    read_data(outp, wrd5);

    assert (read_valid_o != 1)
    else  $error($sformatf("[%t] FIFO not empty!", $realtime));

    // Empty FIFO, looped back (but read is marked as invalid)
    read_data(outp, wrd3);

    $display($sformatf("[%t] TEST SUCCEEDED", $realtime));
    $finish(2);
end

endmodule
