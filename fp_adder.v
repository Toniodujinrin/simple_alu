//half precision(16 bit) floating point adder
module fp_adder_subtractor(x, y, r, add_sub, negative, cout, overflow, zero); 
	input [15:0] x,y; 
	output [15:0] r; 
	output negative, cout, overflow, zero; 
	input add_sub; 

	
	wire x_sign, y_sign, r_sign, x_implicit_bit, y_implicit_bit;
	wire [4:0] x_exponent, y_exponent, r_exponent; 
	wire [9:0] x_mantisa,y_mantisa, r_mantisa;  
	
	
	assign x_sign = x[15]; 
	assign y_sign = y[15]; 
	assign x_exponent = x[14:10]; 
	assign y_exponent = y[14:10]; 
	assign x_mantisa = x[9:0]; 
	assign y_mantisa = y[9:0] 
	assign x_implicit_bit = x_exponent == 5'b0 ? 0:1; 
	assign y_implicit_bit = y_exponent == 5'b0? 0: 1; 
	
	wire temp_gt, temp_lt, temp_eq, temp_cout;
	wire [4:0] greater_exponent, lesser_exponent;
	wire greater_sign, lesser_sign; 
	wire [10:0] greater_mantisa, lesser_mantisa; 
	wire[4:0] shift_value; 
	wire [10:0] aligned_mantisa; 
	wire [11:0] greater_signed_mantisa; 
	wire [11:0] lesser_signed_mantisa;
	wire [11:0] final_adder_sum; 
	wire final_adder_carry; 
	wire [12:0] final_sum; 
	wire [3:0] normalizer_shift; 
	wire final_sum_0; 
	
	simple_comparator#(.WIDTH(5))  UNSIGNED_COMPARATOR(.x(x_exponent),.y(y_exponent),.gt(temp_gt),.lt(temp_lt),.eq(temp_eq)); //5bit unsigned comparator to compare exponents to see which exponent is larger
	crossbar_switch CROSSBAR_1(.x1(x_exponent),.x2(y_exponent),.y1(lesser_exponent),.y2(greater_exponent),.s(temp_gt));\
	simplified_signed_adder#(.WIDTH(5)) SUBTRACTOR(.x(greater_exponent), .y(lesser_exponent), .add_sub(1'b1), .cout(temp_cout), .s(shift_value)); //always positive since greater exponent is always minuend. Can only give overflow if exponent is 11111(value is infinity or Nan), this will be handled specially
	
	
	crossbar_switch#(.WIDTH(11)) CROSSBAR_2(.x1({x_implicit_bit,x_mantisa}), .x2({y_implicit_bit,y_mantisa}), .y1(greater_mantisa), .y2(lesser_mantisa), .s(temp_gt)); 
	barrel_shifter_11 MANTISSA_ALIGNER(.x(lesser_mantisa), .r(aligned_mantisa), .shift_count(shift_value), .mode(1'b0)); 
	
	crossbar_switch#(.WIDTH(1)) CROSSBAR_3(.x1(x_sign), .x2(y_sign), .y1(greater_sign), .y2(lesser_sign), .s(temp_gt)); 
	
	complimenter_2#(.WIDTH(12)) LESSER_COMPLIMENTER(.x({1'b0,lesser_mantisa}),.r(lesser_signed_mantisa), .enable(lesser_sign)); 
	complimenter_2#(.WIDTH(12)) GREATER_COMPLIMENTER(.x({1'b0,greater_mantisa}),.r(greater_signed_mantisa), .enable(greater_sign)); 
	
	simplified_signed_adder#(.WIDTH(12)) FINAL_ADDER(.x(greater_signed_mantisa), .y(lesser_signed_mantisa), .add_sub(1'b0), .cout(final_adder_carry), .s(final_adder_sum));
	assign final_sum = {final_adder_carry, final_adder_sum}; 
	
	leading_zero_counter LEADING_ZERO_COUNTER(.x(final_sum),.q(normalizer_shift),.a(final_sum_0));
	 
endmodule 


//13 bit right or left barrel shifter 4bit shift count 
module barrel_shifter_13(x,r, shift_count, mode);
	input [12:0] x; 
	output [12:0] r; 
	input mode; 
	input [4:0] shift_count; 
	wire [10:0] stage_shift [3:0] 
	//mode == 1 - left shift
	//mode == 0 - right shift
	chained_mux(.x(mode?11'b0:11'b0),.y(x),.s(shift_count[4]),.out(stage_shift[0]));
	chained_mux(.x(mode?{x[2:0],8'b0}:{8'b0,x[10:8]}),.y(stage_shift[0]),.s(shift_count[3]),.out(stage_shift[1]));
	chained_mux(.x(mode?{x[6:0], 4'b0}:{4'b0,x[10:4]}), .y(stage_shift[1]), .s(shift_count[2]), .out(stage_shift[2])); 
	chained_mux(.x(mode?{x[8:0], 2'b0}:{2'b0,x[10:2]}), .y(stage_shift[2]), .s(shift_count[1]), .out(stage_shift[3])); 
	chained_mux(.x(mode?{x[9:0], 1'b0}:{1'b0,x[10:1]}), .y(stage_shift[3]), .s(shift_count[0]), .out(r));

endmodule

//11 bit right or left barrel shifter 5bit shift count 
module barrel_shifter_11(x,r, shift_count, mode);
	input [10:0] x; 
	output [10:0] r; 
	input mode; 
	input [4:0] shift_count; 
	wire [10:0] stage_shift [3:0] 
	//mode == 1 - left shift
	//mode == 0 - right shift
	chained_mux(.x(mode?11'b0:11'b0),.y(x),.s(shift_count[4]),.out(stage_shift[0]));
	chained_mux(.x(mode?{x[2:0],8'b0}:{8'b0,x[10:8]}),.y(stage_shift[0]),.s(shift_count[3]),.out(stage_shift[1]));
	chained_mux(.x(mode?{x[6:0], 4'b0}:{4'b0,x[10:4]}), .y(stage_shift[1]), .s(shift_count[2]), .out(stage_shift[2])); 
	chained_mux(.x(mode?{x[8:0], 2'b0}:{2'b0,x[10:2]}), .y(stage_shift[2]), .s(shift_count[1]), .out(stage_shift[3])); 
	chained_mux(.x(mode?{x[9:0], 1'b0}:{1'b0,x[10:1]}), .y(stage_shift[3]), .s(shift_count[0]), .out(r));

endmodule