`define U_STATE_BITS 3

localparam U_IDLE    = `U_STATE_BITS'b000;
localparam U_START   = `U_STATE_BITS'b001;
localparam U_DATA    = `U_STATE_BITS'b010;
localparam U_PARITY  = `U_STATE_BITS'b011;
localparam U_STOP    = `U_STATE_BITS'b100;
localparam U_ERROR   = `U_STATE_BITS'b101;

localparam integer U_CYCLES_PER_BIT = p_clk_speed_hz / p_baud_rate;
localparam integer U_CNT_REG_LEN = $clog2(U_CYCLES_PER_BIT) + 1;
