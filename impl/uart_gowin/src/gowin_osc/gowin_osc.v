//Copyright (C)2014-2025 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: IP file
//Tool Version: V1.9.11.03 Education
//Part Number: GW2AR-LV18QN88C8/I7
//Device: GW2AR-18
//Device Version: C
//Created Time: Sun Feb  8 17:48:36 2026

module Gowin_OSC (oscout);

output wire oscout;

OSC osc_inst (
    .OSCOUT(oscout)
);

defparam osc_inst.FREQ_DIV = 2;
defparam osc_inst.DEVICE = "GW2AR-18C";

endmodule //Gowin_OSC
