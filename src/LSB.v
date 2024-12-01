`include "config.v"
// `include "/home/hqs123/class_code/CPU/src/config.v"
module LSB (
    input wire clk,
    input wire rst,
    input wire rdy,

    // to decoder
    output wire lsb_full,

    // from Decoder
    input wire instr_issued,
    input wire [31 : 0] instr_in,
    input wire [31 : 0] instr_addr_in,
    input wire [2 : 0] op_in,
    input wire [6 : 0] instr_type_in,
    input wire [31 : 0] imm_in,
    input wire [31 : 0] reg_value1_in,
    input wire [31 : 0] reg_value2_in,
    input wire has_dep1_in,
    input wire has_dep2_in,
    input wire [`ROB_SIZE_WIDTH - 1 : 0] v_rob_id1_in,
    input wire [`ROB_SIZE_WIDTH - 1 : 0] v_rob_id2_in,
    input wire [`ROB_SIZE_WIDTH - 1 : 0] rd_rob_id_in,

    // from RS
    input wire rs_ready,
    input wire [`ROB_SIZE_WIDTH - 1 : 0] rs_rob_id,
    input wire [31 : 0] rs_value,

    // from RoB
    input wire rob_clear,
    input wire [`ROB_SIZE_WIDTH - 1 : 0] head_rob_id,

    // to RoB and RS: data from cache
    output wire lsb_ready,
    output wire [`ROB_SIZE_WIDTH - 1 : 0] lsb_rob_id,
    output wire [31 : 0] lsb_value,

    // from cache
    input wire welcome_lsb,
    input wire cache_ready,
    input wire [6:0] cache_instr_type,
    input wire [31:0] cache_data_out,

    // to cache
    output reg in_lsb_ready,
    output reg [2:0] op_out,
    output reg [6:0] instr_type_out,
    output reg [31:0] data_addr_out,
    output reg [31:0] data_out

);

    reg [`ROB_SIZE_WIDTH - 1 : 0] head, tail;
    reg cache_exe;
    reg [`ROB_SIZE_WIDTH - 1 : 0] cache_exe_rob_id;

    reg busy [0 : `RS_SIZE - 1];
    reg [31 : 0] instr [0 : `RS_SIZE - 1];
    reg [31 : 0] instr_addr [0 : `RS_SIZE - 1];
    reg [2 : 0] op [0 : `RS_SIZE - 1];
    reg [6 : 0] instr_type [0 : `RS_SIZE - 1];
    reg [31 : 0] imm [0 : `RS_SIZE - 1];
    reg [31 : 0] reg_value1 [0 : `RS_SIZE - 1];
    reg [31 : 0] reg_value2 [0 : `RS_SIZE - 1];
    reg has_dep1 [0 : `RS_SIZE - 1];
    reg has_dep2 [0 : `RS_SIZE - 1];
    reg [`ROB_SIZE_WIDTH - 1 : 0] v_rob_id1 [0 : `RS_SIZE - 1];
    reg [`ROB_SIZE_WIDTH - 1 : 0] v_rob_id2 [0 : `RS_SIZE - 1];
    reg [`ROB_SIZE_WIDTH - 1 : 0] rd_rob_id [0 : `RS_SIZE - 1];

    assign lsb_full = (head == tail && busy[head]);

    assign lsb_ready = cache_ready;
    assign lsb_rob_id = cache_exe_rob_id;
    assign lsb_value = instr_type_out == `LD_TYPE ? cache_data_out : 0;

    // 判断这条指令是否进入LSB
    wire judge_instr, accept_instr;
    assign judge_instr = (instr_type_in == `LD_TYPE || instr_type_in == `S_TYPE);
    assign accept_instr = instr_issued && !lsb_full && judge_instr;
    
    integer i;
    always @(posedge clk) begin
        if(rst || rob_clear) begin
            head <= 0;
            tail <= 0;
            cache_exe <= 0;
            cache_exe_rob_id <= 0;
            in_lsb_ready <= 0;
            op_out <= 3'b0;
            instr_type_out <= 7'b0;
            data_addr_out <= 32'b0;
            data_out <= 32'b0;
            for(i = 0; i < `RS_SIZE; i = i + 1) begin
                busy[i] <= 1'b0;
                instr[i] <= 32'b0;
                instr_addr[i] <= 32'b0;
                op[i] <= 3'b0;
                instr_type[i] <= 7'b0;
                imm[i] <= 32'b0;
                reg_value1[i] <= 32'b0;
                reg_value2[i] <= 32'b0;
                has_dep1[i] <= 1'b0;
                has_dep2[i] <= 1'b0;
                v_rob_id1[i] <= {`ROB_SIZE_WIDTH{1'b0}};
                v_rob_id2[i] <= {`ROB_SIZE_WIDTH{1'b0}};
                rd_rob_id[i] <= {`ROB_SIZE_WIDTH{1'b0}};
            end
        end
        else if (head_rob_id != head) begin
            // do nothing
        end
        else if (!rdy) begin
            // do nothing
        end
        else begin

            // update
            if(cache_exe && cache_ready) begin
                cache_exe <= 0;
                cache_exe_rob_id <= 0;
            end

            // add instr
            if (accept_instr) begin
                tail <= tail + 1;
                cache_exe <= 0;
                cache_exe_rob_id <= 0;
                busy[tail] <= 1;
                instr[tail] <= instr_in;
                instr_addr[tail] <= instr_addr_in;
                op[tail] <= op_in;
                instr_type[tail] <= instr_type_in;
                imm[tail] <= imm_in;
                reg_value1[tail] <= reg_value1_in;
                reg_value2[tail] <= reg_value2_in;
                has_dep1[tail] <= has_dep1_in;
                has_dep2[tail] <= has_dep2_in;
                v_rob_id1[tail] <= v_rob_id1_in;
                v_rob_id2[tail] <= v_rob_id2_in;
                rd_rob_id[tail] <= rd_rob_id_in;
            end

            // listen broadcast
            for(i = 0; i < `RS_SIZE; i = i + 1) begin
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

            // send to cache
            if(welcome_lsb && busy[head] && !has_dep1[head] && !has_dep2[head]) begin
                if(instr_type[rd_rob_id[head]] == `LD_TYPE || head_rob_id == rd_rob_id[head]) begin
                    head <= head + 1;
                    cache_exe <= 1;
                    cache_exe_rob_id <= rd_rob_id[head];
                    in_lsb_ready <= 1;
                    op_out <= op[head];
                    instr_type_out <= instr_type[head];
                    data_addr_out <= reg_value1[head] + imm[head];
                    data_out <= reg_value2[head];
                end
            end

        end
    end

endmodule