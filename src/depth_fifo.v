`timescale 1ns/1ps

`default_nettype none

// N-depth, X-size FIFO
// note, that for many FPGA vendors, you will find it possible to generate a FIFO IP Core in their IDEs
module depth_fifo #(
    parameter integer p_depth = 32,
    parameter integer p_word_size = 8
) (
    input wire clk_i,
    // Sync reset, active low
    input wire rst_n_i,

    input  reg[p_word_size - 1 : 0] data_i,
    output reg[p_word_size - 1 : 0] data_o,

    input wire write_enable_i,
    input wire read_enable_i,

    // Indicates, that there is data left to read (NOT empty)
    output wire read_valid_o,
    // The FIFO is full, and won't accept data
    output wire full_o
);

localparam PTR_SIZE = $clog2(p_depth);

reg[PTR_SIZE - 1: 0] read_ptr, write_ptr;

reg last_op_read;

// Valid is negation of empty
assign read_valid_o = (read_ptr != write_ptr) | ~last_op_read;

// If we loop back into read, then the Q is full
assign full_o = (write_ptr == read_ptr) & ~last_op_read;

// The actual backing memory
// TODO: verify if I can make it better by using FPGA primitives (just for fun)
reg[p_word_size - 1 : 0] data[p_depth];

// Continuous read - but actually needs to check `valid` to know if it's OK to read
assign data_o = data[read_ptr];


///////////////////////

// Read pointer advance logic
always @(posedge clk_i) begin
    if (!rst_n_i) begin
        read_ptr <= {PTR_SIZE{1'b0}};
    end else begin
        if (read_enable_i & read_valid_o)
            read_ptr <= read_ptr + 1;
    end
end

// Write pointer advance logic
always @(posedge clk_i) begin
    if (!rst_n_i) begin
        write_ptr <= {PTR_SIZE{1'b0}};
    end else begin
        if (write_enable_i & ~full_o) begin
            write_ptr <= write_ptr + 1;
            data[write_ptr] <= data_i;
        end
    end
end

// Track last operation
always @(posedge clk_i) begin
    if (!rst_n_i) begin
        last_op_read <= 1'b1;
    end else begin
        if (write_enable_i & ~full_o)
            last_op_read <= 1'b0;
        else if(read_enable_i & read_valid_o)
            last_op_read <= 1'b1;
    end
end

endmodule
