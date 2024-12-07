// useless

`include "config.v"
module predictor(
    input wire clk,
    input wire rst,
    input wire rdy,

    input wire [31 : 0] pc,
    input wire [31 : 0] instr,
    input wire [31 : 0] imm,

    output wire [31 : 0] new_pc
);

    function [31 : 0] gen_new_pc;
        input [31 : 0] pc;
        input [31 : 0] instr;
        input [31 : 0] imm;
        case (instr[6 : 0])
            `JAL: gen_new_pc = pc + imm;
            `JALR: gen_new_pc = pc + imm;
            `B_TYPE: gen_new_pc = pc + imm;
            default: gen_new_pc = pc + 4;
        endcase
    endfunction
    
    assign new_pc = gen_new_pc(pc, instr, imm);

endmodule