`include "config.v"
module LSB (
    input wire clk,
    input wire rst,
    input wire rdy,

    // from Decoder
    input wire instr_issued,
    input wire [31 : 0] instr_in,
    input wire [31 : 0] instr_addr_in,
    input wire [6 : 0] instr_type_in,
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
    input wire head_rob_id,

    // to RoB and RS: data from cache
    output wire lsb_ready,
    output wire [`ROB_SIZE_WIDTH - 1 : 0] lsb_rob_id,
    output wire [31 : 0] lsb_value,

    // to cache
    output wire [`ROB_SIZE_WIDTH - 1 : 0] cache_rob_id
);

    reg [`ROB_SIZE_WIDTH - 1 : 0] head, tail;


    reg busy [0 : `RS_SIZE - 1];
    reg [31 : 0] instr [0 : `RS_SIZE - 1];
    reg [31 : 0] instr_addr [0 : `RS_SIZE - 1];
    reg [6 : 0] instr_type [0 : `RS_SIZE - 1];
    reg [31 : 0] reg_value1 [0 : `RS_SIZE - 1];
    reg [31 : 0] reg_value2 [0 : `RS_SIZE - 1];
    reg has_dep1 [0 : `RS_SIZE - 1];
    reg has_dep2 [0 : `RS_SIZE - 1];
    reg [`ROB_SIZE_WIDTH - 1 : 0] v_rob_id1 [0 : `RS_SIZE - 1];
    reg [`ROB_SIZE_WIDTH - 1 : 0] v_rob_id2 [0 : `RS_SIZE - 1];
    reg [`ROB_SIZE_WIDTH - 1 : 0] rd_rob_id [0 : `RS_SIZE - 1];

    always @(posedge clk) begin
        if(rst || rob_clear) begin
            // TODO
        end
        else if (!rdy) begin
            // do nothing
        end
        else begin
            // add instr
            if (instr_issued) begin
                tail <= tail + 1;
                busy[tail] <= 1;
                instr[tail] <= instr_in;
                instr_addr[tail] <= instr_addr_in;
                instr_type[tail] <= instr_type_in;
                reg_value1[tail] <= reg_value1_in;
                reg_value2[tail] <= reg_value2_in;
                has_dep1[tail] <= has_dep1_in;
                has_dep2[tail] <= has_dep2_in;
                v_rob_id1[tail] <= v_rob_id1_in;
                v_rob_id2[tail] <= v_rob_id2_in;
                rd_rob_id[tail] <= rd_rob_id_in;
            end
            // listen broadcast
            integer i;
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
            
        end
    end


endmodule