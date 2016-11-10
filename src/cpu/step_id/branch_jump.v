/*-----------------------------------------------------
 File Name : branch_jump.v
 Purpose : ex jump/branch instructor in advance
 Creation Date : 20-10-2016
 Last Modified : Wed Nov  9 16:43:32 2016
 Created By : Jeasine Ma [jeasinema[at]gmail[dot]com]
-----------------------------------------------------*/
`ifndef __BRANCH_JUMP_V__
`define __BRANCH_JUMP_V__

`timescale 1ns/1ns

`include "../defs.v"

module branch_jump(/*autoarg*/
    //Inputs
    clk, rst_n, pc_addr, inst_code, inst, 
    reg_s_value, reg_t_value, 

    //Outputs
    do_branch, branch_addr, return_addr
);

    input wire clk;
    input wire rst_n;
    
    // get from pc.v, used for calculate return/branch address
    input wire[31:0] pc_addr;
    // parallel with id.v and ex.v, so directly get inst_code instead of inst
    input wire[31:0] inst_code;
    input wire[7:0] inst;
    // get operands from mux, reg_addr was generated by id.v
    input wire[31:0] reg_s_value;
    input wire[31:0] reg_t_value;
    
    // used by pc.v
    output reg do_branch;
    output reg[31:0] branch_addr;
    // used by ex.v, store it in specific reg
    output reg[31:0] return_addr;

    wire sign_bit;
    // pc_address of the branch delay slot inst 
    wire[31:0] current_pc_addr;
    // need to do sign_extension and left_shift to offset
    wire[31:0] sign_addr_offset_ext;

    // most significant bit of offset
    assign sign_bit = inst_code[15]; 
    assign current_pc_addr = pc_addr + 32'd4;
    assign sign_addr_offset_ext = {
        sign_bit, sign_bit, sign_bit, sign_bit, 
        sign_bit, sign_bit, sign_bit, sign_bit,
        sign_bit, sign_bit, sign_bit, sign_bit,
        sign_bit, sign_bit, inst_code[15:0], 2'b00
    };

    always @(*)
    begin
        do_branch <= 1'b0;
        branch_addr <= 32'b0;
        return_addr <= pc_addr + 32'd8;
        //case (inst)
        //`INST_BEQ: 
        //begin
        //    if (reg_s_value == reg_t_value) 
        //    begin
        //        branch_addr <= current_pc_addr + sign_addr_offset_ext;
        //        do_branch <= 1'b1;
        //    end
        //end
        //`INST_BEQZ:
        //begin
        //    if (reg_s_value == 32'b0) 
        //    begin
        //        branch_addr <= current_pc_addr + sign_addr_offset_ext;
        //        do_branch <= 1'b1;
        //    end
        //end
        //`INST_BNE:
        //begin
        //    if (reg_s_value != reg_t_value) 
        //    begin
        //        branch_addr <= current_pc_addr + sign_addr_offset_ext;
        //        do_branch <= 1'b1;
        //    end
        //end
        //`INST_BNEZ:
        //begin
        //    if (reg_s_value != 32'b0) 
        //    begin
        //        branch_addr <= current_pc_addr + sign_addr_offset_ext;
        //        do_branch <= 1'b1;
        //    end
        //end
        //`INST_BGTZ:  // >0 then branch
        //begin
        //    if (!reg_s_value[31] && reg_s_value != 32'b0) 
        //    begin
        //        branch_addr <= current_pc_addr + sign_addr_offset_ext;
        //        do_branch <= 1'b1;
        //    end
        //end
        //`INST_BGEZ,  // >= 0 then branch
        //`INST_BGEZAL:
        //begin
        //    if (!reg_s_value[31]) 
        //    begin
        //        branch_addr <= current_pc_addr + sign_addr_offset_ext;
        //        do_branch <= 1'b1;
        //    end
        //end
        //`INST_BLTZ, // <0 then branch
        //`INST_BLTZAL:
        //begin
        //    if (reg_s_value[31]) 
        //    begin
        //        branch_addr <= current_pc_addr + sign_addr_offset_ext;
        //        do_branch <= 1'b1;
        //    end
        //end
        //`INST_BLEZ:  // <=0 then branch
        //begin
        //if (reg_s_value[31] || reg_s_value == 32'b0) 
        //    begin
        //        branch_addr <= current_pc_addr + sign_addr_offset_ext;
        //        do_branch <= 1'b1;
        //    end
        //end
        //`INST_J,
        //`INST_JAL:
        //begin
        //    branch_addr <= {current_pc_addr[31:28], inst_code[25:0], 2'b00};
        //    do_branch <= 1'b1;
        //end
        //`INST_JR,
        //`INST_JALR:
        //begin
        //    branch_addr <= reg_s_value ;
        //    do_branch <= 1'b1;
        //end
        //default:
        //begin
        //    branch_addr <= 32'b0;
        //    do_branch <= 1'b0;
        //    return_addr <= pc_addr + 32'd8;
        //end
        //endcase 
        case(inst_code[31:26])
        6'h0: begin
            case(inst_code[5:0])
            6'h8, 6'h9: begin //JR, JALR
                branch_addr <= reg_s_value;
                do_branch <= 1'b1;
            end
            endcase
        end
        6'h1: begin //REGIMM
            case(inst_code[20:16])
            5'h0, 5'h10: begin //BLTZ, BLTZAL
                if(reg_s_value[31]) begin
                    branch_addr <= current_pc_addr + sign_addr_offset_ext;
                    do_branch <= 1'b1;
                end
            end
            5'h1, 5'h11: begin //BGEZ, BGEZAL
                if(!reg_s_value[31]) begin
                    branch_addr <= current_pc_addr + sign_addr_offset_ext;
                    do_branch <= 1'b1;
                end
            end
            endcase
        end
        6'h2, 6'h3: begin //J, JAL
            branch_addr <= {current_pc_addr[31:28], inst_code[25:0], 2'b00};
            do_branch <= 1'b1;
        end
        6'h4: begin //BEQ
            if(reg_s_value == reg_t_value) begin
                branch_addr <= current_pc_addr + sign_addr_offset_ext;
                do_branch <= 1'b1;
            end
        end
        6'h5: begin //BNE
            if(reg_s_value != reg_t_value) begin
                branch_addr <= current_pc_addr + sign_addr_offset_ext;
                do_branch <= 1'b1;
            end
        end
        6'h6: begin //BLEZ
            if(reg_s_value[31] || reg_s_value==32'b0) begin
                branch_addr <= current_pc_addr + sign_addr_offset_ext;
                do_branch <= 1'b1;
            end
        end
        6'h7: begin //BGTZ
            if(!reg_s_value[31] && reg_s_value!=32'b0) begin
                branch_addr <= current_pc_addr + sign_addr_offset_ext;
                do_branch <= 1'b1;
            end
        end
        endcase
    end

endmodule

`endif
