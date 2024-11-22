module Decoder(
    input wire clk,
    input wire rst,
    input wire rdy,

    // from Fetcher
    input wire instr_valid,
    input wire instr_ready,
    input wire [31 : 0] instr_in,
    input wire [31 : 0] instr_addr_in,

    // to RS and LSB
    output wire instr_issued,
    output wire [31 : 0] instr_out,
    output wire [31 : 0] instr_addr_out,
    output wire [6 : 0] instr_type_out,
    output wire [31 : 0] reg_value1_out,
    output wire [31 : 0] reg_value2_out,
    output wire has_dep1_out,
    output wire has_dep2_out,
    output wire [`ROB_SIZE_WIDTH - 1 : 0] v_rob_id1_out,
    output wire [`ROB_SIZE_WIDTH - 1 : 0] v_rob_id2_out,
    output wire [`ROB_SIZE_WIDTH - 1 : 0] rd_rob_id_out,

    // to RoB
    output wire [31 : 0] imm,

    // to Reg
    output wire [4 : 0] reg_id1,
    output wire [4 : 0] reg_id2

    // from Reg
    input wire [31 : 0] reg_value1_in,
    input wire [31 : 0] reg_value2_in,
    input wire has_dep1_in,
    input wire has_dep2_in,
    input wire [`ROB_SIZE_WIDTH - 1 : 0] v_rob_id1_in,
    input wire [`ROB_SIZE_WIDTH - 1 : 0] v_rob_id2_in,

);

    assign instr_out = instr_in;
    assign instr_addr_out = instr_addr_in;
    assign instr_type_out = instr_in[6:0];
    assign reg_id1 = inst[19:15];
    assign reg_id2 = inst[24:20];

    generate
        case (instr_type_out)
            `LUI, `AUIPC: begin
                assign imm = {inst[31:12], 12'b0};
            end
            `JAL: begin
                assign imm = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};
            end
            `JALR: begin
                // TODO
            end
            `B_TYPE: begin
                assign imm = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
            end
            `LD_TYPE: begin
                assign imm = {{20{inst[31]}}, inst[31:20]};
            end
            `S_TYPE: begin
                assign imm = {{20{inst[31]}}, inst[31:25], inst[11:7]};
            end
            `I_TYPE: begin
                assign imm = {{20{inst[31]}}, inst[31:20]};// TODO
            end
            `R_TYPE: begin
                assign imm = 0;
            end
            default: begin
                assign imm = 0;
            end
        endcase
    endgenerate
    
    // TODO
    wire has_rs2 = (instr_type_out == `R_TYPE || instr_type_out == `S_TYPE || instr_type_out == `B_TYPE);
    assign reg_value1_out = reg_value1_in;
    assign reg_value2_out = reg_value2_in;
    assign has_dep1_out = has_dep1_in;
    assign has_dep2_out = has_dep2_in;
    assign v_rob_id1_out = v_rob_id1_in;
    assign v_rob_id2_out = v_rob_id2_in;

endmodule