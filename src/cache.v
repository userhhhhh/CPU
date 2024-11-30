`include "config.v"

// taught by graceq
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

    // from fetcher
    input wire in_fetcher_ready,
    input wire [31:0] instr_addr,
    // to fetcher
    output wire out_fetcher_ready,
    output wire [31:0] instr_out,
    output wire [31:0] instr_addr_out,

    // from LSB
    input wire in_lsb_ready,
    input wire [2:0] op_in,
    input wire [6:0] instr_type_in,
    input wire [31:0] data_addr_in,
    input wire [31:0] data_in, // st
    // to LSB
    output wire welcome_lsb,
    output wire out_lsb_ready,
    output wire [6:0] instr_type_out,
    output wire [31:0] data_out // ld

);

    reg busy;
    reg [1:0] cache_user; // fetcher:1  LSB:2
    reg [2:0] already_read; //已读的字节数:0，1，2，3
    reg [2:0] tobe_read; //剩下的字节数：0，1，2，3
    reg [2:0] len; //常数

    reg [2:0] op;
    reg [6:0] instr_type;
    reg [31:0] data_addr;
    reg [31:0] st_data; // to memory
    reg [31:0] ld_data; // from memory

    reg [31:0] cur_addr;

    assign out_fetcher_ready = (cache_user == 1) && busy && (tobe_read == 0);
    assign instr_out = out_fetcher_ready ? {mem_din[7:0], ld_data[23:0]} : 0;
    assign instr_addr_out = out_fetcher_ready ? data_addr : 0;
    
    assign welcome_lsb = !in_fetcher_ready || out_fetcher_ready;
    
    assign out_lsb_ready = (cache_user == 2) && busy && (tobe_read == 0);
    assign instr_type_out = instr_type_in;
    
    always @(posedge clk) begin
        if(rst || rob_clear) begin
            cache_user <= 2'b0;
            busy <= 1'b0;
            already_read <= 3'b0;
            tobe_read <= 3'b0;
            len <= 3'b0;
            op <= 3'b0;
            instr_type <= 7'b0;
            data_addr <= 32'b0;
            st_data <= 32'b0;
            ld_data <= 32'b0;
        end
        else if (!rdy) begin
            // do nothing
        end
        else begin
            if(!busy && !out_lsb_ready && !out_fetcher_ready) begin
                if(in_lsb_ready) begin
                    busy <= 1'b1;
                    cache_user <= 2'b10;
                    len <= (3'b1<<$unsigned(op_in[1:0]))-1;
                    tobe_read <= (3'b1<<$unsigned(op_in[1:0]))-1;
                    already_read <= 3'b0;
                    op <= op_in;
                    instr_type <= instr_type_in;
                    data_addr <= data_addr_in;
                end
                else if(in_fetcher_ready) begin // TODO
                    busy <= 1'b1;
                    cache_user <= 2'b01;
                    len <= 3'b011;
                    tobe_read <= 3'b011;
                    already_read <= 3'b1; //错误：开始就读了，初始值是1不是0
                    op <= 3'b0;
                    instr_type <= 7'b0;
                    data_addr <= instr_addr;
                end
            end
            else begin
                case(tobe_read)
                    3'b011: begin
                        ld_data[7:0] <= mem_din;
                        already_read <= already_read + 1;
                        tobe_read <= tobe_read - 1;
                    end
                    3'b010: begin
                        ld_data[15:8] <= mem_din;
                        already_read <= already_read + 1;
                        tobe_read <= tobe_read - 1;
                    end
                    3'b001: begin
                        ld_data[23:16] <= mem_din;
                        already_read <= already_read + 1;
                        tobe_read <= tobe_read - 1;
                    end
                    3'b000: begin
                        busy <= 0;
                        cache_user <= 2'b0;
                        already_read <= 3'b0;
                        tobe_read <= 3'b0;
                    end
                endcase
            end
        end
    end

    // mem_a 实时更新
    wire [31 : 0] busy_mem_a, free_mem_a;
    assign busy_mem_a = busy ? ((already_read <= 3) ? data_addr + already_read : 0) : 0; //错误：最后一个要置0
    assign free_mem_a = in_lsb_ready ? data_addr : instr_addr;
    assign mem_a = busy ? busy_mem_a : free_mem_a;

    function [8:0] gen_mem_dout;
        input [2:0] _already_read;
        input [31:0] _ld_data;
        case (_already_read)
            3'b000: gen_mem_dout = _ld_data[7:0];
            3'b001: gen_mem_dout = _ld_data[15:8];
            3'b010: gen_mem_dout = _ld_data[23:16];
            3'b011: gen_mem_dout = _ld_data[31:24];
            default: gen_mem_dout = 0;
        endcase
    endfunction
    assign mem_dout = tobe_read ? 0 : gen_mem_dout(already_read, ld_data);

    function [31:0] gen_read_data;
        input [2:0] len;
        input [31:0] tmp_data;
        input [7:0] mem_din;
        case (len)
            3'b000: gen_read_data = {{24{mem_din[7]}}, mem_din}; // lb
            3'b100: gen_read_data = {24'b0, mem_din}; // lbu
            3'b001: gen_read_data = {{16{mem_din[7]}}, mem_din, tmp_data[7:0]}; // lh
            3'b101: gen_read_data = {16'b0, mem_din, tmp_data[7:0]}; // lhu
            3'b010: gen_read_data = {mem_din, tmp_data[23:0]}; // lw
            default: gen_read_data = 0;
        endcase 
    endfunction
    assign data_out = gen_read_data(len, ld_data, mem_din);

endmodule