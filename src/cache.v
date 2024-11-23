`include "config.v"
// `include "/home/hqs123/class_code/CPU/src/config.v"
module cache(
    input wire clk,
    input wire rst,
    input wire rdy,

    // from RoB
    input wire rob_clear,

    // from Memory
    input  wire [ 7:0]          mem_din,		// data input bus
    output wire [ 7:0]          mem_dout,		// data output bus
    output wire [31:0]          mem_a,			// address bus (only 17:0 is used)
    output wire                 mem_wr,			// write/read signal (1 for write)
	input  wire                 io_buffer_full, // 1 if uart buffer is full

    // to fetcher and LSB
    output wire cache_free,

    // from fetcher
    input wire [31:0] instr_addr,
    // to fetcher
    output wire fetcher_ready,
    output wire [31:0] instr_out,
    output wire [31:0] instr_addr_out,

    // from LSB
    input wire [6:0] instr_type_in,
    input wire [31:0] data_addr_in,
    input wire [31:0] data_in, // st
    // to LSB
    output wire [31:0] data_out, // ld



);


    always @(posedge clk) begin
        if(rst || rob_clear) begin
            
        end
        else if (!rdy) begin
            // do nothing
        end
        else begin

        end
    end
endmodule