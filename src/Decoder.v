module Decoder(
    input wire clk,
    input wire rst,
    input wire rdy,

    // from Fetcher
    input wire instr_valid,
    input wire instr_ready,
    input wire [31 : 0] instr_in,
    input wire [31 : 0] instr_addr_in,

    // to RS and LSB
    output wire instr_issued,
    output wire [31 : 0] instr_out,
    output wire [31 : 0] instr_addr_out,
    output wire [6 : 0] instr_type_out,
    output wire [31 : 0] reg_value1_out,
    output wire [31 : 0] reg_value2_out,
    output wire has_dep1_out,
    output wire has_dep2_out,
    output wire [`ROB_SIZE_WIDTH - 1 : 0] v_rob_id1_out,
    output wire [`ROB_SIZE_WIDTH - 1 : 0] v_rob_id2_out,
    output wire [`ROB_SIZE_WIDTH - 1 : 0] rd_rob_id_out,

    // to RoB
    output wire [31 : 0] imm,

    // to Reg
    output wire [4 : 0] get_reg_value1;



);

    assign instr_out = instr_in;
    assign instr_addr_out = instr_addr_in;
    assign instr_type_out = instr_in[6:0];




endmodule