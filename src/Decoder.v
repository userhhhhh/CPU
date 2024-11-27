`include "config.v"

module Decoder(
    input wire clk,
    input wire rst,
    input wire rdy,

    // judge full
    input wire rob_full,
    input wire rs_full,
    input wire lsb_full,

    // from Fetcher
    input wire instr_ready,
    input wire [31 : 0] instr_in,
    input wire [31 : 0] instr_addr_in,

    // to fetcher
    output wire predict_pc,

    // to RS and LSB and RoB
    output wire instr_issued,// and to fetcher

    output wire [31 : 0] instr_out,
    output wire [31 : 0] instr_addr_out,
    output wire [2 : 0] op_out,
    output wire [6 : 0] instr_type_out,
    output wire [31 : 0] reg_value1_out,
    output wire [31 : 0] reg_value2_out,
    output wire has_dep1_out,
    output wire has_dep2_out,
    output wire [`ROB_SIZE_WIDTH - 1 : 0] v_rob_id1_out,
    output wire [`ROB_SIZE_WIDTH - 1 : 0] v_rob_id2_out,
    output wire [`ROB_SIZE_WIDTH - 1 : 0] rd_rob_id_out,

    // to RoB and LSB
    output wire [31 : 0] imm,
    // to RoB
    output wire [31 : 0] rd,

    // to Reg
    output wire [4 : 0] reg_id1,
    output wire [4 : 0] reg_id2,

    // from Reg
    input wire [31 : 0] reg_value1_in,
    input wire [31 : 0] reg_value2_in,
    input wire has_dep1_in,
    input wire has_dep2_in,
    input wire [`ROB_SIZE_WIDTH - 1 : 0] v_rob_id1_in,
    input wire [`ROB_SIZE_WIDTH - 1 : 0] v_rob_id2_in, 

    // from RoB
    input wire [`ROB_SIZE_WIDTH - 1 : 0] rd_rob_id_in

);

    assign instr_out = instr_in;
    assign instr_addr_out = instr_addr_in;
    assign op_out = instr_in[14:12];
    assign instr_type_out = instr_in[6:0];
    assign reg_id1 = instr_in[19:15];
    assign reg_id2 = instr_in[24:20];
    assign rd = instr_in[11:7];

    function [31:0] get_imm(input [31:0] inst, input [6:0] instr_type);
        case (instr_type)
            `LUI, `AUIPC: get_imm = {inst[31:12], 12'b0};
            `JAL: get_imm = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};
            // TODO
            `JALR: get_imm = {{20{inst[31]}}, inst[31:20]};
            `B_TYPE: get_imm = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
            `LD_TYPE, `I_TYPE: get_imm = {{20{inst[31]}}, inst[31:20]};
            `S_TYPE: get_imm = {{20{inst[31]}}, inst[31:25], inst[11:7]};
            `R_TYPE: get_imm = 0;
            default: get_imm = 0;
        endcase
    endfunction

    assign imm = get_imm(instr_in, instr_type_out);
    
    // TODO
    wire has_rs2, has_rd;
    assign has_rs2 = (instr_type_out == `R_TYPE || instr_type_out == `S_TYPE || instr_type_out == `B_TYPE);
    assign has_rd = !(instr_type_out == `B_TYPE || instr_type_out == `S_TYPE);
    assign reg_value1_out = reg_value1_in;
    assign reg_value2_out = reg_value2_in;
    assign has_dep1_out = has_dep1_in;
    assign has_dep2_out = has_dep2_in;
    assign v_rob_id1_out = v_rob_id1_in;
    assign v_rob_id2_out = v_rob_id2_in;
    assign rd_rob_id_out = has_rd ? 0 : rd_rob_id_in;

endmodule