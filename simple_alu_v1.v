module simple_alu_v1(opcode,x,y,r,overflow, negative, zero, cout, division_invalid_flag); 
	parameter WIDTH = 16; 
	input [4:0] opcode; 
	input [15:0] x,y; 
	output reg [15:0] r; 

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//output control flags
   ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////	
	output division_invalid_flag, overlow,negative, zero, cout; 
	
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//temporary outputs
   //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////	
	wire [15:0] temp_div_r, temp_mod_r, temp_mul_h_r, temp_mul_l_r, temp_sub_add_r, temp_lsl_r, temp_lsr_r, temp_asr_r, temp_asl_r, temp_or_nor_r, temp_and_nand_r, temp_xor_xnor_r; 
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
	wire add_sub; signed_unsigned, negate; 
	wire [2:0] shifter_mode;
   assign negate = ((opcode == 5'b01000) || (opcode == 5'b01001) || (opcode == 5'b01011))?1:0; 
	assign add_sub = opcode == 5'b00010 ?1:0  //Add or subtract control bits 
	assign signed_unsigned = opcode == 5'b00011||opcode == 5'b01111 ? 1:0; 
	//shifter modes///////
	//LSL = 3'b000
	//LSR = 3'b001 
	//ASR = 3'b010 
	//ASL = 3'b011 
	//ROR = 3'b100
	///////////////	
	assign shifter_mode = opcode == 5'b11000 ? 3'b001: opcode == 5'b11001 ? 3'b000: opcode == 5'b11010 ? 3'b010: opcode == 5'b11011 ? 3'b011 : 3'b100
	
   ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//initialize modules
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	and_mod#(.WIDTH(WIDTH))  AND_MODULE(.x(x),.y(y),.r(temp_and_nand_r),.negate(negate)); 
	not_mod#(.WIDTH(WIDTH))  NOT_MODULE(.x(x),.r(temp_nor_r)); 
	or_mod#(.WIDTH(WIDTH)) OR_MODULE(.x(x), .y(y), .r(temp_or_nor_r), .negate(negate)); 
	xor_mod#(.WIDTH(WIDTH)) XOR_MODULE(.x(x), .y(y), .r(temp_xor_xnor_r), .negate(negate)); 
	signed_adder#(.WIDTH(WIDTH)) ADDER_MODULE(.x(x), .y(y), .add_sub(add_sub), .overflow(temp_overflow[0]), .negative(temp_negative[0]), .zero(temp_zero[0]),.cout(temp_cout[0]),.s(temp_sub_add_r);
	comparator#(.WIDTH(WIDTH)) COMPARATOR_MODULE(.x(x),.y(y),.negative(temp_negative[1]),.zero(temp_zero[1]),.cout(temp_cout[1]),.overflow(temp_overflow[1]));
	divider#(.WIDTH(WIDTH)) DIVIDER_MODULE(.x(x),.y(y),.quo(temp_div_r),.rem(temp_mod_r),.invalid_flag(division_invalid_flag), .negative(temp_negative[2]), .zero(temp_zero[2]), .cout(temp_cout[2]), .overflow(temp_overflow[2])); 
	multiplier#(.WIDTH(WIDTH)) MULTIPLIER_MODULE(.x(x),.y(y),.r(temp_mul_full_r),.signed_unsigned(signed_unsigned), .negative(temp_negative[3]),.zero(temp_zero[3]), .overflow(temp_overflow[3]), .cout(temp_cout[3]));  
	n_barrel_rotator_shifter#(.WIDTH(WIDTH)) SHIFTER_MODULE(); 
	
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//hard decode opcode 
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	always@(opcode) 
		case(opcode)
		00000: r = x; 
				 negative = x[WIDTH-1] 
				 zero = x == 0 ? 1: 0; 
				 overflow = 0; 
				 cout = 0; 
		00001: r = temp_add_r; 
		00010: r = temp_sub_r; 
		00011: r = 
		
		
		

endmodule 







//logic ops 
//Extensible AND operation 
module and_mod(x,y,r, negate); //negate accounts for nand operaton 
	parameter WIDTH = 8; 
	input [WIDTH-1:0] x,y; 
	output [WIDTH-1:0] r; 
	assign r = negate? ~(x&y) : (x&y); 
endmodule 



//Extensible NOT operation
module not_mod(x,r);
	parameter WIDTH = 8; 
	input [WIDTH-1] x; 
	output [WIDTH-1:0] r; 
	assign r = ~x; 
endmodule
	
	
//Extensible OR operation 
module or_mod(x,y,r,negate); //negate accounts for nor operation
	parameter WIDTH = 8; 
	input [WIDTH-1:0] x,y; 
	output [WIDTH-1:0] r; 
	assign r = negate? ~(x|y) : (x|y); 
endmodule 

module xor_mod(x,y,r,negate); //negate accounts for xnor operation 
	parameter WIDTH = 8; 
	input [WIDTH-1:0] x,y; 
	output [WIDTH-1:0] r; 

	assign r = negate? ~(x^y) : (x^y); 
endmodule 

















