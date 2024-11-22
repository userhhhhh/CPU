`include "config.v"
module Fetcher(
    input wire clk,
    input wire rst,
    input wire rdy,

    // 
    

    // to Decoder
    output wire instr_valid,
    output wire instr_ready,
    output wire [31 : 0] instr,
    output wire [31 : 0] instr_addr,




);

endmodule