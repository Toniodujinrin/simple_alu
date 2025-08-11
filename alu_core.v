`include "./alu_constants.v"
module alu_core(x,y,r, alu_opcode, add_sub, signed_unsigned_multiplier, negate, signed_unsigned_comparator, fp_add_sub, shifter_mode, overflow, negative, zero, cout, inf, subnormal, nan); 
	input [15:0] x,y; 
	input wire [7:0] alu_opcode; 
	input wire add_sub, signed_unsigned_multiplier, negate, signed_unsigned_comparator, fp_add_sub; 
	input wire [2:0] shifter_mode; 
	output reg [15:0] r; 
	output reg overflow, negative, zero, cout, inf, subnormal, nan; 
	
	localparam WIDTH = 16; 
	
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//temporary outputs
   //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////	
	wire [15:0]  temp_mul_h_r, temp_mul_l_r, temp_sub_add_r, temp_shift_r, temp_or_nor_r, temp_and_nand_r, temp_xor_xnor_r, temp_not_r, temp_fp_add_sub_r,temp_fp_mul_r, temp_fp_conv_r, temp_int_conv_r; 
	wire [31:0] temp_mul_full_r;                   //full 32 bit multiply result 
	assign temp_mul_l_r = temp_mul_full_r[15:0];   //integer multiply low bits 
	assign temp_mul_h_r = temp_mul_full_r[31:16];  //integer multiply high bits

	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//temp cpsr bits
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	wire [13:0]	temp_negative, temp_zero, temp_overflow, temp_cout;  
	wire [3:0] temp_inf, temp_subnormal, temp_nan;
	
	
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//initialize internal modules
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	signed_adder#(.WIDTH(WIDTH)) ADDER_MODULE(.x(x), .y(y), .add_sub(add_sub), .overflow(temp_overflow[0]), .negative(temp_negative[0]), .zero(temp_zero[0]),.cout(temp_cout[0]),.s(temp_sub_add_r));
	comparator#(.WIDTH(WIDTH)) COMPARATOR_MODULE(.x(x),.y(y),.signed_unsigned(signed_unsigned_comparator),.negative(temp_negative[1]),.zero(temp_zero[1]),.cout(temp_cout[1]),.overflow(temp_overflow[1]));
	multiplier#(.WIDTH(WIDTH)) MULTIPLIER_MODULE(.x(x),.y(y),.r(temp_mul_full_r),.signed_unsigned(signed_unsigned_multiplier), .negative(temp_negative[3]),.zero(temp_zero[3]), .overflow(temp_overflow[3]), .cout(temp_cout[3]));  
	shift#(.WIDTH(WIDTH))   SHIFTER_MODULE(.x(x),.y(temp_shift_r),.shift_count(y),.mode(shifter_mode),.negative(temp_negative[4]), .zero(temp_zero[4]), .cout(temp_cout[4]), .overflow(temp_overflow[4])) ; 
	and_mod#(.WIDTH(WIDTH)) AND_MODULE(.x(x),.y(y),.r(temp_and_nand_r),.negate(negate), .negative(temp_negative[5]),.zero(temp_zero[5]), .cout(temp_cout[5]), .overflow(temp_overflow[5])); 
	not_mod#(.WIDTH(WIDTH)) NOT_MODULE(.x(x),.r(temp_not_r), .negative(temp_negative[6]),.zero(temp_zero[6]), .cout(temp_cout[6]), .overflow(temp_overflow[6])); 
	or_mod#(.WIDTH(WIDTH))  OR_MODULE(.x(x), .y(y), .r(temp_or_nor_r), .negate(negate), .negative(temp_negative[7]),.zero(temp_zero[7]), .cout(temp_cout[7]), .overflow(temp_overflow[7])); 
	xor_mod#(.WIDTH(WIDTH)) XOR_MODULE(.x(x), .y(y), .r(temp_xor_xnor_r), .negate(negate), .negative(temp_negative[8]),.zero(temp_zero[8]), .cout(temp_cout[8]), .overflow(temp_overflow[8])); 
	fp_adder_subtractor     FP_ADDER_MODULE(.x(x), .y(y), .r(temp_fp_add_sub_r), .add_sub(fp_add_sub), .negative(temp_negative[9]), .cout(temp_cout[9]), .overflow(temp_overflow[9]), .zero(temp_zero[9]), .nan(temp_nan[0]), .inf(temp_inf[0]), .subnormal(temp_subnormal[0]));
	fp_comparator           FP_COMPARATOR_MODULE(.x(x),.y(y), .negative(temp_negative[10]), .zero(temp_zero[10]), .overflow(temp_overflow[10]), .cout(temp_cout[10]), .nan(temp_nan[1]), .inf(temp_inf[1]), .subnormal(temp_subnormal[1]));  
	fp_multiplier           FP_MULTIPLIER_MODULE(.x(x),.y(y),.r(temp_fp_mul_r),.negative(temp_negative[11]), .zero(temp_zero[11]), .overflow(temp_overflow[11]), .cout(temp_cout[11]), .inf(temp_inf[2]), .nan(temp_nan[2]), .subnormal(temp_subnormal[2])); 
	fp_converter            FP_CONVERTER_MODULE(.x(x), .r(temp_fp_conv_r), .negative(temp_negative[12]), .zero(temp_zero[12]), .overflow(temp_overflow[12]), .inf(temp_inf[3]), .nan(temp_nan[3]), .subnormal(temp_subnormal[3])); 
	int_converter           INT_CONVERTER_MODULE(.x(x), .r(temp_int_conv_r),  .negative(temp_negative[13]), .zero(temp_zero[13]), .overflow(temp_overflow[13]), .cout(temp_cout[13])); 
	
	always @(*) begin 
		//set default values
	   r = 16'h0000;
      overflow = 1'b0;
      negative = 1'b0;
      zero = 1'b1;
      cout = 1'b0;
      inf = 1'b0;
      subnormal = 1'b0;
      nan = 1'b0;
		
		
		case(alu_opcode)
			   `ALU_MOV: begin // MOV
                r = x;
                negative = x[WIDTH-1];
                zero = ~|x;
            end

            `ALU_ADD, `ALU_SUB: begin // ADD
                r = temp_sub_add_r;
                negative = temp_negative[0];
                zero = temp_zero[0];
                overflow = temp_overflow[0];
                cout = temp_cout[0];
            end
				
				`ALU_MULL, `ALU_UMULL: begin  
					 r = temp_mul_l_r;
                negative = temp_negative[3];
                zero = temp_zero[3];
                overflow = temp_overflow[3];
                cout = temp_cout[3];
            end
				`ALU_CMP, `ALU_UCMP: begin 
					 r = 16'b0;
                negative = temp_negative[1];
                zero = temp_zero[1];
                overflow = temp_overflow[1];
                cout = temp_cout[1];
				end
				`ALU_AND, `ALU_NAND: begin
					 r = temp_and_nand_r; 
					 negative = temp_negative[5];
                zero = temp_zero[5];
                overflow = temp_overflow[5];
                cout = temp_cout[5];
				end 
				`ALU_OR, `ALU_NOR: begin 
					 r = temp_or_nor_r;
                negative = temp_negative[7];
                zero = temp_zero[7];
                overflow = temp_overflow[7];
                cout = temp_cout[7];
				end 
				
				`ALU_XOR, `ALU_XNOR: begin 
					 r = temp_xor_xnor_r;
                negative = temp_negative[8];
                zero = temp_zero[8];
                overflow = temp_overflow[8];
                cout = temp_cout[8];
            end
				
				`ALU_NOT: begin 
					 r = temp_not_r;
                negative = temp_negative[6];
                zero = temp_zero[6];
                overflow = temp_overflow[6];
                cout = temp_cout[6];
            end
				
				`ALU_FADD, `ALU_FSUB: begin
					 r = temp_fp_add_sub_r;
                negative = temp_negative[9];
                zero = temp_zero[9];
                overflow = temp_overflow[9];
                cout = temp_cout[9];
                inf = temp_inf[0];
                nan = temp_nan[0];
                subnormal = temp_subnormal[0];
				end
				
				`ALU_FMUL: begin
					 r = temp_fp_mul_r;
                negative = temp_negative[11];
                zero = temp_zero[11];
                overflow = temp_overflow[11];
                cout = temp_cout[11];
                inf = temp_inf[2];
                nan = temp_nan[2];
                subnormal = temp_subnormal[2];
            end
				
				`ALU_ITOF: begin
					 r = temp_fp_conv_r;
                negative = temp_negative[12];
                zero = temp_zero[12];
                overflow = temp_overflow[12];
                cout = temp_cout[12];
                inf = temp_inf[3];
                nan = temp_nan[3];
                subnormal = temp_subnormal[3];
				end 
				
				`ALU_FTOI: begin
					 r = temp_int_conv_r;
                negative = temp_negative[13];
                zero = temp_zero[13];
                overflow = temp_overflow[13];
                cout = temp_cout[13];
				end 
				
				`ALU_LSL, `ALU_LSR, `ALU_ASL, `ALU_ASR, `ALU_ROR: begin 
					 r = temp_shift_r;
                negative = temp_negative[4];
                zero = temp_zero[4];
                overflow = temp_overflow[4];
                cout = temp_cout[4];
            end
				default: begin
					 r = 16'b0; 
				end
		endcase
		
	end

endmodule 