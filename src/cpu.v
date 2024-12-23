// RISCV32 CPU top module
// port modification allowed for debugging purposes

`include "config.v"

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

  // judge i or c
  wire is_i;
  wire fetcher_idecoder_instr_ready = fetcher_decoder_instr_ready && is_i;
  wire fetcher_cdecoder_instr_ready = fetcher_decoder_instr_ready && !is_i;

  // clear
  wire rob_clear;
  wire [31:0] back_pc;

  // full
  wire rob_full;
  wire rs_full;
  wire lsb_full;

  // Reg and RoB: RoB change Reg
  wire [`ROB_SIZE_WIDTH - 1 : 0] commit_rob_id;
  wire [4 : 0] commit_rd;
  wire [31 : 0] commit_value;
  wire [`ROB_SIZE_WIDTH - 1 : 0] issue_rob_id;
  wire [4 : 0] issue_rd;
  
  // Reg and RoB: Reg ask RoB
  wire [`ROB_SIZE_WIDTH - 1 : 0] ask_rob_id1;
  wire [`ROB_SIZE_WIDTH - 1 : 0] ask_rob_id2;
  
  // Reg and RoB: RoB ans Reg
  wire [31 : 0] get_value1;
  wire [31 : 0] get_value2;
  wire get_ready1;
  wire get_ready2;
  
  // Reg and decoder： Decoder ask Reg
  wire [4 : 0] get_reg_value1;
  wire [4 : 0] get_reg_value2;

  wire [4 : 0] iget_reg_value1;
  wire [4 : 0] iget_reg_value2;
  wire [4 : 0] cget_reg_value1;
  wire [4 : 0] cget_reg_value2;
  assign get_reg_value1 = is_i ? iget_reg_value1 : cget_reg_value1;
  assign get_reg_value2 = is_i ? iget_reg_value2 : cget_reg_value2;

  // Reg and decoder: Reg ans decoder
  wire [31 : 0] reg_decoder_value1;
  wire [31 : 0] reg_decoder_value2;
  wire reg_has_dep1;
  wire reg_has_dep2;
  wire [`ROB_SIZE_WIDTH - 1 : 0] reg_dep_rob_id1;
  wire [`ROB_SIZE_WIDTH - 1 : 0] reg_dep_rob_id2;

  Reg reg_instance (
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),

    // from RoB
    .commit_rob_id(commit_rob_id),
    .commit_rd(commit_rd),
    .commit_value(commit_value),
    .issue_rob_id(issue_rob_id),
    .issue_rd(issue_rd),

    // get reg value: instant connection
    .ask_rob_id1(ask_rob_id1),
    .ask_rob_id2(ask_rob_id2),
    .get_value1(get_value1),
    .get_value2(get_value2),
    .get_ready1(get_ready1),
    .get_ready2(get_ready2),

    // from Decoder
    .get_reg_value1(get_reg_value1),
    .get_reg_value2(get_reg_value2),

    // to Decoder
    .reg_value1(reg_decoder_value1),
    .reg_value2(reg_decoder_value2),
    .reg_has_dep1(reg_has_dep1),
    .reg_has_dep2(reg_has_dep2),
    .reg_dep_rob_id1(reg_dep_rob_id1),
    .reg_dep_rob_id2(reg_dep_rob_id2)
  );

  // cache and fetcher: fetcher to cache
  wire fetcher_to_cache_ready;
  wire [31 : 0] pc;

  // cache and fetcher: cache ans fetcher
  wire cache_to_fetcher_ready;
  wire [31 : 0] cache_fetcher_instr;
  wire [31 : 0] cache_fetcher_instr_addr;

  // cache and LSB: LSB to cache
  wire lsb_to_cache_ready;
  wire [2:0] lsb_cache_op;
  wire [6:0] lsb_cache_instr_type;
  wire [31:0] lsb_cache_data_addr;
  wire [31:0] lsb_cache_data; // st
  // cache and LSB: cache to LSB
  wire welcome_lsb;
  wire cache_lsb_ready;
  wire [6:0] cache_lsb_instr_type;
  wire [31:0] cache_lsb_data; // ld

  cache cache_instance (
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),

    // from RoB
    .rob_clear(rob_clear),

    // from Memory
    .mem_din(mem_din),
    .mem_dout(mem_dout),
    .mem_a(mem_a),
    .mem_wr(mem_wr),
    .io_buffer_full(io_buffer_full),

    // from fetcher
    .in_fetcher_ready(fetcher_to_cache_ready),
    .instr_addr(pc),
    // to fetcher
    .out_fetcher_ready(cache_to_fetcher_ready),
    .instr_out(cache_fetcher_instr),
    .instr_addr_out(cache_fetcher_instr_addr),

    // from LSB
    .in_lsb_ready(lsb_to_cache_ready),
    .op_in(lsb_cache_op),
    .instr_type_in(lsb_cache_instr_type),
    .data_addr_in(lsb_cache_data_addr),
    .data_in(lsb_cache_data),
    // to LSB
    .welcome_lsb(welcome_lsb),
    .out_lsb_ready(cache_lsb_ready),
    .instr_type_out(cache_lsb_instr_type),
    .data_out(cache_lsb_data)
  );

  // decoder and fetcher: decoder to fetcher
  wire decoder_fetcher_instr_issued;
  wire [31 : 0] decoder_fetcher_new_pc;

  wire idecoder_fetcher_instr_issued;
  wire cdecoder_fetcher_instr_issued;
  wire [31 : 0] idecoder_fetcher_new_pc;
  wire [31 : 0] cdecoder_fetcher_new_pc;
  assign decoder_fetcher_instr_issued = is_i ? idecoder_fetcher_instr_issued : cdecoder_fetcher_instr_issued;
  assign decoder_fetcher_new_pc = is_i ? idecoder_fetcher_new_pc : cdecoder_fetcher_new_pc;

  // decoder and fetcher: fetcher to decoder
  wire fetcher_decoder_instr_ready;
  wire [31 : 0] fetcher_decoder_instr;
  wire [31 : 0] fetcher_decoder_instr_addr;
  
  wire updating_decoder_fetcher_instr_issued;
  wire iupdating_decoder_fetcher_instr_issued;
  wire cupdating_decoder_fetcher_instr_issued;
  assign updating_decoder_fetcher_instr_issued = is_i ? iupdating_decoder_fetcher_instr_issued : cupdating_decoder_fetcher_instr_issued;

  Fetcher fetcher_instance (
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),
    
    // from RoB: clear
    .rob_clear(rob_clear),
    .back_pc(back_pc),

    // to cache
    .start_fetch(fetcher_to_cache_ready),
    .pc(pc),
    // from cache
    .instr_ready_in(cache_to_fetcher_ready),
    .instr_in(cache_fetcher_instr),
    .instr_addr_in(cache_fetcher_instr_addr),

    // from Decoder
    .updating_instr_issued(updating_decoder_fetcher_instr_issued),
    .instr_issued(decoder_fetcher_instr_issued),
    .predictor_pc(decoder_fetcher_new_pc),
    // to Decoder
    .is_i(is_i),
    .instr_ready(fetcher_decoder_instr_ready),
    .instr(fetcher_decoder_instr),
    .instr_addr(fetcher_decoder_instr_addr)
  );

  // decoder to RS and LSB and RoB
  wire [31 : 0] decoder_instr;
  wire [31 : 0] decoder_instr_addr;
  wire [2 : 0] decoder_op;
  wire [6 : 0] decoder_instr_type;
  wire [31 : 0] decoder_reg_value1;
  wire [31 : 0] decoder_reg_value2;
  wire decoder_has_dep1;
  wire decoder_has_dep2;
  wire [`ROB_SIZE_WIDTH - 1 : 0] decoder_v_rob_id1;
  wire [`ROB_SIZE_WIDTH - 1 : 0] decoder_v_rob_id2;
  wire [`ROB_SIZE_WIDTH - 1 : 0] decoder_rd_rob_id;
  wire [31 : 0] decoder_imm;

  wire [31 : 0] idecoder_instr;
  wire [31 : 0] idecoder_instr_addr;
  wire [2 : 0] idecoder_op;
  wire [6 : 0] idecoder_instr_type;
  wire [31 : 0] idecoder_reg_value1;
  wire [31 : 0] idecoder_reg_value2;
  wire idecoder_has_dep1;
  wire idecoder_has_dep2;
  wire [`ROB_SIZE_WIDTH - 1 : 0] idecoder_v_rob_id1;
  wire [`ROB_SIZE_WIDTH - 1 : 0] idecoder_v_rob_id2;
  wire [`ROB_SIZE_WIDTH - 1 : 0] idecoder_rd_rob_id;
  wire [31 : 0] idecoder_imm;
  wire [31 : 0] cdecoder_instr;
  wire [31 : 0] cdecoder_instr_addr;
  wire [2 : 0] cdecoder_op;
  wire [6 : 0] cdecoder_instr_type;
  wire [31 : 0] cdecoder_reg_value1;
  wire [31 : 0] cdecoder_reg_value2;
  wire cdecoder_has_dep1;
  wire cdecoder_has_dep2;
  wire [`ROB_SIZE_WIDTH - 1 : 0] cdecoder_v_rob_id1;
  wire [`ROB_SIZE_WIDTH - 1 : 0] cdecoder_v_rob_id2;
  wire [`ROB_SIZE_WIDTH - 1 : 0] cdecoder_rd_rob_id;
  wire [31 : 0] cdecoder_imm;
  assign decoder_instr = is_i ? idecoder_instr : cdecoder_instr;
  assign decoder_instr_addr = is_i ? idecoder_instr_addr : cdecoder_instr_addr;
  assign decoder_op = is_i ? idecoder_op : cdecoder_op;
  assign decoder_instr_type = is_i ? idecoder_instr_type : cdecoder_instr_type;
  assign decoder_reg_value1 = is_i ? idecoder_reg_value1 : cdecoder_reg_value1;
  assign decoder_reg_value2 = is_i ? idecoder_reg_value2 : cdecoder_reg_value2;
  assign decoder_has_dep1 = is_i ? idecoder_has_dep1 : cdecoder_has_dep1;
  assign decoder_has_dep2 = is_i ? idecoder_has_dep2 : cdecoder_has_dep2;
  assign decoder_v_rob_id1 = is_i ? idecoder_v_rob_id1 : cdecoder_v_rob_id1;
  assign decoder_v_rob_id2 = is_i ? idecoder_v_rob_id2 : cdecoder_v_rob_id2;
  assign decoder_rd_rob_id = is_i ? idecoder_rd_rob_id : cdecoder_rd_rob_id;
  assign decoder_imm = is_i ? idecoder_imm : cdecoder_imm;

  // decoder and RoB: decoder to RoB rd
  wire [4 : 0] actual_rd;
  // decoder and RoB：rd_rob_id
  wire [`ROB_SIZE_WIDTH - 1 : 0] rob_decoder_rd_rob_id;

  wire [4 : 0] iactual_rd;
  wire [4 : 0] cactual_rd;
  assign actual_rd = is_i ? iactual_rd : cactual_rd;

  Decoder decoder_instance (
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),

    // judge full
    .rob_full(rob_full),
    .rs_full(rs_full),
    .lsb_full(lsb_full),

    // from Fetcher
    .instr_ready(fetcher_idecoder_instr_ready),
    .instr_in(fetcher_decoder_instr),
    .instr_addr_in(fetcher_decoder_instr_addr),

    // to fetcher
    .predict_pc(idecoder_fetcher_new_pc),

    // to RS and LSB and RoB
    .instr_issued(idecoder_fetcher_instr_issued),
    .updating_instr_issued(iupdating_decoder_fetcher_instr_issued),

    .instr_out(idecoder_instr),
    .instr_addr_out(idecoder_instr_addr),
    .op_out(idecoder_op),
    .instr_type_out(idecoder_instr_type),
    .reg_value1_out(idecoder_reg_value1),
    .reg_value2_out(idecoder_reg_value2),
    .has_dep1_out(idecoder_has_dep1),
    .has_dep2_out(idecoder_has_dep2),
    .v_rob_id1_out(idecoder_v_rob_id1),
    .v_rob_id2_out(idecoder_v_rob_id2),
    .rd_rob_id_out(idecoder_rd_rob_id),

    // to RoB and LSB
    .imm(idecoder_imm),
    // to RoB
    .rd(iactual_rd),

    // to Reg
    .reg_id1(iget_reg_value1),
    .reg_id2(iget_reg_value2),

    // from Reg
    .reg_value1_in(reg_decoder_value1),
    .reg_value2_in(reg_decoder_value2),
    .has_dep1_in(reg_has_dep1),
    .has_dep2_in(reg_has_dep2),
    .v_rob_id1_in(reg_dep_rob_id1),
    .v_rob_id2_in(reg_dep_rob_id2),

    // from RoB
    .rd_rob_id_in(rob_decoder_rd_rob_id)
  );

  C_Decoder c_decoder_instance (
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),

    // judge full
    .rob_full(rob_full),
    .rs_full(rs_full),
    .lsb_full(lsb_full),

    // from Fetcher
    .instr_ready(fetcher_cdecoder_instr_ready),
    .instr_in(fetcher_decoder_instr),
    .instr_addr_in(fetcher_decoder_instr_addr),

    // to fetcher
    .predict_pc(cdecoder_fetcher_new_pc),

    // to RS and LSB and RoB
    .instr_issued(cdecoder_fetcher_instr_issued),
    .updating_instr_issued(cupdating_decoder_fetcher_instr_issued),

    .instr_out(cdecoder_instr),
    .instr_addr_out(cdecoder_instr_addr),
    .op_out(cdecoder_op),
    .instr_type_out(cdecoder_instr_type),
    .reg_value1_out(cdecoder_reg_value1),
    .reg_value2_out(cdecoder_reg_value2),
    .has_dep1_out(cdecoder_has_dep1),
    .has_dep2_out(cdecoder_has_dep2),
    .v_rob_id1_out(cdecoder_v_rob_id1),
    .v_rob_id2_out(cdecoder_v_rob_id2),
    .rd_rob_id_out(cdecoder_rd_rob_id),

    // to RoB and LSB
    .imm(cdecoder_imm),
    // to RoB
    .rd(cactual_rd),

    // to Reg
    .reg_id1(cget_reg_value1),
    .reg_id2(cget_reg_value2),

    // from Reg
    .reg_value1_in(reg_decoder_value1),
    .reg_value2_in(reg_decoder_value2),
    .has_dep1_in(reg_has_dep1),
    .has_dep2_in(reg_has_dep2),
    .v_rob_id1_in(reg_dep_rob_id1),
    .v_rob_id2_in(reg_dep_rob_id2),

    // from RoB
    .rd_rob_id_in(rob_decoder_rd_rob_id)
  );

  // RS and RoB
  wire rs_rob_ready;
  wire [`ROB_SIZE_WIDTH - 1 : 0] rs_rob_rob_id;
  wire [31 : 0] rs_rob_value;

  // LSB and RoB
  wire lsb_rob_ready;
  wire [`ROB_SIZE_WIDTH - 1 : 0] lsb_rob_rob_id;
  wire [31 : 0] lsb_rob_value;

  wire [`ROB_SIZE_WIDTH - 1 : 0] head_rob_id;

  RoB rob_instance (
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),

    // to decoder
    .rob_full(rob_full),
    .rd_rob_id(rob_decoder_rd_rob_id),

    // from Decoder
    .issue_signal(decoder_fetcher_instr_issued),
    .instr(decoder_instr),
    .op(decoder_op),
    .instr_type(decoder_instr_type),
    .instr_addr(decoder_instr_addr),
    .rd(actual_rd),
    .imm(decoder_imm),

    // from RS
    .rs_ready(rs_rob_ready),
    .rs_rob_id(rs_rob_rob_id),
    .rs_value(rs_rob_value),

    // from LSB
    .lsb_ready(lsb_rob_ready),
    .lsb_rob_id(lsb_rob_rob_id),
    .lsb_value(lsb_rob_value),

    .head_rob_id(head_rob_id),

    // to Reg: issue and commit
    .commit_rob_id(commit_rob_id),
    .commit_rd(commit_rd),
    .commit_value(commit_value),
    .issue_rob_id(issue_rob_id),
    .issue_rd(issue_rd),

    // get reg value: instant connection
    .get_rob_id1(ask_rob_id1),
    .get_rob_id2(ask_rob_id2),
    .get_value1(get_value1),
    .get_value2(get_value2),
    .get_ready1(get_ready1),
    .get_ready2(get_ready2),

    // the predictor
    .clear(rob_clear),
    .back_pc(back_pc)
  );

  LSB lsb_instance (
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),

    // to decoder
    .lsb_full(lsb_full),

    // from Decoder
    .instr_issued(decoder_fetcher_instr_issued),
    .instr_in(decoder_instr),
    .instr_addr_in(decoder_instr_addr),
    .op_in(decoder_op),
    .instr_type_in(decoder_instr_type),
    .imm_in(decoder_imm),
    .reg_value1_in(decoder_reg_value1),
    .reg_value2_in(decoder_reg_value2),
    .has_dep1_in(decoder_has_dep1),
    .has_dep2_in(decoder_has_dep2),
    .v_rob_id1_in(decoder_v_rob_id1),
    .v_rob_id2_in(decoder_v_rob_id2),
    .rd_rob_id_in(decoder_rd_rob_id),

    // from RS
    .rs_ready(rs_rob_ready),
    .rs_rob_id(rs_rob_rob_id),
    .rs_value(rs_rob_value),

    // from RoB
    .rob_clear(rob_clear),
    .head_rob_id(head_rob_id),

    // to RoB and RS: data from cache
    .lsb_ready(lsb_rob_ready),
    .lsb_rob_id(lsb_rob_rob_id),
    .lsb_value(lsb_rob_value),

    // from cache
    .welcome_lsb(welcome_lsb),
    .cache_ready(cache_lsb_ready),
    .cache_instr_type(cache_lsb_instr_type),
    .cache_data_out(cache_lsb_data),

    // to cache
    .in_lsb_ready(lsb_to_cache_ready),
    .op_out(lsb_cache_op),
    .instr_type_out(lsb_cache_instr_type),
    .data_addr_out(lsb_cache_data_addr),
    .data_out(lsb_cache_data)
  );

  RS rs_instance (
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),

    // to Decoder
    .rs_full(rs_full),

    // from Decoder
    .instr_issued(decoder_fetcher_instr_issued),
    .instr_in(decoder_instr),
    .instr_addr_in(decoder_instr_addr),
    .op_in(decoder_op),
    .instr_type_in(decoder_instr_type),
    .reg_value1_in(decoder_reg_value1),
    .reg_value2_in(decoder_reg_value2),
    .has_dep1_in(decoder_has_dep1),
    .has_dep2_in(decoder_has_dep2),
    .v_rob_id1_in(decoder_v_rob_id1),
    .v_rob_id2_in(decoder_v_rob_id2),
    .rd_rob_id_in(decoder_rd_rob_id),

    // from LSB
    .lsb_ready(lsb_rob_ready),
    .lsb_rob_id(lsb_rob_rob_id),
    .lsb_value(lsb_rob_value),

    // from RoB: clear
    .rob_clear(rob_clear),

    // to RoB and LSB: data from ALU
    .rs_ready(rs_rob_ready),
    .rs_rob_id(rs_rob_rob_id),
    .rs_value(rs_rob_value)
  );

  // always @(posedge clk_in) begin
  //       if ((mem_wr == 1 && mem_a <= 598) || mem_a > 131072) begin
  //           $fatal(1,"fuck_you");
  //       end
  //   end

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