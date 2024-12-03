`include "config.v"
// `include "/home/hqs123/class_code/CPU/src/config.v"

module Fetcher(
    input wire clk,
    input wire rst,
    input wire rdy,    
    
    // from RoB: clear
    input wire rob_clear,
    input wire [31 : 0] back_pc,

    // to cache
    output reg start_fetch, // 仅在fetch完且没有issue时为0，其余时刻为1，如果停止，pc不变就行
    output reg [31 : 0] pc,
    // from cache
    input wire instr_ready_in, // 指令已经读好了，但在issue之前还是不能继续fetch
    input wire [31 : 0] instr_in,
    input wire [31 : 0] instr_addr_in,

    // from Decoder
    input wire instr_issued,
    input wire [31 : 0] predictor_pc,
    // to Decoder
    output reg instr_ready,
    output reg [31 : 0] instr,
    output reg [31 : 0] instr_addr

);

    // debug
    wire start_fetch_wire = start_fetch;
    wire fd_instr_ready = instr_ready;
    
    // always @* begin
    //     $display("--------------fetcher----------------time=%0t", $time);
    //     $display("time=%0t fc_start_fetch: %b", $time, start_fetch_wire);
    //     $display("time=%0t pc: %d", $time, pc);
    //     $display("time=%0t fd_instr_ready: %b", $time, fd_instr_ready);
    //     $display("time=%0t cf_instr_ready_in: %b", $time, instr_ready_in);
    // end

    always @(posedge clk) begin
        // $display("time_f_start=%0t", $time);
        if(rst) begin
            start_fetch <= 1;
            pc <= 0;
            instr_ready <= 0;
            instr <= 0;
            instr_addr <= 0;
        end 
        else if(!rdy) begin
            // do nothing
        end
        else begin
            if(rob_clear) begin
                start_fetch <= 1;
                pc <= back_pc;
                instr_ready <= 0;
                instr <= 0;
                instr_addr <= 0;
            end
            else if(instr_ready_in) begin
                start_fetch <= 0;
                instr <= instr_in;
                instr_addr <= instr_addr_in;
                instr_ready <= instr_ready_in;
            end
            else if(instr_issued) begin
                start_fetch <= 1;
                pc <= predictor_pc;
                instr_ready <= 0;
                instr <= 0;
                instr_addr <= 0;
            end
        end
        // $display("time_f_end=%0t", $time);
    end


endmodule