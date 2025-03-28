`include "config.v"
// `include "/home/hqs123/class_code/CPU/src/config.v"
module Reg (
    input wire clk,
    input wire rst,
    input wire rdy,

    // from RoB
    input wire [`ROB_SIZE_WIDTH - 1 : 0] commit_rob_id,
    input wire [4 : 0] commit_rd,
    input wire [31 : 0] commit_value,
    input wire [`ROB_SIZE_WIDTH - 1 : 0] issue_rob_id,
    input wire [4 : 0] issue_rd,

    // get reg value: instant connection
    output wire [`ROB_SIZE_WIDTH - 1 : 0] ask_rob_id1,
    output wire [`ROB_SIZE_WIDTH - 1 : 0] ask_rob_id2,
    input wire [31 : 0] get_value1,
    input wire [31 : 0] get_value2,
    input wire get_ready1,
    input wire get_ready2,

    // from Decoder
    input wire [4 : 0] get_reg_value1,
    input wire [4 : 0] get_reg_value2,

    // to Decoder
    output wire [31 : 0] reg_value1,
    output wire [31 : 0] reg_value2,
    output wire reg_has_dep1,
    output wire reg_has_dep2,
    output wire [`ROB_SIZE_WIDTH - 1 : 0] reg_dep_rob_id1,
    output wire [`ROB_SIZE_WIDTH - 1 : 0] reg_dep_rob_id2

);

    reg [31 : 0] regs [0 : 31];
    reg has_dep [0 : 31];
    reg [`ROB_SIZE_WIDTH - 1 : 0] dep_rob_id [0 : 31];

    // Decoder 给一个 reg_id，Reg 返回这个 reg_id 对应的值或者依赖的 RoB_id
    wire has_issued_1, has_issued_2;
    assign has_issued_1 = has_dep[get_reg_value1] || ((issue_rd == get_reg_value1) && (issue_rd != 0));//
    assign has_issued_2 = has_dep[get_reg_value2] || ((issue_rd == get_reg_value2) && (issue_rd != 0));//
    assign reg_has_dep1 = has_issued_1 && (!get_ready1);//
    assign reg_has_dep2 = has_issued_2 && (!get_ready2);//
    assign reg_value1 = (has_issued_1 ? get_value1 : regs[get_reg_value1]);//
    assign reg_value2 = (has_issued_2 ? get_value2 : regs[get_reg_value2]);//
    assign reg_dep_rob_id1 = (issue_rd == get_reg_value1 ? issue_rob_id : dep_rob_id[get_reg_value1]);//
    assign reg_dep_rob_id2 = (issue_rd == get_reg_value2 ? issue_rob_id : dep_rob_id[get_reg_value2]);//
    assign ask_rob_id1 = reg_dep_rob_id1;
    assign ask_rob_id2 = reg_dep_rob_id2;

    integer i;
    always @(posedge clk) begin
        if(rst) begin
            for(i = 0; i < 32; i = i + 1) begin
                regs[i] <= 0;
                has_dep[i] <= 0;
                dep_rob_id[i] <= 0;
            end
        end 
        else if(!rdy) begin
            // do nothing
        end
        else begin
            if(issue_rd != 0) begin
                has_dep[issue_rd] <= 1;
                dep_rob_id[issue_rd] <= issue_rob_id;
            end
            if(commit_rd != 0) begin
                regs[commit_rd] <= commit_value;
                if(has_dep[commit_rd] && dep_rob_id[commit_rd] == commit_rob_id) begin
                    has_dep[commit_rd] <= 0;
                    dep_rob_id[commit_rd] <= 0;
                end
            end
        end
    end
    
    
    // debug
    wire [31:0] zero = regs[0];
    wire [31:0] ra = regs[1];
    wire [31:0] sp = regs[2];
    wire [31:0] gp = regs[3];
    wire [31:0] tp = regs[4];
    wire [31:0] t0 = regs[5];
    wire [31:0] t1 = regs[6];
    wire [31:0] t2 = regs[7];
    wire [31:0] s0 = regs[8];
    wire [31:0] s1 = regs[9];
    wire [31:0] a0 = regs[10];
    wire [31:0] a1 = regs[11];
    wire [31:0] a2 = regs[12];
    wire [31:0] a3 = regs[13];
    wire [31:0] a4 = regs[14];
    wire [31:0] a5 = regs[15];
    wire [31:0] a6 = regs[16];
    wire [31:0] a7 = regs[17];
    wire [31:0] s2 = regs[18];
    wire [31:0] s3 = regs[19];
    wire [31:0] s4 = regs[20];
    wire [31:0] s5 = regs[21];
    wire [31:0] s6 = regs[22];
    wire [31:0] s7 = regs[23];
    wire [31:0] s8 = regs[24];
    wire [31:0] s9 = regs[25];
    wire [31:0] s10 = regs[26];
    wire [31:0] s11 = regs[27];
    wire [31:0] t3 = regs[28];
    wire [31:0] t4 = regs[29];
    wire [31:0] t5 = regs[30];
    wire [31:0] t6 = regs[31];
    wire zero_has_dep = has_dep[0];
    wire ra_has_dep = has_dep[1];
    wire sp_has_dep = has_dep[2];
    wire gp_has_dep = has_dep[3];
    wire tp_has_dep = has_dep[4];
    wire t0_has_dep = has_dep[5];
    wire t1_has_dep = has_dep[6];
    wire t2_has_dep = has_dep[7];
    wire s0_has_dep = has_dep[8];
    wire s1_has_dep = has_dep[9];
    wire a0_has_dep = has_dep[10];
    wire a1_has_dep = has_dep[11];
    wire a2_has_dep = has_dep[12];
    wire a3_has_dep = has_dep[13];
    wire a4_has_dep = has_dep[14];
    wire a5_has_dep = has_dep[15];
    wire a6_has_dep = has_dep[16];
    wire a7_has_dep = has_dep[17];
    wire s2_has_dep = has_dep[18];
    wire s3_has_dep = has_dep[19];
    wire s4_has_dep = has_dep[20];
    wire s5_has_dep = has_dep[21];
    wire s6_has_dep = has_dep[22];
    wire s7_has_dep = has_dep[23];
    wire s8_has_dep = has_dep[24];
    wire s9_has_dep = has_dep[25];
    wire s10_has_dep = has_dep[26];
    wire s11_has_dep = has_dep[27];
    wire t3_has_dep = has_dep[28];
    wire t4_has_dep = has_dep[29];
    wire t5_has_dep = has_dep[30];
    wire t6_has_dep = has_dep[31];
    wire zero_dep_rob_id = dep_rob_id[0];
    wire ra_dep_rob_id = dep_rob_id[1];
    wire sp_dep_rob_id = dep_rob_id[2];
    wire gp_dep_rob_id = dep_rob_id[3];
    wire tp_dep_rob_id = dep_rob_id[4];
    wire t0_dep_rob_id = dep_rob_id[5];
    wire t1_dep_rob_id = dep_rob_id[6];
    wire t2_dep_rob_id = dep_rob_id[7];
    wire s0_dep_rob_id = dep_rob_id[8];
    wire s1_dep_rob_id = dep_rob_id[9];
    wire a0_dep_rob_id = dep_rob_id[10];
    wire a1_dep_rob_id = dep_rob_id[11];
    wire a2_dep_rob_id = dep_rob_id[12];
    wire a3_dep_rob_id = dep_rob_id[13];
    wire a4_dep_rob_id = dep_rob_id[14];
    wire a5_dep_rob_id = dep_rob_id[15];
    wire a6_dep_rob_id = dep_rob_id[16];
    wire a7_dep_rob_id = dep_rob_id[17];
    wire s2_dep_rob_id = dep_rob_id[18];
    wire s3_dep_rob_id = dep_rob_id[19];
    wire s4_dep_rob_id = dep_rob_id[20];
    wire s5_dep_rob_id = dep_rob_id[21];
    wire s6_dep_rob_id = dep_rob_id[22];
    wire s7_dep_rob_id = dep_rob_id[23];
    wire s8_dep_rob_id = dep_rob_id[24];
    wire s9_dep_rob_id = dep_rob_id[25];
    wire s10_dep_rob_id = dep_rob_id[26];
    wire s11_dep_rob_id = dep_rob_id[27];
    wire t3_dep_rob_id = dep_rob_id[28];
    wire t4_dep_rob_id = dep_rob_id[29];
    wire t5_dep_rob_id = dep_rob_id[30];
    wire t6_dep_rob_id = dep_rob_id[31];

endmodule