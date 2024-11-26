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
    input wire in_fetcher_ready,
    input wire [31:0] instr_addr,
    // to fetcher
    output wire out_fetcher_ready,
    output wire [31:0] instr_out,
    output wire [31:0] instr_addr_out,

    // from LSB
    input wire in_lsb_ready,
    input wire [6:0] instr_type_in,
    input wire [31:0] data_addr_in,
    input wire [31:0] data_in, // st
    // to LSB
    output wire out_lsb_ready,
    output wire [31:0] data_out // ld

);

    reg cache_user; // fetcher:0  LSB:1
    reg busy;
    reg [2:0] state; //剩下的字节数：0，1，2，3，4

    // LSB
    reg [6:0] instr_type;
    reg [31:0] data_addr;
    reg [31:0] st_data; // to memory
    reg [31:0] ld_data; // from meomory
    // Fetcher





    always @(posedge clk) begin
        if(rst || rob_clear) begin
            cache_user <= 0;
            busy <= 0;
            state <= 0;
            instr_type <= 0;
            data_addr <= 0;
            st_data <= 0;
            ld_data <= 0;
        end
        else if (!rdy) begin
            // do nothing
        end
        else begin
            if(!busy) begin
                if(in_lsb_ready) begin
                    cache_user <= 1;
                    state <= 3'b100;
                end
                else if(in_fetcher_ready) begin // TODO
                    cache_user <= 0;
                    busy <= 1;

                end
            end
            else begin
                case(state)
                    3'b100: begin
                        ld_data[31:24] <= mem_dout;
                        state <= 3'b011;
                    end
                    3'b011: begin
                        ld_data[23:16] <= mem_dout;
                        state <= 3'b010;
                    end
                    3'b010: begin
                        ld_data[15:8] <= mem_dout;
                        state <= 3'b001;
                    end
                    3'b001: begin
                        ld_data[7:0] <= mem_dout;
                        state <= 3'b000;
                    end
                    3'b000: begin
                        busy <= 0;
                    end
                endcase
            end
        end
    end
endmodule