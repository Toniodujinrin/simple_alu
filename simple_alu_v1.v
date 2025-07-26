module simple_alu_v1(opcode,x,y,r,overflow, negative, zero, cout, option_bits); 
	parameter WIDTH = 16; 
	input [4:0] opcode; 
	input [15:0] x,y; 
	input [2:0] option_bits; 
	output reg [15:0] r; 

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//output control flags
   ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////	
	output reg overflow,negative, zero, cout; 
	
	
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//temporary outputs
   //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////	
	wire [15:0]  temp_mul_h_r, temp_mul_l_r, temp_sub_add_r, temp_shift_r, temp_or_nor_r, temp_and_nand_r, temp_xor_xnor_r, temp_not_r, temp_fp_add_sub_r,temp_fp_mul_r; 
	wire [31:0] temp_mul_full_r; 
	assign temp_mul_l_r = temp_mul_full_r[15:0]; 
	assign temp_mul_h_r = temp_mul_full_r[31:16]; 

	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//temp cpsr bits
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	wire [31:0]	temp_negative, temp_zero, temp_overflow, temp_cout;

	
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//internal control signals based on opcode 
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	wire add_sub, signed_unsigned_multiplier, negate, signed_unsigned_comparator, fp_add_sub; 
	wire [2:0] shifter_mode;
   assign negate = ((opcode == 5'b01000) || (opcode == 5'b01001) || (opcode == 5'b01011))?1:0; 
	assign add_sub = opcode == 5'b00010 ?1:0;  //Add or subtract control bits 
	assign signed_unsigned_multiplier = (opcode == 5'b00011)||(opcode == 5'b01111) ? 1:0; 
	assign signed_unsigned_comparator = (option_bits == 3'b001) ? 1:0; 
	assign fp_add_sub = opcode == 5'b10010 ? 1:0; 
	//shifter modes///////
	//LSL = 3'b000
	//LSR = 3'b001 
	//ASR = 3'b010 
	//ASL = 3'b011 
	//ROR = 3'b100
	///////////////	
	assign shifter_mode = (opcode == 5'b11000) ? 3'b001: ((opcode == 5'b11001) ? 3'b000: ((opcode == 5'b11010) ? 3'b010:((opcode == 5'b11011) ? 3'b011 : 3'b100))); 
	
   ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//initialize modules
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	signed_adder#(.WIDTH(WIDTH)) ADDER_MODULE(.x(x), .y(y), .add_sub(add_sub), .overflow(temp_overflow[0]), .negative(temp_negative[0]), .zero(temp_zero[0]),.cout(temp_cout[0]),.s(temp_sub_add_r));
	comparator#(.WIDTH(WIDTH)) COMPARATOR_MODULE(.x(x),.y(y),.signed_unsigned(signed_unsigned_comparator),.negative(temp_negative[1]),.zero(temp_zero[1]),.cout(temp_cout[1]),.overflow(temp_overflow[1]));
	multiplier#(.WIDTH(WIDTH)) MULTIPLIER_MODULE(.x(x),.y(y),.r(temp_mul_full_r),.signed_unsigned(signed_unsigned_multiplier), .negative(temp_negative[3]),.zero(temp_zero[3]), .overflow(temp_overflow[3]), .cout(temp_cout[3]));  
	shift#(.WIDTH(WIDTH)) SHIFTER_MODULE(.x(x),.y(temp_shift_r),.shift_count(y),.mode(shifter_mode),.negative(temp_negative[4]), .zero(temp_zero[4]), .cout(temp_cout[4]), .overflow(temp_overflow[4])) ; 
	and_mod#(.WIDTH(WIDTH))  AND_MODULE(.x(x),.y(y),.r(temp_and_nand_r),.negate(negate), .negative(temp_negative[5]),.zero(temp_zero[5]), .cout(temp_cout[5]), .overflow(temp_overflow[5])); 
	not_mod#(.WIDTH(WIDTH))  NOT_MODULE(.x(x),.r(temp_not_r), .negative(temp_negative[6]),.zero(temp_zero[6]), .cout(temp_cout[6]), .overflow(temp_overflow[6])); 
	or_mod#(.WIDTH(WIDTH)) OR_MODULE(.x(x), .y(y), .r(temp_or_nor_r), .negate(negate), .negative(temp_negative[7]),.zero(temp_zero[7]), .cout(temp_cout[7]), .overflow(temp_overflow[7])); 
	xor_mod#(.WIDTH(WIDTH)) XOR_MODULE(.x(x), .y(y), .r(temp_xor_xnor_r), .negate(negate), .negative(temp_negative[8]),.zero(temp_zero[8]), .cout(temp_cout[8]), .overflow(temp_overflow[8])); 
	fp_adder_subtractor     FP_ADDER_MODULE(.x(x), .y(y), .r(temp_fp_add_sub_r), .add_sub(fp_add_sub), .negative(temp_negative[9]), .cout(temp_cout[9]), .overflow(temp_overflow[9]), .zero(temp_zero[9]));
	fp_comparator           FP_COMPARATOR_MODULE(.x(x),.y(y), .negative(temp_negative[10]), .zero(temp_zero[10]), .overflow(temp_overflow[10]), .cout(temp_cout[10]));  
	fp_multiplier           FP_MULTIPLIER_MODULE(.x(x),.y(y),.r(temp_fp_mul_r),.negative(temp_negative[11]), .zero(temp_zero[11]), .overflow(temp_overflow[11]), .cout(temp_cout[11])); 
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//hard decode opcode 
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	always@(opcode) 
		begin
		case(opcode)
		00000: begin
				r = x; 
				negative = x[WIDTH-1]; 
				zero = x == 0 ? 1: 0; 
				overflow = 0; 
				cout = 0; 
				end 
		00001:begin 
				r = temp_sub_add_r; 
				negative = temp_negative[0]; 
				zero = temp_zero[0]; 
				overflow = temp_overflow[0]; 
				cout = temp_cout[0]; 
				end
		00010: begin
				r = temp_sub_add_r; 
				negative = temp_negative[0]; 
				zero = temp_zero[0]; 
				overflow = temp_overflow[0]; 
				cout = temp_cout[0]; 
				end 
		00011: begin
				r = temp_mul_h_r; 
				negative = temp_negative[3]; 
				zero = temp_zero[3]; 
				overflow = temp_overflow[3]; 
				cout = temp_cout[3]; 	
				end
		00100: begin 
				r = temp_mul_h_r; 
				negative = temp_negative[3]; 
				zero = temp_zero[3]; 
				overflow = temp_overflow[3]; 
				cout = temp_cout[3];
				end 
		00101: begin
				r = 0; //no output for comparison operation, just CPSR update
				negative = (option_bits == 3'b010)? temp_negative[10]:temp_negative[1]; 
				zero = (option_bits == 3'b010)?temp_zero[10]:temp_zero[1]; 
				overflow = (option_bits == 3'b010)? temp_overflow[10]: temp_overflow[1]; 
				cout = (option_bits ==3'b010)? temp_cout[10]:temp_cout[1];
				end
		00110: begin
				r = temp_and_nand_r; 
				negative = temp_negative[5]; 
				zero = temp_zero[5]; 
				overflow = temp_overflow[5]; 
				cout = temp_cout[5]; 
				end
		00111: begin 
				r = temp_or_nor_r; 
				negative = temp_negative[7]; 
				zero = temp_zero[7]; 
				overflow = temp_overflow[7]; 
				cout = temp_cout[7]; 
				end
		01000: begin
				r = temp_or_nor_r; 
				negative = temp_negative[7]; 
			   zero = temp_zero[7]; 
			   overflow = temp_overflow[7]; 
			   cout = temp_cout[7]; 
				end
		01001: begin 
				r = temp_and_nand_r; 
				negative = temp_negative[5]; 
				zero = temp_zero[5]; 
				overflow = temp_overflow[5]; 
				cout = temp_cout[5]; 
				end 
		01010: begin
				r = temp_xor_xnor_r; 
				negative = temp_negative[8]; 
				zero = temp_zero[8]; 
				overflow = temp_overflow[8]; 
				cout = temp_cout[8];	
				end
		01011: begin
				r = temp_xor_xnor_r; 
				negative = temp_negative[8]; 
				zero = temp_zero[8]; 
				overflow = temp_overflow[8]; 
				cout = temp_cout[8];			
				end
		01100: begin
				r = temp_not_r; 
				negative = temp_negative[6]; 
				zero = temp_zero[6]; 
				overflow = temp_overflow[6]; 
				cout = temp_cout[6];			
				end

		01111: begin
				r = temp_mul_l_r; 
				negative = temp_negative[2]; 
				zero = temp_zero[2]; 
				overflow = temp_overflow[2]; 
				cout = temp_cout[2];
				end
		10000: begin 
				r = temp_mul_l_r; 
				negative = temp_negative[2]; 
				zero = temp_zero[2]; 
				overflow = temp_overflow[2]; 
				cout = temp_cout[2];
				end
		10001: begin 
				r = temp_fp_add_sub_r; 
				negative = temp_negative[9]; 
				zero = temp_zero[9]; 
				overflow = temp_overflow[9]; 
				cout = temp_cout[9];
				end
		10010: begin 
				r = temp_fp_add_sub_r; 
				negative = temp_negative[9]; 
				zero = temp_zero[9]; 
				overflow = temp_overflow[9]; 
				cout = temp_cout[9];
				end
		10011: begin 
				r = temp_fp_mul_r; 
				negative = temp_negative[11]; 
				zero = temp_zero[11]; 
				overflow = temp_overflow[11]; 
				cout = temp_cout[11];
				end
		//floating point arithmetic opcodes
		11000: begin
				r = temp_shift_r; 
				negative = temp_negative[4]; 
				zero = temp_zero[4]; 
				overflow = temp_overflow[4]; 
				cout = temp_cout[4];
				end 
		11001: begin
				r = temp_shift_r; 
				negative = temp_negative[4]; 
				zero = temp_zero[4]; 
				overflow = temp_overflow[4]; 
				cout = temp_cout[4];
				end 
		11010: begin
				r = temp_shift_r; 
				negative = temp_negative[4]; 
				zero = temp_zero[4]; 
				overflow = temp_overflow[4]; 
				cout = temp_cout[4];
				end
		11011: begin
				r = temp_shift_r; 
				negative = temp_negative[4]; 
				zero = temp_zero[4]; 
				overflow = temp_overflow[4]; 
				cout = temp_cout[4];
				end
		11100: begin
				r = temp_shift_r; 
				negative = temp_negative[4]; 
				zero = temp_zero[4]; 
				overflow = temp_overflow[4]; 
				cout = temp_cout[4];
				end


		endcase 
		end 
		
endmodule 







//logic ops 
//Extensible AND operation 
module and_mod(x,y,r, negate, negative, zero, cout, overflow); //negate accounts for nand operaton 
	parameter WIDTH = 8; 
	input [WIDTH-1:0] x,y; 
	output [WIDTH-1:0] r; 
	input negate; 
	output negative, zero, cout, overflow; 
	assign r = negate? ~(x&y) : (x&y); 
	assign negative = r[WIDTH-1];  
	assign zero = ~|r; 
	assign cout = 0; 
	assign overflow = 0; 
endmodule 



//Extensible NOT operation
module not_mod(x,r, negative, zero, cout, overflow);
	parameter WIDTH = 8; 
	input [WIDTH-1:0] x; 
	output [WIDTH-1:0] r; 
	output negative, zero, cout, overflow;
	
	assign r = ~x;
	assign negative = r[WIDTH-1];  
	assign zero = ~|r; 
	assign cout = 0; 
	assign overflow = 0; 
endmodule
	
	
//Extensible OR operation 
module or_mod(x,y,r,negate, negative, zero, cout, overflow); //negate accounts for nor operation
	parameter WIDTH = 8; 
	input [WIDTH-1:0] x,y; 
	input negate; 
	output [WIDTH-1:0] r; 
	output negative, zero, cout, overflow;
	assign r = negate? ~(x|y) : (x|y); 
	assign negative = r[WIDTH-1]; 
	assign zero = ~|r; 
	assign cout = 0; 
	assign overflow = 0; 
endmodule 

module xor_mod(x,y,r,negate, negative, zero, cout, overflow); //negate accounts for xnor operation 
	parameter WIDTH = 8; 
	input [WIDTH-1:0] x,y; 
	input negate; 
	output [WIDTH-1:0] r; 
	output negative, zero, cout, overflow; 

	assign r = negate? ~(x^y) : (x^y); 
	assign negative = r[WIDTH-1]; 
	assign zero = ~|r; 
	assign cout = 0; 
	assign overflow = 0; 
endmodule 

















