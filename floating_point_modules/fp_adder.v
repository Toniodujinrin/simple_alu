//half precision(16 bit) floating point adder
module fp_adder_subtractor(x, y, r, add_sub, negative, cout, overflow, zero, inf , nan, subnormal);
	//port declarations
	input [15:0] x,y; 
	output [15:0] r; 
	output negative, cout, overflow, zero, nan, subnormal, inf; 
	input add_sub; 

	//internal wire declarations
	wire x_sign, y_sign, x_implicit_bit, y_implicit_bit;
	wire [4:0] x_exponent, y_exponent; 
	wire [9:0] x_mantisa,y_mantisa;  
	wire temp_gt, temp_lt, temp_eq;
	wire mant_gt, mant_lt, mant_eq;
	wire swap;
	wire [1:0] temp_cout; 
	wire [4:0] greater_exponent, lesser_exponent;
	wire greater_sign, lesser_sign; 
	wire [10:0] greater_mantisa, lesser_mantisa; 
	wire [4:0] shift_value; 
	wire [10:0] aligned_mantisa; 
	wire aligned_zero;
	wire [11:0] greater_signed_mantisa; 
	wire [11:0] lesser_signed_mantisa;
	wire [11:0] final_adder_sum; 
	wire final_adder_carry; 
	wire [12:0] signed_final_sum;
	wire effective_sub;
	wire borrow;
	wire sum_negative;
	wire [12:0] abs_final_sum;
	wire [3:0] normalizer_shift; 
	wire final_sum_0; 
	wire [12:0] normalized_mantisa; 
	wire [9:0] rounded_mantisa; 
	wire [5:0] normalized_exponent; 
	wire [4:0] result_exponent; 
	wire [4:0] rounded_exponent; 
	wire normalized_exponent_underflow; 
	wire result_sign;
	wire rounder_carry_out, exponent_rounder_carry_out; 
	wire exp_overflow;
	wire [15:0] special_result; 
	wire special_operands; 
	
	//pre-assignments 
	assign x_sign = x[15]; 
	assign y_sign = y[15] ^ add_sub; 
	assign x_exponent = x[14:10]; 
	assign y_exponent = y[14:10]; 
	assign x_mantisa = x[9:0]; 
	assign y_mantisa = y[9:0]; 
	assign x_implicit_bit = x_exponent == 5'b0 ? 0:1; 
	assign y_implicit_bit = y_exponent == 5'b0 ? 0:1; 
	

	
	//Initiate internal modules
	simple_comparator#(.WIDTH(5))  EXP_COMPARATOR(.x(x_exponent),.y(y_exponent),.gt(temp_gt),.lt(temp_lt),.eq(temp_eq)); //5bit unsigned comparator to compare exponents to see which exponent is larger
	simple_comparator#(.WIDTH(11)) MANT_COMPARATOR(.x({x_implicit_bit,x_mantisa}), .y({y_implicit_bit,y_mantisa}), .gt(mant_gt), .lt(mant_lt), .eq(mant_eq));
	assign swap = temp_gt | (temp_eq & mant_gt);
	crossbar_switch#(.WIDTH(5)) CROSSBAR_1(.x1(x_exponent),.x2(y_exponent),.y1(lesser_exponent),.y2(greater_exponent),.s(swap));
	simplified_signed_adder#(.WIDTH(5)) SUBTRACTOR(.x(greater_exponent), .y(lesser_exponent), .add_sub(1'b1), .cout(temp_cout[0]), .s(shift_value)); //always positive since greater exponent is always minuend. Can only give overflow if exponent is 11111(value is infinity or Nan), this will be handled specially
	crossbar_switch#(.WIDTH(11)) CROSSBAR_2(.x1({x_implicit_bit,x_mantisa}), .x2({y_implicit_bit,y_mantisa}), .y1(lesser_mantisa), .y2(greater_mantisa), .s(swap)); //identifies the lesser mantisa and greater mantisa, using the exponent comparison result
	barrel_shifter_11_13#(.WIDTH(11)) MANTISSA_ALIGNER(.x(lesser_mantisa), .r(aligned_mantisa), .shift_count(shift_value), .mode(1'b0));// aligns mantissa of lesser value using the difference in exponents as the right shift count
	assign aligned_zero = ~|aligned_mantisa;
	crossbar_switch#(.WIDTH(1)) CROSSBAR_3(.x1(x_sign), .x2(y_sign), .y1(lesser_sign), .y2(greater_sign), .s(swap)); //identifies the lesser and greater sign bits based on exponent comparison
	complimenter_2#(.WIDTH(12)) LESSER_COMPLIMENTER(.x({1'b0,aligned_mantisa}),.r(lesser_signed_mantisa), .enable(effective_sub)); 
	complimenter_2#(.WIDTH(12)) GREATER_COMPLIMENTER(.x({1'b0,greater_mantisa}),.r(greater_signed_mantisa), .enable(1'b0)); 
	simplified_signed_adder#(.WIDTH(12)) FINAL_ADDER(.x(greater_signed_mantisa), .y(lesser_signed_mantisa), .add_sub(1'b0), .cout(final_adder_carry), .s(final_adder_sum));
	assign signed_final_sum = {final_adder_carry & ~effective_sub, final_adder_sum};
	assign effective_sub = greater_sign ^ lesser_sign;
	assign borrow = (~final_adder_carry) & (~aligned_zero);
	assign sum_negative = effective_sub & borrow;
	complimenter_2#(.WIDTH(13)) SUM_ABS(.x(signed_final_sum), .r(abs_final_sum), .enable(sum_negative));
	leading_zero_counter_13 LEADING_ZERO_COUNTER(.x(abs_final_sum),.q(normalizer_shift),.a(final_sum_0));
	barrel_shifter_11_13#(.WIDTH(13)) NORMALIZER(.x(abs_final_sum),.r(normalized_mantisa), .shift_count(final_sum_0?5'b00000:{1'b0,normalizer_shift}), .mode(1'b1)); 
	simplified_signed_adder#(.WIDTH(6)) EXPONENT_NORMALIZER(.x({1'b0,greater_exponent} + 6'd2), .y(final_sum_0?6'b000000:{2'b0,normalizer_shift}), .add_sub(1'b1), .cout(temp_cout[1]), .s(normalized_exponent)); 
	round_to_nearest_even_13 ROUNDER(.in(normalized_mantisa), .out(rounded_mantisa), .carry_out(rounder_carry_out)); 
	simplified_signed_adder#(.WIDTH(5)) EXPONENT_ROUNDER(.x(result_exponent), .y({4'b0000,rounder_carry_out}), .add_sub(1'b0), .cout(exponent_rounder_carry_out), .s(rounded_exponent));
	special_case_handler_adder SPECIAL_CASE_MODULE(.x(x),.y(y),.is_special(special_operands), .special_result(special_result), .add_sub(add_sub)); 
	
	//result derivation 
	assign normalized_exponent_underflow = normalized_exponent[5]; 
	assign result_exponent = normalized_exponent_underflow?5'b00000:normalized_exponent[4:0]; 
	assign result_sign = greater_sign ^ sum_negative; 
	assign exp_overflow = exponent_rounder_carry_out;
	assign r = (special_operands | exp_overflow) ? (exp_overflow ? {result_sign, 5'b11111, 10'b0} : special_result) : {result_sign, rounded_exponent, rounded_mantisa}; 
	
	//cpsr status bits 
	assign negative = r[15]; 
	assign zero = ~|r[14:0]; 
	assign cout = 1'b0; 
	assign overflow = exponent_rounder_carry_out | (rounded_exponent == 5'b11111); 
	assign subnormal = (~|r[14:10]) & (|r[9:0]); 
	assign inf = (&r[14:10]) & (~|r[9:0]); 
	assign nan = (&r[14:10]) & (|r[9:0]); 
	
	
endmodule 


//half precision rounding module
module round_to_nearest_even_13 (in, out, carry_out);
	input wire [12:0] in; // normalized mantissa: [12] = implicit bit, [11:2] = mantissa, [2:0] = guard, round, sticky
    output wire [9:0] out;  // rounded 10-bit mantissa
    output wire carry_out; // set if rounding causes mantissa overflow
    wire guard = in[2];
    wire round = in[1];   // no sticky bit; 
    wire sticky = |in[0]; // in[0] is already sticky if NORMALIZER packed it that way

  wire [9:0] mantissa = in[11:2];
  wire [9:0] rounded;

  simplified_signed_adder #(.WIDTH(10)) adder (
    .x(mantissa),
    .y(10'b0000000001),
    .add_sub(1'b0),
    .cout(carry_out),
    .s(rounded)
  );

  // round-to-nearest-even
  assign out = guard && (round || sticky || mantissa[0]) ? rounded : mantissa;
endmodule




module special_case_handler_adder (x,y,is_special, special_result, add_sub);
    input [15:0] x, y;
    output reg is_special;
    output reg [15:0] special_result;
	 input add_sub; 
    wire x_inf =  (&x[14:10]) & (~|x[9:0]);
    wire y_inf =  (&y[14:10]) & (~|y[9:0]);
    wire x_nan =  (&x[14:10]) & (|x[9:0]);
    wire y_nan =  (&y[14:10]) & (|y[9:0]);

    always @(*) 
	 begin
        is_special = 1'b0;
        special_result = 16'b0;

        if (x_nan || y_nan) 
			begin
            is_special = 1'b1;
            special_result = 16'h7FFF; // NaN (sign=0, exponent=all 1s, mantissa=nonzero)
			end 
		  else if (x_inf && y_inf) 
			begin
            is_special = 1'b1;
            if (x[15] == (y[15] ^ add_sub))
                special_result = {x[15], 5'b11111, 10'b0};
            else
                special_result = 16'h7FFF; // Inf + Inf = Inf, Inf - Inf = NaN
			end 
		  else if (x_inf) 
			begin
            is_special = 1'b1;
            special_result = x;
			end 
			else if (y_inf) 
			 begin
            is_special = 1'b1;
            special_result = {y[15] ^ add_sub, 5'b11111, 10'b0};
			 end
    end
	 
endmodule