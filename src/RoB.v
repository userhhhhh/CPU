`include "config.v"
// `include "/home/hqs123/class_code/CPU/src/config.v"
module RoB (
    input wire clk,
    input wire rst,
    input wire rdy,

    // to decoder
    output wire rob_full,
    output wire [`ROB_SIZE_WIDTH - 1 : 0] rd_rob_id,

    // from Decoder
    input wire issue_signal,
    input wire [31 : 0] instr,
    input wire [2 : 0] op,
    input wire [6 : 0] instr_type,
    input wire [31 : 0] instr_addr,
    input wire [4 : 0] rd,
    input wire [31 : 0] imm,

    // from RS
    input wire rs_ready,
    input wire [`ROB_SIZE_WIDTH - 1 : 0] rs_rob_id,
    input wire [31 : 0] rs_value,

    // from LSB
    input wire lsb_ready,
    input wire [`ROB_SIZE_WIDTH - 1 : 0] lsb_rob_id,
    input wire [31 : 0] lsb_value,

    // to LSB
    output wire [`ROB_SIZE_WIDTH - 1 : 0] head_rob_id,

    // to Reg: issue and commit
    output wire [`ROB_SIZE_WIDTH - 1 : 0] commit_rob_id,
    output wire [4 : 0] commit_rd,
    output wire [31 : 0] commit_value,
    output wire [`ROB_SIZE_WIDTH - 1 : 0] issue_rob_id,
    output wire [4 : 0] issue_rd,

    // get reg value: instant connection
    input wire [`ROB_SIZE_WIDTH - 1 : 0] get_rob_id1,
    input wire [`ROB_SIZE_WIDTH - 1 : 0] get_rob_id2,
    output wire [31 : 0] get_value1,
    output wire [31 : 0] get_value2,
    output wire get_ready1,
    output wire get_ready2,

    // the predictor
    output wire clear,
    output wire [31 : 0] back_pc

);

    // 循环队列
    reg [`ROB_SIZE_WIDTH - 1 : 0] head, tail;

    // 记录每个指令的状态
    reg busy [0 : `ROB_SIZE - 1]; // 是否已经有指令了
    reg prepared [0 : `ROB_SIZE - 1]; // 是否已经等到值了

    reg [4:0] rds [0 : `ROB_SIZE - 1]; // 存放指令原来的rd
    reg [31:0] values [0 : `ROB_SIZE - 1]; // 存放已经算好的值
    reg [2:0] ops [0 : `ROB_SIZE - 1];
    reg [31:0] insts [0 : `ROB_SIZE - 1];
    reg [6:0] insts_type [0 : `ROB_SIZE - 1];
    reg [31:0] insts_addr [0 : `ROB_SIZE - 1];

    integer i;

    parameter [`ROB_SIZE_WIDTH-1:0]tmp = (`ROB_SIZE_WIDTH'b1<<`ROB_SIZE_WIDTH)-1;
    assign rob_full = (((tail + 1-head)&tmp) == 0) && busy[head];
    
    // predictor
    assign clear = busy[head] && prepared[head] && insts_type[head] == `B_TYPE && values[head][0] != 1;
    wire head_is_i = (insts[head][1:0]==2'b11);
    wire [31:0] pc_plus_head = head_is_i ? 32'h4 : 32'h2; 
    assign back_pc = clear ? insts_addr[head] + pc_plus_head : 0;
    assign head_rob_id = head;
    
    wire init_prepared = (instr_type == `LUI || instr_type == `AUIPC || instr_type == `JAL || instr_type == `JALR);
    // assign rob_full = (head == tail && busy[head]);
    assign rd_rob_id = tail;

    always @(posedge clk) begin
        if(rst || (clear && rdy)) begin
            head <= 0;
            tail <= 0;
            for(i = 0; i < `ROB_SIZE; i = i + 1) begin
                busy[i] <= 0;
                prepared[i] <= 0;
                rds[i] <= 0;
                values[i] <= 0;
                ops[i] <= 0;
                insts[i] <= 0;
                insts_type[i] <= 0;
                insts_addr[i] <= 0;
            end
        end
        else if(!rdy) begin
            // do nothing
        end
        else begin
            // issue: 接受从Decoder传来的指令
            if(issue_signal) begin
                tail <= tail + 1;
                busy[tail] <= 1;
                prepared[tail] <= init_prepared;
                rds[tail] <= rd;
                insts[tail] <= instr;
                ops[tail] <= op;
                insts_type[tail] <= instr_type;
                insts_addr[tail] <= instr_addr;
                values[tail] <= gen_decoder_value(instr_type, imm, instr_addr, instr);

                // case (instr_type)
                //     `LUI: values[tail] <= imm;
                //     `AUIPC: values[tail] <= instr_addr + imm;
                //     `JAL: values[tail] <= instr_addr + pc_plus_tail;
                //     default: values[tail] <= 0;
                // endcase
            end
            // receive: 听RS、LSB的广播
            if(rs_ready) begin
                prepared[rs_rob_id] <= 1;
                values[rs_rob_id] <= rs_value;
            end
            if(lsb_ready) begin
                prepared[lsb_rob_id] <= 1;
                values[lsb_rob_id] <= lsb_value;
            end
            // commit: 向RS、LSB广播
            if(busy[head] && prepared[head]) begin
                head <= head + 1;
                busy[head] <= 0;
                prepared[head] <= 0;
                rds[head] <= 0;
                values[head] <= 0;
                ops[head] <= 0;
                insts[head] <= 0;
                insts_type[head] <= 0;
                insts_addr[head] <= 0;
            end
        end
    end

    // to reg: issue and commit
    // 这里一定要实时更新，不然会出现数据丢失
    wire head_change_reg, update_head;
    assign head_change_reg = !(insts_type[head] == `B_TYPE || insts_type[head] == `S_TYPE); // 表示RoB是否对reg进行了修改
    assign update_head = rdy && head_change_reg && busy[head] && prepared[head];
    assign commit_rob_id = update_head ? head : 0;
    assign commit_rd = update_head ? rds[head] : 0;
    assign commit_value = update_head ? values[head] : 0;

    wire tail_change_reg, update_tail;
    assign tail_change_reg = !(instr_type == `B_TYPE || instr_type == `S_TYPE); // 表示RoB是否对reg进行了修改
    assign update_tail = rdy && tail_change_reg && issue_signal;
    assign issue_rob_id = update_tail ? tail : 0;
    assign issue_rd = update_tail ? rd : 0;

    // get reg value: instant connection
    wire rs_value_ready1 = rs_ready && rs_rob_id == get_rob_id1;
    wire lsb_value_ready1 = lsb_ready && lsb_rob_id == get_rob_id1;
    wire rs_value_ready2 = rs_ready && rs_rob_id == get_rob_id2;
    wire lsb_value_ready2 = lsb_ready && lsb_rob_id == get_rob_id2;
    wire ready_type = (instr_type == `LUI || instr_type == `AUIPC || instr_type == `JAL || instr_type == `JALR);
    wire decoder_value_ready = issue_signal && ready_type;
    wire [31:0] decoder_value = gen_decoder_value(instr_type, imm, instr_addr, instr);
    assign get_ready1 = prepared[get_rob_id1] || rs_value_ready1 || lsb_value_ready1 || (issue_signal && decoder_value_ready && get_rob_id1 == tail);
    assign get_ready2 = prepared[get_rob_id2] || rs_value_ready2 || lsb_value_ready2 || (issue_signal && decoder_value_ready && get_rob_id2 == tail);
    assign get_value1 = prepared[get_rob_id1] ? values[get_rob_id1] : rs_value_ready1 ? rs_value : lsb_value_ready1 ? lsb_value : decoder_value;
    assign get_value2 = prepared[get_rob_id2] ? values[get_rob_id2] : rs_value_ready2 ? rs_value : lsb_value_ready2 ? lsb_value : decoder_value;

    function [31:0] gen_decoder_value;
        input [6:0] _instr_type_in;
        input [31:0] _imm_in;
        input [31:0] _instr_addr_in;
        input [31:0] _instr;
        begin
            case (_instr_type_in)
                `LUI: gen_decoder_value = _imm_in;
                `AUIPC: gen_decoder_value = _imm_in + _instr_addr_in;
                `JAL, `JALR: gen_decoder_value = (_instr[1:0]==2'b11) ? _instr_addr_in + 4 : _instr_addr_in + 2;
                default: gen_decoder_value = 32'h0;
            endcase
        end
    endfunction
    
    // debug
    wire debug_rob_busy0 = busy[0];
    wire debug_rob_busy1 = busy[1];
    wire debug_rob_prepared0 = prepared[0];
    wire debug_rob_prepared1 = prepared[1];
    wire[4:0] debug_rob_rds0 = rds[0];
    wire[4:0] debug_rob_rds1 = rds[1];
    wire[31:0] debug_rob_values0 = values[0];
    wire[31:0] debug_rob_values1 = values[1];
    wire[2:0] debug_rob_ops0 = ops[0];
    wire[2:0] debug_rob_ops1 = ops[1];
    wire[31:0] debug_rob_insts0 = insts[0];
    wire[31:0] debug_rob_insts1 = insts[1];
    wire[6:0] debug_rob_insts_type0 = insts_type[0];
    wire[6:0] debug_rob_insts_type1 = insts_type[1];
    wire[31:0] debug_rob_insts_addr0 = insts_addr[0];
    wire[31:0] debug_rob_insts_addr1 = insts_addr[1];

endmodule