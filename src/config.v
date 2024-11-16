
`define ROB_SIZE_WIDTH 5
`define ROB_SIZE (1<<`ROB_SIZE_WIDTH) 

`define LUI 7'b0110111
`define AUIPC 7'b0010111
`define JAL 7'b1101111
`define JALR 7'b1100111

`define B_TYPE 7'b1100011
`define LD_TYPE 7'b0000011
`define S_TYPE 7'b0100011
`define I_TYPE 7'b0010011
`define R_TYPE 7'b0110011
