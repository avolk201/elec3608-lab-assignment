/*
 *  NERV -- Naive Educational RISC-V Processor
 *
 *  Copyright (C) 2020  Claire Xenia Wolf <claire@yosyshq.com>
 *
 *  Permission to use, copy, modify, and/or distribute this software for any
 *  purpose with or without fee is hereby granted, provided that the above
 *  copyright notice and this permission notice appear in all copies.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 *  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 *  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 *  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 *  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 *  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 *  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 */

 `include "constants.svh"
 `default_nettype none
	// CSR numbers per Privileged ISA sec 2.2.4 table 7
	localparam CSR_MSTATUS	= 12'h 300;
	localparam CSR_MIE  	= 12'h 304;
	localparam CSR_MTVEC 	= 12'h 305;
	localparam CSR_MSCRATCH = 12'h 340;
	localparam CSR_MEPC		= 12'h 341;
	localparam CSR_MCAUSE 	= 12'h 342;
	localparam CSR_MIP		= 12'h 344;

module nerv #(
	parameter [31:0] RESET_ADDR = 32'h 0000_0000,
	parameter integer NUMREGS = 32,
	parameter integer MTVEC_ADDR = 32'h 0000_1000 // Interrupt/trap vector address
) (
	input clock,
	input reset,
	output trap,
	input intr,	// interrupt request

	// we have 2 external memories
	// one is instruction memory
	output [31:0] imem_addr,
	input  [31:0] imem_data,

	// the other is data memory
	output        dmem_valid,
	output [31:0] dmem_addr,
	output [ 3:0] dmem_wstrb,
	output [31:0] dmem_wdata,
	input  [31:0] dmem_rdata

);
	// your processor goes here

	logic [31:0] dmem [0:1023];
    logic dmem_wr_enable;
    logic [31:0] dmem_wr_addr;
    logic [31:0] dmem_wr_data;
                          
    logic [31:0] dmem_rd_addr;
    logic [31:0] dmem_rd_data;


 // instruction memory pointer
    assign imem_addr = reset ? RESET_ADDR : npc;
    assign  insn = imem_data;

 // Debugging
    logic   [4:0] d_rd;
    logic   [31:0] d_x0;
    logic   [31:0] d_x1;
    logic   [31:0] d_x2;
    logic   [31:0] d_x3;
    logic   [31:0] d_x4;
    logic   [31:0] testmem;
    logic   [6:0] d_opcode;

    // trap is an output to show that execution has halted 
    logic illegalinsn;
    logic trapped;
	logic halt;
    assign trap = trapped;

	




    // registers, instruction reg, program counter, next pc
    logic   [31:0] regfile [0:`NUMREGS-1];
    logic   [31:0] pc;
    logic   [31:0] insn;

    // components of the instruction
    logic   [6:0] insn_funct7;
    logic   [4:0] insn_rs2;
    logic   [4:0] insn_rs1;
    logic   [2:0] insn_funct3;
    logic   [4:0] insn_rd;
    logic   [6:0] insn_opcode;



	

    // split R-type instruction - see section 2.2 of RiscV spec
    assign {insn_funct7, insn_rs2, insn_rs1, insn_funct3, insn_rd, insn_opcode} = insn;

    // setup for I, S, B & J type instructions
    // I - short immediates and loads
    logic   [11:0] imm_i;
    assign  imm_i = insn[31:20];
    // sign extended imm_i
    wire    [31:0] imm_i_sext = { {20{imm_i[11]}}, imm_i };
    // sign extended short immediate for shifts
    wire    [31:0] imm_shift = 32'(signed'({1'b0, insn[24:20]}));
    // use the 5-bit immediate for shifts otherwise the 12-bit one
    logic   [31:0] imm_val;
    assign imm_val = 
        ({insn_funct7, insn_funct3} == `OPCODE_SLLI ||
         {insn_funct7, insn_funct3} == `OPCODE_SRLI ||
         {insn_funct7, insn_funct3} == `OPCODE_SRAI)
         ? imm_shift : imm_i_sext; // either a shift or an imm

	// B - conditionals
	logic   [12:0] imm_b;
	assign {imm_b[12], imm_b[10:5]} = insn_funct7, {imm_b[4:1], imm_b[11]} = insn_rd, imm_b[0] = 1'b0;

	// J - unconditional jumps
	logic   [20:0] imm_j;
	assign  {imm_j[20], imm_j[10:1], imm_j[11], imm_j[19:12], imm_j[0]} = {insn[31:12], 1'b0};

    // S - store type 
    logic [11:0] imm_s;
    assign imm_s[11:5] = insn_funct7 ;
    assign imm_s[4:0]  = insn_rd; 

    // L - Load type
    

    wire    [31:0] imm_s_sext = 32'(signed'(imm_s));
	wire    [31:0] imm_b_sext = 32'(signed'(imm_b));
	wire    [31:0] imm_j_sext = 32'(signed'(imm_j));




	// CSR access bus (from the Zicsr instruction decode)
	logic [11:0] csr_addr;
	logic [31:0] csr_re;
	logic [31:0] csr_we;
	logic [31:0] csr_wdata;
	logic [31:0] csr_rdata;
	logic [31:0] uimm;
 
	assign csr_addr  = imm_i;
	assign uimm = insn_rs1;


	always_comb begin	
    	csr_re = 32'h0;   // logic for csr read enable
    	if (insn_opcode == `OPCODE_ZICSR) begin
        	case (insn_funct3)
            	3'b001, 3'b101:                   // CSRRW, CSRRWI: no read if rd == x0
                	csr_re = (insn_rd != 0) ? 32'hFFFFFFFF : 32'h0;
            	3'b010, 3'b011, 3'b110, 3'b111:   // CSRRS, CSRRC, CSRRSI, CSRRCI: always read
                	csr_re = 32'hFFFFFFFF;
            	default:                          // 000 = ecall/ebreak/mret, 
                	csr_re = 32'h0;
        endcase
    end end
	//double check this above logic lmao. Its just checking for the edge cases where a register is 0 or a result is 0.
	//The description of these edge cases was in the risc docs


    // ALU 
	logic  alu_eq_zero;
    logic  [31:0] alu_result;
    logic  alu_eq;
    wire   [31:0] alu_op_a = regfile[insn_rs1];
	wire   [31:0] alu_op_b = insn_opcode == `OPCODE_OP_IMM ? 
                                imm_val : regfile[insn_rs2];
	logic   [4:0] alu_op;



always_comb begin  //This is the same old ALU stuff from the labs. Nothing has been changed
	alu_op = `ALU_ADD; 
		case (insn_opcode)
			`OPCODE_OP_IMM: begin
				casez ({insn_funct7, insn_funct3})
					10'b zzzzzzz_000 /* ADDI  */: alu_op = `ALU_ADD;
					10'b zzzzzzz_010 /* SLTI  */: alu_op = `ALU_SLT;
					10'b zzzzzzz_011 /* SLTIU */: alu_op = `ALU_SLTU;
					10'b zzzzzzz_100 /* XORI  */: alu_op = `ALU_XOR;
					10'b zzzzzzz_110 /* ORI   */: alu_op = `ALU_OR;
					10'b zzzzzzz_111 /* ANDI  */: alu_op = `ALU_AND;
					10'b 0000000_001 /* SLLI  */: alu_op = `ALU_SLL;
					10'b 0000000_101 /* SRLI  */: alu_op = `ALU_SRL;
					10'b 0100000_101 /* SRAI  */: alu_op = `ALU_SRA;
					default: illegalinsn = 1;
				endcase
			end

			`OPCODE_OP: begin
				casez ({insn_funct7, insn_funct3})
					10'b 0000000_000 /* ADD  */: alu_op = `ALU_ADD;
					10'b 0100000_000 /* SUB  */: alu_op = `ALU_SUB;
					10'b 0000000_001 /* SLL  */: alu_op = `ALU_SLL;
					10'b 0000000_010 /* SLT  */: alu_op = `ALU_SLT;
					10'b 0000000_011 /* SLTU */: alu_op = `ALU_SLTU;
					10'b 0000000_100 /* XOR  */: alu_op = `ALU_XOR;
					10'b 0000000_101 /* SRL  */: alu_op = `ALU_SRL;
					10'b 0100000_101 /* SRA  */: alu_op = `ALU_SRA;
					10'b 0000000_110 /* OR   */: alu_op = `ALU_OR;
					10'b 0000000_111 /* AND  */: alu_op = `ALU_AND;
					default: illegalinsn = 1;
				endcase
            end

            `OPCODE_BRANCH: begin
				case (insn_funct3)
                    // LAB need to map branches to ALU operations here
					3'b 000 /* BEQ  */: alu_op = `ALU_SUB;
                    3'b 001 /*BNE */ : alu_op = `ALU_SUB;
                    3'b 100 /* BLT */ : alu_op = `ALU_SLT;
                    3'b 101 /* BGE */ : alu_op = `ALU_SLT;
                    3'b 110 /* BLTU*/ : alu_op = `ALU_SLTU; 
                    3'b 111 /* BGEU*/ : alu_op = `ALU_SLTU; 
					default: illegalinsn = 1;

                endcase
            end

			
        endcase
    end




    // instantiate ALU
	alu alu_1 (
		.alu_function(alu_op),
		.op_a(alu_op_a),
		.op_b(alu_op_b),
		.result(alu_result),
		.result_eq_zero(alu_eq_zero)
	);


	// combinational assignment of control signals
    logic   regwrite;
    logic   [31:0] npc;
    logic   [31:0] rfilewdata;
	logic take_intr; //the variable called intr is the actual interrupt signal. This is an extra control signal
					//It is the result of checking if the mstatus and mie bits are high.
    logic mret_flag; //just a flag used in flipflo logic that says when mret is being used.
	




	// control signals for CPU
    always_comb begin
		illegalinsn = 0; //default values
		regwrite = 0;
		take_intr = 0; 
		npc = pc + 4;
		csr_we = 0;
		csr_wdata = 0; 
        rfilewdata = alu_result;
		dmem_wr_enable = 0; 
		mret_flag = 0; 
		halt = 0;

		take_intr = csr_mip[11] & csr_mie[11] & csr_mstatus[3]; //
		if (take_intr) begin
			npc = MTVEC_ADDR; end //we dont want anything to change. 
	
		else begin //standard opcode checks

			case (insn_opcode)
			

				`OPCODE_OP_IMM: begin
                	regwrite = 1;
				end

				`OPCODE_OP: begin
            	    regwrite = 1;
				end

            	`OPCODE_JAL: begin
                	// LAB implement JAL control signals here
                	regwrite = 1;
                	rfilewdata = pc + 4;
                	npc = pc + imm_j_sext; 
            	end

            	`OPCODE_JALR: begin
                	// LAB implement JALR control signals here
                	regwrite = 1; 
                	rfilewdata = pc + 4; 
                	npc = (regfile[insn_rs1] + imm_i_sext) & ~32'b 1; 
            	end

				// branch instructions: Branch If Equal, Branch Not Equal, Branch Less Than, Branch Greater Than, Branch Less Than Unsigned, Branch Greater Than Unsigned
				`OPCODE_BRANCH: begin
					case (insn_funct3)
						3'b 000 /* BEQ  */: begin if (alu_eq_zero) npc = pc + imm_b_sext; end
						3'b 001 /* BNE */ : begin if (alu_eq_zero == 0) npc = pc + imm_b_sext; end
						3'b 100 /* BLT */ : begin if (alu_eq_zero == 0) npc = pc + imm_b_sext; end
						3'b 101 /* BGE */ : begin if (alu_eq_zero == 1) npc = pc + imm_b_sext; end
						3'b 110 /* BLTU */: begin if (alu_eq_zero == 0) npc = pc + imm_b_sext; end
						3'b 111 /* BGEU */: begin if (alu_eq_zero == 1) npc = pc + imm_b_sext; end

						default: illegalinsn = 1;
					endcase
				end

				`OPCODE_LOAD: begin
					// LAB implement LW here
					regwrite = 1; 
					dmem_rd_addr = regfile[insn_rs1] + imm_i_sext;
					dmem_rd_data = dmem[dmem_rd_addr];
					rfilewdata = dmem_rd_data;
				// $display("lw from 0x%08x = 0x%08x", dmem_rd_addr, dmem_rd_data);
				end
				`OPCODE_ZICSR: begin
					case(insn_funct3)
						3'b001 /*CSRRW*/: 
							begin csr_wdata = regfile[insn_rs1]; 
								csr_we = 32'hFFFFFFFF;
								rfilewdata = csr_rdata;
								regwrite = 1; 
							end
						3'b010 /*CSRRS*/:
							begin rfilewdata = csr_rdata;
								regwrite = 1; 
								csr_we = insn_rs1 != 0 ? regfile[insn_rs1]: 32'h00000000; //we only want to enable change where the bits are 1 in rs1. 
								csr_wdata = 32'hFFFFFFFF;  // and we want to change them to 1
							end 
						3'b011 /*CSRRC*/:
							begin rfilewdata = csr_rdata; 
								regwrite = 1; 
								csr_we = insn_rs1 != 0 ? regfile[insn_rs1]: 32'h00000000; //We only want to enable change where the bits are 1 in rs1
								csr_wdata = 32'h00000000;// and we want to change them to 0
							end
						3'b101 /*CSRRWI*/:
							begin csr_wdata = uimm;
								csr_we = 32'hFFFFFFFF;
								rfilewdata = csr_rdata;
								regwrite = 1; 
							end
						3'b110 /*CSRRSI*/:
							begin rfilewdata = csr_rdata;
								regwrite = 1; 
								csr_we = uimm != 0 ? uimm: 32'h00000000; //we only want to enable change where the bits are 1 in rs1. 
								csr_wdata = 32'hFFFFFFFF;  // and we want to change them to 1
							end 
						3'b111 /*CSRRCI*/: 
							begin rfilewdata = csr_rdata; 
								regwrite = 1; 
								csr_we = uimm != 0 ? uimm: 32'h00000000; //We only want to enable change where the bits are 1 in rs1
								csr_wdata = 32'h00000000;// and we wan tto change them to 0
							end
						3'b000 : begin
						if (insn_funct7 != 0) /*MRET*/ 
							begin npc = csr_mepc;  //if funct7 is 0 then it is ebreak, mret and ebreak share the same funct3.
								mret_flag = 1; 
							end 
						else begin halt = 1; end //ebreak now sets a halt flag, which triggers trap output stopping the cpu.
						end
								

						default: illegalinsn = 1; //if instruction never recognised, defaults to illegal
						endcase
				end


				`OPCODE_STORE: begin
					dmem_wr_enable = 1; 
					dmem_wr_addr = regfile[insn_rs1] + imm_s_sext; 
					dmem_wr_data = regfile[insn_rs2];
					
					// LAB implement SW here

					
				end

				default: illegalinsn = 1;
			endcase
			// check that branches etc weren't to an unaligned address
			if ((npc & 32'b11) != 0) begin
				illegalinsn = 1;
				npc = pc & ~32'b 11;
			end

		end

		if (illegalinsn) begin
    		npc = MTVEC_ADDR; //have to place this after the previous checks cause they set illegalinsn
    		regwrite = 0; csr_we = 0; dmem_wr_enable = 0; mret_flag = 0; halt = 0;
		end //these checks can modify the other signals, so we have to return them back to 0
	end

    // every cycle
    always_ff @(posedge clock) begin

		if (!trapped && !reset) begin
			if (halt) //if ebreak we stop
				trapped <= 1; //This not the same as trap condition.
		end

        if (regwrite && insn_rd > 0) begin
            regfile[insn_rd] <= rfilewdata;
            
    	end

        // LAB update the data memory here
        if (dmem_wr_enable)
            dmem[dmem_wr_addr] <= dmem_wr_data;

        // reset

		pc <= npc;

        if (reset) begin
		    pc <= 0;
           	trapped <= 0;
        end

        
		if (reset) begin
			csr_mepc   <= 32'h0;
			csr_mip    <= 32'h0;
			csr_mcause <= 32'h0;
		end
		else begin
			if (intr) begin
				csr_mip[11]  <= 1;  //set the mip bit when interrupt
			end 

			else if (mret_flag) begin
				csr_mip <= 32'h0; end //when mret happens clear that bit.


			if (take_intr) begin
				csr_mepc <= pc; 
				csr_mcause <= 32'h8000000B;	end
			
			else if (illegalinsn) begin
				csr_mepc <= pc+4; 
				csr_mcause <= 32'h00000002;end
		
		end

		

		$display("pc=%h illegalinsn = %h csr_mcause = %h  halt = %h csr_mepc = %h insn=%h take_intr=%b mip=%h mie=%h mstatus=%h x0 = %0d x1 = %0d x2 = %0d x3 =%0d x4 = %0d x5=%0d x6=%0d x7 = %0d x8 = %0d x9 = %0d x10=%0d ", pc, illegalinsn,csr_mcause, halt, csr_mepc, insn, take_intr, csr_mip, csr_mie, csr_mstatus, regfile[0],regfile[1],regfile[2],regfile[3],regfile[4],regfile[5],regfile[6],regfile[7],regfile[8],regfile[9],regfile[10]);
		

    end




	logic [31:0] csr_mepc;
	logic [31:0] csr_mip;
	logic [31:0] csr_mcause;
	// mtvec is hard-wired to MTVEC_ADDR
	wire  [31:0] csr_mtvec = MTVEC_ADDR;
	// read-write CSRs: flip-flops live inside csrfile, exposed here
	wire  [31:0] csr_mie;
	wire  [31:0] csr_mstatus;
	wire  [31:0] csr_mscratch;
 
	



	// instantiate the CSR file
	csrfile csr_file (
		.clock(clock),
		.reset(reset),
		.addr(csr_addr),
		.re(csr_re),
		.we(csr_we),
		.rdata(csr_rdata),
		.wdata(csr_wdata),
		.ro_mepc_bits(csr_mepc),
		.rw_mstatus_bits(csr_mstatus),
		.rw_mie_bits(csr_mie),
		.ro_mtvec_bits(csr_mtvec),
		.ro_mip_bits(csr_mip),
		.ro_mcause_bits(csr_mcause),
		.rw_mscratch_bits(csr_mscratch),
		.take_intr(take_intr),
		.mret_flag(mret_flag)
	);
 
 
endmodule
 






 
// CSR file.  Slightly different than register file since it's bit addressable
// this skeleton provides bit addressable read & write.
// Some CSRs are marked read-only, some write only, and some read/write
// It's intended that you connect the addr, re, we, wdata and rdata to the
// instruction decoder logic, while the "bits" ports connect to internal "wire" or "logic" signals
module csrfile
(
	input  wire clock,			// clock input
	input  wire reset,			// reset signal
	input  wire [11:0] addr,	// CSR address (CSR ID number)
	input  wire [31:0] re,		// bit-addressable write enable
	input  wire [31:0] we,		// bit-addressable read enable
	output wire [31:0] rdata,	// CSR bits  for read out (use w/ re lines)
	input  wire [31:0] wdata,	// CSR bits for write input (use w/ we lines)
	input  wire take_intr,
	input wire mret_flag, 
 
	// raw bits
	input  wire [31:0] ro_mepc_bits,	// actual internal bits of MEPC register
	output wire [31:0] rw_mstatus_bits,	// ... etc
	output wire [31:0] rw_mie_bits,
	input  wire [31:0] ro_mtvec_bits,
	input  wire [31:0] ro_mip_bits,
	input  wire [31:0] ro_mcause_bits,
	output wire [31:0] rw_mscratch_bits
);
	// internal flipflops
	// these will hold logic that is for read-write and write only registers
	// the rest of the CSRs are read-only, and so the actual FF is contained
	// inside the processor logic, not here.
	logic [31:0] mie_bits;
	logic [31:0] mscratch_bits;
	logic [31:0] mstatus_bits;
	
	
 
	genvar i;
 
	// combinational read
	assign rdata = (addr == CSR_MEPC) 		? ro_mepc_bits 		& re :
					(addr == CSR_MSTATUS) 	? rw_mstatus_bits	& re :
					(addr == CSR_MIE) 		? rw_mie_bits 		& re :
					(addr == CSR_MTVEC) 	? ro_mtvec_bits 	& re :
					(addr == CSR_MIP) 		? ro_mip_bits 		& re :
					(addr == CSR_MCAUSE) 	? ro_mcause_bits 	& re:
					(addr == CSR_MSCRATCH) 	? rw_mscratch_bits 	& re:
					32'h x;
 
	// map the internal FFs into ports that can be used by your processor's controller
	assign rw_mie_bits = mie_bits;
	assign rw_mscratch_bits = mscratch_bits;
	assign rw_mstatus_bits = mstatus_bits;
 
	// construct  bitwise those CSRs that are read-write
	// the rest not listed here are read-only, and thus controlled
	// outside this module
	generate
		for (i = 0; i<32; i++) begin : gen_write_bits
 
			always @(posedge clock) begin
				if(reset == 1) begin
					mie_bits[i] <= 0;
					mscratch_bits[i] <= 0;
					mstatus_bits[i] <= 0;
				end
				else if(take_intr == 1)
					mstatus_bits[3] <= 0; 
				else if(mret_flag == 1)
					mstatus_bits[3] <= 1; 

				else if(addr == CSR_MIE && we[i])
					mie_bits[i] <= wdata[i];
				else if(addr == CSR_MSCRATCH && we[i])
					mscratch_bits[i] <= wdata[i];
				else if(addr == CSR_MSTATUS && we[i])
					mstatus_bits[i] <= wdata[i];
				
				
			end
		end: gen_write_bits
	endgenerate
 
 
endmodule
