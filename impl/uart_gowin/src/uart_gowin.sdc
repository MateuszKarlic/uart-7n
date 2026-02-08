//Copyright (C)2014-2026 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//Tool Version: V1.9.11.03 Education 
//Created Time: 2026-02-08 17:53:36
create_clock -name clk_osc -period 20 -waveform {0 10} [get_nets {clkout}]
