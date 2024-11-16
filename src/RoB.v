`include "config.v"
module RoB (
    input wire clk,
    input wire rst,
    input wire rdy,

    // from Decoder
    input wire instr_valid,
    input wire instr_ready,
    input wire [31 : 0] instr,
    input wire [6 : 0] instr_type,
    input wire [31 : 0] instr_addr,
    input wire [4 : 0] rd,
    input wire [4 : 0] rs1,


    input wire [31 : 0] imm,

    // from RS
    input wire rs_ready,
    input wire [`ROB_SIZE_WIDTH - 1 : 0] rs_rob_id,
    input wire [31 : 0] rs_value,

    // from ALU
    input wire alu_ready,
    input wire [`ROB_SIZE_WIDTH - 1 : 0] alu_rob_id,
    input wire [31 : 0] alu_value,

    // from LSB
    input wire lsb_ready,
    input wire [`ROB_SIZE_WIDTH - 1 : 0] lsb_rob_id,
    input wire [31 : 0] lsb_value,

    // to RS

    // issue
    output wire [4:0] issue_rd, // instr result的rd
    output wire [31 : 0] issue_rob_id, // instr的rob_id

    // the pc
    output reg [31 : 0] next_pc,
    output reg pc_frozen,

    // the predictor
    output reg clear

);

    localparam UNKNOWN = 3'b000;
    localparam ISSUE = 3'b001;
    localparam WRITE = 3'b010;
    localparam COMMIT = 3'b011;
    localparam TODELETECDB = 3'b100;

    // 循环队列
    reg [`ROB_SIZE_WIDTH - 1 : 0] head, tail;

    // 记录每个指令的状态
    reg busy [0 : `ROB_SIZE - 1];
    reg ready [0 : `ROB_SIZE - 1];

    reg [2:0] state [0 : `ROB_SIZE - 1];
    reg [4:0] rds [0 : `ROB_SIZE - 1];
    reg [31:0] values [0 : `ROB_SIZE - 1];
    reg [31:0] insts [0 : `ROB_SIZE - 1];
    reg [6:0] insts_type [0 : `ROB_SIZE - 1];
    reg [31:0] insts_addr [0 : `ROB_SIZE - 1];

    always @(posedge clk) begin
        if (rst) begin
            // TODO
        end 
        else if (rdy) begin
            if(rs_ready) begin
                ready[rs_rob_id] <= 1;
                values[rs_rob_id] <= rs_value;
            end
            if(alu_ready) begin
                ready[alu_rob_id] <= 1;
                values[alu_rob_id] <= alu_value;
            end
            if(lsb_ready) begin
                ready[lsb_rob_id] <= 1;
                values[lsb_rob_id] <= lsb_value;
            end
            if(instr_valid) begin
                tail <= tail + 1;
                busy[tail] <= 1;
                ready[tail] <= instr_ready;

                if(instr_type == `LUI || instr_type == `JAL) begin
                    state[tail] <= WRITE;
                end else begin
                    state[tail] <= ISSUE;
                end
                
                rds[tail] <= rd;

                insts[tail] <= instr;
                insts_type[tail] <= instr_type;
                insts_addr[tail] <= instr_addr;

                case (instr_type)
                    `LUI: begin
                        values[tail] <= imm;
                    end
                    `AUIPC: begin
                        state[tail] <= ISSUE;
                    end
                    `JAL: begin
                        state[tail] <= ISSUE;
                    end
                    `JALR: begin
                        state[tail] <= ISSUE;
                    end
                    `B_TYPE: begin
                        pc_frozen <= 1;
                        next_pc <= instr_addr + 4;
                    end
                    `LD_TYPE: begin
                        state[tail] <= ISSUE;
                    end
                    `S_TYPE: begin
                        state[tail] <= ISSUE;
                    end
                    `I_TYPE: begin
                        state[tail] <= ISSUE;
                    end
                    `R_TYPE: begin
                        state[tail] <= ISSUE;
                    end
                    default: begin
                        state[tail] <= TODELETECDB;
                    end
                endcase
            end
        end
    end

endmodule