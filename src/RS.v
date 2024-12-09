`include "config.v"
// `include "ALU.v"
// `include "/home/hqs123/class_code/CPU/src/config.v"
// `include "/home/hqs123/class_code/CPU/src/RS_chooser.v"
// `include "/home/hqs123/class_code/CPU/src/ALU.v"

module RS (
    input wire clk,
    input wire rst,
    input wire rdy,

    // to Decoder
    output wire rs_full,

    // from Decoder
    input wire instr_issued,
    input wire [31 : 0] instr_in,
    input wire [31 : 0] instr_addr_in,
    input wire [2 : 0] op_in,
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
    output wire [31 : 0] rs_value

);

    // to ALU
    wire [`ROB_SIZE_WIDTH - 1 : 0] alu_rob_id;
    wire valid;
    wire [2:0] op_out;
    wire [6:0] instr_type_out;
    wire op_other;
    wire [31 : 0] v1;
    wire [31 : 0] v2;
    
    ALU alu_instance (
        .clk(clk),
        .rst(rst),
        .rdy(rdy),

        .rob_clear(rob_clear),
        .rob_id_in(alu_rob_id),
        .valid(valid),
        .op(op_out),
        .instr_type_in(instr_type_out),
        .op_other(op_other),
        .v1(v1),
        .v2(v2),

        .rob_id_out(rs_rob_id),
        .result(rs_value),
        .ready(rs_ready)
    );

    reg [`RS_SIZE_WIDTH - 1 : 0] rs_size;

    reg busy [0 : `RS_SIZE - 1];
    reg [31 : 0] instr [0 : `RS_SIZE - 1];
    reg [31 : 0] instr_addr [0 : `RS_SIZE - 1];
    reg [2 : 0] op [0 : `RS_SIZE - 1];
    reg [6 : 0] instr_type [0 : `RS_SIZE - 1];
    reg [31 : 0] reg_value1 [0 : `RS_SIZE - 1];
    reg [31 : 0] reg_value2 [0 : `RS_SIZE - 1];
    reg has_dep1 [0 : `RS_SIZE - 1];
    reg has_dep2 [0 : `RS_SIZE - 1];
    reg [`ROB_SIZE_WIDTH - 1 : 0] v_rob_id1 [0 : `RS_SIZE - 1];
    reg [`ROB_SIZE_WIDTH - 1 : 0] v_rob_id2 [0 : `RS_SIZE - 1];
    reg [`ROB_SIZE_WIDTH - 1 : 0] rob_id [0 : `RS_SIZE - 1];

    // 通过 RS_chooser 选择两个line
    wire [`RS_SIZE_WIDTH - 1 : 0] free_rs_line;
    wire [`RS_SIZE_WIDTH - 1 : 0] exe_rs_line;

    function gen_op_other;
        input [31:0] inst;
        case (inst[1:0])
            2'b00,2'b10: gen_op_other = 0;
            2'b01: begin
                case (inst[15:13])
                    3'b100: case (inst[11:10])
                        2'b01:gen_op_other = 1;
                        2'b11:gen_op_other = (inst[6:5] == 2'b00) ? 1 : 0;
                        default:gen_op_other = 0;
                    endcase
                    default: gen_op_other = 0;
                endcase
            end
        endcase
    endfunction

    // --------RS_chooser---------
    wire free_tree[0 : (`RS_SIZE<<1)-1];
    wire [`RS_SIZE_WIDTH - 1 : 0] free_tree_id [0 : (`RS_SIZE<<1)-1];
    wire exe_tree [0 : (`RS_SIZE<<1)-1];
    wire [`RS_SIZE_WIDTH - 1 : 0] exe_tree_id [0 : (`RS_SIZE<<1)-1];
    assign free_tree[0] = free_tree[1];
    assign free_tree_id[0] = free_tree_id[1];
    assign exe_tree[0] = exe_tree[1];
    assign exe_tree_id[0] = exe_tree_id[1];
    generate
        genvar gi;
        for(gi = `RS_SIZE; gi < `RS_SIZE << 1; gi = gi + 1) begin
            assign free_tree[gi] = ~busy[gi-`RS_SIZE];
            assign free_tree_id[gi] = gi-`RS_SIZE;
            assign exe_tree[gi] = busy[gi-`RS_SIZE] && !has_dep1[gi-`RS_SIZE] && !has_dep2[gi-`RS_SIZE];
            assign exe_tree_id[gi] = gi-`RS_SIZE;
        end
        for(gi = 1; gi < `RS_SIZE; gi = gi + 1) begin
            assign free_tree[gi] = free_tree[gi<<1] || free_tree[gi<<1|1];
            assign free_tree_id[gi] = free_tree[gi<<1] ? free_tree_id[gi<<1] : free_tree_id[gi<<1|1];
            assign exe_tree[gi] = exe_tree[gi<<1] || exe_tree[gi<<1|1];
            assign exe_tree_id[gi] = exe_tree[gi<<1] ? exe_tree_id[gi<<1] : exe_tree_id[gi<<1|1];
        end
    endgenerate
    assign exe_rs_line = exe_tree_id[0];
    assign free_rs_line = free_tree_id[0];

    assign valid = exe_tree[0];
    assign op_out = op[exe_rs_line];
    assign alu_rob_id = rob_id[exe_rs_line];
    // 错误：要判断这条指令有没有op_other
    wire has_op_other = instr_type[exe_rs_line]==`I_TYPE && op[exe_rs_line]==3'b101 || instr_type[exe_rs_line]==`R_TYPE && (op[exe_rs_line]==3'b101 || op[exe_rs_line]==3'b000);
    assign is_i = (instr[exe_rs_line][1:0] == 2'b11);
    wire get_op_other = is_i ? instr[exe_rs_line][30] : gen_op_other(instr[exe_rs_line]);
    assign op_other = has_op_other && get_op_other;
    assign instr_type_out = instr_type[exe_rs_line];
    assign v1 = reg_value1[exe_rs_line];
    assign v2 = reg_value2[exe_rs_line];
    // --------RS_chooser---------

    // 判断这条指令是否进入RS
    wire judge_instr, accept_instr;
    assign judge_instr = (instr_type_in == `I_TYPE || instr_type_in == `R_TYPE || instr_type_in == `B_TYPE);
    assign accept_instr = instr_issued && judge_instr;

    // assign rs_full = (rs_size == `RS_SIZE) || (rs_size + 1 == `RS_SIZE && !exe_tree[0]);
    assign rs_full = (rs_size - exe_tree[0] + accept_instr == `RS_SIZE);
    
    integer i;
    always @(posedge clk) begin
        if(rst || rob_clear) begin
            rs_size <= 0;
            for(i = 0; i < `RS_SIZE; i = i + 1) begin
                busy[i] <= 1'b0;
                instr[i] <= 32'b0;
                instr_addr[i] <= 32'b0;
                op[i] <= 3'b0;
                instr_type[i] <= 7'b0;
                reg_value1[i] <= 32'b0;
                reg_value2[i] <= 32'b0;
                has_dep1[i] <= 1'b0;
                has_dep2[i] <= 1'b0;
                v_rob_id1[i] <= {`ROB_SIZE_WIDTH{1'b0}};
                v_rob_id2[i] <= {`ROB_SIZE_WIDTH{1'b0}};
                rob_id[i] <= {`ROB_SIZE_WIDTH{1'b0}};
            end
        end
        else if (!rdy) begin
            // do nothing
        end
        else begin
            // update rs_size
            rs_size <= rs_size - exe_tree[0] + accept_instr;
            // add instr
            if (accept_instr) begin
                busy[free_rs_line] <= 1;
                instr[free_rs_line] <= instr_in;
                instr_addr[free_rs_line] <= instr_addr_in;
                op[free_rs_line] <= op_in;
                instr_type[free_rs_line] <= instr_type_in;
                reg_value1[free_rs_line] <= !has_dep1_in ? reg_value1_in : rs_ready && v_rob_id1_in == rs_rob_id ? rs_value : lsb_ready && v_rob_id1_in == lsb_rob_id ? lsb_value : 0;
                reg_value2[free_rs_line] <= !has_dep2_in ? reg_value2_in : rs_ready && v_rob_id2_in == rs_rob_id ? rs_value : lsb_ready && v_rob_id2_in == lsb_rob_id ? lsb_value : 0;
                has_dep1[free_rs_line] <= has_dep1_in && !(rs_ready && v_rob_id1_in == rs_rob_id) && !(lsb_ready && v_rob_id1_in == lsb_rob_id);
                has_dep2[free_rs_line] <= has_dep2_in && !(rs_ready && v_rob_id2_in == rs_rob_id) && !(lsb_ready && v_rob_id2_in == lsb_rob_id);
                v_rob_id1[free_rs_line] <= (has_dep1_in && !(rs_ready && v_rob_id1_in == rs_rob_id) && !(lsb_ready && v_rob_id1_in == lsb_rob_id)) ? v_rob_id1_in : 0;
                v_rob_id2[free_rs_line] <= (has_dep2_in && !(rs_ready && v_rob_id2_in == rs_rob_id) && !(lsb_ready && v_rob_id2_in == lsb_rob_id)) ? v_rob_id2_in : 0;
                rob_id[free_rs_line] <= rd_rob_id_in;
            end
            // listen broadcast
            for(i = 0; i < `RS_SIZE; i = i + 1) begin
                if(busy[i]) begin
                    // 错误：这里判断要加上has_dep，不然就更新炸了
                    if(lsb_ready) begin
                        if(has_dep1[i] && v_rob_id1[i] == lsb_rob_id) begin
                            reg_value1[i] <= lsb_value;
                            has_dep1[i] <= 0;
                        end
                        if(has_dep2[i] && v_rob_id2[i] == lsb_rob_id) begin
                            reg_value2[i] <= lsb_value;
                            has_dep2[i] <= 0;
                        end
                    end
                    if(rs_ready) begin
                        if(has_dep1[i] && v_rob_id1[i] == rs_rob_id) begin
                            reg_value1[i] <= rs_value;
                            has_dep1[i] <= 0;
                        end
                        if(has_dep2[i] && v_rob_id2[i] == rs_rob_id) begin
                            reg_value2[i] <= rs_value;
                            has_dep2[i] <= 0;
                        end
                    end
                end
            end
            // calculate
            if(exe_tree[0]) begin
                busy[exe_rs_line] <= 0;
            end
        end
    end
    
    // debug
    wire debug_rs_busy0 = busy[0];
    wire debug_rs_busy1 = busy[1];
    wire [31:0] debug_rs_instr0 = instr[0];
    wire [31:0] debug_rs_instr1 = instr[1];
    wire [31:0] debug_rs_instr_addr0 = instr_addr[0];
    wire [31:0] debug_rs_instr_addr1 = instr_addr[1];
    wire [2:0] debug_rs_op0 = op[0];
    wire [2:0] debug_rs_op1 = op[1];
    wire [6:0] debug_rs_instr_type0 = instr_type[0];
    wire [6:0] debug_rs_instr_type1 = instr_type[1];
    wire [31:0] debug_rs_reg_value10 = reg_value1[0];
    wire [31:0] debug_rs_reg_value11 = reg_value1[1];
    wire [31:0] debug_rs_reg_value20 = reg_value2[0];
    wire [31:0] debug_rs_reg_value21 = reg_value2[1];
    wire debug_rs_has_dep10 = has_dep1[0];
    wire debug_rs_has_dep11 = has_dep1[1];
    wire debug_rs_has_dep20 = has_dep2[0];
    wire debug_rs_has_dep21 = has_dep2[1];
    wire [`ROB_SIZE_WIDTH - 1 : 0] debug_rs_v_rob_id10 = v_rob_id1[0];
    wire [`ROB_SIZE_WIDTH - 1 : 0] debug_rs_v_rob_id11 = v_rob_id1[1];
    wire [`ROB_SIZE_WIDTH - 1 : 0] debug_rs_v_rob_id20 = v_rob_id2[0];
    wire [`ROB_SIZE_WIDTH - 1 : 0] debug_rs_v_rob_id21 = v_rob_id2[1];
    wire [`ROB_SIZE_WIDTH - 1 : 0] debug_rs_rob_id0 = rob_id[0];
    wire [`ROB_SIZE_WIDTH - 1 : 0] debug_rs_rob_id1 = rob_id[1];

endmodule