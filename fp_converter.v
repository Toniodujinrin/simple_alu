module fp_converter(x,r,negative,cout,overflow,zero, inf , nan, subnormal); 
	input [15:0] x; 
	output [15:0] r; 
	output negative, cout, overflow, zero, inf, nan, subnormal; 
	
	wire x_sign = x[15]; 
	wire [4:0] x_exponent = x[14:10]; 
	wire [9:0] x_mantissa = x[9:0]; 
	
	wire [4:0] unbiased_exponent; 
	wire exponent_unbias_cout; //not needed 
	wire shift_diff_1_cout, shift_diff_2_cout; 
	wire implicit_leading_bit = 1'b1; 
	wire unbiased_exp_gt_10, unbiased_exp_lt_10, unbiased_exp_eq_10; 
	wire [4:0] shift_diff_1, shift_diff_2, mantissa_shift; 
	wire [15:0] unsigned_normal_int, signed_normal_int; 
	wire special_case, special_case_overflow ; 
	wire[15:0] special_case_result;
	
	
	
	simplified_signed_adder#(.WIDTH(5)) EXPONENT_UNBIAS(.x(x_exponent), .y(5'd15), .add_sub(1'b1), .cout(exponent_unbias_cout), .s(unbiased_exponent)); 
	simple_comparator#(.WIDTH(5))       COMPARE_10(.x(unbiased_exponent),.y(5'd10),.gt(unbiased_exp_gt_10),.lt(unbiased_exp_lt_10),.eq(unbiased_exp_eq_10));
	simplified_signed_adder#(.WIDTH(5)) SHIFT_DIFF1(.x(unbiased_exponent), .y(5'd10), .add_sub(1'b1), .cout(shift_diff_1_cout), .s(shift_diff_1));
	simplified_signed_adder#(.WIDTH(5)) SHIFT_DIFF2(.x(5'd10), .y(unbiased_exponent), .add_sub(1'b1), .cout(shift_diff_2_cout), .s(shift_diff_2)); 
	assign mantissa_shift = unbiased_exp_lt_10 ? shift_diff_2: shift_diff_1; 
	barrel_shifter_11_13#(.WIDTH(16))   BARREL_SHIFTER(.x({5'd0,implicit_leading_bit,x_mantissa}),.r(unsigned_normal_int), .shift_count(mantissa_shift), .mode(~unbiased_exp_lt_10)); 
	complimenter_2#(.WIDTH(16))         COMPLIMENTER (.x(unsigned_normal_int), .r(signed_normal_int), .enable(x_sign));
	special_case_converter              SPECIAL_CASE_MODULE(.x(x),.special_case(special_case), .special_case_result(special_case_result), .special_case_overflow(special_case_overflow), .inf(inf), .nan(nan), .subnormal(subnormal));
	
	assign r = special_case? special_case_result: signed_normal_int; 
	assign negative = r[15]; 
	assign cout = 1'b0; 
	assign overflow = special_case_overflow | unsigned_normal_int[15];   //overflow if unsigned integer MSB is 1. 
	assign zero= ~|r; 
	


endmodule 





module special_case_converter(x,special_case, special_case_result, special_case_overflow, inf, nan, subnormal); 
	input [15:0] x; 
	output reg special_case, special_case_overflow, inf, nan, subnormal; 
	output reg [15:0] special_case_result; 
	
	wire x_sign = x[15]; 
	wire [4:0] x_exponent = x[14:10]; 
	wire [9:0] x_mantissa = x[9:0]; 
	//TODO fix for cases like 1.xxx, check for exp = 01111
	always @(*)
		begin 
			if((~|x_exponent)& (~|x_mantissa))  //zero 
				begin 
					special_case = 1'b1; 
					special_case_result = 16'd0; 
					special_case_overflow = 1'b0; 
					inf = 1'b0; 
					nan = 1'b0; 
					subnormal = 1'b0; 
				end 
			else if((~|x_exponent)&(|x_mantissa))  //subnormal value
				begin 
					special_case = 1'b1; 
					special_case_result = 16'd0; 
					special_case_overflow = 1'b0; 
					inf = 1'b0; 
					nan = 1'b0; 
					subnormal = 1'b1; 
					
				end 
			else if((&x_exponent) & (~|x_mantissa) )  //+ or = infinity
				begin 
					special_case = 1'b1; 
					special_case_overflow = 1'b1; 
					special_case_result = x_sign ? 16'h8000 : 16'h7FFF;
					inf = 1'b1; 
					nan = 1'b0; 
					subnormal = 1'b0; 
				end 
			else if ((&x_exponent) & (|x_mantissa)) //NAN
				begin 
					special_case = 1'b1; 
					special_case_overflow = 1'b1; 
					inf = 1'b0; 
					nan = 1'b1; 
					subnormal = 1'b0; 
					
				end 
			else if ((~x_exponent[4]) & (&x_exponent[3:0])) //decimal = 1.XXX ; truncates to 1 as integer; occurs when exponent = 01111
				begin
					special_case = 1'b1; 
					special_case_result = 16'd1; 
					special_case_overflow = 1'b0; 
					inf = 1'b0; 
					nan = 1'b0; 
					subnormal = 1'b0; 
				end 
			else if ((~x_exponent[4]) & (|x_exponent[3:0])) //decimal = 0.XXX; truncates to 0 as integer ; occurs when exponent = 0XXXX (except 01111)
				begin 
					special_case = 1'b1; 
					special_case_result = 16'd0; 
					special_case_overflow = 1'b0; 
					inf = 1'b0; 
					nan = 1'b0; 
					subnormal = 1'b0; 
				end 
			else 
				begin 
					special_case = 1'b0; 
					special_case_overflow = 1'b0; 
					inf = 1'b0; 
					nan = 1'b0; 
					subnormal = 1'b0; 
				end 
		end 
		
endmodule