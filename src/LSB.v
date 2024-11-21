`include "config.v"
module LSB (
    input wire clk,
    input wire rst,
    input wire rdy,

    // from RoB
    input wire rob_ready,
    input wire [`ROB_SIZE_WIDTH - 1 : 0] rob_rob_id,
    input wire [31 : 0] rob_value,

    // from RS
    input wire rs_ready,
    input wire [`ROB_SIZE_WIDTH - 1 : 0] rs_rob_id,
    input wire [31 : 0] rs_value,

    // to Reg: issue and commit
    output wire [`ROB_SIZE_WIDTH - 1 : 0] commit_rob_id,
    output wire [31 : 0] commit_value,
    output wire [`ROB_SIZE_WIDTH - 1 : 0] issue_rob_id,
    output wire [31 : 0] issue_value,

    // get reg value: instant connection
    input wire [`ROB_SIZE_WIDTH - 1 : 0] get_rob_id1,
    input wire [`ROB_SIZE_WIDTH - 1 : 0] get_rob_id2,
    output wire [31 : 0] get_value1,
    output wire [31 : 0] get_value2,
    output wire get_ready1,
    output wire get_ready2
);
endmodule