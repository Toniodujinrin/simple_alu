//half precision floating point comparator 
module fp_comparator(x,y, negative, zero, overflow, cout, inf, subnormal, nan); 
	input [15:0] x,y; 
	output wire negative, zero, cout, overflow; 
	
	wire x_sign, y_sign;  
	wire [4:0] x_exponent, y_exponent; 
	wire [9:0] x_mantissa, y_mantissa;
	
	assign x_sign = x[15];
	assign y_sign = y[15];
	assign x_exponent = x[14:10];
	assign y_exponent = y[14:10];
	assign x_mantissa = x[9:0];
	assign y_mantissa = y[9:0];
	
	//individual section comparison bits 
	wire sign_eq;  
	wire exponent_gt, exponent_eq, exponent_lt; 
	wire mantissa_gt, mantissa_eq, mantissa_lt; 
	wire gt, lt, eq; 
	wire mag_lt, mag_gt, mag_eq; 
	wire y_nan, x_nan, y_inf,x_inf, y_subnormal,x_subnormal; 

	//compare exponent magnitude
	simple_comparator#(.WIDTH(5))  EXPONENT_COMPARE(.x(x_exponent), .y(y_exponent), .gt(exponent_gt), .lt(exponent_lt), .eq(exponent_eq)); 
	//compare mantisa magnitude
	simple_comparator#(.WIDTH(10)) MANTISA_COMPARE (.x(x_mantissa), .y(y_mantissa), .gt(mantissa_gt), .lt(mantissa_lt), .eq(mantissa_eq)); 
	
	//overal magnitude comparison
	assign mag_gt = exponent_gt | (exponent_eq&mantissa_gt); 
	assign mag_lt = exponent_lt | (exponent_eq&mantissa_lt); 
	assign mag_eq = exponent_eq&mantissa_eq; 
	
	//overal signed comparison
	assign sign_eq = ~(x_sign ^ y_sign); 
	assign gt = (~x_sign&y_sign) | (~x_sign & ~y_sign & mag_gt ) | (x_sign & y_sign & mag_lt); //if x is +ve and y is -ve (gt), if x is +ve and y is +ve and x magnitude > y magnitude (gt), if x is -ve and y is -ve and x magnitude < y magnitude (gt)
	assign eq = sign_eq & mag_eq; 
	assign lt = ~(gt | eq); 
	
	assign negative = lt; 
	assign zero = eq & ~inf & ~nan; 
	//cout and overflow are default assigned to 0
	assign cout = 1'b0; 
	assign overflow = 1'b0; 
	assign x_subnormal = (~|x_exponent & |x_mantissa); 
	assign y_subnormal = (~|y_exponent & |y_mantissa); 
	assign x_inf = (&x_exponent & ~|x_mantissa); 
	assign y_inf = (&y_exponent & ~|y_mantissa); 
	assign x_nan = (&x_exponent & |x_mantissa); 
	assign y_nan = (&y_exponent & |y_mantissa); 
	assign nan = x_nan | y_nan;  
	assign subnormal = x_subnormal|y_subnormal; 
	assign inf = x_inf | y_inf;   

endmodule 