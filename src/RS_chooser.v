`include "config.v"
// `include "/home/hqs123/class_code/CPU/src/config.v"

module RS_chooser(
    input wire clk,
    input wire rst,
    input wire rdy,

    // from RS
    input wire [`RS_SIZE - 1 : 0] busy,
    input wire [`RS_SIZE - 1 : 0] ready,

    // to RS
    output wire [`RS_SIZE_WIDTH - 1 : 0] free_rs_line,
    output wire has_exe_rs_line,
    output wire [`RS_SIZE_WIDTH - 1 : 0] exe_rs_line

);

    reg [`RS_SIZE_WIDTH - 1 : 0] free_tree [0 : `RS_SIZE - 1];
    reg [`RS_SIZE_WIDTH - 1 : 0] ready_tree [0 : `RS_SIZE - 1];

    integer i;
    always @(*) begin
        for(i = `RS_SIZE; i < 2 * `RS_SIZE; i = i + 1) begin
            free_tree[i] = busy[i - `RS_SIZE] ? 0 : i - `RS_SIZE;
        end
    end

    

endmodule