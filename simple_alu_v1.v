module simple_alu_v1(partial_instruction,x, y, option_bits, r,overflow, negative, zero, cout, inf, subnormal, nan); 
	parameter WIDTH = 16; 
	input [6:0] partial_instruction;  
	input [15:0] x,y; 
	input [2:0] option_bits; 
	output reg [15:0] r; 
	
	wire [1:0] class_code = partial_instruction[6:5];
	wire [4:0] opcode_class_01; 
	wire [1:0] opcode_class_00; 
	wire [2:0] opcode_class_10; 
	wire [2:0] opcode_class_11; 
	wire class_10_option_code; 
	
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//assign opcode bits accroding to class code
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	assign class_10_option_code = partial_instruction[1]; //Get opt field for class 10 instructions 
	assign opcode_class_01 = class_code == 2'b01 ? partial_instruction[4:0] : 5'bz; 
	assign opcode_class_00 = class_code == 2'b00 ? partial_instruction[4:3] : 2'bz; 
	assign opcode_class_10 = class_code == 2'b10 && class_10_option_code ? partial_instruction[4:2] : 3'bz; 
	assign opcode_class_11 = class_code == 2'b11 ? partial_instruction[4:2] : 3'bz; 
	

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//output control flags
   ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////	
	output reg overflow,negative, zero, cout, inf, subnormal, nan; 
	
	
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
	//internal control signals based on opcode bits
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	wire add_sub, signed_unsigned_multiplier, negate, signed_unsigned_comparator, fp_add_sub; 
	wire [2:0] shifter_mode;
   assign negate = ((opcode_class_01 == 5'b01000) || (opcode_class_01 == 5'b01001) || (opcode_class_01 == 5'b01011))?1:0; 
	assign add_sub = ((opcode_class_01 == 5'b00010) || (opcode_class_00 == 2'b11)) ?1:0;  //Add or subtract control bits 
	assign signed_unsigned_multiplier = (opcode_class_01 == 5'b00011)||(opcode_class_01 == 5'b01111) ? 1:0; 
	assign signed_unsigned_comparator = (class_code == 2'b01 && option_bits == 3'b001) || (class_code == 2'b10 && opcode_class_10 == 3'b000) ? 1:0; //signed, unsigned and floating point compare operations are distinguished using option bits for class 01, and opcode bits for class  
	assign fp_add_sub = opcode_class_01 == 5'b10010 ? 1:0; 
	//shifter modes///////
	//LSL = 3'b000
	//LSR = 3'b001 
	//ASR = 3'b010 
	//ASL = 3'b011 
	//ROR = 3'b100
	///////////////	
	assign shifter_mode = ((opcode_class_01 == 5'b11000) || (opcode_class_11 == 3'b001))? 3'b001:  //assign shifter mode for which based on class 01 or class 11 opcodes 
								 ((opcode_class_01 == 5'b11001) || (opcode_class_11 == 3'b000))? 3'b000: 
								 ((opcode_class_01 == 5'b11010) || (opcode_class_11 == 3'b010))? 3'b010:
								 ((opcode_class_01 == 5'b11011) || (opcode_class_11 == 3'b011))? 3'b011: 
																													  3'b100; 
	
	
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
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//hard decode opcode 
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	always@(partial_instruction) 
		begin
		inf = 0; 
		nan = 0; 
		subnormal = 0; 
		
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//class 01 instructions
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		if(class_code == 2'b01)  
			begin
				case(opcode_class_01)
				5'b00000: begin                             //MOV /  MOVF
						r = x; 
						negative = x[WIDTH-1]; 
						zero = ~|x ; 
						overflow = (option_bits == 3'b001)? (&r[14:0]) & (~|r[9:0]) | (&r[14:0]) & (|r[9:0]) : 0  ; 
						cout = 1'b0; 
						subnormal = (option_bits == 3'b001) ?  (~|x[14:10]) & (|x[9:0]):1'b0; 
						inf = (option_bits == 3'b001) ?  (&r[14:0]) & (~|r[9:0]):1'b0; 
						nan = (option_bits == 3'b001) ? (&r[14:0]) & (|r[9:0]) :1'b0 ; 
						end 
				5'b00001:begin 
						r = temp_sub_add_r;                  //ADD
						negative = temp_negative[0]; 
						zero = temp_zero[0]; 
						overflow = temp_overflow[0]; 
						cout = temp_cout[0]; 
						end
				5'b00010: begin                              //SUB
						r = temp_sub_add_r; 
						negative = temp_negative[0]; 
						zero = temp_zero[0]; 
						overflow = temp_overflow[0]; 
						cout = temp_cout[0]; 
						end 
				5'b00011: begin
						r = temp_mul_h_r;                     //MULH
						negative = temp_negative[3]; 
						zero = temp_zero[3]; 
						overflow = temp_overflow[3]; 
						cout = temp_cout[3]; 	
						end
				5'b00100: begin                               //UMULH
						r = temp_mul_h_r; 
						negative = temp_negative[3]; 
						zero = temp_zero[3]; 
						overflow = temp_overflow[3]; 
						cout = temp_cout[3];
						end 
				5'b00101: begin                               //CMP / UCMP / FCMP
						r = 16'b0; //no output for comparison operation, just CPSR update
						negative = (option_bits == 3'b010)? temp_negative[10]:temp_negative[1]; 
						zero = (option_bits == 3'b010)?temp_zero[10]:temp_zero[1]; 
						overflow = (option_bits == 3'b010)? temp_overflow[10]: temp_overflow[1]; 
						cout = (option_bits ==3'b010)? temp_cout[10]:temp_cout[1];
						inf = (option_bits ==3'b010)? temp_inf[1]:1'b0; 
						nan = (option_bits ==3'b010)? temp_nan[1]:1'b0; 
						subnormal = (option_bits == 3'b010)? temp_subnormal[1]:1'b0; 
						end
				5'b00110: begin                       //AND
						r = temp_and_nand_r; 
						negative = temp_negative[5]; 
						zero = temp_zero[5]; 
						overflow = temp_overflow[5]; 
						cout = temp_cout[5]; 
						end
				5'b00111: begin                       //OR
						r = temp_or_nor_r; 
						negative = temp_negative[7]; 
						zero = temp_zero[7]; 
						overflow = temp_overflow[7]; 
						cout = temp_cout[7]; 
						end
				5'b01000: begin                       //NOR
						r = temp_or_nor_r; 
						negative = temp_negative[7]; 
						zero = temp_zero[7]; 
						overflow = temp_overflow[7]; 
						cout = temp_cout[7]; 
						end
				5'b01001: begin                      //NAND
						r = temp_and_nand_r; 
						negative = temp_negative[5]; 
						zero = temp_zero[5]; 
						overflow = temp_overflow[5]; 
						cout = temp_cout[5]; 
						end 
				5'b01010: begin                        //XOR   
						r = temp_xor_xnor_r; 
						negative = temp_negative[8]; 
						zero = temp_zero[8]; 
						overflow = temp_overflow[8]; 
						cout = temp_cout[8];	
						end
				5'b01011: begin                       //XNOR
						r = temp_xor_xnor_r; 
						negative = temp_negative[8]; 
						zero = temp_zero[8]; 
						overflow = temp_overflow[8]; 
						cout = temp_cout[8];			
						end
				5'b01100: begin                        //NOT
						r = temp_not_r; 
						negative = temp_negative[6]; 
						zero = temp_zero[6]; 
						overflow = temp_overflow[6]; 
						cout = temp_cout[6];			
						end

				5'b01111: begin                        //MULL 
						r = temp_mul_l_r; 
						negative = temp_negative[2]; 
						zero = temp_zero[2]; 
						overflow = temp_overflow[2]; 
						cout = temp_cout[2];
						end
				5'b10000: begin                         //UMULL
						r = temp_mul_l_r;              
						negative = temp_negative[2]; 
						zero = temp_zero[2]; 
						overflow = temp_overflow[2]; 
						cout = temp_cout[2];
						end
				5'b10001: begin                          //FADD
						r = temp_fp_add_sub_r; 
						negative = temp_negative[9]; 
						zero = temp_zero[9]; 
						overflow = temp_overflow[9]; 
						cout = temp_cout[9];
						inf = temp_inf[0]; 
						nan = temp_nan[0];
						subnormal = temp_subnormal[0]; 
						end
				5'b10010: begin                           //FSUB 
						r = temp_fp_add_sub_r; 
						negative = temp_negative[9]; 
						zero = temp_zero[9]; 
						overflow = temp_overflow[9]; 
						cout = temp_cout[9];
						inf = temp_inf[0]; 
						nan = temp_nan[0]; 
						subnormal = temp_subnormal[0]; 
						end
				5'b10011: begin                         //FMUL                  
						r = temp_fp_mul_r; 
						negative = temp_negative[11]; 
						zero = temp_zero[11]; 
						overflow = temp_overflow[11]; 
						cout = temp_cout[11];
						inf = temp_inf[2]; 
						nan = temp_nan[2]; 
						subnormal = temp_subnormal[2]; 
						end
				5'b10110: begin                        //ITOF / FTOI 
						r = (option_bits == 3'b000 )? temp_fp_conv_r :temp_int_conv_r; 
						negative = (option_bits == 3'b000 )?temp_negative[12]: temp_negative[13]; 
						zero = (option_bits == 3'b000 )?temp_zero[12]: temp_zero[13]; 
						overflow = (option_bits == 3'b000 )? temp_overflow[12]: temp_overflow[13] ; 
						cout = (option_bits == 3'b000 )? temp_cout[12]: temp_cout[13]; 
						inf = (option_bits == 3'b000 )? temp_inf[3]:1'b0; 
						nan = (option_bits == 3'b000 )?temp_nan[3]:1'b0; 
						subnormal = (option_bits == 3'b000 )?temp_subnormal[3]: 1'b0; 
						end
				
				5'b11000: begin                      //LSR            
						r = temp_shift_r; 
						negative = temp_negative[4]; 
						zero = temp_zero[4]; 
						overflow = temp_overflow[4]; 
						cout = temp_cout[4];
						end 
				5'b11001: begin                     //LSL
						r = temp_shift_r; 
						negative = temp_negative[4]; 
						zero = temp_zero[4]; 
						overflow = temp_overflow[4]; 
						cout = temp_cout[4];
						end 
				5'b11010: begin                    //ASR
						r = temp_shift_r; 
						negative = temp_negative[4]; 
						zero = temp_zero[4]; 
						overflow = temp_overflow[4]; 
						cout = temp_cout[4];
						end
				5'b11011: begin                    //ASL
						r = temp_shift_r; 
						negative = temp_negative[4]; 
						zero = temp_zero[4]; 
						overflow = temp_overflow[4]; 
						cout = temp_cout[4];
						end
				5'b11100: begin                   //ROR
						r = temp_shift_r; 
						negative = temp_negative[4]; 
						zero = temp_zero[4]; 
						overflow = temp_overflow[4]; 
						cout = temp_cout[4];
						end
				default: begin
						r = 16'b0; 
						negative = 1'b0; 
						zero = 1'b0; 
						overflow = 1'b0; 
						cout = 1'b0; 
						end 
				endcase 
			end 
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//class 00 instructions
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		else if(class_code == 2'b00)   
			begin
				case(opcode_class_00)
					2'b00: begin 
							r = temp_sub_add_r;                  //ADD
							negative = temp_negative[0]; 
							zero = temp_zero[0]; 
							overflow = temp_overflow[0]; 
							cout = temp_cout[0]; 
							end 
					2'b01: begin
							r = temp_sub_add_r;                  //ADD
							negative = temp_negative[0]; 
							zero = temp_zero[0]; 
							overflow = temp_overflow[0]; 
							cout = temp_cout[0]; 
						end 
					2'b10: begin
							r = temp_sub_add_r;                  //ADD
							negative = temp_negative[0]; 
							zero = temp_zero[0]; 
							overflow = temp_overflow[0]; 
							cout = temp_cout[0]; 
						end 
					2'b11: begin
							r = temp_sub_add_r;                  //ADD
							negative = temp_negative[0]; 
							zero = temp_zero[0]; 
							overflow = temp_overflow[0]; 
							cout = temp_cout[0]; 
						end
					default:begin										//DEFAULT
							r = 16'b0; 
							negative = 1'b0; 
							zero = 1'b0; 
							overflow = 1'b0; 
							cout = 1'b0; 
					end
				endcase
			end
		
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//class 10 instructions
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		else if(class_code == 2'b10)  
			begin 
				case(opcode_class_10)
					3'b000: begin 									//CMP 
						r = 16'b0; //no output for comparison operation, just CPSR update
						negative = temp_negative[1]; 
						zero = temp_zero[1]; 
						overflow = temp_overflow[1]; 
						cout = temp_cout[1];
					end 
					
					3'b001: begin 								   //UCMP 
						r = 16'b0; //no output for comparison operation, just CPSR update
						negative = temp_negative[1]; 
						zero = temp_zero[1]; 
						overflow = temp_overflow[1]; 
						cout = temp_cout[1];
					end
					
					default:begin                         //DEFAULT
						r = 16'b0; 
						negative = 1'b0; 
						zero = 1'b0; 
						overflow = 1'b0; 
						cout = 1'b0; 
					end 
				endcase
			end 
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//class 11 instructions
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////		
		else  
			begin
				case(opcode_class_11)
					3'b000: begin							//LSL
						r = temp_shift_r; 
						negative = temp_negative[4]; 
						zero = temp_zero[4]; 
						overflow = temp_overflow[4]; 
						cout = temp_cout[4];
					end 
					
					3'b001: begin 							//LSR
						r = temp_shift_r; 
						negative = temp_negative[4]; 
						zero = temp_zero[4]; 
						overflow = temp_overflow[4]; 
						cout = temp_cout[4];
					end
					
					3'b010: begin 							//ASR
						r = temp_shift_r; 
						negative = temp_negative[4]; 
						zero = temp_zero[4]; 
						overflow = temp_overflow[4]; 
						cout = temp_cout[4];
					end 
					
					3'b011: begin 							//ASL
						r = temp_shift_r; 
						negative = temp_negative[4]; 
						zero = temp_zero[4]; 
						overflow = temp_overflow[4]; 
						cout = temp_cout[4];
					end
					
					3'b100:begin							//ROR
						r = temp_shift_r; 
						negative = temp_negative[4]; 
						zero = temp_zero[4]; 
						overflow = temp_overflow[4]; 
						cout = temp_cout[4];
					end 
					
					default: begin                  //DEFAULT
						r = 16'b0; 
						negative = 1'b0; 
						zero = 1'b0; 
						overflow = 1'b0; 
						cout = 1'b0; 
					end 
				endcase
			end
		end 
		
endmodule 


