/* verilator coverage_off*/

`timescale 1ns/1ps

// 50_000_000 Hz
localparam real CLK_FREQ = 0.05;
localparam real CLK_PERIOD = 1/CLK_FREQ;
localparam integer BAUD = 9_600;
localparam integer SIM_TICK_PER_S = 1_000_000_000;

// Delay in ticks which allows to tx/rx one data bit
localparam real DELAY = SIM_TICK_PER_S / BAUD;
