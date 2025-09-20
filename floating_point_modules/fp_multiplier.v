module fp_multiplier(x,y,r,negative, zero, overflow, cout, inf, nan, subnormal); 
	input [15:0] x, y; 
	output [15:0] r; 
	output negative, zero, overflow, cout, inf, nan, subnormal; 
	
	//wire declaration 
	wire x_sign = x[15]; 
	wire y_sign = y[15]; 
	wire [9:0] x_mantissa = x[9:0]; 
	wire [9:0] y_mantissa = y[9:0]; 
	wire [4:0] x_exp = x[14:10]; 
	wire [4:0] y_exp = y[14:10]; 
	wire [21:0] mantissa_product; 
	wire x_implicit_bit; 
	wire y_implicit_bit; 
	wire [4:0] normalization_shift; 
	wire product_0; 
	wire [21:0] normalized_product; 
	wire rounder_cout; 
	wire [9:0] rounded_mantissa; 
	wire [15:0] special_result; 
	wire special_case; 
	
	// Denormal handling
	wire x_is_denorm = ~|x_exp & |x_mantissa;
	wire y_is_denorm = ~|y_exp & |y_mantissa;
	wire [4:0] x_bias_exp = |x_exp ? x_exp : (x_is_denorm ? 5'd1 : 5'd0);
	wire [4:0] y_bias_exp = |y_exp ? y_exp : (y_is_denorm ? 5'd1 : 5'd0);
	
	// Exponent computation (using signed arithmetic to handle underflow)
	wire signed [6:0] signed_x_bias = $signed({1'b0, x_bias_exp});
	wire signed [6:0] signed_y_bias = $signed({1'b0, y_bias_exp});
	wire signed [6:0] exp_sum_s = signed_x_bias + signed_y_bias - 7'sd15;
	wire signed [6:0] lz_s = $signed({2'b0, normalization_shift});
	wire signed [6:0] exp_final_s = exp_sum_s - lz_s + 7'sd1;
	wire signed [6:0] exp_rounded_s = exp_final_s + $signed({6'b0, rounder_cout});
	
	wire is_overflow = (exp_rounded_s > 7'sd30);
	wire is_underflow = (exp_rounded_s < 7'sd1);
	wire signed [6:0] underflow_shift_s = 7'sd1 - exp_rounded_s;
	wire [4:0] clamp_shift = (underflow_shift_s > 7'sd11) ? 5'd11 : underflow_shift_s[4:0];
	
	wire [4:0] final_exp = is_overflow ? 5'b11111 : 
	                       is_underflow ? 5'd0 : 
	                       exp_rounded_s[4:0];
	
	wire [10:0] full_mant = {1'b1, rounded_mantissa};
	wire [10:0] shifted_full;
	barrel_shifter_11_13 #(.WIDTH(11)) MANT_RIGHT_SHIFTER (
	    .x(full_mant),
	    .r(shifted_full),
	    .shift_count(clamp_shift),
	    .mode(1'b0)  // right shift
	);
	
	wire [9:0] final_mantissa = is_overflow ? 10'b0 : 
	                            is_underflow ? shifted_full[9:0] : 
	                            rounded_mantissa;
	
	//assign implicit leading bits 
	assign x_implicit_bit = |x_exp; 
	assign y_implicit_bit = |y_exp; 
	
	//initiate submodules 
	unsigned_multiplier#(.WIDTH(11)) MANTISSA_MULTIPLIER(.x({x_implicit_bit,x_mantissa}),.y({y_implicit_bit,y_mantissa}),.r(mantissa_product));
	leading_zero_counter_22 LEADING_ZERO_COUNTER(.x(mantissa_product), .q(normalization_shift), .a(product_0));
	barrel_shifter_11_13#(.WIDTH(22)) LEFT_SHIFTER(.x(mantissa_product),.r(normalized_product), .shift_count(product_0 ? 5'b0 : normalization_shift), .mode(1'b1));
	round_to_nearest_even_22 ROUNDER(.in(normalized_product), .out(rounded_mantissa), .carry_out(rounder_cout));
	special_case_handler_multiplier SPECIAL_CASE_MODULE(.x(x),.y(y),.is_special(special_case), .special_result(special_result));
	
	//assign final outputs 
	assign r = special_case ? special_result : {x_sign ^ y_sign, final_exp, final_mantissa}; 
	assign negative = r[15]; 
	assign cout = 0; 
	assign zero = ~|r[14:0]; 
	assign overflow = !special_case & is_overflow; 
	assign subnormal = (~|r[14:10]) & |r[9:0]; 
	assign inf = (r[14:10] == 5'b11111) & ~|r[9:0]; 
	assign nan = (r[14:10] == 5'b11111) & |r[9:0]; 
	
endmodule

//rounding logic
module round_to_nearest_even_22 (in, out, carry_out);
	 input wire [21:0] in; // normalized mantissa (22 bits)
    output wire [9:0] out;  // rounded 10-bit mantissa
    output wire carry_out; // set if rounding causes mantissa overflow
    wire guard = in[10];
    wire round = in[9];
    wire sticky = |in[8:0];
    wire [9:0] mantissa = in[20:11]; // 10-bit mantissa
    wire [9:0] rounded;

    // Instantiate adder to compute mantissa + 1
    simplified_signed_adder#(.WIDTH(10)) adder (
        .x(mantissa),
        .y(10'b0000000001),
        .add_sub(1'b0), // Add operation
        .cout(carry_out),
        .s(rounded)
    );

    // Round-to-nearest-even: round up if guard=1 and (round=1 or sticky=1 or LSB=1)
    assign out = guard ? (( round| sticky) ? rounded :(mantissa[0]?rounded:mantissa)) : mantissa;
endmodule


//logic to handle special cases: infinity, nan, zero 
module special_case_handler_multiplier (x,y,is_special, special_result);
   input [15:0] x, y;
   output reg is_special;
   output reg [15:0] special_result; 
   wire x_inf = (x[14:10] == 5'b11111) && (x[9:0] == 0);
   wire y_inf = (y[14:10] == 5'b11111) && (y[9:0] == 0);
   wire x_nan = (x[14:10] == 5'b11111) && (x[9:0] != 0);
   wire y_nan = (y[14:10] == 5'b11111) && (y[9:0] != 0);
	wire x_zero = (x[14:0] == 0);
	wire y_zero = (y[14:0] == 0);

   always @(*)
	begin
      is_special = 0;
      special_result = 0;

	   if (x_nan || y_nan)
			begin
				is_special = 1;
				if (x_nan)
					special_result = {x[15], 5'b11111, x[9:0]};
				else
					special_result = {y[15], 5'b11111, y[9:0]};
			end 
		else if (x_inf && y_inf) 
			begin
				is_special = 1;
				special_result = {x[15]^y[15], 5'b11111, 10'b0}; // -Inf * +Inf = -Inf, -Inf * -Inf = Inf, Inf * Inf = Inf
			end
		else if (x_inf & ~y_zero) 
			begin
				is_special = 1;
				special_result = {x[15]^y[15],x[14:0]};
			end
		else if (y_inf & ~x_zero) 
			begin
				is_special = 1;
				special_result = {y[15]^x[15],y[14:0]};
			end
		else if ((x_zero & y_inf) | (y_zero & x_inf)) 
			begin
				is_special = 1;
				special_result = 16'h7FFF; // NaN
			end
   end
endmodule
