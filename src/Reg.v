// `include "config.v"
`include "/home/hqs123/class_code/CPU/src/config.v"
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
    assign has_issued_1 = has_dep[get_reg_value1] || (issue_rob_id == ask_rob_id1) && (ask_rob_id1 != 0);
    assign has_issued_2 = has_dep[get_reg_value2] || (issue_rob_id == ask_rob_id2) && (ask_rob_id2 != 0);
    assign reg_has_dep1 = has_issue_1 && (!get_ready1);
    assign reg_has_dep2 = has_issue_2 && (!get_ready2);
    assign ask_rob_id1 = has_issued_1 ? dep_rob_id[get_reg_value1] : issue_rob_id;
    assign ask_rob_id2 = has_issued_2 ? dep_rob_id[get_reg_value2] : issue_rob_id;
    assign reg_value1 = reg_has_dep1 ? 0 : (has_issued_1 ? regs[get_reg_value1] : get_value1);
    assign reg_value2 = reg_has_dep2 ? 0 : (has_issued_2 ? regs[get_reg_value2] : get_value2);
    assign reg_dep_rob_id1 = reg_has_dep1 ? (has_dep[get_reg_value1] ? dep_rob_id[get_reg_value1] : issue_rob_id) : 0;
    assign reg_dep_rob_id2 = reg_has_dep2 ? (has_dep[get_reg_value2] ? dep_rob_id[get_reg_value2] : issue_rob_id) : 0;

    always @(posedge clk) begin
        integer i;
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
            if(issue_rob_id != 0) begin
                has_dep[issue_rd] <= 1;
                dep_rob_id[issue_rd] <= ask_rob_id1;
            end
            if(commit_rob_id != 0) begin
                regs[commit_rd] <= commit_value;
                if(has_dep[commit_rd] && dep_rob_id[commit_rd] == commit_rob_id) begin
                    has_dep[commit_rd] <= 0;
                    dep_rob_id[commit_rd] <= 0;
                end
            end
        end
    end


endmodule