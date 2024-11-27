`include "config.v"
// `include "/home/hqs123/class_code/CPU/src/config.v"
module RoB (
    input wire clk,
    input wire rst,
    input wire rdy,

    // from Decoder
    input wire instr_valid,
    input wire instr_ready,
    input wire [31 : 0] instr,
    input wire [2 : 0] op,
    input wire [6 : 0] instr_type,
    input wire [31 : 0] instr_addr,
    input wire [4 : 0] rd,
    input wire [4 : 0] rs1,
    input wire [31 : 0] imm,

    // from RS
    input wire rs_ready,
    input wire [`ROB_SIZE_WIDTH - 1 : 0] rs_rob_id,
    input wire [31 : 0] rs_value,

    // from LSB
    input wire lsb_ready,
    input wire [`ROB_SIZE_WIDTH - 1 : 0] lsb_rob_id,
    input wire [31 : 0] lsb_value,

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

    // the pc
    output reg [31 : 0] next_pc,
    output reg pc_frozen,

    // the predictor
    output reg clear

);

    // TODO: predictor

    // 循环队列
    reg [`ROB_SIZE_WIDTH - 1 : 0] head, tail;

    // 记录每个指令的状态
    reg busy [0 : `ROB_SIZE - 1]; // 是否已经有指令了
    reg ready [0 : `ROB_SIZE - 1]; // 是否已经等到值了

    reg [4:0] rds [0 : `ROB_SIZE - 1]; // 存放指令原来的rd
    reg [31:0] values [0 : `ROB_SIZE - 1]; // 存放已经算好的值
    reg [2:0] ops [0 : `ROB_SIZE - 1];
    reg [31:0] insts [0 : `ROB_SIZE - 1];
    reg [6:0] insts_type [0 : `ROB_SIZE - 1];
    reg [31:0] insts_addr [0 : `ROB_SIZE - 1];

    integer i;

    // clear: 清空RoB
    always @(posedge clk) begin
        if(rst || (clear && rdy)) begin
            head <= 0;
            tail <= 0;
            for(i = 0; i < `ROB_SIZE; i = i + 1) begin
                busy[i] <= 0;
                ready[i] <= 0;
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
            // do nothing
        end
    end

    // issue: 接受从Decoder传来的指令
    always @(posedge clk) begin
        if(rst || (clear && rdy) || !rdy) begin
             // do nothing
        end 
        else begin
            if(instr_valid) begin
                tail <= tail + 1;

                busy[tail] <= 1;
                ready[tail] <= instr_ready;
                rds[tail] <= rd;

                insts[tail] <= instr;
                ops[tail] <= op;
                insts_type[tail] <= instr_type;
                insts_addr[tail] <= instr_addr;

                case (instr_type)
                    `LUI: values[tail] <= imm;
                    `AUIPC: values[tail] <= instr_addr + imm;
                    `JAL: values[tail] <= instr_addr + 4;
                    default: values[tail] <= 0;
                endcase
            end
        end
    end

    // receive: 听RS、LSB的广播
    always @(posedge clk) begin
        if(rst|| (clear && rdy) || !rdy) begin
             // do nothing
        end 
        else begin
            if(rs_ready) begin
                ready[rs_rob_id] <= 1;
                values[rs_rob_id] <= rs_value;
            end
            if(lsb_ready) begin
                ready[lsb_rob_id] <= 1;
                values[lsb_rob_id] <= lsb_value;
            end
        end
    end

    // commit: 向RS、LSB广播
    always @(posedge clk) begin
        if(rst|| (clear && rdy) || !rdy) begin
             // do nothing
        end 
        else begin
            if(busy[head] && ready[head]) begin
                head <= head + 1;
                busy[head] <= 0;
                ready[head] <= 0;
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
    assign update_head = rdy && head_change_reg && busy[head] && ready[head];
    assign commit_rob_id = update_head ? head : 0;
    assign commit_rd = update_head ? rds[head] : 0;
    assign commit_value = update_head ? values[head] : 0;

    wire tail_change_reg, update_tail;
    assign tail_change_reg = !(instr_type == `B_TYPE || instr_type == `S_TYPE); // 表示RoB是否对reg进行了修改
    assign update_tail = rdy && tail_change_reg;// TODO: instr_valid
    assign issue_rob_id = update_tail ? tail : 0;
    assign issue_rd = update_tail ? rd : 0;

    // get reg value: instant connection
    wire rs_value_ready1 = rs_ready && rs_rob_id == get_rob_id1;
    wire lsb_value_ready1 = lsb_ready && lsb_rob_id == get_rob_id1;
    wire rs_value_ready2 = rs_ready && rs_rob_id == get_rob_id2;
    wire lsb_value_ready2 = lsb_ready && lsb_rob_id == get_rob_id2;
    wire decoder_value_ready1 = instr_ready && tail == get_rob_id1;
    wire decoder_value_ready2 = instr_ready && tail == get_rob_id2;
    assign get_ready1 = rs_value_ready1 || lsb_value_ready1 || decoder_value_ready1;
    assign get_ready2 = rs_value_ready2 || lsb_value_ready2 || decoder_value_ready2;
    assign get_value1 = rs_value_ready1 ? rs_value : (lsb_value_ready1 ? lsb_value : (decoder_value_ready1 ? values[tail] : 0));
    assign get_value2 = rs_value_ready2 ? rs_value : (lsb_value_ready2 ? lsb_value : (decoder_value_ready2 ? values[tail] : 0));

endmodule