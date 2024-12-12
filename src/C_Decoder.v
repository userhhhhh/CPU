`include "config.v"

module C_Decoder(
    input wire clk,
    input wire rst,
    input wire rdy,

    // judge full
    input wire rob_full,
    input wire rs_full,
    input wire lsb_full,

    // from Fetcher
    input wire instr_ready,
    input wire [31 : 0] instr_in,
    input wire [31 : 0] instr_addr_in,

    // to fetcher
    output reg [31 : 0] predict_pc,

    // to RS and LSB and RoB
    output reg instr_issued,// and to fetcher
    output wire updating_instr_issued,

    output reg [31 : 0] instr_out,
    output reg [31 : 0] instr_addr_out,
    output reg [2 : 0] op_out,
    output reg [6 : 0] instr_type_out,
    output reg [31 : 0] reg_value1_out,
    output reg [31 : 0] reg_value2_out,
    output reg has_dep1_out,
    output reg has_dep2_out,
    output reg [`ROB_SIZE_WIDTH - 1 : 0] v_rob_id1_out,
    output reg [`ROB_SIZE_WIDTH - 1 : 0] v_rob_id2_out,
    output wire [`ROB_SIZE_WIDTH - 1 : 0] rd_rob_id_out, //这行指令对应的rob_id

    // to RoB and LSB
    output reg [31 : 0] imm,
    // to RoB
    output reg [4 : 0] rd,

    // to Reg
    output wire [4 : 0] reg_id1,
    output wire [4 : 0] reg_id2,

    // from Reg
    input wire [31 : 0] reg_value1_in,
    input wire [31 : 0] reg_value2_in,
    input wire has_dep1_in,
    input wire has_dep2_in,
    input wire [`ROB_SIZE_WIDTH - 1 : 0] v_rob_id1_in,
    input wire [`ROB_SIZE_WIDTH - 1 : 0] v_rob_id2_in, 

    // from RoB
    input wire [`ROB_SIZE_WIDTH - 1 : 0] rd_rob_id_in

);
    
    wire [6:0] d_instr_type_in;
    assign d_instr_type_in = gen_instr_type(instr_in);
    wire jalr_not_ready = d_instr_type_in == `JALR && has_dep1_in;
    
    // 用来表示这个信息现在能不能发送
    wire need_work;
    assign need_work = instr_ready && !rob_full && !rs_full && !lsb_full && !jalr_not_ready;
    assign updating_instr_issued = need_work;

    wire has_rs2;
    assign has_rs2 = !(d_instr_type_in == `LUI || d_instr_type_in == `AUIPC || d_instr_type_in == `JAL || d_instr_type_in == `JALR || d_instr_type_in == `LD_TYPE || d_instr_type_in == `I_TYPE);
    
    assign reg_id1 = gen_reg_id1(instr_in);
    assign reg_id2 = gen_reg_id2(instr_in);

    assign rd_rob_id_out = rd_rob_id_in;

    wire [31:0] get_imm = gen_imm(instr_in);
    wire get_op_other = gen_op_other(instr_in);
    
    // predictor
    function [31:0] gen_c_new_pc;
        input [31:0] _c_pc;
        input [6:0] _c_instr_type;
        input [31:0] _c_reg_value1_in;
        input [31:0] _c_imm;
        case (_c_instr_type)
            `JAL: gen_c_new_pc = _c_pc + _c_imm;
            `JALR: gen_c_new_pc = _c_reg_value1_in + _c_imm;
            `B_TYPE: gen_c_new_pc = _c_pc + _c_imm;
            default: gen_c_new_pc = _c_pc + 2;
        endcase
    endfunction
    wire [31:0] new_pc = gen_c_new_pc(instr_addr_in, d_instr_type_in, reg_value1_in, get_imm);

    localparam Add= 3'b000,Sub = 3'b000, Sll = 3'b001, Slt = 3'b010, Sltu = 3'b011, Xor = 3'b100, Srl= 3'b101,Sra = 3'b101, Or = 3'b110, And = 3'b111;
    localparam Beq = 3'b000, Bne = 3'b001, Blt = 3'b100, Bge = 3'b101, Bltu = 3'b110, Bgeu = 3'b111;
    localparam Lb = 3'b000, Lh = 3'b001, Lw = 3'b010, Lbu = 3'b100, Lhu = 3'b101;
    localparam Sb = 3'b000, Sh = 3'b001, Sw = 3'b010;

    always @(posedge clk) begin
        if (rst) begin
            predict_pc <= 0;
            instr_issued <= 0;
            instr_out <= 0;
            instr_addr_out <= 0;
            op_out <= 0;
            instr_type_out <= 0;
            reg_value1_out <= 0;
            reg_value2_out <= 0;
            has_dep1_out <= 0;
            has_dep2_out <= 0;
            v_rob_id1_out <= 0;
            v_rob_id2_out <= 0;
            // rd_rob_id_out <= 0;
            imm <= 0;
            rd <= 0;
        end
        else if(!rdy) begin
            // do nothing
        end
        else if (!need_work) begin
            instr_issued <= need_work;
        end
        else begin
            case (instr_in[1:0])
                2'b00: case (instr_in[15:13])
                    3'b000: begin
                        instr_type_out <= `I_TYPE;
                        op_out <= Add;
                        rd <= 8 + instr_in[4:2];
                        imm <= {22'b0,instr_in[10:7],instr_in[12:11],instr_in[5],instr_in[6],2'b0};
                    end
                    3'b010: begin
                        instr_type_out <= `LD_TYPE;
                        op_out <= Lw;
                        rd <= 8 + instr_in[4:2];
                        imm <= {25'b0,instr_in[5],instr_in[12:10],instr_in[6],2'b0};
                    end
                    3'b110: begin
                        instr_type_out <= `S_TYPE;
                        op_out <= Sw;
                        rd <= 0;
                        imm <= {25'b0,instr_in[5],instr_in[12:10],instr_in[6],2'b0};
                    end
                endcase
                2'b01: begin
                    case (instr_in[15:13])
                        3'b000: begin
                            instr_type_out <= `I_TYPE;
                            op_out <= Add;
                            rd <= instr_in[11:7];
                            imm <= {{27{instr_in[12]}},instr_in[6:2]};
                        end
                        3'b001: begin
                            instr_type_out <= `JAL;
                            op_out <= 0;
                            rd <= 1;
                            imm <= {{21{instr_in[12]}},instr_in[8],instr_in[10:9],instr_in[6],instr_in[7],instr_in[2],instr_in[11],instr_in[5:3],1'b0};
                        end
                        3'b010: begin
                            instr_type_out <= `I_TYPE;
                            op_out <= Add;
                            rd <= instr_in[11:7];
                            imm <= {{27{instr_in[12]}},instr_in[6:2]};
                        end
                        3'b011: begin
                            instr_type_out <= (instr_in[11:7] == 2) ? `I_TYPE : `LUI;
                            op_out <= (instr_in[11:7] == 2) ? Add : 0;
                            rd <= instr_in[11:7];
                            if (instr_in[11:7] == 2) imm <= {{23{instr_in[12]}},instr_in[4:3],instr_in[5],instr_in[2],instr_in[6],4'b0};
                            else imm <= {{15{instr_in[12]}},instr_in[6:2],12'b0};
                        end
                        3'b100: begin
                            instr_type_out <= (instr_in[11:10] == 2'b11) ? `R_TYPE : `I_TYPE;
                            rd <= 8 + instr_in[9:7];
                            case (instr_in[11:10])
                                2'b00: begin
                                    op_out <= Srl;
                                    imm <= {26'b0,instr_in[12],instr_in[6:2]};
                                end
                                2'b01:begin
                                    op_out <= Sra;
                                    imm <= {26'b0,instr_in[12],instr_in[6:2]};
                                end
                                2'b10:begin
                                    op_out <= And;
                                    imm <= {{27{instr_in[12]}},instr_in[6:2]};
                                end
                                2'b11:begin
                                    case (instr_in[6:5])
                                        2'b00: op_out <= Sub;
                                        2'b01: op_out <= Xor;
                                        2'b10: op_out <= Or;
                                        2'b11: op_out <= And;
                                    endcase
                                    imm <= 0;
                                end
                            endcase
                        end
                        3'b101: begin
                            instr_type_out <= `JAL;
                            op_out <= 0;
                            rd <= 0;
                            imm <= {{21{instr_in[12]}},instr_in[8],instr_in[10:9],instr_in[6],instr_in[7],instr_in[2],instr_in[11],instr_in[5:3],1'b0};
                        end
                        3'b110: begin
                            instr_type_out <= `B_TYPE;
                            op_out <= Beq;
                            rd <= 0;
                            imm <= {{24{instr_in[12]}},instr_in[6:5],instr_in[2],instr_in[11:10],instr_in[4:3],1'b0};
                        end
                        3'b111: begin
                            instr_type_out <= `B_TYPE;
                            op_out <= Bne;
                            rd <= 0;
                            imm <= {{24{instr_in[12]}},instr_in[6:5],instr_in[2],instr_in[11:10],instr_in[4:3],1'b0};
                        end
                    endcase
                end
                2'b10: begin
                    case (instr_in[15:13])
                        3'b000: begin
                            instr_type_out <= `I_TYPE;
                            op_out <= Sll;
                            rd <= instr_in[11:7];
                            imm <= {26'b0,instr_in[12],instr_in[6:2]};
                        end
                        3'b010: begin
                            instr_type_out <= `LD_TYPE;
                            op_out <= Lw;
                            rd <= instr_in[11:7];
                            imm <= {24'b0,instr_in[3:2],instr_in[12],instr_in[6:4],2'b0};
                        end
                        3'b100: begin
                            instr_type_out <= (instr_in[6:2] == 5'b00000) ? `JALR : `R_TYPE;
                            op_out <= (instr_in[6:2] == 5'b00000) ? 0 : Add;
                            imm <= 0;
                            case(instr_in[12])
                                1'b0: rd <= (instr_in[6:2] == 5'b00000) ? 0 : instr_in[11:7];
                                1'b1: rd <= (instr_in[6:2] == 5'b00000) ? 1 : instr_in[11:7];
                            endcase
                        end
                        3'b110: begin
                            instr_type_out <= `S_TYPE;
                            op_out <= Sw;
                            rd <= 0;
                            imm <= {24'b0,instr_in[8:7],instr_in[12:9],2'b0};
                        end
                    endcase
                end
            endcase
            predict_pc <= new_pc;
            instr_issued <= need_work;
            instr_out <= {1'b0,get_op_other,14'b0,instr_in[15:0]};
            instr_addr_out <= instr_addr_in;
            reg_value1_out <= reg_value1_in;
            reg_value2_out <= has_rs2 ? reg_value2_in : get_imm;
            has_dep1_out <= has_dep1_in;
            has_dep2_out <= has_rs2 ? has_dep2_in : 0;
            v_rob_id1_out <= v_rob_id1_in;
            v_rob_id2_out <= has_rs2 ? v_rob_id2_in : 0;
            // rd_rob_id_out <= rd_rob_id_in;
        end
    end
    
    function [4:0]gen_reg_id1;
        input [31:0] inst;
        case (inst[1:0])
            2'b00: gen_reg_id1 = (inst[15:13] == 3'b000) ? 2 : 8+inst[9:7];
            2'b01: begin
                case (inst[15:13])
                    3'b000: gen_reg_id1 = inst[11:7];
                    3'b001: gen_reg_id1 = 0;
                    3'b010: gen_reg_id1 = 0;
                    3'b011: gen_reg_id1 = (inst[11:7] == 2) ? 2 :0;
                    3'b100,3'b110,3'b111: gen_reg_id1 = 8+inst[9:7];
                    3'b101: gen_reg_id1 = 0;
                endcase
            end
            2'b10: begin
                case (inst[15:13])
                    3'b000: gen_reg_id1 = inst[11:7];
                    3'b010: gen_reg_id1 = 2;
                    3'b100: case (inst[12])
                        1'b0: gen_reg_id1 = (inst[6:2] == 5'b00000) ? inst[11:7] : 0;
                        1'b1:gen_reg_id1 = inst[11:7];
                    endcase
                    3'b110: gen_reg_id1 = 2;
                endcase
            end
        endcase
    endfunction

    function [4:0]gen_reg_id2;
        input [31:0] inst;
        case (inst[1:0])
            2'b00: gen_reg_id2 = (inst[15:13] == 3'b110) ? 8+inst[4:2] : 0;
            2'b01: gen_reg_id2 = (inst[15:13]==3'b100 && inst[11:10]==2'b11) ? 8+inst[4:2] : 0;
            2'b10: gen_reg_id2 = (inst[15:13] == 3'b100 || inst[15:13] == 3'b110) ? inst[6:2] : 0;
        endcase
    endfunction
    
    function [6:0]gen_instr_type;
        input [31:0] inst;
        case (inst[1:0])
            2'b00: case (inst[15:13])
                3'b000: gen_instr_type = `I_TYPE;
                3'b010: gen_instr_type = `LD_TYPE;
                3'b110: gen_instr_type = `S_TYPE;
            endcase
            2'b01: begin
                case (inst[15:13])
                    3'b000: gen_instr_type = `I_TYPE;
                    3'b001: gen_instr_type = `JAL;
                    3'b010: gen_instr_type = `I_TYPE;
                    3'b011: gen_instr_type = (inst[11:7] == 2) ? `I_TYPE : `LUI;
                    3'b100: gen_instr_type = (inst[11:10] == 2'b11) ? `R_TYPE : `I_TYPE; 
                    3'b101: gen_instr_type = `JAL;
                    3'b110: gen_instr_type = `B_TYPE;
                    3'b111: gen_instr_type = `B_TYPE;
                endcase
            end
            2'b10: begin
                case (inst[15:13])
                    3'b000: gen_instr_type = `I_TYPE;
                    3'b010: gen_instr_type = `LD_TYPE;
                    3'b100: gen_instr_type = (inst[6:2] == 5'b00000) ? `JALR : `R_TYPE;
                    3'b110: gen_instr_type = `S_TYPE;
                endcase
            end
        endcase
    endfunction

    function [31:0]gen_imm;
        input [31:0] inst;
        case (inst[1:0])
            2'b00: case (inst[15:13])
                3'b000: gen_imm = {22'b0,inst[10:7],inst[12:11],inst[5],inst[6],2'b0};
                default: gen_imm = {25'b0,inst[5],inst[12:10],inst[6],2'b0};
            endcase
            2'b01: begin
                case (inst[15:13])
                    3'b000,3'b010: gen_imm = {{27{inst[12]}},inst[6:2]};
                    3'b001,3'b101: gen_imm = {{21{inst[12]}},inst[8],inst[10:9],inst[6],inst[7],inst[2],inst[11],inst[5:3],1'b0};
                    3'b011: gen_imm = (inst[11:7] == 2) ? {{23{inst[12]}},inst[4:3],inst[5],inst[2],inst[6],4'b0} : {{15{inst[12]}},inst[6:2],12'b0};
                    3'b100: case (inst[11:10])
                        2'b00,2'b01:gen_imm = {26'b0,inst[12],inst[6:2]};
                        2'b10:gen_imm = {{27{inst[12]}},inst[6:2]};
                        2'b11:gen_imm = 0;
                    endcase
                    3'b110,3'b111: gen_imm = {{24{inst[12]}},inst[6:5],inst[2],inst[11:10],inst[4:3],1'b0};
                endcase
            end
            2'b10: begin
                case (inst[15:13])
                    3'b000: gen_imm = {26'b0,inst[12],inst[6:2]};
                    3'b010: gen_imm = {24'b0,inst[3:2],inst[12],inst[6:4],2'b0};
                    3'b100: gen_imm = 0;
                    3'b110: gen_imm = {24'b0,inst[8:7],inst[12:9],2'b0};
                endcase
            end
        endcase
    endfunction

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
    
endmodule