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
    output reg [31 : 0] predict_pc,

    // to RS and LSB and RoB
    output reg instr_issued,// and to fetcher
    output wire updating_instr_issued,

    output reg [31 : 0] instr_out,
    output reg [31 : 0] instr_addr_out,
    output reg [2 : 0] op_out,
    output reg [6 : 0] instr_type_out,
    output reg [31 : 0] reg_value1_out,
    output reg [31 : 0] reg_value2_out,
    output reg has_dep1_out,
    output reg has_dep2_out,
    output reg [`ROB_SIZE_WIDTH - 1 : 0] v_rob_id1_out,
    output reg [`ROB_SIZE_WIDTH - 1 : 0] v_rob_id2_out,
    output wire [`ROB_SIZE_WIDTH - 1 : 0] rd_rob_id_out, //这行指令对应的rob_id

    // to RoB and LSB
    output reg [31 : 0] imm,
    // to RoB
    output reg [4 : 0] rd,

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
    
    wire [6:0] d_instr_type_in;
    assign d_instr_type_in = instr_in[6:0];
    wire [2:0] d_op_in;
    assign d_op_in = instr_in[14:12];
    wire jalr_not_ready = d_instr_type_in == `JALR && has_dep1_in;
    
    // 用来表示这个信息现在能不能发送
    wire need_work;
    assign need_work = instr_ready && !rob_full && !rs_full && !lsb_full && !jalr_not_ready;
    assign updating_instr_issued = need_work;

    wire has_rs2, has_rd;
    assign has_rs2 = !(d_instr_type_in == `LUI || d_instr_type_in == `AUIPC || d_instr_type_in == `JAL || d_instr_type_in == `JALR || d_instr_type_in == `LD_TYPE || d_instr_type_in == `I_TYPE);
    assign has_rd = !(d_instr_type_in == `B_TYPE || d_instr_type_in == `S_TYPE);
    
    assign reg_id1 = instr_in[19:15];
    assign reg_id2 = instr_in[24:20];

    assign rd_rob_id_out = rd_rob_id_in;

    function [31:0] get_imm(input [31:0] inst, input [6:0] _instr_type, input [2:0] _op);
        case (_instr_type)
            `LUI, `AUIPC: get_imm = {inst[31:12], 12'b0};
            `JAL: get_imm = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};
            `JALR: get_imm = {{20{inst[31]}}, inst[31:20]};
            `B_TYPE: get_imm = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
            `LD_TYPE: get_imm = {{20{inst[31]}}, inst[31:20]};
            `I_TYPE: begin
                if (_op != 3'b001 && _op != 3'b101) begin
                    get_imm = {{20{inst[31]}}, inst[31:20]};
                end
                else begin
                    get_imm = {{26{inst[25]}}, inst[25:20]};
                end
            end
            `S_TYPE: get_imm = {{20{inst[31]}}, inst[31:25], inst[11:7]};
            `R_TYPE: get_imm = 0;
            default: get_imm = 0;
        endcase
    endfunction
    wire [31:0] gen_imm = get_imm(instr_in, d_instr_type_in, d_op_in);
    
    // predictor
    function [31 : 0] gen_new_pc;
        input [31 : 0] _pc;
        input [31 : 0] _instr;
        input [31 : 0] _imm;
        input [31 : 0] _reg_value1_in;
        case (_instr[6 : 0])
            `JAL: gen_new_pc = _pc + _imm;
            `JALR: gen_new_pc = _reg_value1_in + _imm;
            `B_TYPE: gen_new_pc = _pc + _imm;
            default: gen_new_pc = _pc + 4;
        endcase
    endfunction
    wire [31:0] new_pc = gen_new_pc(instr_addr_in, instr_in, gen_imm, reg_value1_in);

    always @(posedge clk) begin
        if (rst) begin
            predict_pc <= 0;
            instr_issued <= 0;
            instr_out <= 0;
            instr_addr_out <= 0;
            op_out <= 0;
            instr_type_out <= 0;
            reg_value1_out <= 0;
            reg_value2_out <= 0;
            has_dep1_out <= 0;
            has_dep2_out <= 0;
            v_rob_id1_out <= 0;
            v_rob_id2_out <= 0;
            // rd_rob_id_out <= 0;
            imm <= 0;
            rd <= 0;
        end
        else if(!rdy) begin
            // do nothing
        end
        else if (!need_work) begin
            instr_issued <= need_work;
        end
        else begin
            predict_pc <= new_pc;
            instr_issued <= need_work;
            instr_out <= instr_in;
            instr_addr_out <= instr_addr_in;
            op_out <= instr_in[14:12];
            instr_type_out <= instr_in[6:0];
            rd <= has_rd ? instr_in[11:7] : 0;
            imm <= gen_imm;
            reg_value1_out <= reg_value1_in;
            reg_value2_out <= has_rs2 ? reg_value2_in : gen_imm;
            has_dep1_out <= has_dep1_in;
            has_dep2_out <= has_rs2 ? has_dep2_in : 0;
            v_rob_id1_out <= v_rob_id1_in;
            v_rob_id2_out <= has_rs2 ? v_rob_id2_in : 0;
            // rd_rob_id_out <= rd_rob_id_in;
        end
    end
    
    // always @* begin
    //     $display("--------------decoder----------------time=%0t", $time);
    //     $display("time=%0t rob_full: %b", $time, rob_full);
    //     $display("time=%0t rs_full: %b", $time, rs_full);
    //     $display("time=%0t lsb_full: %b", $time, lsb_full);
    //     $display("time=%0t fd_instr_ready: %b", $time, instr_ready);
    //     $display("time=%0t d_instr_issued: %b", $time, instr_issued);
    // end
    
endmodule