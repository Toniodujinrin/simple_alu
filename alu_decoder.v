`include "./alu_constants.v"
module alu_decoder(partial_instruction, option_bits, alu_opcode, add_sub, signed_unsigned_comparator, signed_unsigned_multiplier, negate, fp_add_sub, shifter_mode); 
	input wire [6:0] partial_instruction; 
	input wire [2:0] option_bits; 
	output reg [7:0] alu_opcode; 
	output reg add_sub, fp_add_sub, signed_unsigned_comparator, signed_unsigned_multiplier, negate; 
	output reg [2:0] shifter_mode; 
	
	
	wire [1:0] class_code = partial_instruction[6:5];
	wire [4:0] opcode_class_01; 
	wire [1:0] opcode_class_00; 
	wire [2:0] opcode_class_10; 
	wire [2:0] opcode_class_11; 
	wire class_10_option_code; 
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//set local parameters
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////	
	
	localparam CLASS_00    = 2'b00; 
	localparam CLASS_01    = 2'b01; 
	localparam CLASS_10    = 2'b10; 
	localparam CLASS_11    = 2'b11; 
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//assign opcode bits accroding to class code
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	assign class_10_option_code = partial_instruction[1]; //Get opt field for class 10 instructions 
	assign opcode_class_01 = class_code == CLASS_01 ? partial_instruction[4:0] : 5'bz; 
	assign opcode_class_00 = class_code == CLASS_00 ? partial_instruction[4:3] : 2'bz; 
	assign opcode_class_10 = class_code == CLASS_10 && class_10_option_code ? partial_instruction[4:2] : 3'bz; 
	assign opcode_class_11 = class_code == CLASS_11 ? partial_instruction[4:2] : 3'bz; 
	
	always @(*) begin
		//set default 
		alu_opcode = 8'h00; 
		add_sub    = 1'b0; 
		signed_unsigned_comparator = 1'b0; 
		signed_unsigned_multiplier = 1'b0; 
		fp_add_sub = 1'b0; 
		negate = 1'b0; 
		shifter_mode = `SH_LSL; 
		
		case (class_code)
			CLASS_01:begin 
				case(opcode_class_01)
					5'b00000: begin alu_opcode = `ALU_MOV; end
               5'b00001: begin alu_opcode = `ALU_ADD; add_sub = 1'b0; end
               5'b00010: begin alu_opcode = `ALU_SUB; add_sub = 1'b1; end
               5'b00011: begin alu_opcode = `ALU_MULH; signed_unsigned_multiplier = 1'b1; end
               5'b00100: begin alu_opcode = `ALU_UMULH; signed_unsigned_multiplier = 1'b0; end
               5'b00101: begin 
										 case(option_bits)  //use option bits to select FP, Unsigned, signed 
											 3'b000:begin alu_opcode = `ALU_UCMP; signed_unsigned_comparator = 1'b0; end
											 3'b001:begin alu_opcode = `ALU_CMP; signed_unsigned_comparator = 1'b1; end
											 3'b010:begin alu_opcode = `ALU_FCMP; signed_unsigned_comparator = 1'b0; end
											 default:begin alu_opcode = `ALU_NOP; end
										 endcase
								 end 
					5'b00110: begin alu_opcode = `ALU_AND; negate = 1'b0; end
               5'b00111: begin alu_opcode = `ALU_OR;  negate = 1'b0; end
               5'b01000: begin alu_opcode = `ALU_NOR; negate = 1'b1; end
               5'b01001: begin alu_opcode = `ALU_NAND; negate = 1'b1; end
               5'b01010: begin alu_opcode = `ALU_XOR; negate = 1'b0; end
               5'b01011: begin alu_opcode = `ALU_XNOR; negate = 1'b1; end
               5'b01100: begin alu_opcode = `ALU_NOT; end
               5'b01111: begin alu_opcode = `ALU_MULL; signed_unsigned_multiplier = 1'b1; end
               5'b10000: begin alu_opcode = `ALU_UMULL;signed_unsigned_multiplier = 1'b0; end
               5'b10001: begin alu_opcode = `ALU_FADD; fp_add_sub = 1'b1; end
               5'b10010: begin alu_opcode = `ALU_FSUB; fp_add_sub = 1'b0; end
               5'b10011: begin alu_opcode = `ALU_FMUL; end
					5'b10110: begin 
										 case(option_bits)// ITOF / FTOI distinguished by option_bits
											 3'b000 :begin alu_opcode = `ALU_ITOF; end
											 3'b001: begin alu_opcode = `ALU_FTOI; end
											 default:begin alu_opcode = `ALU_NOP; end
										 endcase
                         end	
					5'b11000: begin alu_opcode = `ALU_LSR; shifter_mode = `SH_LSR; end
               5'b11001: begin alu_opcode = `ALU_LSL; shifter_mode = `SH_LSL; end
               5'b11010: begin alu_opcode = `ALU_ASR; shifter_mode = `SH_ASR; end
               5'b11011: begin alu_opcode = `ALU_ASL; shifter_mode = `SH_ASL; end
               5'b11100: begin alu_opcode = `ALU_ROR; shifter_mode = `SH_ROR; end
					default: begin alu_opcode = `ALU_NOP; end
				endcase
			end 
				
			CLASS_00:begin 
				case(opcode_class_00) 
					 2'b00: begin alu_opcode = `ALU_ADD; add_sub = 1'b0; end // LDR offset calc uses adder
                2'b01: begin alu_opcode = `ALU_ADD; add_sub = 1'b0; end // STR offset calc
                2'b10: begin alu_opcode = `ALU_ADD; add_sub = 1'b0; end // ADDI
                2'b11: begin alu_opcode = `ALU_SUB; add_sub = 1'b1; end // SUBI
                default:begin alu_opcode = `ALU_NOP;end
				endcase
			end 
			
			CLASS_10:begin 
				if(class_10_option_code)
					begin 
						case(opcode_class_10) 
							3'b000: begin alu_opcode = `ALU_CMP; signed_unsigned_comparator = 1'b1; end 
							3'b001: begin alu_opcode = `ALU_UCMP; signed_unsigned_comparator = 1'b0; end
							default: begin alu_opcode = `ALU_NOP;end
						endcase
					end 
				else 
					alu_opcode = `ALU_NOP; 
			 end 
			 
			 CLASS_11:begin 
				case(opcode_class_11)
					 3'b000: begin alu_opcode = `ALU_LSL; shifter_mode = `SH_LSL; end
                3'b001: begin alu_opcode = `ALU_LSR; shifter_mode = `SH_LSR; end
                3'b010: begin alu_opcode = `ALU_ASR; shifter_mode = `SH_ASR; end
                3'b011: begin alu_opcode = `ALU_ASL; shifter_mode = `SH_ASL; end
                3'b100: begin alu_opcode = `ALU_ROR; shifter_mode = `SH_ROR; end
					 default:begin alu_opcode = `ALU_NOP;end
				 endcase 
			 end  
		endcase
	end 

endmodule 