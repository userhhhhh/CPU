`include "config.v"
// `include "/home/hqs123/class_code/CPU/src/config.v"

module ALU(
    input wire clk,
    input wire rst,
    input wire rdy,

    input wire rob_clear,
    input wire [`ROB_SIZE_WIDTH - 1 : 0] rob_id_in,
    input wire valid,
    input wire [2:0] op,
    input wire [6:0] instr_type_in,
    input wire op_other,
    input wire [31:0] v1,
    input wire [31:0] v2,

    output reg [`ROB_SIZE_WIDTH - 1 : 0] rob_id_out,
    output reg [31:0] result,
    output reg ready
);

    always @(posedge clk) begin
        if (rst || rob_clear) begin
            rob_id_out <= 0;
            result <= 0;
            ready <= 0;
        end else if (!rdy) begin
            // do nothing
        end else begin
            if(instr_type_in != 7'b0010011 && instr_type_in != 7'b0110011) begin
                case(op)
                    3'b000: result <= v1 == v2; // beq
                    3'b001: result <= v1 != v2; // bne
                    3'b100: result <= $signed(v1) < $signed(v2); // blt
                    3'b101: result <= $signed(v1) >= $signed(v2); // bge
                    3'b110: result <= $unsigned(v1) < $unsigned(v2); // bltu
                    3'b111: result <= $unsigned(v1) >= $unsigned(v2); // bgeu
                endcase
            end
            else begin
                case(op)
                    3'b000: result <= (op_other) ? (v1 - v2) : (v1 + v2); // add or sub
                    3'b001: result <= v1 << v2[4:0]; // sll
                    3'b010: result <= ($signed(v1) < $signed(v2)) ? 1 : 0; // slt
                    3'b011: result <= ($unsigned(v1) < $unsigned(v2)) ? 1 : 0; // sltu
                    3'b100: result <= v1 ^ v2; // xor
                    3'b101: result <= (op_other) ? ($signed(v1) >>> v2[4:0]) : (v1 >> v2[4:0]); // srl or sra
                    3'b110: result <= v1 | v2; // or
                    3'b111: result <= v1 & v2; // and
                endcase
            end
            ready <= valid;
            rob_id_out <= rob_id_in;
        end
    end

endmodule