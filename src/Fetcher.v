// `include "config.v"
`include "/home/hqs123/class_code/CPU/src/config.v"

module Fetcher(
    input wire clk,
    input wire rst,
    input wire rdy,

    // to cache
    output wire start_fetch,
    output reg [31 : 0] instr_addr_out,
    input wire instr_ready_in,
    input wire [31 : 0] instr_in,

    // from Decoder
    input wire instr_issued,
    input wire [31 : 0] new_pc,
    // to Decoder
    output wire instr_ready,
    output wire [31 : 0] instr,
    output wire [31 : 0] instr_addr,

    // from RoB: clear
    input wire rob_clear,
    input wire back_pc
);

    always @(posedge clk) begin
        if(rst) begin
            // TODO
        end 
        else if(!rdy) begin
            // TODO
        end
        else begin
            if(instr_ready_in) begin
                instr <= instr_in;
                instr_addr <= instr_addr_out;
                instr_ready <= instr_ready_in;
            end
            if(instr_issued) begin
                // TODO
            end
            if(rob_clear) begin
                // TODO
            end
        end
    end


endmodule