// `include "config.v"
// `include "RS_chooser.v"
// `include "ALU.v"
`include "/home/hqs123/class_code/CPU/src/config.v"
`include "/home/hqs123/class_code/CPU/src/RS_chooser.v"
`include "/home/hqs123/class_code/CPU/src/ALU.v"

module RS (
    input wire clk,
    input wire rst,
    input wire rdy,

    // from Decoder
    input wire instr_issued,
    input wire [31 : 0] instr_in,
    input wire [31 : 0] instr_addr_in,
    input wire [6 : 0] instr_type_in,
    input wire [31 : 0] reg_value1_in,
    input wire [31 : 0] reg_value2_in,
    input wire has_dep1_in,
    input wire has_dep2_in,
    input wire [`ROB_SIZE_WIDTH - 1 : 0] v_rob_id1_in,
    input wire [`ROB_SIZE_WIDTH - 1 : 0] v_rob_id2_in,
    input wire [`ROB_SIZE_WIDTH - 1 : 0] rd_rob_id_in,

    // from LSB
    input wire lsb_ready,
    input wire [`ROB_SIZE_WIDTH - 1 : 0] lsb_rob_id,
    input wire [31 : 0] lsb_value,

    // from RoB: clear
    input wire rob_clear,

    // to RoB and LSB: data from ALU
    output wire rs_ready,
    output wire [`ROB_SIZE_WIDTH - 1 : 0] rs_rob_id,
    output wire [31 : 0] rs_value,

    // to ALU
    output wire [`ROB_SIZE_WIDTH - 1 : 0] alu_rob_id
);

    reg busy [0 : `RS_SIZE - 1];
    reg [31 : 0] instr [0 : `RS_SIZE - 1];
    reg [31 : 0] instr_addr [0 : `RS_SIZE - 1];
    reg [6 : 0] instr_type [0 : `RS_SIZE - 1];
    reg [31 : 0] reg_value1 [0 : `RS_SIZE - 1];
    reg [31 : 0] reg_value2 [0 : `RS_SIZE - 1];
    reg has_dep1 [0 : `RS_SIZE - 1];
    reg has_dep2 [0 : `RS_SIZE - 1];
    reg [`ROB_SIZE_WIDTH - 1 : 0] v_rob_id1 [0 : `RS_SIZE - 1];
    reg [`ROB_SIZE_WIDTH - 1 : 0] v_rob_id2 [0 : `RS_SIZE - 1];
    reg [`ROB_SIZE_WIDTH - 1 : 0] rd_rob_id [0 : `RS_SIZE - 1];

    // 通过 RS_chooser 选择两个line
    wire [`RS_SIZE_WIDTH - 1 : 0] free_rs_line;
    wire has_exe_rs_line;
    wire [`RS_SIZE_WIDTH - 1 : 0] exe_rs_line;

    always @(posedge clk) begin
        if(rst || rob_clear) begin
            // TODO
        end
        else if (!rdy) begin
            // do nothing
        end
        else begin
            // add instr
            if (instr_issued) begin
                busy[free_rs_line] <= 1;
                instr[free_rs_line] <= instr_in;
                instr_addr[free_rs_line] <= instr_addr_in;
                instr_type[free_rs_line] <= instr_type_in;
                reg_value1[free_rs_line] <= reg_value1_in;
                reg_value2[free_rs_line] <= reg_value2_in;
                has_dep1[free_rs_line] <= has_dep1_in;
                has_dep2[free_rs_line] <= has_dep2_in;
                v_rob_id1[free_rs_line] <= v_rob_id1_in;
                v_rob_id2[free_rs_line] <= v_rob_id2_in;
                rd_rob_id[free_rs_line] <= rd_rob_id_in;
            end
            // listen broadcast
            for(int i = 0; i < `RS_SIZE; i = i + 1) begin
                if(lsb_ready) begin
                    if(v_rob_id1[i] == lsb_rob_id) begin
                        reg_value1[i] <= lsb_value;
                        has_dep1[i] <= 0;
                    end
                    if(v_rob_id2[i] == lsb_rob_id) begin
                        reg_value2[i] <= lsb_value;
                        has_dep2[i] <= 0;
                    end
                end
                if(rs_ready) begin
                    if(v_rob_id1[i] == rs_rob_id) begin
                        reg_value1[i] <= rs_value;
                        has_dep1[i] <= 0;
                    end
                    if(v_rob_id2[i] == rs_rob_id) begin
                        reg_value2[i] <= rs_value;
                        has_dep2[i] <= 0;
                    end
                end
            end
            // calculate
            if(has_exe_rs_line) begin
                busy[exe_rs_line] <= 0;
            end
        end
    end

    ALU alu (
        .clk(clk),
        .rst(rst),
        .rdy(rdy),
        .rob_id_in(alu_rob_id),
        .op(instr_type[alu_rob_id][6:0]),// TODO
        .v1(reg_value1[alu_rob_id]),
    );


endmodule