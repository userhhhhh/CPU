// RISCV32 CPU top module
// port modification allowed for debugging purposes


module cpu(
  input  wire                 clk_in,			// system clock signal
  input  wire                 rst_in,			// reset signal
	input  wire					        rdy_in,			// ready signal, pause cpu when low

  input  wire [ 7:0]          mem_din,		// data input bus
  output wire [ 7:0]          mem_dout,		// data output bus
  output wire [31:0]          mem_a,			// address bus (only 17:0 is used)
  output wire                 mem_wr,			// write/read signal (1 for write)
	
	input  wire                 io_buffer_full, // 1 if uart buffer is full
	
	output wire [31:0]			dbgreg_dout		// cpu register output (debugging demo)
);

// implementation goes here

// Specifications:
// - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
// - Memory read result will be returned in the next cycle. Write takes 1 cycle(no need to wait)
// - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
// - I/O port is mapped to address higher than 0x30000 (mem_a[17:16]==2'b11)
// - 0x30000 read: read a byte from input
// - 0x30000 write: write a byte to output (write 0x00 is ignored)
// - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
// - 0x30004 write: indicates program stop (will output '\0' through uart tx)

  // clear
  wire rob_clear;
  wire [31:0] back_pc;

  Reg reg_instance (
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),
    .commit_rob_id(), 
    .commit_rd(), 
    .commit_value(), 
    .issue_rob_id(), 
    .issue_rd(), 
    .ask_rob_id1(), 
    .ask_rob_id2(), 
    .get_value1(), 
    .get_value2(), 
    .get_ready1(), 
    .get_ready2(), 
    .get_reg_value1(), 
    .get_reg_value2(), 
    .reg_value1(), 
    .reg_value2(), 
    .reg_has_dep1(), 
    .reg_has_dep2(), 
    .reg_dep_rob_id1(), 
    .reg_dep_rob_id2() 
  );

  RoB rob_instance (
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),
    .instr_valid(), 
    .instr_ready(), 
    .instr(), 
    .instr_type(), 
    .instr_addr(), 
    .rd(), 
    .rs1(), 
    .imm(), 
    .rs_ready(), 
    .rs_rob_id(), 
    .rs_value(), 
    .lsb_ready(), 
    .lsb_rob_id(), 
    .lsb_value(), 
    .commit_rob_id(), 
    .commit_rd(), 
    .commit_value(), 
    .issue_rob_id(), 
    .issue_rd(), 
    .get_rob_id1(), 
    .get_rob_id2(), 
    .get_value1(), 
    .get_value2(), 
    .get_ready1(), 
    .get_ready2(), 
    .issue_rd(), 
    .issue_rob_id(), 
    .next_pc(), 
    .pc_frozen(), 
    .clear() 
  );

  LSB lsb_instance (
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),
    .rob_clear(), 
    .head_rob_id(), 
    .lsb_ready(), 
    .lsb_rob_id(), 
    .lsb_value(), 
    .tail_rob_id(), 
    .tail_rd(), 
    .tail_value() 
  );

  RS rs_instance (
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),
    .instr_issued(), 
    .instr_in(), 
    .instr_addr_in(), 
    .instr_type_in(), 
    .reg_value1_in(), 
    .reg_value2_in(), 
    .has_dep1_in(), 
    .has_dep2_in(), 
    .v_rob_id1_in(), 
    .v_rob_id2_in(), 
    .rd_rob_id_in(), 
    .lsb_ready(), 
    .lsb_rob_id(), 
    .lsb_value(), 
    .rob_clear(), 
    .rs_ready(), 
    .rs_rob_id(), 
    .rs_value(), 
    .alu_rob_id() 
  );

  Decoder decoder_instance (
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),
    .instr_valid(), 
    .instr_ready(), 
    .instr(), 
    .instr_type(), 
    .instr_addr(), 
    .rd(), 
    .rs1(), 
    .imm(), 
    .instr_issued(), 
    .instr_in(), 
    .instr_addr_in(), 
    .instr_type_in(), 
    .reg_value1_in(), 
    .reg_value2_in(), 
    .has_dep1_in(), 
    .has_dep2_in(), 
    .v_rob_id1_in(), 
    .v_rob_id2_in(), 
    .rd_rob_id_in(), 
    .rs_ready(), 
    .rs_rob_id(), 
    .rs_value(), 
    .lsb_ready(), 
    .lsb_rob_id(), 
    .lsb_value(), 
    .rob_clear(), 
    .commit_rob_id(), 
    .commit_rd(), 
    .commit_value(), 
    .issue_rob_id(), 
    .issue_rd(), 
    .get_rob_id1(), 
    .get_rob_id2(), 
    .get_value1(), 
    .get_value2(), 
    .get_ready1(), 
    .get_ready2(), 
    .issue_rd(), 
    .issue_rob_id(), 
    .next_pc(), 
    .pc_frozen(), 
    .clear() 
  );

  Fetcher fetcher_instance (
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),
    .pc(), 
    .pc_frozen(), 
    .next_pc(), 
    .instr_valid(), 
    .instr_ready(), 
    .instr(), 
    .instr_type(), 
    .instr_addr() 
  );

  cache cache_instance (
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),
    .mem_din(), 
    .mem_dout(), 
    .mem_a(), 
    .mem_wr() 
  );

always @(posedge clk_in)
  begin
    if (rst_in)
      begin
      
      end
    else if (!rdy_in)
      begin
      
      end
    else
      begin
      
      end
  end

endmodule